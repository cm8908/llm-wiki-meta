---
name: wiki-ingest
description: Meta-level ingest entry point that dispatches to the currently attached sub-wiki's local <name>-wiki-ingest skill. Use when the user asks to ingest, add, process, summarize, compile, or integrate a source AND a wiki is attached. Refuses with a pointer to attach-wiki when no wiki is attached — never runs at the top-level meta scope.
---

# wiki-ingest (meta)

## Contract

A thin dispatcher. This skill performs no ingest work itself. It resolves the currently attached sub-wiki, locates that wiki's local `<name>-wiki-ingest` skill, and follows the local skill's contract with the attached wiki directory as the working context. If no wiki is attached, refuse and point the user at `attach-wiki` — the meta scope is not a valid ingest target.

## When To Use

- The user asks to ingest, add, process, summarize, compile, integrate, or incorporate a source AND a wiki is attached.
- The user typed `/wiki-ingest` from the top-level `llm-wiki/` directory.

## When Not To Use

- No wiki is attached → refuse, do not pick a wiki. Tell the user to run `attach-wiki <name>` first (or `list-wikis` to see options).
- The user is already inside a wiki dir and the local `<name>-wiki-ingest` is directly available — let that one fire instead; this dispatcher is only needed when the user is at the meta scope.

## Locate The Root And Attached Wiki

1. Resolve ROOT using the shared detection rule (ascend from CWD at most 4 levels; first ancestor with ≥2 immediate subdirs each containing `CLAUDE.md` or `AGENTS.md`). Or accept an explicit path.
2. Read `<ROOT>/.claude/state/attached-wiki`. If missing or empty, **refuse** with a one-liner — do not prompt the user to pick, do not default to anything, do not run ingest against the meta scope.
3. Let `WIKI` be the attached name and `WIKI_DIR="$ROOT/$WIKI"`. Validate `WIKI_DIR` exists and contains `CLAUDE.md` or `AGENTS.md`. If not, refuse with `error: attached wiki '<WIKI>' missing or invalid — run detach-wiki or attach-wiki <other>` and stop.

## Procedure

1. Resolve ROOT and the attached wiki (see above). Refuse early if no wiki is attached.
2. Locate the local skill at `WIKI_DIR/.claude/skills/${WIKI}-wiki-ingest/SKILL.md`. If it is missing, refuse with `error: local skill '${WIKI}-wiki-ingest' not found under ${WIKI}` — do not fall back to a generic implementation. The user should run `create-wiki` (or re-scaffold) to restore it.
3. **Read** the local SKILL.md and follow its contract. Treat `WIKI_DIR` as the effective working directory for every step (file reads/writes, `rg` searches, `tools/wiki_health.py` invocations). Read `WIKI_DIR/CLAUDE.md`, `WIKI_DIR/wiki/index.md`, `WIKI_DIR/wiki/log.md`, and `WIKI_DIR/wiki/current-status.md` as the local skill requires.
4. Write back **only** inside `WIKI_DIR`. Never modify another wiki's content. Never modify files outside `WIKI_DIR` except for `<ROOT>/.claude/state/` (which this skill does not touch — that is `attach-wiki`/`detach-wiki`/`remove-wiki`).
5. Announce dispatch on the first line: `dispatch: ${WIKI}-wiki-ingest (attached)`. Then execute the local skill's workflow.

## Reference Bash

```bash
# Usage: wiki_ingest_resolve [ROOT]
# Prints two lines on success: ROOT path, then attached wiki name.
# Exits non-zero with an error if no wiki is attached or the attached wiki is invalid.
wiki_ingest_resolve() {
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
  local local_skill="$wiki_dir/.claude/skills/${wiki}-wiki-ingest/SKILL.md"
  if [ ! -f "$local_skill" ]; then
    echo "error: local skill '${wiki}-wiki-ingest' not found under $wiki — re-scaffold or repair" >&2
    return 5
  fi
  printf "%s\n%s\n%s\n" "$root" "$wiki" "$local_skill"
}

wiki_ingest_resolve "$@"
```

## Output Style

- First line: `dispatch: ${WIKI}-wiki-ingest (attached)`.
- Then follow the local skill's output conventions (log entry, source page summary, manifest update reports).
- On refusal: a single `error: …` line, no dispatch line.

## Anti-Patterns

- Do not run an ingest workflow with no attached wiki — meta-level ingest is forbidden by contract.
- Do not silently pick a wiki even if there is exactly one under ROOT. The user must attach explicitly.
- Do not duplicate the local skill's contract here. Read and follow it verbatim from `WIKI_DIR/.claude/skills/${WIKI}-wiki-ingest/SKILL.md`.
- Do not write outside `WIKI_DIR` (the one exception — attach state — is not a concern of this skill).
- Do not bypass a missing local skill by improvising. Refuse and let the user fix the scaffold.
