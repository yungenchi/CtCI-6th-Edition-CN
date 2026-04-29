#!/usr/bin/env bash
# build_all_chapter_booklets.sh 的單項目 worker：由 xargs -P 平行呼叫。
# 環境變數（父程序 export）：
#   PDF_W_CHUNK_ROOT     — 專案根目錄絕對路徑
#   PDF_W_CHUNK_CONFIG   — pdf 版面設定檔路徑
#   PDF_W_CHUNK_OUT_ROOT — out/chapters 等輸出根
#   PDF_W_CHUNK_TMP_ROOT — manifest 暫存目錄（各條目共用，檔名以 name 區隔）
#
# 參數：單筆 entries 項目 "編號-prefix|對應.md"

set -euo pipefail

entry="${1:?}"
name="${entry%%|*}"
source_file="${entry##*|}"

ROOT="${PDF_W_CHUNK_ROOT:?}"
tmp_root="${PDF_W_CHUNK_TMP_ROOT:?}"
config="${PDF_W_CHUNK_CONFIG:?}"
out_root="${PDF_W_CHUNK_OUT_ROOT:?}"

manifest_file="$tmp_root/$name.txt"
reader_dir="$out_root/reader-a5"
booklet_dir="$out_root/booklet-a4"

printf '%s\n' "$source_file" > "$manifest_file"

cd "$ROOT"
./scripts/build_booklet_pdf.sh \
  "$manifest_file" \
  "$reader_dir/$name-reader-a5.pdf" \
  "$booklet_dir/$name-booklet-a4.pdf" \
  "$config" \
  >/dev/null

echo "Built $name"
