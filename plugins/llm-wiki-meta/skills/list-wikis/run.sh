#!/usr/bin/env bash
# list-wikis/run.sh [ROOT] — enumerate sub-wikis under ROOT, mark attached.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../lib/wiki_lib.sh"

ROOT="$(resolve_root "${1:-}")" || exit 2
attached="$(read_attached "$ROOT")"

if [ -n "$attached" ]; then echo "Attached: $attached"; else echo "Attached: (none)"; fi
echo
printf "%-2s %-28s %-6s %-30s %s\n" " " "wiki" "meta" "layers" "modified"
printf "%-2s %-28s %-6s %-30s %s\n" " " "----" "----" "------" "--------"

count=0
for d in "$ROOT"/*/; do
  [ -d "$d" ] || continue
  name="$(basename "$d")"
  meta="$(meta_file "$d")"
  [ -z "$meta" ] && continue
  layers="$(layer_badges "$d")"
  mtime="$(dir_mtime "$d")"
  marker=" "
  [ "$name" = "$attached" ] && marker="*"
  printf "%-2s %-28s %-6s %-30s %s\n" "$marker" "$name" "$meta" "$layers" "$mtime"
  count=$((count+1))
done

if [ "$count" -eq 0 ]; then
  echo
  echo "(no sub-wikis detected under $ROOT)"
fi
