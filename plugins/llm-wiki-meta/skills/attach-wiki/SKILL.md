---
name: attach-wiki
description: Attach the current session to a specific sub-wiki under a top-level llm-wiki/ root, so subsequent conversation operates inside that wiki as its working context. Use when the user names a sub-wiki and asks to "attach", "switch to", "work inside", "이 위키로 들어가", "위키 선택". Writes the wiki name to <ROOT>/.claude/state/attached-wiki and reads the wiki's CLAUDE.md/AGENTS.md to ground subsequent work.
---

# attach-wiki

## Contract

Bind the current session to one named sub-wiki inside the user's `llm-wiki/` collection. After attach, Claude treats `<ROOT>/<wiki>/` as the effective working directory, prefers that wiki's local skills (ingest/lint/query), and grounds answers in its `CLAUDE.md`/`AGENTS.md` and `wiki/index.md`. Other wikis are not blocked — only warned.

## When To Use

- The user names a wiki and asks to attach, switch to, or work inside it.
- The user implies extended work on a single wiki ("이 위키만 다루자", "앞으로 generative-embeddings 안에서").
- After `list-wikis`, when the user picks one of the listed wikis.

## When Not To Use

- The user is asking a one-off question about a wiki — answer with that wiki's `*-wiki-query` skill without attaching.
- The user has not chosen a wiki — run `list-wikis` first and ask.

## Locate The Root

The ROOT is the top-level `llm-wiki/` directory that holds multiple sub-wikis. Resolve in this order:

1. If the user passed an explicit path, use it.
2. Otherwise start at the current working directory and walk up at most 4 levels. The ROOT is the first ancestor (inclusive) that contains two or more immediate subdirectories each with `CLAUDE.md` or `AGENTS.md`.
3. If detection fails, ask the user to `cd` to their `llm-wiki/` directory or pass the path.

Never assume the directory containing this SKILL.md is the ROOT.

## Procedure

1. Resolve ROOT (see above).
2. Resolve the target wiki name from the user's message. If ambiguous or missing, run `list-wikis` and ask.
3. Validate the target:
   - `<ROOT>/<wiki>/` exists.
   - It contains `CLAUDE.md` or `AGENTS.md` (the same detection rule as `list-wikis`).
4. If `<ROOT>/.claude/state/attached-wiki` already exists and points at a *different* wiki, surface that and confirm before overwriting.
5. Write the wiki name to `<ROOT>/.claude/state/attached-wiki` (single line).
6. Read the target wiki's `CLAUDE.md` or `AGENTS.md` and give the user a one-paragraph briefing including:
   - which meta file was loaded
   - which of `wiki/manifests/raw/tools` exist
   - the names of the wiki's local skills under `<wiki>/.claude/skills/`, if any
7. From this point on in the conversation:
   - Treat `<ROOT>/<wiki>/` as the working context for file ops.
   - Prefer that wiki's local ingest/lint/query skills over generic ones.
   - When the user asks about a different wiki, **warn** ("currently attached to X; you asked about Y") but proceed if they confirm.

## Reference Bash

```bash
# Usage: attach_wiki TARGET [ROOT]
attach_wiki() {
  local target="${1:?usage: attach_wiki TARGET [ROOT]}"
  local root="${2:-}"
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

  local wiki_dir="$root/$target"
  if [ ! -d "$wiki_dir" ]; then
    echo "error: $target does not exist under $root" >&2; return 2
  fi
  if [ ! -f "$wiki_dir/CLAUDE.md" ] && [ ! -f "$wiki_dir/AGENTS.md" ]; then
    echo "error: $target has neither CLAUDE.md nor AGENTS.md; not a wiki" >&2; return 2
  fi

  local state_dir="$root/.claude/state"
  local state_file="$state_dir/attached-wiki"
  mkdir -p "$state_dir"
  local prev=""
  [ -f "$state_file" ] && prev="$(cat "$state_file" | tr -d '[:space:]')"
  printf "%s\n" "$target" > "$state_file"

  if [ -n "$prev" ] && [ "$prev" != "$target" ]; then
    echo "switched: $prev -> $target"
  else
    echo "attached: $target"
  fi
  echo
  if [ -f "$wiki_dir/CLAUDE.md" ]; then
    echo "[meta] CLAUDE.md present"
  elif [ -f "$wiki_dir/AGENTS.md" ]; then
    echo "[meta] AGENTS.md present"
  fi
  local layers=""
  [ -d "$wiki_dir/wiki" ]      && layers="${layers}wiki "
  [ -d "$wiki_dir/manifests" ] && layers="${layers}manifests "
  [ -d "$wiki_dir/raw" ]       && layers="${layers}raw "
  [ -d "$wiki_dir/tools" ]     && layers="${layers}tools "
  echo "[layers] ${layers% }"
  if [ -d "$wiki_dir/.claude/skills" ]; then
    echo "[skills]"
    for s in "$wiki_dir/.claude/skills"/*/; do
      [ -d "$s" ] && echo "  - $(basename "$s")"
    done
  fi
}

attach_wiki "$@"
```

## Output Style

- Confirm in one short line: `attached: <wiki>` or `switched: <prev> -> <wiki>`.
- Follow with the briefing block.
- Do not dump the entire CLAUDE.md/AGENTS.md back at the user.

## Anti-Patterns

- Do not silently overwrite a different attached wiki without surfacing it.
- Do not block work in other wikis after attach — warn only.
- Do not treat attach as `cd` inside bash; each bash call is independent. Always resolve paths from the detected ROOT plus the state file.
- Do not attach to a directory that lacks `CLAUDE.md`/`AGENTS.md`. That is the detection contract; auxiliaries like `Excalidraw/` must be rejected.
