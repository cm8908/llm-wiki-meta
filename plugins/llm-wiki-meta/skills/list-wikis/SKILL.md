---
name: list-wikis
description: List sub-wikis under a top-level llm-wiki/ collection. Use when the user asks to see, list, enumerate, show, or summarize the available wikis in their llm-wiki knowledge base. Detects a sub-wiki as any immediate subdirectory containing CLAUDE.md or AGENTS.md. Also surfaces the currently attached wiki, if any.
---

# list-wikis

## Contract

Enumerate every sub-wiki under the user's top-level `llm-wiki/` root and present them compactly. Skip non-wiki entries (auxiliary folders, hidden directories, loose files). Show the currently attached wiki up top so the user always sees the active context. Read-only — never modifies state.

## When To Use

- "위키 나열", "현재 위키 보여줘", "list wikis", "어떤 위키들이 있어"
- Any time the user is choosing a wiki to attach.
- Before `attach-wiki` to confirm a valid target.

## Locate The Root

The ROOT is the top-level `llm-wiki/` directory that holds multiple sub-wikis as siblings. Resolve in this order:

1. If the user passed an explicit path, use it.
2. Otherwise start at the current working directory and walk up at most 4 levels. The ROOT is the first ancestor (inclusive) that contains **two or more** immediate subdirectories each with `CLAUDE.md` or `AGENTS.md`.
3. If detection fails, ask the user to `cd` to their `llm-wiki/` directory or pass the path.

Never assume the directory containing this SKILL.md is the ROOT — under plugin install, that path is in `~/.claude/plugins/...`, unrelated to the user's wiki.

## Detection Rule For A Sub-Wiki

An immediate subdirectory of ROOT is a **wiki** if it contains a `CLAUDE.md` **or** `AGENTS.md` file. Everything else is filtered out: dotfiles, `Excalidraw/`, `.obsidian/`, scratch files, etc.

## Procedure

1. Resolve ROOT (see above).
2. Read the attached state (if present): `<ROOT>/.claude/state/attached-wiki`. Treat a missing file as "no wiki attached".
3. List immediate subdirectories of ROOT.
4. For each subdirectory, check for `CLAUDE.md` or `AGENTS.md`. If neither, drop it.
5. For each detected wiki, collect: name, meta file (`CLAUDE.md` vs `AGENTS.md`), which of `wiki/manifests/raw/tools` exist (badges), and the directory mtime.
6. Print the result. Mark the attached wiki with a leading `*`.

## Reference Bash

```bash
# Usage: list_wikis [ROOT]
list_wikis() {
  local root="${1:-}"
  if [ -z "$root" ]; then
    # Detect ROOT by walking up from CWD.
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

  local state="$root/.claude/state/attached-wiki"
  local attached=""
  [ -f "$state" ] && attached="$(cat "$state" | tr -d '[:space:]')"

  if [ -n "$attached" ]; then echo "Attached: $attached"; else echo "Attached: (none)"; fi
  echo
  printf "%-2s %-28s %-6s %-30s %s\n" " " "wiki" "meta" "layers" "modified"
  printf "%-2s %-28s %-6s %-30s %s\n" " " "----" "----" "------" "--------"

  for d in "$root"/*/; do
    local name; name="$(basename "$d")"
    local meta=""
    [ -f "${d}CLAUDE.md" ] && meta="CLAUDE"
    [ -z "$meta" ] && [ -f "${d}AGENTS.md" ] && meta="AGENTS"
    [ -z "$meta" ] && continue
    local layers=""
    [ -d "${d}wiki" ]      && layers="${layers}wiki "
    [ -d "${d}manifests" ] && layers="${layers}manifests "
    [ -d "${d}raw" ]       && layers="${layers}raw "
    [ -d "${d}tools" ]     && layers="${layers}tools "
    local mtime; mtime="$(date -r "$d" '+%Y-%m-%d' 2>/dev/null || stat -c '%y' "$d" | cut -d' ' -f1)"
    local marker=" "
    [ "$name" = "$attached" ] && marker="*"
    printf "%-2s %-28s %-6s %-30s %s\n" "$marker" "$name" "$meta" "${layers% }" "$mtime"
  done
}

list_wikis "$@"
```

## Output Style

- Lead with the attached wiki line.
- One compact table; do not list excluded items.
- If zero wikis are detected, say so plainly.

## Anti-Patterns

- Do not recursively scan. One level under ROOT only.
- Do not assume the SKILL.md's own directory is ROOT.
- Do not Read every `CLAUDE.md`; the listing should be cheap.
- Do not modify state. This skill is read-only.
