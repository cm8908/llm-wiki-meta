---
name: detach-wiki
description: Detach the current session from any attached sub-wiki, returning Claude to the top-level llm-wiki/ meta context. Use when the user says "detach", "exit this wiki", "go back to top", "위키에서 나가", "최상위로 돌아가", or otherwise signals they want to stop scoping work to a single wiki. Removes <ROOT>/.claude/state/attached-wiki if present.
---

# detach-wiki

## Contract

Release the session from the currently attached sub-wiki. After detach, Claude operates at the top-level `llm-wiki/` meta scope: it can talk about any wiki, list them, or attach to a different one.

## When To Use

- "detach", "위키에서 나가", "최상위로", "exit wiki", "stop scoping".
- The user is wrapping up work in one wiki and wants to compare across wikis.
- The user explicitly requests to clear the attach state.

## When Not To Use

- The user is staying inside the same wiki but switching tasks — do nothing.
- The user wants a *different* wiki — use `attach-wiki` (it overwrites).

## Locate The Root

Same detection as `list-wikis` / `attach-wiki`: ascend from CWD until you find a directory with two or more immediate subdirectories that each have `CLAUDE.md` or `AGENTS.md`. Or accept an explicit path.

## Procedure

1. Resolve ROOT.
2. Read `<ROOT>/.claude/state/attached-wiki` if present. Remember the previous name for the confirmation message.
3. If the file is missing, report `already detached` and stop.
4. Delete the state file. Leave `<ROOT>/.claude/state/` itself in place.
5. Respond with a one-line confirmation: `detached: <previous>` or `already detached`.

## Reference Bash

```bash
# Usage: detach_wiki [ROOT]
detach_wiki() {
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
  if [ ! -f "$state_file" ]; then echo "already detached"; return 0; fi
  local prev; prev="$(cat "$state_file" | tr -d '[:space:]')"
  rm -f "$state_file"
  echo "detached: $prev"
}

detach_wiki "$@"
```

## Output Style

- One line, plain. No briefing, no list.
- If the user asks "what next?", suggest `list-wikis`.

## Anti-Patterns

- Do not remove the `.claude/state/` directory itself.
- Do not modify any wiki content. Detach is purely a state operation.
- Do not auto-detach on errors elsewhere — only when the user asks for it.
