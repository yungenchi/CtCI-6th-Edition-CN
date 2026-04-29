#!/usr/bin/env bash
# build_balanced_booklets.sh 的單項目 worker：由 xargs -P 平行呼叫。
# 環境變數（父程序 export）：
#   PDF_W_BALANCED_ROOT     — 專案根目錄絕對路徑
#   PDF_W_BALANCED_CONFIG   — pdf 版面設定檔路徑
#   PDF_W_BALANCED_OUT_ROOT — out/balanced 等輸出根
#   PDF_W_A4_ONLY          — 0 或 1（與父 --a4-only）
#   PDF_W_TMP_KEEP         — a4_only=1 時 reader 暫存目錄

set -euo pipefail

name="${1:?}"

ROOT="${PDF_W_BALANCED_ROOT:?}"
config="${PDF_W_BALANCED_CONFIG:?}"
out_root="${PDF_W_BALANCED_OUT_ROOT:?}"
a4_only="${PDF_W_A4_ONLY:-0}"

reader_dir="$out_root/reader-a5"
booklet_dir="$out_root/booklet-a4"
manifest="$ROOT/print/manifests/balanced/$name.txt"

if [[ "$a4_only" == "1" ]]; then
  tmp_keep="${PDF_W_TMP_KEEP:?}"
  reader_out="$tmp_keep/$name-reader-a5.pdf"
else
  reader_out="$reader_dir/$name-reader-a5.pdf"
fi
booklet_out="$booklet_dir/$name-booklet-a4.pdf"

cd "$ROOT"
./scripts/build_booklet_pdf.sh \
  "$manifest" \
  "$reader_out" \
  "$booklet_out" \
  "$config" \
  >/dev/null

echo "Built $name"
