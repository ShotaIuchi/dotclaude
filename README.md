# dotclaude

Claude Code 用のワークフロー管理システム。人間と Claude Code が同じ状態・成果物を見ながら作業できる環境を提供します。

## 現状

このリポジトリは更新を止めています。

- 実際に使っている設定（`CLAUDE.md`、`PRINCIPLES.md`、`CONSTITUTION.md`、ルール、フック）は dotfiles リポジトリの `HOME/.claude/` で管理し、`~/.claude` にリンクしています。
- スキルは下のとおり ip リポジトリに移しました。
- `dotclaude-ja/` は移行前の日本語版の控えです（dotfiles 側とは内容が分かれています）。

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
dotclaude-ja/       # 移行前の日本語版の控え
.claude/            # 本プロジェクト自体の Claude Code 設定
```

## 設計思想

詳細は以下のファイルを参照してください（使っている版は dotfiles の `HOME/.claude/` にあります）:

- **PRINCIPLES.md** — 最優先の基本原則 (安全性、誠実性、ユーザー利益、透明性)
- **CONSTITUTION.md** — ファイル追加・変更時の絶対ルール (構造、命名、依存関係)

## ライセンス

MIT
