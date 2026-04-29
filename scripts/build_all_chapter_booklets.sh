#!/usr/bin/env bash

# 依「單一 .md 檔」各產一組 reader（A5）+ booklet（A4 騎馬釘排版）。
# 頁數隨章節內容變動，不保證 24–48 頁；若要裝訂友善的分頁厚度，請用 build_balanced_booklets.sh。
#
# 用法（擇一）：
#
# A) mode 為第一參數
#    ./scripts/build_all_chapter_booklets.sh [all|chapters] [config.env] [output_root]
#    chapters — 僅 Chapter_1 … Chapter_17（17 份）
#    all      — 含前言／章節／附錄等全部約 31 份（預設）
#
# B) 相容舊寫法：未寫 mode 時，若第一個參數為 .env 檔視為設定檔
#    ./scripts/build_all_chapter_booklets.sh [config.env] [output_root]
#
# 並發預設 4：（依機器調整）
#   PDF_BUILD_JOBS=8 ./scripts/build_all_chapter_booklets.sh chapters
#
# 範例：
#   ./scripts/build_all_chapter_booklets.sh
#   ./scripts/build_all_chapter_booklets.sh chapters
#   ./scripts/build_all_chapter_booklets.sh chapters print/config/chapter-booklet.env out/chapters
#   ./scripts/build_all_chapter_booklets.sh print/config/chapter-booklet.env out/my-out

set -euo pipefail

defaults_config="print/config/chapter-booklet.env"
defaults_out="out/chapters"

config_file=""
output_root=""
mode=""

if (($# >= 1)) && [[ "$1" == all || "$1" == chapters ]]; then
  mode="$1"
  shift
  config_file="${1:-$defaults_config}"
  output_root="${2:-$defaults_out}"
elif (($# >= 1)) && [[ -f "$1" ]] && [[ "$1" == *.env ]]; then
  # 相容舊版：無 all|chapters 關鍵字、第一項為設定檔
  mode="all"
  config_file="$1"
  output_root="${2:-$defaults_out}"
elif (($# == 0)); then
  mode="all"
  config_file="$defaults_config"
  output_root="$defaults_out"
else
  echo "用法: $0 [all|chapters] [config.env] [output_root]" >&2
  echo "  或 $0 [config.env] [output_root]" >&2
  exit 1
fi

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
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

mkdir -p "$reader_dir" "$booklet_dir"

pdf_jobs="${PDF_BUILD_JOBS:-4}"

entries_all=(
  "000-translator-preface|README.md"
  "001-foreword|Foreword.md"
  "002-introduction|Introduction.md"
  "003-part-1-interview-process|I.The_Interview_Process.md"
  "004-part-2-behind-the-scenes|II.Behind_the_Scenes.md"
  "005-part-3-special-situations|III.Special_Situations.md"
  "006-part-4-before-the-interview|IV.Before_the_Interview.md"
  "007-part-5-behavioral-questions|V.Behavioral_Questions.md"
  "008-part-6-big-o|VI.Big_O.md"
  "009-part-7-technical-questions|VII.Technical_Questions.md"
  "010-part-8-the-offer-and-beyond|VIII.The_Offer_and_Beyond.md"
  "011-part-9-interview-questions|IX.Interview_Questions.md"
  "012-chapter-1-arrays-and-strings|Chapter_1_Arrays_and_Strings.md"
  "013-chapter-2-linked-lists|Chapter_2_Linked_Lists.md"
  "014-chapter-3-stacks-and-queues|Chapter_3_Stacks_and_Queues.md"
  "015-chapter-4-trees-and-graphs|Chapter_4_Trees_and_Graphs.md"
  "016-chapter-5-bit-manipulation|Chapter_5_Bit_Manipulation.md"
  "017-chapter-6-math-and-logic-puzzles|Chapter_6_Math_and_Logic_Puzzles.md"
  "018-chapter-7-object-oriented-design|Chapter_7_Object-Oriented_Design.md"
  "019-chapter-8-recursion-and-dp|Chapter_8_Recursion_and_Dynamic_Programming.md"
  "020-chapter-9-system-design-and-scalability|Chapter_9_System_Design_and_Scalability.md"
  "021-chapter-10-sorting-and-searching|Chapter_10_Sorting_and_Searching.md"
  "022-chapter-11-testing|Chapter_11_Testing.md"
  "023-chapter-12-c-and-cpp|Chapter_12_C_and_C++.md"
  "024-chapter-13-java|Chapter_13_Java.md"
  "025-chapter-14-databases|Chapter_14_Databases.md"
  "026-chapter-15-threads-and-locks|Chapter_15_Threads_and_Locks.md"
  "027-chapter-16-moderate|Chapter_16_Moderate.md"
  "028-chapter-17-hard|Chapter_17_Hard.md"
  "029-part-12-code-library|XII.Code_Library.md"
  "030-part-14-about-the-author|XIV.About_the_Author.md"
)

entries_questions=(
  "012-chapter-1-arrays-and-strings|Chapter_1_Arrays_and_Strings.md"
  "013-chapter-2-linked-lists|Chapter_2_Linked_Lists.md"
  "014-chapter-3-stacks-and-queues|Chapter_3_Stacks_and_Queues.md"
  "015-chapter-4-trees-and-graphs|Chapter_4_Trees_and_Graphs.md"
  "016-chapter-5-bit-manipulation|Chapter_5_Bit_Manipulation.md"
  "017-chapter-6-math-and-logic-puzzles|Chapter_6_Math_and_Logic_Puzzles.md"
  "018-chapter-7-object-oriented-design|Chapter_7_Object-Oriented_Design.md"
  "019-chapter-8-recursion-and-dp|Chapter_8_Recursion_and_Dynamic_Programming.md"
  "020-chapter-9-system-design-and-scalability|Chapter_9_System_Design_and_Scalability.md"
  "021-chapter-10-sorting-and-searching|Chapter_10_Sorting_and_Searching.md"
  "022-chapter-11-testing|Chapter_11_Testing.md"
  "023-chapter-12-c-and-cpp|Chapter_12_C_and_C++.md"
  "024-chapter-13-java|Chapter_13_Java.md"
  "025-chapter-14-databases|Chapter_14_Databases.md"
  "026-chapter-15-threads-and-locks|Chapter_15_Threads_and_Locks.md"
  "027-chapter-16-moderate|Chapter_16_Moderate.md"
  "028-chapter-17-hard|Chapter_17_Hard.md"
)

if [[ "$mode" == "chapters" ]]; then
  entries=("${entries_questions[@]}")
else
  entries=("${entries_all[@]}")
fi

export PDF_W_CHUNK_ROOT="$ROOT"
export PDF_W_CHUNK_TMP_ROOT="$tmp_dir"
export PDF_W_CHUNK_CONFIG="$abs_config"
export PDF_W_CHUNK_OUT_ROOT="$abs_out_root"

WORKER="$ROOT/scripts/pdf_worker_chunk_booklet.sh"

printf '%s\n' "${entries[@]}" | (
  cd "$ROOT" && xargs -P "$pdf_jobs" -n 1 bash "$WORKER"
)

echo "Reader PDFs: $reader_dir/"
echo "Booklet PDFs: $booklet_dir/"
