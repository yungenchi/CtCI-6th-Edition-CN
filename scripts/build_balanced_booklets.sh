#!/usr/bin/env bash

# 「平衡分冊」：依 print/manifests/booklet-0*.txt（共 8 冊）產騎馬釘用 A4 PDF。
# 每冊對應一個輸出檔：預設寫入 dist/booklets/booklet-*.pdf。
#
# 用法：
#   ./scripts/build_balanced_booklets.sh [config.env] [輸出目錄對 repo 相對路徑]
#
#   輸出目錄預設：dist/booklets
#
# 並發：PDF_BUILD_JOBS（預設 4）。
#   PDF_BUILD_JOBS=8 ./scripts/build_balanced_booklets.sh

set -euo pipefail

config_file="${1:-print/config/chapter-booklet.env}"
outdir_rel="${2:-dist/booklets}"
pdf_jobs="${PDF_BUILD_JOBS:-4}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ "${config_file:0:1}" == "/" ]]; then
  abs_config="$config_file"
else
  abs_config="$ROOT/$config_file"
fi

TMPD="$(mktemp -d)"
trap 'rm -rf "$TMPD"' EXIT

mkdir -p "$ROOT/$outdir_rel"

export PDF_DIST_ROOT="$ROOT"
export PDF_DIST_CONFIG="$abs_config"
export PDF_DIST_OUTDIR="$outdir_rel"
export PDF_DIST_TMP="$TMPD"

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
echo "A4 booklet PDFs: $ROOT/$outdir_rel/"
