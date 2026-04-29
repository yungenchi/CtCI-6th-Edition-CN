#!/usr/bin/env bash

# 「平衡分冊」：依 print/manifests/booklet-0*-*.txt（共 8 冊）。
# 輸出路徑與先前約定一致：
#   <輸出根>/reader-a5/<slug>-reader-a5.pdf
#   <輸出根>/booklet-a4/<slug>-booklet-a4.pdf
# 預設輸出根：out/balanced
#
# 用法：
#   ./scripts/build_balanced_booklets.sh [config.env] [輸出根目錄]
#   ./scripts/build_balanced_booklets.sh [config.env] [輸出根目錄] --a4-only
#
# --a4-only  不另存 reader-a5（仍建暫存檔供 pdfbook2）
#
# 並發：PDF_BUILD_JOBS（預設 4）

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

export PDF_BOOKLET_ROOT="$ROOT"
export PDF_BOOKLET_BASE="$abs_out_root"
export PDF_BOOKLET_CONFIG="$abs_config"
export PDF_BOOKLET_A4_ONLY="$a4_only"
if [[ "$a4_only" == "1" ]]; then
  export PDF_BOOKLET_TMP="$tmp_keep"
else
  unset PDF_BOOKLET_TMP
fi

entries=(
  "booklet-01-preface-to-before-interview|print/manifests/booklet-01-preface-to-before-interview.txt"
  "booklet-02-behavioral-big-o-technical|print/manifests/booklet-02-behavioral-big-o-technical.txt"
  "booklet-03-offer-arrays-linked-lists|print/manifests/booklet-03-offer-arrays-linked-lists.txt"
  "booklet-04-stacks-queues-trees-graphs|print/manifests/booklet-04-stacks-queues-trees-graphs.txt"
  "booklet-05-bit-math-ood|print/manifests/booklet-05-bit-math-ood.txt"
  "booklet-06-recursion-dp|print/manifests/booklet-06-recursion-dp.txt"
  "booklet-07-system-design-to-databases|print/manifests/booklet-07-system-design-to-databases.txt"
  "booklet-08-threads-moderate-hard-code-library|print/manifests/booklet-08-threads-moderate-hard-code-library.txt"
)

WORKER="$ROOT/scripts/pdf_worker_dist_booklet.sh"

printf '%s\n' "${entries[@]}" | (
  cd "$ROOT" && xargs -P "$pdf_jobs" -n 1 bash "$WORKER"
)

echo ""
echo "Booklet PDFs: $booklet_dir/"
if [[ "$a4_only" != "1" ]]; then
  echo "Reader PDFs: $reader_dir/"
fi
