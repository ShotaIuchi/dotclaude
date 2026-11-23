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

## スキル

スキルはすべて、個人用プラグインのマーケットプレイス [ShotaIuchi/ip](https://github.com/ShotaIuchi/ip) に移しました。

| 旧スキル | 移行先 |
|---------|------|
| `/feature-auto` | `dev` プラグインの `/dev:spec`、`/dev:build` |
| `/task-decompose` | `dev` プラグインの `/dev:decompose` |
| `/review-design`、`/review-skim` | `read` プラグインの `/read:diagram`、`/read:outline` |
| `/multi-review`、`/review-fix`、`/pr-comment-fix` | `review` プラグイン |
| `/qa-inspect` | 廃止 |

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
