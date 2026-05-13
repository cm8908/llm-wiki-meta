---
name: wiki-ingest
description: Meta-level ingest entry point that dispatches to the currently attached sub-wiki's local <name>-wiki-ingest skill. Use when the user asks to ingest, add, process, summarize, compile, or integrate a source AND a wiki is attached. Refuses with a pointer to attach-wiki when no wiki is attached — never runs at the top-level meta scope.
---

# wiki-ingest (meta)

## Contract

A thin dispatcher. Performs no ingest work itself. Resolves the attached sub-wiki, locates that wiki's local `<name>-wiki-ingest` skill, and follows the local skill's contract with `<ROOT>/<wiki>/` as the working context. If no wiki is attached, refuse — meta scope is not a valid ingest target.

## When To Use

- The user asks to ingest, add, process, summarize, compile, or incorporate a source AND a wiki is attached.
- The user typed `/wiki-ingest` from the top-level `llm-wiki/` directory.

## When Not To Use

- No wiki is attached → refuse, do not pick a wiki.
- The user is already inside a wiki dir and the local `<name>-wiki-ingest` is directly available — let that one fire instead.

## How To Run

```bash
bash "$SKILL_DIR/resolve.sh" [ROOT]
```

On success the script prints three lines:

```
ROOT=<absolute path>
WIKI=<attached name>
SKILL=<absolute path to the local SKILL.md>
```

Exit codes: `0` ok, `2` ROOT/structure error, `3` no wiki attached, `4` attached wiki invalid on disk, `5` local skill not scaffolded. On any non-zero exit, surface the script's stderr line verbatim and stop — do not improvise.

## After Resolve Succeeds

1. Print one line: `dispatch: <WIKI>-wiki-ingest (attached)`.
2. **Read** the file at `SKILL=` and follow its contract exactly. Treat `<ROOT>/<WIKI>/` as the effective working directory for every file read/write, `rg` search, and `tools/wiki_health.py` invocation.
3. Write back **only** inside `<ROOT>/<WIKI>/`. Never modify another wiki. Never touch `<ROOT>/.claude/state/` (owned by attach/detach/remove).

## Output Style

- First line: `dispatch: <WIKI>-wiki-ingest (attached)`.
- Then follow the local skill's output conventions.
- On refusal: one `error: …` line, no dispatch line.

## Anti-Patterns

- Do not run an ingest workflow with no attached wiki — meta-level ingest is forbidden by contract.
- Do not silently pick a wiki even if there is exactly one under ROOT. The user must attach explicitly.
- Do not improvise without the local skill present. Refuse and let the user fix the scaffold.
- Do not write outside `<ROOT>/<WIKI>/`.
- Do not re-derive resolve logic in chat; always invoke `resolve.sh`.
