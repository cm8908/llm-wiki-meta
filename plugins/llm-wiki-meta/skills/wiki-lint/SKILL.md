---
name: wiki-lint
description: Meta-level lint entry point that dispatches to the currently attached sub-wiki's local <name>-wiki-lint skill. Use when the user asks to lint, audit, validate, repair, clean up, or health-check a wiki AND a wiki is attached. Refuses with a pointer to attach-wiki when no wiki is attached — never runs at the top-level meta scope, and never lints across multiple wikis in one invocation.
---

# wiki-lint (meta)

## Contract

A thin dispatcher. Performs no lint work itself. Resolves the attached sub-wiki, locates that wiki's local `<name>-wiki-lint` skill, and follows the local skill's contract with `<ROOT>/<wiki>/` as the working context. If no wiki is attached, refuse — meta scope has no schema to lint.

## When To Use

- The user asks to lint, audit, validate, repair, clean up, or health-check the wiki AND a wiki is attached.
- The user typed `/wiki-lint` from the top-level `llm-wiki/` directory.

## When Not To Use

- No wiki is attached → refuse. Do not lint the meta repo itself; this plugin is not an LLM-wiki target.
- The user wants to lint *every* wiki — refuse and ask which one to attach. One wiki per invocation.
- The user is already inside a wiki dir and the local `<name>-wiki-lint` is directly available — let that one fire instead.

## How To Run

```bash
bash "$SKILL_DIR/resolve.sh" [ROOT]
```

On success the script prints `ROOT=`, `WIKI=`, `SKILL=` on three lines. Non-zero exits surface a single `error: …` line — pass it through verbatim and stop. Exit codes match `wiki-ingest`.

## After Resolve Succeeds

1. Print: `dispatch: <WIKI>-wiki-lint (attached)`.
2. Run the mechanical check first if `<ROOT>/<WIKI>/tools/wiki_health.py` exists:

   ```bash
   python3 "$ROOT/$WIKI/tools/wiki_health.py" "$ROOT/$WIKI"
   ```

3. **Read** the file at `SKILL=` and follow its contract. Treat `<ROOT>/<WIKI>/` as the working directory.
4. Apply the lint categories from the local SKILL.md: structure, wikilinks, index coverage, manifests, source provenance, stale/contradicted claims.
5. Repairs must stay inside `<ROOT>/<WIKI>/`. Record meaningful repairs in `<ROOT>/<WIKI>/wiki/log.md` per the local skill's contract.

## Output Style

- First line: `dispatch: <WIKI>-wiki-lint (attached)`.
- Then `wiki_health.py` output (if available), then per-category lint report and any repairs applied.
- On refusal: one `error: …` line.

## Anti-Patterns

- Do not lint the meta repository or the `llm-wiki/` ROOT itself. Only the attached wiki.
- Do not lint multiple wikis in a single invocation.
- Do not silently auto-fix things outside the local skill's repair rules.
- Do not improvise without the local skill present. Refuse and ask the user to repair the scaffold.
- Do not write to `<ROOT>/.claude/state/`. Attach state is owned by attach/detach/remove.
- Do not re-derive resolve logic in chat; always invoke `resolve.sh`.
