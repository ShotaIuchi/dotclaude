# dotclaude プロジェクト CLAUDE.md

## プロジェクト概要

Claude Code と人間が同じ状態・同じ成果物を見て作業するためのワークフロー管理システム。
`dotclaude/` フォルダを `~/.claude` にシンボリックリンクして使用する。

## ディレクトリ構成

```
dotclaude/
├── dotclaude/             # ~/.claude にリンクする対象
│   ├── commands/          # スラッシュコマンド定義（*.md）
│   ├── guides/            # アーキテクチャガイド
│   ├── examples/          # 設定ファイル例（config.json, state.json, local.json）
│   ├── scripts/           # シェルスクリプト（wf-*.sh）
│   └── templates/         # ドキュメントテンプレート（00_*.md〜05_*.md）
├── .claude/               # このプロジェクト用の Claude 設定
├── .gitignore
└── README.md
```

## 開発規約

### コマンド（commands/*.md）

- ファイル名は `wf{N}-{name}.md` 形式
- 環境系は `wf0-*`、ドキュメント系は `wf1-4`、実装系は `wf5-6`
- コマンドの引数はMarkdown内で明示的に定義
- 状態管理は `.wf/state.json` を通じて行う

### スクリプト（scripts/*.sh）

- `wf-utils.sh` - 共通ユーティリティ関数
- `wf-state.sh` - 状態管理関数（state.json 操作）
- `wf-init.sh` - プロジェクト初期化スクリプト
- 必要な外部コマンド: `bash`, `jq`, `gh`, `git`

### テンプレート（templates/*.md）

- テンプレートは AI と人間の思考を揃えるインターフェース
- 必須項目は空でも枠を作る（抜けを可視化）
- AI が勝手に決めてはいけない箇所は Open Questions で明示

### 設定ファイル例（examples/*.json）

- `config.json` - 共有設定の例
- `state.json` - 共有状態の例
- `local.json` - ローカル設定の例（gitignore対象）

## 重要な制約

1. **後方互換性**: 既存の wf コマンドを使用しているプロジェクトに影響しないよう注意
2. **スクリプトの依存関係**: `jq` が必須、なければエラーメッセージを出す
3. **JSON スキーマ**: state.json/config.json の構造を変更する場合は examples も更新

## テスト方針

- スクリプト変更時は実際のプロジェクトで動作確認
- コマンド変更時は Claude Code 上で実行して確認
- テンプレート変更時は生成されるドキュメントの整合性を確認
