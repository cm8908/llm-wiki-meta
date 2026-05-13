---
name: list-wikis
description: List sub-wikis under a top-level llm-wiki/ collection. Use when the user asks to see, list, enumerate, show, or summarize the available wikis in their llm-wiki knowledge base. Detects a sub-wiki as any immediate subdirectory containing CLAUDE.md or AGENTS.md. Also surfaces the currently attached wiki, if any.
---

# list-wikis

## Contract

Enumerate every sub-wiki under the user's top-level `llm-wiki/` root and present them compactly, marking the attached wiki with `*`. Skip non-wiki entries (dotfiles, auxiliary folders like `Excalidraw/`, scratch files). Read-only — never modifies state.

## When To Use

- "위키 나열", "현재 위키 보여줘", "list wikis", "어떤 위키들이 있어"
- Before `attach-wiki` to confirm a valid target.

## How To Run

```bash
bash "$SKILL_DIR/run.sh" [ROOT]
```

`$SKILL_DIR` is the absolute path of the directory holding this SKILL.md. `ROOT` is optional — if omitted, the script auto-detects by walking up from CWD until it finds an ancestor with ≥2 sibling dirs each containing `CLAUDE.md` or `AGENTS.md`. The script's stdout is the user-facing output; pass it through verbatim.

## Output Style

- First line: `Attached: <name>` or `Attached: (none)`.
- One compact table; excluded items are not shown.
- If zero wikis are detected, the script prints `(no sub-wikis detected under <ROOT>)`.

## Anti-Patterns

- Do not recursively scan — the script only walks one level under ROOT.
- Do not Read every `CLAUDE.md`; the listing is intentionally cheap.
- Do not modify state. This skill is read-only.
- Do not re-implement the logic in chat; always invoke `run.sh`.
