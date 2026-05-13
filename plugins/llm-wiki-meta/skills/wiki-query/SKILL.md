---
name: wiki-query
description: Meta-level query entry point that dispatches to the currently attached sub-wiki's local <name>-wiki-query skill. Use when the user asks a question, comparison, summary, or recommendation against a wiki AND a wiki is attached. Refuses with a pointer to attach-wiki when no wiki is attached — never runs at the top-level meta scope.
---

# wiki-query (meta)

## Contract

A thin dispatcher. This skill performs no query work itself. It resolves the currently attached sub-wiki, locates that wiki's local `<name>-wiki-query` skill, and follows the local skill's contract with the attached wiki directory as the working context. If no wiki is attached, refuse and point the user at `attach-wiki` — the meta scope is not a valid query target.

## When To Use

- The user asks a question, comparison, summary, explanation, report, synthesis, or recommendation that must be answered from a wiki AND a wiki is attached.
- The user typed `/wiki-query` from the top-level `llm-wiki/` directory.

## When Not To Use

- No wiki is attached → refuse. Do not pick a wiki, do not search across all wikis, do not improvise a meta-level answer.
- The user is already inside a wiki dir and the local `<name>-wiki-query` is directly available — let that one fire instead.
- The question is about cross-wiki comparison or meta operations (e.g. "어떤 위키들이 있어") — use `list-wikis` / `current-wiki` instead.

## Locate The Root And Attached Wiki

Same as `wiki-ingest`:

1. Resolve ROOT using the shared detection rule, or accept an explicit path.
2. Read `<ROOT>/.claude/state/attached-wiki`. If missing or empty, **refuse** — do not prompt, do not default, do not run at meta scope.
3. Let `WIKI` be the attached name and `WIKI_DIR="$ROOT/$WIKI"`. Validate `WIKI_DIR` exists and contains `CLAUDE.md` or `AGENTS.md`. If not, refuse with a pointer to `detach-wiki` / `attach-wiki <other>`.

## Procedure

1. Resolve ROOT and the attached wiki. Refuse early if no wiki is attached.
2. Locate the local skill at `WIKI_DIR/.claude/skills/${WIKI}-wiki-query/SKILL.md`. If missing, refuse with `error: local skill '${WIKI}-wiki-query' not found under ${WIKI}`. Do not fall back to a generic implementation.
3. **Read** the local SKILL.md and follow its contract. Treat `WIKI_DIR` as the working directory for every step. Read `WIKI_DIR/CLAUDE.md`, `WIKI_DIR/wiki/index.md`, `WIKI_DIR/wiki/current-status.md`, and `WIKI_DIR/wiki/synthesis/current-thesis.md` as the local skill requires.
4. Search and read only inside `WIKI_DIR`. Never read another wiki's content to answer this question, even if it might help. If the attached wiki lacks evidence, say so explicitly — do not silently borrow from siblings.
5. The local query skill is read-by-default. It only writes back if the user asks for a durable artifact (synthesis page, decision page). Honor that — do not write into another wiki, and do not write into this wiki without the local skill's preconditions.
6. Announce dispatch on the first line: `dispatch: ${WIKI}-wiki-query (attached)`. Then execute the local workflow.

## Reference Bash

The resolver is identical in shape to `wiki-ingest`'s — only the skill suffix differs. See the `wiki-ingest` SKILL.md for the full helper; the equivalent here is `wiki_query_resolve` with `${wiki}-wiki-query` substituted.

```bash
# Usage: wiki_query_resolve [ROOT]
wiki_query_resolve() {
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
  local local_skill="$wiki_dir/.claude/skills/${wiki}-wiki-query/SKILL.md"
  if [ ! -f "$local_skill" ]; then
    echo "error: local skill '${wiki}-wiki-query' not found under $wiki — re-scaffold or repair" >&2
    return 5
  fi
  printf "%s\n%s\n%s\n" "$root" "$wiki" "$local_skill"
}

wiki_query_resolve "$@"
```

## Output Style

- First line: `dispatch: ${WIKI}-wiki-query (attached)`.
- Then the local skill's normal answer style: cited Obsidian links to `[[sources/…]]`, gaps named explicitly, list of consulted pages.
- On refusal: one `error: …` line.

## Anti-Patterns

- Do not answer cross-wiki questions here. Use `list-wikis` for cross-wiki visibility instead.
- Do not search a different wiki's content because it might have a better answer — that violates attach semantics.
- Do not improvise without the local skill present. Refuse and ask the user to repair the scaffold.
- Do not silently switch wikis if attach state is stale — surface the inconsistency and stop.
