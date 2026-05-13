---
name: remove-wiki
description: Permanently delete a sub-wiki directory under the top-level llm-wiki/ root. Use only when the user explicitly asks to "remove", "delete", "drop", "지워", "삭제해" a named wiki. Destructive and irreversible — requires the user to re-type the wiki name as a second-line confirmation before any rm. If the removed wiki is the currently attached one, also clears <ROOT>/.claude/state/attached-wiki.
---

# remove-wiki

## Contract

Delete one named sub-wiki — the whole `<ROOT>/<name>/` directory tree — after an explicit double-confirmation. This is destructive and there is no undo other than `git`. Never bulk-remove. Never proceed without the user re-typing the exact wiki name. Always clear the attach state if the deleted wiki was the attached one.

## When To Use

- The user names a wiki and asks to remove, delete, drop, purge it.
- The user typed `/remove-wiki <name>` directly.

## When Not To Use

- The user only wants to clear files inside a wiki — do that targeted edit, do not remove the whole wiki.
- The user wants to detach, not delete — use `detach-wiki`.
- The user did not name a specific wiki — run `list-wikis` and ask which one. Never guess.

## Locate The Root

Same detection rule as the other meta skills: ascend from CWD at most 4 levels, accept the first ancestor with two or more immediate subdirectories that each contain `CLAUDE.md` or `AGENTS.md`. Or accept an explicit path argument as the second positional.

## Procedure

1. **Resolve ROOT.** Fail with a clear message if detection fails.
2. **Resolve the target name** from the user's message or arguments. If ambiguous or missing, run `list-wikis` and ask the user to pick one. Never assume.
3. **Validate the target:**
   - `<ROOT>/<name>/` must exist.
   - It must contain `CLAUDE.md` or `AGENTS.md` (the same detection rule the other skills use). This prevents `rm -rf` against unrelated folders like `Excalidraw/` or `.obsidian/`.
   - Refuse names containing `/`, `..`, or leading `.` — these are not valid sub-wiki names.
4. **Show what will be deleted, then ask for re-confirmation.** Print:
   - the absolute path of `<ROOT>/<name>/`
   - file/directory counts (cheap: `find … | wc -l`)
   - which of `wiki/manifests/raw/tools` exist
   - whether it is the currently attached wiki
   Then ask the user, in a single sentence, to **type the wiki name again exactly** to confirm. Stop and wait for their reply. Do not run any `rm` in the same turn as the listing.
5. **Verify the confirmation string** in the user's next reply:
   - It must equal the resolved wiki name byte-for-byte after trimming surrounding whitespace.
   - If it does not match (including if the user typed "yes", "y", "확인", or a different wiki name), abort with `aborted: confirmation did not match` and do not delete.
   - If the user clearly cancels ("no", "취소", "stop"), abort with `aborted: by user`.
6. **Delete** `<ROOT>/<name>/` recursively. Use `rm -rf -- "<ROOT>/<name>"` with the `--` separator. Never use a glob, never substitute the name unquoted.
7. **Clear attach state if needed.** If `<ROOT>/.claude/state/attached-wiki` exists and its contents equal the removed name, delete that file too. Leave `.claude/state/` itself in place.
8. **Report.** One line per fact: `removed: <name>` and, if applicable, `detached: <name> (was attached)`.

## Reference Bash

The procedure is split into two helpers because it spans two turns. `remove_wiki_preview` runs in the confirmation turn; `remove_wiki_apply` runs only after the user re-types the name.

```bash
# Usage: remove_wiki_preview TARGET [ROOT]
remove_wiki_preview() {
  local target="${1:?usage: remove_wiki_preview TARGET [ROOT]}"
  local root="${2:-}"
  # --- ROOT detection (same as other skills) ---
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

  # --- Name sanity ---
  case "$target" in
    */*|..|.*) echo "error: invalid wiki name: $target" >&2; return 2 ;;
  esac
  local wiki_dir="$root/$target"
  if [ ! -d "$wiki_dir" ]; then
    echo "error: $target does not exist under $root" >&2; return 2
  fi
  if [ ! -f "$wiki_dir/CLAUDE.md" ] && [ ! -f "$wiki_dir/AGENTS.md" ]; then
    echo "error: $target has neither CLAUDE.md nor AGENTS.md; refusing to delete" >&2
    return 2
  fi

  # --- Preview ---
  local file_count; file_count="$(find "$wiki_dir" -type f 2>/dev/null | wc -l | tr -d ' ')"
  local dir_count;  dir_count="$(find "$wiki_dir" -type d 2>/dev/null | wc -l | tr -d ' ')"
  local layers=""
  [ -d "$wiki_dir/wiki" ]      && layers="${layers}wiki "
  [ -d "$wiki_dir/manifests" ] && layers="${layers}manifests "
  [ -d "$wiki_dir/raw" ]       && layers="${layers}raw "
  [ -d "$wiki_dir/tools" ]     && layers="${layers}tools "
  local attached=""
  [ -f "$root/.claude/state/attached-wiki" ] && attached="$(cat "$root/.claude/state/attached-wiki" | tr -d '[:space:]')"

  echo "About to permanently delete:"
  echo "  path:     $wiki_dir"
  echo "  files:    $file_count"
  echo "  dirs:     $dir_count"
  echo "  layers:   ${layers% }"
  if [ "$attached" = "$target" ]; then
    echo "  attached: YES (state will be cleared)"
  else
    echo "  attached: no"
  fi
}

# Usage: remove_wiki_apply TARGET TYPED [ROOT]
#   TARGET — the resolved wiki name
#   TYPED  — the string the user re-typed (already trimmed by the caller)
remove_wiki_apply() {
  local target="${1:?usage: remove_wiki_apply TARGET TYPED [ROOT]}"
  local typed="${2?usage: remove_wiki_apply TARGET TYPED [ROOT]}"
  local root="${3:-}"

  if [ "$typed" != "$target" ]; then
    echo "aborted: confirmation did not match"
    return 1
  fi

  # Re-run the same detection so this helper is safe to call independently.
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

  case "$target" in
    */*|..|.*) echo "error: invalid wiki name: $target" >&2; return 2 ;;
  esac
  local wiki_dir="$root/$target"
  if [ ! -d "$wiki_dir" ]; then
    echo "error: $target does not exist under $root" >&2; return 2
  fi
  if [ ! -f "$wiki_dir/CLAUDE.md" ] && [ ! -f "$wiki_dir/AGENTS.md" ]; then
    echo "error: $target has neither CLAUDE.md nor AGENTS.md; refusing to delete" >&2
    return 2
  fi

  rm -rf -- "$wiki_dir"
  echo "removed: $target"

  local state_file="$root/.claude/state/attached-wiki"
  if [ -f "$state_file" ]; then
    local cur; cur="$(cat "$state_file" | tr -d '[:space:]')"
    if [ "$cur" = "$target" ]; then
      rm -f "$state_file"
      echo "detached: $target (was attached)"
    fi
  fi
}
```

## Output Style

- Confirmation turn: a short header (`About to permanently delete:`), the preview block, then a single sentence asking the user to type the name again exactly to confirm.
- Apply turn: at most two lines — `removed: <name>` and optionally `detached: <name> (was attached)`.
- On abort: a single line — `aborted: confirmation did not match` or `aborted: by user`.

## Anti-Patterns

- Do not run `rm` in the same turn as the preview. The double-check must span two user turns; otherwise it is not a double-check.
- Do not accept "yes" / "y" / "확인" / "ok" as confirmation. The only valid confirmation is the exact wiki name.
- Do not fuzzy-match the confirmation (case-insensitive, trimmed punctuation, etc.). It must match byte-for-byte after trimming surrounding whitespace.
- Do not delete a directory that lacks `CLAUDE.md`/`AGENTS.md` even if the user insists — that is the safety contract shared with `attach-wiki` and `list-wikis`. Tell the user it is not a wiki and stop.
- Do not skip the attach-state cleanup. A stale attach pointer to a removed wiki is a foot-gun.
- Do not offer to remove multiple wikis in one invocation. One name per call.
- Do not use destructive shortcuts like `rm -rf $root/*` — the `<ROOT>/<name>` path must be assembled explicitly with the `--` separator.
