#!/usr/bin/env bash

# 「平衡分冊」：依 print/manifests/balanced/*.txt 合成約 10 本小冊，
# 目標為較適合騎馬釘的厚度（討論上常以約 24–48 頁為參考；實際頁數依內容而變）。
#
# 用法：
#   ./scripts/build_balanced_booklets.sh [config.env] [output_root]
#   ./scripts/build_balanced_booklets.sh [config.env] [output_root] --a4-only
#
# --a4-only  只輸出 A4 騎馬釘 PDF；不要求另存 reader-a5（仍會建暫存檔供 pdfbook2 用）。

set -euo pipefail

a4_only=0
args=()
for a in "$@"; do
  if [[ "$a" == --a4-only ]]; then
    a4_only=1
  else
    args+=("$a")
  fi
done
set -- "${args[@]}"

config_file="${1:-print/config/chapter-booklet.env}"
output_root="${2:-out/balanced}"

reader_dir="$output_root/reader-a5"
booklet_dir="$output_root/booklet-a4"
tmp_dir=""
if [[ "$a4_only" == "1" ]]; then
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' EXIT
fi

mkdir -p "$reader_dir" "$booklet_dir"

entries=(
  "01-frontmatter-and-overview"
  "02-special-situations-and-prep"
  "03-big-o"
  "04-technical-questions-and-offer"
  "05-core-data-structures"
  "06-bit-math-ood"
  "07-dp-system-design-sorting"
  "08-testing-cpp-java"
  "09-db-threads-moderate-hard"
  "10-code-library-and-author"
)

for name in "${entries[@]}"; do
  manifest="print/manifests/balanced/$name.txt"

  if [[ "$a4_only" == "1" ]]; then
    reader_out="$tmp_dir/$name-reader-a5.pdf"
  else
    reader_out="$reader_dir/$name-reader-a5.pdf"
  fi
  booklet_out="$booklet_dir/$name-booklet-a4.pdf"

  ./scripts/build_booklet_pdf.sh \
    "$manifest" \
    "$reader_out" \
    "$booklet_out" \
    "$config_file" \
    >/dev/null

  echo "Built $name"
done

echo "Booklet PDFs: $booklet_dir"
if [[ "$a4_only" != "1" ]]; then
  echo "Reader PDFs: $reader_dir"
fi
