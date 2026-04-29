# Print Edition

這個 repo 是 `mdBook` 結構，但要輸出可列印的中文 PDF，最穩的是 `pandoc + xelatex`。

## 腳本該用哪一支？（騎馬釘／頁數）


| 情境                                             | 用哪支 script                                  | 說明                                                                                                                                  |
| ---------------------------------------------- | ------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| 希望 **8 冊騎馬釘分冊**（`booklet-0*` manifest） | `./scripts/build_balanced_booklets.sh [config.env] [輸出根]` | 預設輸出根 `out/balanced`：`reader-a5/`、`booklet-a4/`。可加 `--a4-only`。並發：`PDF_BUILD_JOBS`。 |
| 一章（或一卷）對應 **一個 PDF**；頁數隨該檔長度而定，**可能超過** 上述範圍   | `./scripts/build_all_chapter_booklets.sh …` | 預設產約 31 份（前言到附錄）。只要第 1–17 題章節：加 `chapters` 當第一參數（見下文）。                                                                          |


底層都會呼叫 `build_booklet_pdf.sh`（A5 → `pdfbook2` → A4 騎馬釘排版）。

更底層、自己指定單次 manifest：`./scripts/build_print_pdf.sh`。

並發預設 **4**（同時跑多個 XeLaTeX，可縮短總時間；依 CPU／記憶體調校）：

```bash
PDF_BUILD_JOBS=8 ./scripts/build_balanced_booklets.sh
PDF_BUILD_JOBS=6 ./scripts/build_all_chapter_booklets.sh chapters
```

## 檔案分工

- `print/manifests/*.txt`
放「這一冊要收哪些章節」。
- `print/config/default.env`
放版面參數，例如字體、頁面大小、邊界、字級。
- `scripts/build_print_pdf.sh`
讀 manifest 和 config，然後輸出 PDF。

## 第一冊

第一冊的章節清單在 `print/manifests/vol1-frontmatter-a5.txt`：

- `Foreword.md`
- `Introduction.md`
- `I.The_Interview_Process.md`
- `II.Behind_the_Scenes.md`
- `III.Special_Situations.md`
- `IV.Before_the_Interview.md`

用 `print/config/default.env` 這組設定輸出時，頁數大約是 `50` 頁。

## Build

用預設設定檔：

```bash
./scripts/build_print_pdf.sh print/manifests/vol1-frontmatter-a5.txt out/ctci-vol1-frontmatter-a5.pdf
```

指定另一個設定檔：

```bash
./scripts/build_print_pdf.sh print/manifests/vol1-frontmatter-a5.txt out/ctci-vol1-frontmatter-a5.pdf print/config/default.env
```

## 你最常會改的地方

在 `print/config/default.env` 直接改：

- `CJK_MAINFONT`
中文正文字體。
- `PAPER_WIDTH` / `PAPER_HEIGHT`
頁面尺寸。
- `INNER_MARGIN` / `OUTER_MARGIN` / `TOP_MARGIN` / `BOTTOM_MARGIN`
四邊邊界。
- `FONT_SIZE`
正文字級。

## 補充

- 目前這套設定是 `A5 + 12pt`，比較像書，不像講義。
- 目前 `50 頁` 不是寫死在腳本裡，而是「第一冊 manifest + default.env 版面設定」跑出來的結果。

## 平衡版分冊（8 冊）

整書依 `print/manifests/booklet-0*-*.txt` 合為 **8 本**；預設寫入 **`out/balanced/reader-a5/`** 與 **`out/balanced/booklet-a4/`**（檔名形如 `booklet-01-…-reader-a5.pdf`、`booklet-01-…-booklet-a4.pdf`）。

```bash
./scripts/build_balanced_booklets.sh
./scripts/build_balanced_booklets.sh print/config/chapter-booklet.env out/balanced
# 只保留 booklet-a4、reader 用暫存：
./scripts/build_balanced_booklets.sh print/config/chapter-booklet.env out/balanced --a4-only
```

舊版 `print/manifests/balanced/01-*`～`10-*` 仍可手動餵給 `./scripts/build_print_pdf.sh`。

## 依「單一檔案」各產一冊（一章一 PDF）

與平衡分冊不同：每個條目只是一份 `.md`，適合快速單章重印或帶解答單章。

```bash
# 全部條目（約 31 份）→ out/chapters/
./scripts/build_all_chapter_booklets.sh

# 只要 Chapter_1 … Chapter_17（17 份）
./scripts/build_all_chapter_booklets.sh chapters

# 自訂設定與輸出目錄（並指定 chapters）
./scripts/build_all_chapter_booklets.sh chapters print/config/chapter-booklet.env out/chapters

# 舊版寫法（未寫 chapters / all）：第一個變數為 .env
./scripts/build_all_chapter_booklets.sh print/config/chapter-booklet.env out/chapters
```

