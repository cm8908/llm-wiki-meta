#!/usr/bin/env bash
# current-wiki/run.sh [ROOT] — print the currently attached wiki name, or (none).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../../lib/wiki_lib.sh"

ROOT="$(resolve_root "${1:-}")" || exit 2
name="$(read_attached "$ROOT")"

if [ -z "$name" ]; then
  echo "attached: (none)"
  exit 0
fi

echo "attached: $name"
if [ ! -d "$ROOT/$name" ]; then
  echo "warning: $name no longer exists under $ROOT — consider detach-wiki"
fi
