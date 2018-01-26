# 部誌
[![CircleCI](https://circleci.com/gh/oithxs/club_magazine.svg?style=svg)](https://circleci.com/gh/oithxs/club_magazine)

## はじめかた

※ clone / push するためには Collaborator権限が必要です。 eliza0xに声をかけてください！

```
git clone git@github.com:oithxs/club_magazine.git
```

## 作業の流れ

1. リポジトリをcloneする
2. forkしたリポジトリをcloneする
3. masterからbranchを切って作業する
4. pushする

## 執筆の流れ
1. 適当な名前でディレクトリを作る (ここでは poyo とする)
2. articles/poyo 以下に poyo.md という名前のmarkdownファイルを作る
3. Makefile の MD_DIRS に articles/poyo を追加する
4. main.tex に \input{build/poyo} を追加する
5. inputの1行上に \chapter{タイトル名} を追加する

## pdfファイルの生成の仕方
dockerが使えること前提で書いています  
自分でpandocやlatexの環境を構築してもいいですが，きっと骨が折れます
```
make docker-pull
make docker-all
```

## Pull Requestを投げるまで

1. `master` から好きな名前でbranchを切って下さい(ここではadd-poyoとする)
```
git checkout -b add-poyo
```

2. 上に書いた執筆作業をする
3. git add & git commit する
4. git push origin add-poyo
5. ブラウザでリポジトリを開いてPRを作成する
6. 自動でlint + build が実行され，circle ciのページにpdfが生成されます
