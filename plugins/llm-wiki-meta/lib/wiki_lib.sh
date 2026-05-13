# wiki_lib.sh — shared helpers for llm-wiki-meta skill scripts.
# Source from a skill's run.sh / preview.sh / apply.sh / resolve.sh.
# Do not execute directly.

# detect_root [start_dir] — print the detected llm-wiki ROOT to stdout, or empty.
# Walks up at most 5 levels from start_dir (default CWD) looking for an ancestor
# whose immediate subdirectories include >= 2 entries each containing CLAUDE.md
# or AGENTS.md. Returns 0 on success, 1 if no ROOT is found.
detect_root() {
  local p="${1:-$(pwd)}"
  local _ d hits
  for _ in 1 2 3 4 5; do
    hits=0
    for d in "$p"/*/; do
      [ -d "$d" ] || continue
      if [ -f "${d}CLAUDE.md" ] || [ -f "${d}AGENTS.md" ]; then
        hits=$((hits+1))
      fi
      if [ "$hits" -ge 2 ]; then break; fi
    done
    if [ "$hits" -ge 2 ]; then printf "%s\n" "$p"; return 0; fi
    [ "$p" = "/" ] && break
    p="$(dirname "$p")"
  done
  return 1
}

# resolve_root [explicit_root] — print ROOT or error to stderr + return 2.
# Honors an explicit arg; otherwise uses detect_root from CWD.
resolve_root() {
  local root="${1:-}"
  if [ -n "$root" ]; then
    if [ ! -d "$root" ]; then
      echo "error: ROOT does not exist: $root" >&2
      return 2
    fi
    printf "%s\n" "$root"
    return 0
  fi
  if root="$(detect_root)"; then
    printf "%s\n" "$root"
    return 0
  fi
  echo "error: could not detect llm-wiki ROOT; pass it explicitly" >&2
  return 2
}

# read_attached ROOT — print the attached wiki name (whitespace-stripped) or empty.
read_attached() {
  local root="${1:?usage: read_attached ROOT}"
  local f="$root/.claude/state/attached-wiki"
  [ -f "$f" ] || return 0
  tr -d '[:space:]' < "$f"
}

# is_wiki_dir DIR — return 0 if DIR contains CLAUDE.md or AGENTS.md.
is_wiki_dir() {
  local d="${1:?usage: is_wiki_dir DIR}"
  [ -f "$d/CLAUDE.md" ] || [ -f "$d/AGENTS.md" ]
}

# validate_wiki_name NAME — error to stderr + return 2 if invalid or reserved.
# Rejects path-like names, dotfiles, whitespace, backslashes, and reserved auxiliaries.
validate_wiki_name() {
  local name="${1:?usage: validate_wiki_name NAME}"
  case "$name" in
    */*|..|.*|*\ *|*\\*|"")
      echo "error: invalid wiki name: $name" >&2; return 2 ;;
  esac
  case "$name" in
    Excalidraw|.obsidian|.claude|tools|manifests|wiki|raw)
      echo "error: '$name' is a reserved auxiliary name" >&2; return 2 ;;
  esac
  return 0
}

# validate_wiki_dir ROOT WIKI — error + return 2 if not a valid sub-wiki under ROOT.
validate_wiki_dir() {
  local root="${1:?usage: validate_wiki_dir ROOT WIKI}"
  local wiki="${2:?usage: validate_wiki_dir ROOT WIKI}"
  local d="$root/$wiki"
  if [ ! -d "$d" ]; then
    echo "error: $wiki does not exist under $root" >&2; return 2
  fi
  if ! is_wiki_dir "$d"; then
    echo "error: $wiki has neither CLAUDE.md nor AGENTS.md; not a wiki" >&2; return 2
  fi
  return 0
}

# meta_file DIR — print "CLAUDE" or "AGENTS" or empty.
meta_file() {
  local d="${1:?usage: meta_file DIR}"
  if [ -f "$d/CLAUDE.md" ]; then echo "CLAUDE"
  elif [ -f "$d/AGENTS.md" ]; then echo "AGENTS"
  fi
}

# layer_badges DIR — print space-separated names of present layer dirs.
layer_badges() {
  local d="${1:?usage: layer_badges DIR}"
  local out=""
  [ -d "$d/wiki" ]      && out="${out}wiki "
  [ -d "$d/manifests" ] && out="${out}manifests "
  [ -d "$d/raw" ]       && out="${out}raw "
  [ -d "$d/tools" ]     && out="${out}tools "
  echo "${out% }"
}

# dir_mtime DIR — print modified date as YYYY-MM-DD (BSD or GNU stat).
dir_mtime() {
  local d="${1:?usage: dir_mtime DIR}"
  date -r "$d" '+%Y-%m-%d' 2>/dev/null \
    || stat -c '%y' "$d" 2>/dev/null | cut -d' ' -f1 \
    || echo "unknown"
}
