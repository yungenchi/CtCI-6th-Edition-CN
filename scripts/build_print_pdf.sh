#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Usage: $0 <manifest.txt> <output.pdf> [config.env]" >&2
  exit 1
fi

manifest="$1"
output="$2"
config_file="${3:-print/config/default.env}"
project_root="$(pwd)"

if [[ ! -f "$manifest" ]]; then
  echo "Manifest not found: $manifest" >&2
  exit 1
fi

if [[ ! -f "$config_file" ]]; then
  echo "Config file not found: $config_file" >&2
  exit 1
fi

files=()
while IFS= read -r file || [[ -n "$file" ]]; do
  [[ -z "$file" ]] && continue
  files+=("$file")
done < "$manifest"

if [[ ${#files[@]} -eq 0 ]]; then
  echo "Manifest is empty: $manifest" >&2
  exit 1
fi

for file in "${files[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "Input file not found: $file" >&2
    exit 1
  fi
done

mkdir -p "$(dirname "$output")"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

# Load print-layout settings from a plain shell env file so layout changes
# live outside the script. Command-line env vars still override these values.
set -a
# shellcheck disable=SC1090
source "$config_file"
set +a

font="${CJK_MAINFONT:-Songti SC}"
latin_main="${LATIN_MAINFONT:-}"
latin_mono="${LATIN_MONOFONT:-}"
paperwidth="${PAPER_WIDTH:-148mm}"
paperheight="${PAPER_HEIGHT:-210mm}"
inner_margin="${INNER_MARGIN:-18mm}"
outer_margin="${OUTER_MARGIN:-14mm}"
top_margin="${TOP_MARGIN:-18mm}"
bottom_margin="${BOTTOM_MARGIN:-18mm}"
fontsize="${FONT_SIZE:-12pt}"
include_toc="${INCLUDE_TOC:-1}"

processed_files=()
for file in "${files[@]}"; do
  processed_file="$tmp_dir/$file"
  mkdir -p "$(dirname "$processed_file")"
  PROJECT_ROOT="$project_root" SOURCE_FILE="$file" PROCESSED_FILE="$processed_file" python3 - <<'PY'
from pathlib import Path
import os
import re

project_root = Path(os.environ["PROJECT_ROOT"])
source_file = Path(os.environ["SOURCE_FILE"])
processed_file = Path(os.environ["PROCESSED_FILE"])

include_pattern = re.compile(r"\{\{\#include\s+([^}\s]+)\s*\}\}")


def expand_includes(text: str, current_file: Path) -> str:
    def replace(match: re.Match[str]) -> str:
        include_path = match.group(1)
        resolved = (project_root / include_path).resolve()
        try:
            resolved.relative_to(project_root.resolve())
        except ValueError:
            raise SystemExit(f"Include path escapes project root: {include_path}")
        if not resolved.is_file():
            raise SystemExit(f"Included file not found: {include_path}")
        included_text = resolved.read_text(encoding="utf-8")
        return expand_includes(included_text, resolved)

    return include_pattern.sub(replace, text)


text = source_file.read_text(encoding="utf-8")
text = expand_includes(text, source_file)
text = re.sub(
    r'<div\s+align=center>\s*<img\s+src="([^"]+)"\s*/>\s*</div>',
    r'\n\n![](\1){ width=90% }\n\n',
    text,
)
text = re.sub(
    r'<div>\s*<img\s+src="([^"]+)"\s*/>\s*</div>',
    r'\n\n![](\1){ width=90% }\n\n',
    text,
)
text = re.sub(
    r'<img\s+src="([^"]+)"\s*/>',
    r'![](\1){ width=90% }',
    text,
)
processed_file.write_text(text, encoding="utf-8")
PY
  processed_files+=("$processed_file")
done

pandoc_args=(
  "${processed_files[@]}"
  -V documentclass=book
  -V fontsize="$fontsize"
  -V CJKmainfont="$font"
  -V geometry:paperwidth="$paperwidth",paperheight="$paperheight",inner="$inner_margin",outer="$outer_margin",top="$top_margin",bottom="$bottom_margin"
  --resource-path="$project_root"
  --pdf-engine=xelatex
  -o "$output"
)

# 拉丁文／等寬（log₂ 等 Unicode 下角標若用 Latin Modern 會缺字）。見 print/config/*.env 內 LATIN_* 說明。
if [[ -n "$latin_main" ]]; then
  pandoc_args+=(-V "mainfont=$latin_main")
fi
if [[ -n "$latin_mono" ]]; then
  pandoc_args+=(-V "monofont=$latin_mono")
fi

if [[ "$include_toc" == "1" ]]; then
  pandoc_args+=(--toc)
fi

pandoc "${pandoc_args[@]}"

echo "Built $output using $config_file"
