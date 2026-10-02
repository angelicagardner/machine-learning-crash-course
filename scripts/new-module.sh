#!/usr/bin/env bash
# Create modules/NN-slug/{notes.md,code/} and add a row to the README progress table.
#
# Usage: scripts/new-module.sh "Title" [source-url]
set -euo pipefail

usage() { echo "usage: $0 \"Title\" [source-url]" >&2; exit 1; }
[[ $# -ge 1 && -n $1 ]] || usage

title=$1
source_url=${2:-"<!-- add link -->"}
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"

# Escape a value for use on the replacement side of sed s|...|...|
esc() { printf '%s' "$1" | sed -e 's/[&|\\]/\\&/g'; }

slug=$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' \
  | sed -e 's/[^a-z0-9]\{1,\}/-/g' -e 's/^-//' -e 's/-$//')
[[ -n $slug ]] || { echo "error: title produced an empty slug" >&2; exit 1; }

# Next number = highest existing NN prefix + 1
max=0
for dir in modules/[0-9][0-9]-*/; do
  [[ -d $dir ]] || continue
  n=$(basename "$dir"); n=${n%%-*}
  (( 10#$n > max )) && max=$((10#$n))
done
num=$(printf '%02d' $((max + 1)))
dir="modules/${num}-${slug}"

mkdir -p "$dir/code"
touch "$dir/code/.gitkeep"
# YAML-safe title (escape \ and ") and table-safe title (escape |)
yaml_title=$(printf '%s' "$title" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')
table_title=$(printf '%s' "$title" | sed -e 's/|/\\|/g')

sed -e "s|{{NUM}}|$num|g" \
    -e "s|{{TITLE_YAML}}|$(esc "$yaml_title")|g" \
    -e "s|{{TITLE}}|$(esc "$title")|g" \
    -e "s|{{SOURCE}}|$(esc "$source_url")|g" \
    templates/module.md > "$dir/notes.md"

row="| ${num} | [${table_title}](${dir}/notes.md) | not started |"
if grep -q '<!-- progress:end -->' README.md; then
  tmp=$(mktemp)
  # Pass the row via the environment: awk -v would interpret backslash escapes.
  ROW=$row awk '/<!-- progress:end -->/ { print ENVIRON["ROW"] } { print }' README.md > "$tmp"
  mv "$tmp" README.md
else
  echo "warning: no progress markers in README.md; add this row by hand:" >&2
  echo "$row" >&2
fi

echo "created $dir"
