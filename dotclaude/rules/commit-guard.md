# Commit Guard Rule

## 前提（MUST）

commit を行う前に、以下のいずれかの場所に schema が存在することを確認する：

**プロジェクト固有（優先）:**
- `docs/rules/commit.schema.md`
- `docs/rules/commit.md`

**グローバル（フォールバック）:**
- `.claude/rules/commit.schema.md`
- `.claude/rules/commit.md`

## ガード（MUST）

上記のどちらの場所にも schema が存在しない場合、**いかなる理由でも `git commit` を実行してはならない**。

その場合は以下のいずれかを行う：

- schema / ルール文書を先に作成する（保存先はユーザーに選択させる）
- ユーザーに「schema が無いため commit できない」と通知して終了

## 作成先の選択（保存先オプション）

schema が存在せず新規作成する場合、以下の選択肢をユーザーに提示する：

| 選択肢 | パス | 用途 |
|--------|------|------|
| `docs/` | `docs/rules/commit.schema.md` | プロジェクト固有、リポジトリにコミット |
| `.claude/` | `.claude/rules/commit.schema.md` | プロジェクト固有、リポジトリにコミット |
| `~/.claude/` | `~/.claude/rules/commit.schema.md` | グローバル、全プロジェクト共通 |

**デフォルト推奨**: `docs/` （プロジェクトのドキュメントとして管理）

## 禁止（MUST NOT）

schema 確認なしに `git commit` を直接実行してはならない。
