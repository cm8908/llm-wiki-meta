#!/usr/bin/env bash
# remove-wiki/preview.sh TARGET [ROOT] — show what would be deleted.
# Read-only. Apply only happens after the user re-types the name via apply.sh.
set -euo pipefail

TARGET="${1:?usage: preview.sh TARGET [ROOT]}"
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../lib/wiki_lib.sh"

validate_wiki_name "$TARGET" || exit 2
ROOT="$(resolve_root "${2:-}")" || exit 2
validate_wiki_dir "$ROOT" "$TARGET" || exit 2

wiki_dir="$ROOT/$TARGET"
file_count="$(find "$wiki_dir" -type f 2>/dev/null | wc -l | tr -d ' ')"
dir_count="$(find "$wiki_dir" -type d 2>/dev/null | wc -l | tr -d ' ')"
layers="$(layer_badges "$wiki_dir")"
attached="$(read_attached "$ROOT")"

echo "About to permanently delete:"
echo "  path:     $wiki_dir"
echo "  files:    $file_count"
echo "  dirs:     $dir_count"
echo "  layers:   $layers"
if [ "$attached" = "$TARGET" ]; then
  echo "  attached: YES (state will be cleared)"
else
  echo "  attached: no"
fi
