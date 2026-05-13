#!/usr/bin/env bash
# wiki-query/resolve.sh [ROOT] — print ROOT/WIKI/SKILL for the attached wiki's local query.
exec "$(cd "$(dirname "$0")" && pwd)/../../lib/dispatch.sh" query "$@"
