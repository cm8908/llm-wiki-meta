---
name: current-wiki
description: Report the sub-wiki currently attached to this session, by reading <ROOT>/.claude/state/attached-wiki. Use when the user asks "현재 위키", "current wiki", "which wiki am I in", "what's attached", "show attach state", or otherwise wants to confirm the active scope without listing all wikis. Read-only; never modifies state.
---

# current-wiki

## Contract

Return the name of the currently attached sub-wiki — nothing else. If no wiki is attached, say so plainly. Read-only: never writes state, never lists all wikis, never reads wiki content. This is the cheapest possible probe of the attach state.

## When To Use

- "현재 위키", "지금 어떤 위키", "what wiki am I attached to", "current wiki"
- The user wants a quick sanity check before running other operations.
- Programmatic check before commands that should branch on attach state.

## When Not To Use

- The user wants to see every available wiki — use `list-wikis`.
- The user wants to switch wikis — use `attach-wiki`.
- The user wants to clear the attach state — use `detach-wiki`.

## Locate The Root

Same detection as the other meta skills: ascend from CWD at most 4 levels, accept the first ancestor with two or more immediate subdirectories that each contain `CLAUDE.md` or `AGENTS.md`. Or accept an explicit path argument.

If the user passed a wiki name as an argument, ignore it — this skill takes no target. Just report attach state.

## Procedure

1. Resolve ROOT.
2. Check `<ROOT>/.claude/state/attached-wiki`.
3. If the file is missing or empty, print `attached: (none)` and stop.
4. Otherwise print `attached: <name>` on a single line.
5. Do not validate that the named wiki still exists — that is `attach-wiki`'s concern. Just surface what the state file says. If the named wiki no longer exists on disk, mention that on a second line so the user can fix it.

## Reference Bash

```bash
# Usage: current_wiki [ROOT]
current_wiki() {
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
    echo "attached: (none)"
    return 0
  fi
  local name; name="$(cat "$state_file" | tr -d '[:space:]')"
  if [ -z "$name" ]; then
    echo "attached: (none)"
    return 0
  fi
  echo "attached: $name"
  if [ ! -d "$root/$name" ]; then
    echo "warning: $name no longer exists under $root — consider detach-wiki"
  fi
}

current_wiki "$@"
```

## Output Style

- Exactly one line in the normal case: `attached: <name>` or `attached: (none)`.
- Add a second `warning:` line only when the state file points at a wiki that no longer exists on disk.
- No table, no briefing, no layer badges. Use `list-wikis` for that.

## Anti-Patterns

- Do not write to the state file.
- Do not auto-detach on stale state — only warn. The user decides whether to run `detach-wiki` or `attach-wiki <other>`.
- Do not load the wiki's `CLAUDE.md`/`AGENTS.md`; that is `attach-wiki`'s job.
