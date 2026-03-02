# dotclaude

Claude Code 用のワークフロー管理システム。人間と Claude Code が同じ状態・成果物を見ながら作業できる環境を提供します。

## セットアップ

### 1. リポジトリのクローン

```bash
git clone https://github.com/ShotaIuchi/dotclaude.git
```

### 2. シンボリックリンクの作成

`dotclaude/` フォルダを `~/.claude` にリンクします。

```bash
ln -s /path/to/dotclaude/dotclaude ~/.claude
```

日本語版を使用する場合:

```bash
ln -s /path/to/dotclaude/dotclaude-ja ~/.claude
```

### 3. feature-dev プラグインのインストール (必須)

構造化された機能開発ワークフローを使用するために、**feature-dev** プラグインが必要です。
Claude Code 内で以下を実行してください:

```
/plugin install feature-dev@claude-plugins-official
```

## コマンド一覧

| コマンド | 説明 |
|---------|------|
| `/feature-dev <説明>` | 7フェーズの対話的な機能開発ワークフローを開始する (feature-dev プラグイン) |
| `/feature-auto <説明>` | feature-dev の全7フェーズを人間の介入なしで自動実行する |

### `/feature-dev`

feature-dev プラグインが提供する対話的な機能開発ワークフローです。以下の7フェーズで構成されます:

1. **Discovery** — 機能の目的と要件を把握
2. **Exploration** — コードベースの調査
3. **Clarifying Questions** — 曖昧な点の質問・確認
4. **Architecture** — アーキテクチャの設計・選択
5. **Implementation** — 実装
6. **Review** — コードレビュー
7. **Summary** — 成果のまとめ

3つの専門エージェント (`code-explorer`, `code-architect`, `code-reviewer`) が連携して作業を進めます。

### `/feature-auto`

`/feature-dev` を完全自律モードで実行するスキルです。すべてのフェーズでユーザーへの確認・質問をスキップし、自律的に判断して進行します。

- 曖昧な要件は安全側の仮定で進行
- アーキテクチャは推奨案を自動選択
- レビュー指摘は重要度に応じて自動修正/ログ記録
- 完了時に自律判断のログを出力

## ディレクトリ構成

```
dotclaude/          # 成果物 (配布される ~/.claude の内容、英語)
dotclaude-ja/       # 日本語翻訳版
docs/               # ドキュメント
.claude/            # 本プロジェクト自体の Claude Code 設定
```

## 設計思想

詳細は以下のファイルを参照してください:

- **PRINCIPLES.md** — 最優先の基本原則 (安全性、誠実性、ユーザー利益、透明性)
- **CONSTITUTION.md** — ファイル追加・変更時の絶対ルール (構造、命名、依存関係)

## ライセンス

MIT
