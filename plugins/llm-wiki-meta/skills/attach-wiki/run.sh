#!/usr/bin/env bash
# attach-wiki/run.sh TARGET [ROOT] — pin the session to TARGET sub-wiki.
set -euo pipefail

TARGET="${1:?usage: run.sh TARGET [ROOT]}"
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../lib/wiki_lib.sh"

ROOT="$(resolve_root "${2:-}")" || exit 2
validate_wiki_dir "$ROOT" "$TARGET" || exit 2

state_dir="$ROOT/.claude/state"
state_file="$state_dir/attached-wiki"
mkdir -p "$state_dir"
prev="$(read_attached "$ROOT")"
printf "%s\n" "$TARGET" > "$state_file"

if [ -n "$prev" ] && [ "$prev" != "$TARGET" ]; then
  echo "switched: $prev -> $TARGET"
else
  echo "attached: $TARGET"
fi

echo
wiki_dir="$ROOT/$TARGET"
meta="$(meta_file "$wiki_dir")"
[ -n "$meta" ] && echo "[meta] ${meta}.md present"
echo "[layers] $(layer_badges "$wiki_dir")"
if [ -d "$wiki_dir/.claude/skills" ]; then
  echo "[skills]"
  for s in "$wiki_dir/.claude/skills"/*/; do
    [ -d "$s" ] && echo "  - $(basename "$s")"
  done
fi
