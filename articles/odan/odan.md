# TL;DR
- 大学の部活で部誌を作りたいという声が挙がったので執筆環境を構築した
- markdownで書いてpandocでtexファイルを生成，latexでpdf化した
- texlintで文章を自動校閲する仕組みを導入した
- 開発環境はDocker上に構築した
- Circle CIと連携することでコミットのたびに部誌pdfが生成されるようにした