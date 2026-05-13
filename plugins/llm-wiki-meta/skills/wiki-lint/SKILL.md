---
name: wiki-lint
description: Meta-level lint entry point that dispatches to the currently attached sub-wiki's local <name>-wiki-lint skill. Use when the user asks to lint, audit, validate, repair, clean up, or health-check a wiki AND a wiki is attached. Refuses with a pointer to attach-wiki when no wiki is attached — never runs at the top-level meta scope, and never lints across multiple wikis in one invocation.
---

# wiki-lint (meta)

## Contract

A thin dispatcher. This skill performs no lint work itself. It resolves the currently attached sub-wiki, locates that wiki's local `<name>-wiki-lint` skill, and follows the local skill's contract with the attached wiki directory as the working context. If no wiki is attached, refuse and point the user at `attach-wiki` — the meta scope has no schema to lint against.

## When To Use

- The user asks to lint, audit, validate, repair, clean up, or health-check the wiki AND a wiki is attached.
- The user typed `/wiki-lint` from the top-level `llm-wiki/` directory.

## When Not To Use

- No wiki is attached → refuse. Do not lint the meta repository itself; this plugin is not an LLM-wiki target.
- The user wants to lint *every* wiki — refuse and ask which one to attach. One wiki per invocation. The user can repeat after re-attaching.
- The user is already inside a wiki dir and the local `<name>-wiki-lint` is directly available — let that one fire instead.

## Locate The Root And Attached Wiki

Same as `wiki-ingest` / `wiki-query`:

1. Resolve ROOT using the shared detection rule, or accept an explicit path.
2. Read `<ROOT>/.claude/state/attached-wiki`. If missing or empty, **refuse**.
3. Let `WIKI` be the attached name and `WIKI_DIR="$ROOT/$WIKI"`. Validate it exists and contains `CLAUDE.md` or `AGENTS.md`. If not, refuse with a pointer to `detach-wiki` / `attach-wiki <other>`.

## Procedure

1. Resolve ROOT and the attached wiki. Refuse early if no wiki is attached.
2. Locate the local skill at `WIKI_DIR/.claude/skills/${WIKI}-wiki-lint/SKILL.md`. If missing, refuse with `error: local skill '${WIKI}-wiki-lint' not found under ${WIKI}`. Do not fall back to a generic implementation.
3. **Read** the local SKILL.md and follow its contract. Treat `WIKI_DIR` as the working directory for every step.
4. Run the mechanical check first if `WIKI_DIR/tools/wiki_health.py` exists:

   ```bash
   python3 "$WIKI_DIR/tools/wiki_health.py" "$WIKI_DIR"
   ```

   Use its output as the starting point for the lint pass.
5. Apply the lint categories listed in the local SKILL.md: structure, wikilinks, index coverage, manifests, source provenance, stale or contradicted claims.
6. Repairs must stay inside `WIKI_DIR`. Never modify another wiki. Record meaningful repairs in `WIKI_DIR/wiki/log.md` per the local skill's contract.
7. Announce dispatch on the first line: `dispatch: ${WIKI}-wiki-lint (attached)`. Then execute the local workflow.

## Reference Bash

```bash
# Usage: wiki_lint_resolve [ROOT]
wiki_lint_resolve() {
  local root="${1:-}"
  if [ -z "$root" ]; then
    local p; p="$(pwd)"
    for _ in 1 2 3 4 5; do
      local hits=0
      for d in "$p"/*/; do
        [ -d "$d" ] || continue
        if [ -f "${d}CLAUDE.md" ] || [ -f "${d}AGENTS.md" ]; then
          hits=$((hits+1))
        fi
        if [ "$hits" -ge 2 ]; then break; fi
      done
      if [ "$hits" -ge 2 ]; then root="$p"; break; fi
      [ "$p" = "/" ] && break
      p="$(dirname "$p")"
    done
  fi
  if [ -z "$root" ] || [ ! -d "$root" ]; then
    echo "error: could not detect llm-wiki ROOT; pass it explicitly" >&2
    return 2
  fi
  local state_file="$root/.claude/state/attached-wiki"
  if [ ! -f "$state_file" ]; then
    echo "error: no wiki attached — run 'attach-wiki <name>' first (or 'list-wikis' to see options)" >&2
    return 3
  fi
  local wiki; wiki="$(cat "$state_file" | tr -d '[:space:]')"
  if [ -z "$wiki" ]; then
    echo "error: attach state file is empty — run 'attach-wiki <name>'" >&2
    return 3
  fi
  local wiki_dir="$root/$wiki"
  if [ ! -d "$wiki_dir" ] || { [ ! -f "$wiki_dir/CLAUDE.md" ] && [ ! -f "$wiki_dir/AGENTS.md" ]; }; then
    echo "error: attached wiki '$wiki' missing or invalid — run 'detach-wiki' or 'attach-wiki <other>'" >&2
    return 4
  fi
  local local_skill="$wiki_dir/.claude/skills/${wiki}-wiki-lint/SKILL.md"
  if [ ! -f "$local_skill" ]; then
    echo "error: local skill '${wiki}-wiki-lint' not found under $wiki — re-scaffold or repair" >&2
    return 5
  fi
  printf "%s\n%s\n%s\n" "$root" "$wiki" "$local_skill"
}

wiki_lint_resolve "$@"
```

## Output Style

- First line: `dispatch: ${WIKI}-wiki-lint (attached)`.
- Then the wiki_health.py output (if available), then the per-category lint report and any repairs applied.
- On refusal: one `error: …` line.

## Anti-Patterns

- Do not lint the meta repository or the `llm-wiki/` ROOT itself. Only the attached wiki.
- Do not lint multiple wikis in a single invocation.
- Do not silently auto-fix things outside the local skill's repair rules.
- Do not improvise without the local skill present. Refuse and ask the user to repair the scaffold.
- Do not write to `<ROOT>/.claude/state/`. Attach state is owned by `attach-wiki`, `detach-wiki`, and `remove-wiki`.
