#!/usr/bin/env bash
# wiki-ingest/resolve.sh [ROOT] — print ROOT/WIKI/SKILL for the attached wiki's local ingest.
exec "$(cd "$(dirname "$0")" && pwd)/../../lib/dispatch.sh" ingest "$@"
