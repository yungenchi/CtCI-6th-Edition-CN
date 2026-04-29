#!/usr/bin/env bash
# build_balanced_booklets.sh 並行 worker：一封 manifest → reader（A5）+ booklet（A4）。
#
# 第 1 參數：「輸出檔名作為 slug｜manifest 對 repo 相對路徑」
#
# 環境變數：
#   PDF_BOOKLET_ROOT     — repo 根目錄（絕對路徑）
#   PDF_BOOKLET_BASE     — 輸出根目錄（絕對路徑，如 .../out/balanced）
#   PDF_BOOKLET_CONFIG   — 版面設定檔（絕對路徑）
#   PDF_BOOKLET_A4_ONLY  — 若為 1，reader 寫入 PDF_BOOKLET_TMP，不寫 reader-a5/
#   PDF_BOOKLET_TMP      — a4-only 時 reader 暫存目錄

set -euo pipefail

line="${1:?}"
slug="${line%%|*}"
manifest_rel="${line#*|}"

ROOT="${PDF_BOOKLET_ROOT:?}"
BASE="${PDF_BOOKLET_BASE:?}"
CONFIG="${PDF_BOOKLET_CONFIG:?}"
a4_only="${PDF_BOOKLET_A4_ONLY:-0}"

manifest="$ROOT/$manifest_rel"
booklet_out="$BASE/booklet-a4/$slug-booklet-a4.pdf"

if [[ "$a4_only" == "1" ]]; then
  tmpdir="${PDF_BOOKLET_TMP:?}"
  reader_out="$tmpdir/$slug-reader-a5.pdf"
else
  reader_out="$BASE/reader-a5/$slug-reader-a5.pdf"
fi

cd "$ROOT"
mkdir -p "$(dirname "$reader_out")" "$(dirname "$booklet_out")"

./scripts/build_booklet_pdf.sh \
  "$manifest" \
  "$reader_out" \
  "$booklet_out" \
  "$CONFIG" \
  >/dev/null

echo "Built $slug"
