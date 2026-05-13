---
name: detach-wiki
description: Detach the current session from any attached sub-wiki, returning Claude to the top-level llm-wiki/ meta context. Use when the user says "detach", "exit this wiki", "go back to top", "위키에서 나가", "최상위로 돌아가", or otherwise signals they want to stop scoping work to a single wiki. Removes <ROOT>/.claude/state/attached-wiki if present.
---

# detach-wiki

## Contract

Release the session from the currently attached sub-wiki. After detach, Claude operates at the top-level meta scope: it can talk about any wiki, list them, or attach to a different one.

## When To Use

- "detach", "위키에서 나가", "최상위로", "exit wiki", "stop scoping".
- Wrapping up work in one wiki before comparing across wikis.

## When Not To Use

- The user is staying in the same wiki but switching tasks — do nothing.
- The user wants a *different* wiki — use `attach-wiki` (it overwrites).

## How To Run

```bash
bash "$SKILL_DIR/run.sh" [ROOT]
```

Prints `detached: <previous>` or `already detached` on a single line. Deletes the state file but leaves `<ROOT>/.claude/state/` itself in place.

## Output Style

- One line, plain. No briefing, no list.
- If the user asks "what next?", suggest `list-wikis`.

## Anti-Patterns

- Do not remove the `.claude/state/` directory itself — only the `attached-wiki` file.
- Do not modify any wiki content. Detach is purely a state operation.
- Do not auto-detach on errors elsewhere — only when the user asks for it.
- Do not re-derive the logic in chat; always invoke `run.sh`.
