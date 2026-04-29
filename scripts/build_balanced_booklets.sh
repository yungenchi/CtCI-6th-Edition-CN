#!/usr/bin/env bash

# 「平衡分冊」：依 print/manifests/balanced/*.txt 合成約 10 本小冊，
# 目標為較適合騎馬釘的厚度（討論上常以約 24–48 頁為參考；實際頁數依內容而變）。
#
# 用法：
#   ./scripts/build_balanced_booklets.sh [config.env] [output_root]
#   ./scripts/build_balanced_booklets.sh [config.env] [output_root] --a4-only
#
# --a4-only  只輸出 A4 騎馬釘 PDF；不要求另存 reader-a5（仍會建暫存檔供 pdfbook2 用）。
#
# 並發：預設同時最多 4 個 XeLaTeX（可用環境變數調整）。
#   PDF_BUILD_JOBS=8 ./scripts/build_balanced_booklets.sh

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
if ((${#args[@]})); then
  set -- "${args[@]}"
else
  set --
fi

config_file="${1:-print/config/chapter-booklet.env}"
output_root="${2:-out/balanced}"
pdf_jobs="${PDF_BUILD_JOBS:-4}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ "${config_file:0:1}" == "/" ]]; then
  abs_config="$config_file"
else
  abs_config="$ROOT/$config_file"
fi
if [[ "${output_root:0:1}" == "/" ]]; then
  abs_out_root="$output_root"
else
  abs_out_root="$ROOT/$output_root"
fi

reader_dir="$abs_out_root/reader-a5"
booklet_dir="$abs_out_root/booklet-a4"
tmp_keep=""
if [[ "$a4_only" == "1" ]]; then
  tmp_keep="$(mktemp -d)"
  trap 'rm -rf "$tmp_keep"' EXIT
fi

mkdir -p "$reader_dir" "$booklet_dir"

export PDF_W_BALANCED_ROOT="$ROOT"
export PDF_W_BALANCED_CONFIG="$abs_config"
export PDF_W_BALANCED_OUT_ROOT="$abs_out_root"
export PDF_W_A4_ONLY="$a4_only"
if [[ "$a4_only" == "1" ]]; then
  export PDF_W_TMP_KEEP="$tmp_keep"
else
  unset PDF_W_TMP_KEEP
fi

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

WORKER="$ROOT/scripts/pdf_worker_balanced.sh"

printf '%s\n' "${entries[@]}" | (
  cd "$ROOT" && xargs -P "$pdf_jobs" -n 1 bash "$WORKER"
)

echo "Booklet PDFs: $booklet_dir/"
if [[ "$a4_only" != "1" ]]; then
  echo "Reader PDFs: $reader_dir/"
fi
