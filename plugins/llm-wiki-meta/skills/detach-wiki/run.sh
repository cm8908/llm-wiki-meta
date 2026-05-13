#!/usr/bin/env bash
# detach-wiki/run.sh [ROOT] — clear the attach state, leaving .claude/state/ intact.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../lib/wiki_lib.sh"

ROOT="$(resolve_root "${1:-}")" || exit 2
state_file="$ROOT/.claude/state/attached-wiki"

if [ ! -f "$state_file" ]; then
  echo "already detached"
  exit 0
fi

prev="$(read_attached "$ROOT")"
rm -f "$state_file"
echo "detached: ${prev:-(unknown)}"
