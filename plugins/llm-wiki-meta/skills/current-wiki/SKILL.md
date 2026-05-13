---
name: current-wiki
description: Report the sub-wiki currently attached to this session, by reading <ROOT>/.claude/state/attached-wiki. Use when the user asks "현재 위키", "current wiki", "which wiki am I in", "what's attached", "show attach state", or otherwise wants to confirm the active scope without listing all wikis. Read-only; never modifies state.
---

# current-wiki

## Contract

Return the attached sub-wiki name — nothing else. If no wiki is attached, say so plainly. Read-only: never writes state, never lists all wikis, never reads wiki content.

## When To Use

- "현재 위키", "지금 어떤 위키", "what wiki am I attached to", "current wiki"
- Quick sanity check before another operation.

## When Not To Use

- The user wants to see every available wiki — use `list-wikis`.
- The user wants to switch wikis — use `attach-wiki`.
- The user wants to clear the attach state — use `detach-wiki`.

## How To Run

```bash
bash "$SKILL_DIR/run.sh" [ROOT]
```

If the user passed a wiki name, ignore it — this skill takes no target. Pass the script's stdout through verbatim.

## Output Style

- Exactly one line normally: `attached: <name>` or `attached: (none)`.
- A second `warning:` line is added only when the state file points at a wiki that no longer exists on disk.

## Anti-Patterns

- Do not write to the state file.
- Do not auto-detach on stale state — only surface the warning.
- Do not load the wiki's `CLAUDE.md`/`AGENTS.md`; that is `attach-wiki`'s job.
- Do not re-derive the logic in chat; always invoke `run.sh`.
