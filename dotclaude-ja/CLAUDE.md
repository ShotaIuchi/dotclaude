# CLAUDE.md

## プロジェクト概要

Claude Codeと人間が同じ状態と成果物を見ながら作業するためのワークフロー管理システム。
`dotclaude/` フォルダから `~/.claude` へシンボリックリンクを作成して使用する。

## 原則 (PRINCIPLES.md)

**最重要**: `PRINCIPLES.md` は全てのルールに優先する基本原則。
セッション開始時に必ず `PRINCIPLES.md` を読むこと。

## 憲法 (CONSTITUTION.md)

**重要**: ファイルの追加・変更時は必ず `CONSTITUTION.md` を参照すること。

## 機能開発ワークフロー

機能開発には、個人用プラグインのマーケットプレイス [ShotaIuchi/ip](https://github.com/ShotaIuchi/ip) の `dev` プラグインを使う（feature-dev プラグインは不要）。

- `/dev:spec <やりたいこと>` — ユーザーと詳細を詰めて、承認済みの `SPEC.md` を書く
- `/dev:build [<SPEC.md>]` — 仕様をもとに実装し、チェック・仕様との照合・レビュー・修正を問題が無くなるまで（最大3周）回す。仕様からずれる時だけ質問する
