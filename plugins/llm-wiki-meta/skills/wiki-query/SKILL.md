---
name: wiki-query
description: Meta-level query entry point that dispatches to the currently attached sub-wiki's local <name>-wiki-query skill. Use when the user asks a question, comparison, summary, or recommendation against a wiki AND a wiki is attached. Refuses with a pointer to attach-wiki when no wiki is attached — never runs at the top-level meta scope.
---

# wiki-query (meta)

## Contract

A thin dispatcher. Performs no query work itself. Resolves the attached sub-wiki, locates that wiki's local `<name>-wiki-query` skill, and follows the local skill's contract with `<ROOT>/<wiki>/` as the working context. If no wiki is attached, refuse — meta scope is not a valid query target.

## When To Use

- The user asks a question, comparison, summary, explanation, report, synthesis, or recommendation AND a wiki is attached.
- The user typed `/wiki-query` from the top-level `llm-wiki/` directory.

## When Not To Use

- No wiki is attached → refuse. Do not search across all wikis, do not improvise a meta-level answer.
- The user is already inside a wiki dir and the local `<name>-wiki-query` is directly available — let that one fire instead.
- The question is about cross-wiki comparison or meta operations — use `list-wikis` / `current-wiki` instead.

## How To Run

```bash
bash "$SKILL_DIR/resolve.sh" [ROOT]
```

On success the script prints `ROOT=`, `WIKI=`, `SKILL=` on three lines. Non-zero exits surface a single `error: …` line — pass it through verbatim and stop. Exit codes match `wiki-ingest`.

## After Resolve Succeeds

1. Print: `dispatch: <WIKI>-wiki-query (attached)`.
2. **Read** the file at `SKILL=` and follow its contract. Treat `<ROOT>/<WIKI>/` as the working directory for every step.
3. Search and read only inside `<ROOT>/<WIKI>/`. If the attached wiki lacks evidence, say so explicitly — do not silently borrow from siblings.
4. The local query skill is read-by-default. Only write back when the user asks for a durable artifact (synthesis or decision page) AND the local skill's preconditions are met.

## Output Style

- First line: `dispatch: <WIKI>-wiki-query (attached)`.
- Then the local skill's normal answer style: cited Obsidian links to `[[sources/…]]`, gaps named explicitly, list of consulted pages.
- On refusal: one `error: …` line.

## Anti-Patterns

- Do not answer cross-wiki questions here. Use `list-wikis` for cross-wiki visibility.
- Do not search a different wiki's content because it might have a better answer — that violates attach semantics.
- Do not improvise without the local skill present. Refuse and ask the user to repair the scaffold.
- Do not silently switch wikis if attach state is stale — the script will fail; pass the error through.
- Do not re-derive resolve logic in chat; always invoke `resolve.sh`.
