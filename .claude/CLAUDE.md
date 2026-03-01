# dotclaude

## ディレクトリの役割

- `.claude/` — 本プロジェクト用の設定
- `dotclaude/` — 本プロジェクトの成果物（配布される `.claude/` の内容）

特別な指示がない限り、作成・変更の対象は `dotclaude/` とする。

## ドキュメント言語

本ルールは `dotclaude/` 配下にのみ適用する。`.claude/` 配下は日本語で記載する。

`dotclaude/` 配下の全てのドキュメントは英語で記載すること。
ただし、スキルのフロントマター内 `description` フィールドは日本語で記載する（Claude Codeが直接読み取るため）。

日本語翻訳は `dotclaude-ja/` に同一ディレクトリ構成・同一ファイル名で用意すること。

- 翻訳対象はMarkdownファイル（`.md`）のみ
- Markdown以外のファイルは `dotclaude-ja/` にシンボリックリンクを作成し、`dotclaude/` の原本を参照する

例:
- `dotclaude/CLAUDE.md` → `dotclaude-ja/CLAUDE.md`（日本語翻訳）
- `dotclaude/hooks.json` → `dotclaude-ja/hooks.json`（シンボリックリンク）
