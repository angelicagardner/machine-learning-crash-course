#!/usr/bin/env bash
# One-time setup for a repo generated from course-template.
# Fills placeholders, sets up the language toolchain, optionally creates modules
# from an outline, then removes TEMPLATE.md and itself.
#
# Usage:
#   scripts/init-course.sh --name "Course name" --url https://... \
#     [--lang go|python|both|none] [--outline outline.tsv] [--module github.com/you/repo]
set -euo pipefail

usage() {
  sed -n '2,9p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2
  exit 1
}

name="" url="" lang="none" outline="" module=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --name)    name=${2:-};    shift 2 ;;
    --url)     url=${2:-};     shift 2 ;;
    --lang)    lang=${2:-};    shift 2 ;;
    --outline) outline=${2:-}; shift 2 ;;
    --module)  module=${2:-};  shift 2 ;;
    -h|--help) usage ;;
    *) echo "unknown option: $1" >&2; usage ;;
  esac
done
[[ -n $name && -n $url ]] || usage
case $lang in go|python|both|none) ;; *) echo "error: --lang must be go, python, both or none" >&2; exit 1 ;; esac
if [[ -n $outline && ! -f $outline ]]; then
  echo "error: outline file not found: $outline" >&2; exit 1
fi
outline=${outline:+$(cd "$(dirname "$outline")" && pwd)/$(basename "$outline")}

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"
repo=$(basename "$root")

esc() { printf '%s' "$1" | sed -e 's/[&|\\]/\\&/g'; }

case $lang in
  go)     lang_label="Go" ;;
  python) lang_label="Python" ;;
  both)   lang_label="Go and Python" ;;
  none)   lang_label="—" ;;
esac

for f in README.md AGENTS.md resources.md; do
  sed -i \
    -e "s|{{COURSE_NAME}}|$(esc "$name")|g" \
    -e "s|{{COURSE_URL}}|$(esc "$url")|g" \
    -e "s|{{START_DATE}}|$(date +%Y-%m-%d)|g" \
    -e "s|{{LANG}}|$(esc "$lang_label")|g" \
    "$f"
done

# Derive the Go module path from the origin remote unless given explicitly.
if [[ -z $module ]]; then
  remote=$(git remote get-url origin 2>/dev/null || true)
  if [[ $remote == *github.com* ]]; then
    slug=${remote#*github.com[:/]}
    module="github.com/${slug%.git}"
  else
    module="example.com/${repo}"
  fi
fi

if [[ $lang == go || $lang == both ]]; then
  if command -v go >/dev/null 2>&1; then
    [[ -f go.mod ]] || go mod init "$module"
  else
    echo "warning: go not found; run 'go mod init $module' later" >&2
  fi
fi

if [[ $lang == python || $lang == both ]]; then
  [[ -f pyproject.toml ]] || cat > pyproject.toml <<EOF
[project]
name = "${repo}"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = []

[tool.ruff]
line-length = 100

[tool.ruff.lint]
select = ["E", "F", "I", "B", "UP"]

[tool.pytest.ini_options]
testpaths = ["modules"]
addopts = "--import-mode=importlib"
EOF
fi

if [[ -n $outline ]]; then
  while IFS=$'\t' read -r title src || [[ -n $title ]]; do
    [[ -z $title || $title == \#* ]] && continue
    "$root/scripts/new-module.sh" "$title" "${src:-}"
  done < "$outline"
fi

rm -f TEMPLATE.md
echo "initialised '$name' in $repo"
rm -- "${BASH_SOURCE[0]}"
