#!/usr/bin/env bash
# remove-wiki/apply.sh TARGET TYPED [ROOT] — delete TARGET iff TYPED matches.
#
# TYPED must equal TARGET byte-for-byte after surrounding-whitespace trim.
# "yes" / "y" / "ok" / "확인" are NOT valid confirmations — only the exact name.
set -euo pipefail

TARGET="${1:?usage: apply.sh TARGET TYPED [ROOT]}"
TYPED="${2-}"
[ -n "${2+x}" ] || { echo "usage: apply.sh TARGET TYPED [ROOT]" >&2; exit 2; }

# Trim leading/trailing whitespace from TYPED. No other normalization.
TYPED="${TYPED#"${TYPED%%[![:space:]]*}"}"
TYPED="${TYPED%"${TYPED##*[![:space:]]}"}"

if [ "$TYPED" != "$TARGET" ]; then
  echo "aborted: confirmation did not match"
  exit 1
fi

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../lib/wiki_lib.sh"

validate_wiki_name "$TARGET" || exit 2
ROOT="$(resolve_root "${3:-}")" || exit 2
validate_wiki_dir "$ROOT" "$TARGET" || exit 2

rm -rf -- "$ROOT/$TARGET"
echo "removed: $TARGET"

state_file="$ROOT/.claude/state/attached-wiki"
if [ -f "$state_file" ]; then
  cur="$(read_attached "$ROOT")"
  if [ "$cur" = "$TARGET" ]; then
    rm -f "$state_file"
    echo "detached: $TARGET (was attached)"
  fi
fi
