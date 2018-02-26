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
textlintはECMAScript(JavaScript)のLintツールです．
ESLintの影響を強く受けているツールです．

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

# Dockerの設定
Dockerはコンテナ型の仮想化を行うオープンソフトウェアです．
`Dockerfile` という設定ファイルを使えば，異なる端末でほぼ同一の開発環境を用意できます．

## 執筆環境構築の難しさ
部誌の執筆環境には大きく分けて，`textlint`,`pandoc`,`latex`の3つの開発環境を用意する必要があります．
このうち，latexの開発環境にはtexliveというパッケージをインストールする必要がありますが，ローカルに導入する難易度が高く，導入できたとしても環境が壊れやすいという特性があります．
またpandocは，引用の表示のために`pandoc-citeproc`，図表番号の相互参照のために`pandoc-crossref`というfilterを導入する必要がありました．
pandoc及びこれらのfilterは，Haskell製のソフトウェアですが，Haskellのパッケージ間の依存関係の闇は深く，Stackと呼ばれるパッケージマネージャを用いても，環境構築が難しいものでした．

上述したとおり，執筆環境を部員それぞれのローカルに構築して貰うのは，非常に難しいと判断したため，Dockerコンテナ上に環境を構築することにしました．
これにより，Dockerさえインストールすれば，各自のPCで部誌を生成することが可能になります．

## Dockerのuidとgidのマッピング問題
Dockerコンテナ内で部誌pdfを生成することになりましたが，これによりDockerのuidとgidのマッピング問題が生じます．
これは，Dockerコンテナ内のuid,gidがホストマシンのuid,gidと異なるために，パーミッションの設定によっては，コンテナで生成されたファイルをホストマシンで自由に扱えないという問題です．
[jupyter/docker-stacks](https://github.com/jupyter/docker-stacks)では，コンテナ起動時にホストマシンのuidとgidを指定することで，コンテナ内のユーザのuidとgidをそれに設定するシェルスクリプトを書き，それをDockerのENTRYPOINTに指定しています．
この仕組みを真似することで，マッピング問題を回避することにしました．

# Circle CIの設定
Circle CIとは，継続的インテグレーション(Continuous Integration;CI)のSaaSです．
このサービスをGitHubと連携することで，コミットのたびに様々な処理を走らせることができます．
CIのSaaSで有名なものにTravis CIがありますが，Circle CIはDockerのサポートが手厚いため，こちらのサービスを使用することに決めました．

## 部誌pdf生成の自動化
Circle CIの設定を行うことでコミットのたびに次の処理が走るようになりました．

1. textlintを用いた文章の自動校正
2. pandocを用いてMarkdownで書かれた文章をtexファイルに変換
3. texファイルからpLaTeXを用いてpdf生成

また，`.circleci/config.yml`に `store_artifacts` の設定を書くことで，生成されたpdfをCircle CIのページから確認できるようにしました．
```yaml
- store_artifacts:
    path: ~/work/main.pdf
```

## Dockerイメージのキャッシュ
Circle CI上での部誌生成もDockerコンテナ内で実行されます．
この時，何も設定をしないとコミットのたびに，Dockerfileを変更していないにも関わらず，毎回コンテナのbuildが走ることになります．
これは時間の無駄です．
特にpandocコンテナのbuildには30分ほど時間がかかります．
そこで，Circle CIのcache機能を用いて，Dockerイメージをキャッシュするようにしました．
次のような設定を書けばDockerイメージのキャッシュが可能になります．

```yaml
- restore_cache:
    key: docker-base-{{ checksum "Dockerfile.base" }}
    path: ~/cache/base-image.tar
- run:
    command: |
        if [ -f ~/cache/base-image.tar ]; then
            docker load -i ~/cache/base-image.tar
        else
            docker-compose build base
        fi

- save_cache:
    key: docker-base-{{ checksum "Dockerfile.base" }}
    paths: ~/cache/base-image.tar
```

次の3つのことを順番に行っています．

1. `restore_cache`: Dockerfileのハッシュ値をkeyにDockerイメージのファイルのキャッシュを読み込む
2. 真ん中の`run`: キャッシュファイルが存在するならそれを読み込み，しないならDocker buildを実行
3. `save_cache`: Dockerfileのハッシュ値をkeyにDockerイメージのファイルのキャッシュを作成

Dockerfileのハッシュ値をkeyの一部に含めることで，Dockerfileの変更を検知できます．
