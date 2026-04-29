#!/usr/bin/env bash
# build_balanced_booklets.sh 並行時用的 worker：一章分冊一個 manifest → 輸出一個騎馬釘 A4 PDF。
#
# 參數：「輸出檔名作為 slug｜manifest 檔對 repo 相對路徑」
#
# 環境變數（父程式 export）：
#   PDF_DIST_ROOT       — repo 根目錄
#   PDF_DIST_CONFIG      — pdf 版面設定絕對路徑
#   PDF_DIST_OUTDIR     — 對 repo 的根相對輸出目錄（如 dist/booklets）
#   PDF_DIST_TMP        — reader 暫存目錄（各 slug 不重名）

set -euo pipefail

line="${1:?}"
slug="${line%%|*}"
manifest_rel="${line#*|}"

ROOT="${PDF_DIST_ROOT:?}"
CONFIG="${PDF_DIST_CONFIG:?}"
outdir_rel="${PDF_DIST_OUTDIR:?}"
tmpdir="${PDF_DIST_TMP:?}"

manifest="$ROOT/$manifest_rel"
reader_tmp="$tmpdir/$slug-reader.tmp.pdf"
booklet_out="$ROOT/$outdir_rel/$slug.pdf"

cd "$ROOT"
mkdir -p "$(dirname "$booklet_out")"

./scripts/build_booklet_pdf.sh \
  "$manifest" \
  "$reader_tmp" \
  "$booklet_out" \
  "$CONFIG" \
  >/dev/null

echo "Built $slug"
