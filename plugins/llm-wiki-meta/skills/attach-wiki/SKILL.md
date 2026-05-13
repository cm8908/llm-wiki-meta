---
name: attach-wiki
description: Attach the current session to a specific sub-wiki under a top-level llm-wiki/ root, so subsequent conversation operates inside that wiki as its working context. Use when the user names a sub-wiki and asks to "attach", "switch to", "work inside", "이 위키로 들어가", "위키 선택". Writes the wiki name to <ROOT>/.claude/state/attached-wiki and reads the wiki's CLAUDE.md/AGENTS.md to ground subsequent work.
---

# attach-wiki

## Contract

Bind the current session to one named sub-wiki inside `llm-wiki/`. After attach, treat `<ROOT>/<wiki>/` as the effective working directory, prefer that wiki's local skills (ingest/lint/query), and ground answers in its `CLAUDE.md`/`AGENTS.md` and `wiki/index.md`. Other wikis are not blocked — only warned.

## When To Use

- The user names a wiki and asks to attach, switch to, or work inside it.
- The user implies extended work on one wiki ("앞으로 generative-embeddings 안에서").

## When Not To Use

- One-off question about a wiki — answer with that wiki's `*-wiki-query` skill without attaching.
- The user has not chosen a wiki — run `list-wikis` first and ask.

## How To Run

```bash
bash "$SKILL_DIR/run.sh" "$TARGET" [ROOT]
```

The script:
- Validates `<ROOT>/<TARGET>` exists and contains `CLAUDE.md` or `AGENTS.md`.
- Writes `<ROOT>/.claude/state/attached-wiki`.
- Prints `attached: <wiki>` or `switched: <prev> -> <wiki>`, followed by a meta/layers/skills briefing.

If the user gave no `TARGET`, do not invoke yet — run `list-wikis` and ask them to pick one. The script intentionally has no interactive prompt.

## After The Script Succeeds

Read the wiki's `CLAUDE.md` (or `AGENTS.md`) once and summarize scope in one paragraph for the user. From here on:

- Treat `<ROOT>/<TARGET>/` as the working context for file ops.
- Prefer that wiki's local ingest/lint/query skills over generic ones.
- When the user asks about a different wiki, **warn** ("currently attached to X; you asked about Y") but proceed if they confirm.

## Output Style

- One line from the script (`attached:` or `switched:`).
- Three optional info lines: `[meta]`, `[layers]`, `[skills]`.
- Then your one-paragraph wiki briefing.
- Do not dump the full CLAUDE.md back at the user.

## Anti-Patterns

- Do not silently overwrite a different attached wiki — the `switched:` output already surfaces it; do not pretend it was a fresh attach.
- Do not block work in other wikis after attach — warn only.
- Do not treat attach as `cd` inside bash; always resolve paths from `<ROOT>/<TARGET>`.
- Do not attach to a directory that lacks `CLAUDE.md`/`AGENTS.md`. The script enforces this and so should you.
- Do not re-derive the logic in chat; always invoke `run.sh`.
