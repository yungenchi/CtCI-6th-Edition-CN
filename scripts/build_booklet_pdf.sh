#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 3 || $# -gt 4 ]]; then
  echo "Usage: $0 <manifest.txt> <reader-a5.pdf> <booklet-a4.pdf> [config.env]" >&2
  exit 1
fi

manifest="$1"
reader_output="$2"
booklet_output="$3"
config_file="${4:-print/config/default.env}"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

raw_pdf="$tmp_dir/raw-a5.pdf"
booklet_workdir="$tmp_dir/booklet"
mkdir -p "$booklet_workdir"

./scripts/build_print_pdf.sh "$manifest" "$raw_pdf" "$config_file" >/dev/null

mkdir -p "$(dirname "$reader_output")"
mkdir -p "$(dirname "$booklet_output")"
cp "$raw_pdf" "$reader_output"

cp "$raw_pdf" "$booklet_workdir/input.pdf"
(
  cd "$booklet_workdir"
  LC_ALL=C LANG=C pdfbook2 --paper=a4paper input.pdf >/dev/null
)

mv "$booklet_workdir/input-book.pdf" "$booklet_output"

echo "Built reader PDF: $reader_output"
echo "Built booklet PDF: $booklet_output"
