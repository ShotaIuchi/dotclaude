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

### feature-dev プラグイン（必須）

構造化された機能開発のために、マーケットプレイスから **feature-dev** プラグインをインストールする：

```
/plugin install feature-dev@claude-plugins-official
```

7フェーズのワークフロー（ディスカバリー、探索、明確化質問、アーキテクチャ、実装、レビュー、サマリー）と3種の専門エージェント（`code-explorer`、`code-architect`、`code-reviewer`）を提供する。

`/feature-dev <説明>` でインタラクティブなワークフローを開始する。

### feature-auto スキル

`/feature-auto <説明>` で feature-dev の全7フェーズワークフローを人間の介入なしで実行する。全てのヒューマンインザループチェックポイントが自律的な意思決定でオーバーライドされる。
