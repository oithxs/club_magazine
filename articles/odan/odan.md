# TL;DR
- 大学の部活で部誌を作りたいという声が挙がったので執筆環境を構築した
- markdownで書いてpandocでtexファイルを生成，latexでpdf化した
- texlintで文章を自動校正する仕組みを導入した
- 開発環境はDocker上に構築した
- Circle CIと連携することでコミットのたびに部誌pdfが生成されるようにした

# pandocの設定
pandocの説明は[公式サイト](http://sky-y.github.io/site-pandoc-jp/users-guide/)に
次にように書かれています．

> Pandocは Haskell で書かれたライブラリおよびコマンドラインツールであり、 あるマークアップ形式で書かれた文書を別の形式へ変換するものです。

例えば，pandocを使うことで，markdownで書かれた文章をdocx形式に変換できます．

部室を執筆するにはいくつかの方法がありますが最終的には，markdownで記事を書き，pandocでtexファイルに変換し，最終的にlatexでpdfを生成する方針に決定しました．
まず，他に検討した方針の採用に至らなかった理由を書いていきます．
次に採用した方針のメリットについて紹介します．

## latexで書きpdfを生成
まず真っ先に思いつく方針がこれです．
実際に「サークル 部誌」で検索するとこの方針を採用したという記事がヒットします．
しかし，この方針は次の2つの理由により不採用となりました．

1. latexの環境構築および習得の難しさ
2. 後述するtextlintという自動校正ツールのサポートを受けられない

## markdownで書き，pandocで直接pdfを生成
pandocというツールを知っていたため，次に思いついた方針がこれでした．
pandocでpdfを生成する時は，内部で一度texファイルに変換された後， `xelatex` か `lualatex` によってpdf化されます．
latexエンジンが普段使っている `pLaTeX` とは違うため， `jsbook` などのドキュメントクラスを使えず，設定方法も独特なものでした．
これではエラーに出会った時，解決できない可能性があり，この方針は見送りました．

## markdownで書き，pandocでtexファイルを生成し，pLaTeXでpdf化
最終的にこの方針に決定しました．
この方針ではmarkdownで書くため，textlintを使うことで文章の自動校正が可能になります．
また，一度texファイルにするこで，レイアウトの調整などはlatexのレイヤーで行うことができます．これにより柔軟な調整が可能になります．

# textlintの設定
Lintツールとは，ソースコードに対して静的解析を行うツールです．
これにより，変数の初期化忘れなどのバグや，`(` 周辺の空白の挿入し忘れなどのコーディングスタイルに従っていない箇所を検出できます．
[textlint](http://efcl.info/2014/12/30/textlint/)はMarkdownで書かれたテキスト向けのLintツールです．
textlintはECMAScript(JavaScript)のLintツールである，ESLintの影響を強く受けているツールです．

textlintはESLintと同様に，文章に関する様々なルールを使用できます．
textlintについて何も詳しくなかったため，[江添亮氏のC++17 Book](https://github.com/EzoeRyou/cpp17book)のものをベースに設定ファイルを書きました．
以下が設定の全体です．

```json
{
    "rules": {
        "preset-ja-technical-writing": {
            "no-exclamation-question-mark": false,
            "sentence-length": {
                "max" : 500
            },
            "ja-no-mixed-period": {
                "periodMark": "。",
                "allowPeriodMarks": ["．"]
            },
            "no-doubled-joshi": {
                "separatorChars": ["。","?","!","？","！","．"]
            },
            "no-doubled-conjunctive-particle-ga": false
        },
        "spellcheck-tech-word": true
    },
    "filters": {
        "comments": true
    }
}
```