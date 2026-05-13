#!/usr/bin/env bash
# dispatch.sh OP [ROOT] — resolve ROOT + attached wiki + the wiki's local
# <wiki>-wiki-<OP> SKILL.md. Used by wiki-ingest/query/lint resolve.sh scripts.
#
# Output on success (three labelled lines):
#   ROOT=<absolute path>
#   WIKI=<attached name>
#   SKILL=<absolute path to the local SKILL.md>
#
# Exit codes:
#   0  ok
#   2  could not detect ROOT, or attached wiki is structurally invalid
#   3  no wiki attached
#   4  attached wiki missing or invalid on disk
#   5  local skill <wiki>-wiki-<OP> not found under the attached wiki

set -euo pipefail

OP="${1:?usage: dispatch.sh OP [ROOT]}"; shift || true
case "$OP" in
  ingest|query|lint) : ;;
  *) echo "error: unknown OP '$OP' (expected ingest|query|lint)" >&2; exit 2 ;;
esac

HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/wiki_lib.sh"

ROOT="$(resolve_root "${1:-}")" || exit 2

attached="$(read_attached "$ROOT")"
if [ -z "$attached" ]; then
  echo "error: no wiki attached — run 'attach-wiki <name>' first (or 'list-wikis' to see options)" >&2
  exit 3
fi

if ! validate_wiki_dir "$ROOT" "$attached" 2>/dev/null; then
  echo "error: attached wiki '$attached' missing or invalid — run 'detach-wiki' or 'attach-wiki <other>'" >&2
  exit 4
fi

local_skill="$ROOT/$attached/.claude/skills/${attached}-wiki-${OP}/SKILL.md"
if [ ! -f "$local_skill" ]; then
  echo "error: local skill '${attached}-wiki-${OP}' not found under $attached — re-scaffold or repair" >&2
  exit 5
fi

printf "ROOT=%s\nWIKI=%s\nSKILL=%s\n" "$ROOT" "$attached" "$local_skill"
