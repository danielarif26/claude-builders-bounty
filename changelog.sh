#!/usr/bin/env bash
# changelog.sh — generate a structured CHANGELOG.md from git history.
# Dependency-free: bash + git only.
#
# Usage:
#   bash changelog.sh                       # writes CHANGELOG.md since the last tag
#   CHANGELOG_OUT=- bash changelog.sh       # print to stdout only
#   CHANGELOG_SINCE=v1.0.0 bash changelog.sh
set -euo pipefail

OUT="${CHANGELOG_OUT:-CHANGELOG.md}"
TITLE="${CHANGELOG_TITLE:-# Changelog}"
CATS="${CHANGELOG_CATEGORIES:-Added,Fixed,Changed,Removed}"

# --- resolve range -----------------------------------------------------------
SINCE="${CHANGELOG_SINCE:-}"
if [[ -z "$SINCE" ]]; then
  LAST_TAG="$(git describe --abbrev=0 --tags 2>/dev/null || true)"
  [[ -n "$LAST_TAG" ]] && SINCE="$LAST_TAG"
fi

if [[ -n "$SINCE" ]]; then
  RANGE="${SINCE}..HEAD"
  RANGE_LABEL="${SINCE}..HEAD"
else
  RANGE="HEAD"
  RANGE_LABEL="all history"
fi

# --- collect commits ---------------------------------------------------------
RAW="$(git log --pretty=format:'%h|%s' "$RANGE" 2>/dev/null || true)"

# --- categorize (no associative arrays, portable to stock bash 3.2) ----------
declare -a CAT_ARR=()
IFS=',' read -ra CAT_ARR <<< "$CATS"
for i in "${!CAT_ARR[@]}"; do
  CAT_ARR[$i]="$(printf '%s' "${CAT_ARR[$i]}" | xargs)"
done

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

while IFS='|' read -r hash subject; do
  [[ -z "$hash" ]] && continue
  case "$subject" in
    feat:*|add:*|new:*|feature:*) key="Added" ;;
    fix:*|bugfix:*|hotfix:*)      key="Fixed" ;;
    remove:*|delete:*|rm:*)       key="Removed" ;;
    *)                            key="Changed" ;;
  esac
  # only honor categories the caller requested; anything else folds into Changed
  found=0
  for c in "${CAT_ARR[@]}"; do [[ "$c" == "$key" ]] && found=1 && break; done
  [[ "$found" -eq 0 ]] && key="Changed"
  printf '%s\t%s\n' "$key" "${hash}  ${subject}" >> "$TMP"
done <<< "$RAW"

emit_section() {
  local label="$1" file="$2" line
  [[ ! -s "$file" ]] && return 0
  printf '## %s\n\n' "$label"
  while IFS= read -r line; do
    printf -- '- %s\n' "$line"
  done < "$file"
}

DOC="$(
  {
    printf '%s\n\n' "$TITLE"
    printf '_Generated %s from git range `%s`._\n\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$RANGE_LABEL"
    for c in "${CAT_ARR[@]}"; do
      f="$(mktemp)"
      while IFS=$'\t' read -r k line; do
        [[ "$k" == "$c" ]] && printf '%s\n' "$line" >> "$f"
      done < "$TMP"
      emit_section "$c" "$f"
      rm -f "$f"
    done
  }
)"

if [[ "$OUT" == "-" ]]; then
  printf '%s\n' "$DOC"
else
  printf '%s\n' "$DOC" > "$OUT"
  cat "$OUT"
fi