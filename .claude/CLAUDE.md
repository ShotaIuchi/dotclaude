# dotclaude プロジェクト CLAUDE.md

## プロジェクト概要

Claude Code と人間が同じ状態・同じ成果物を見て作業するためのワークフロー管理システム。
`dotclaude/` フォルダを `~/.claude` にシンボリックリンクして使用する。

## 開発規約

### コマンド（commands/*.md）

- ファイル名は `wf{N}-{name}.md` 形式
- 環境系は `wf0-*`、ドキュメント系は `wf1-4`、実装系は `wf5-6`
- コマンドの引数はMarkdown内で明示的に定義
- 状態管理は `.wf/state.json` を通じて行う

