# wf0-remote - リモートワークフロー操作

GitHub Issueコメント経由でワークフローを監視・実行するコマンド。
外出先からモバイル等でIssueにコメントするだけで、PCのデーモンがワークフローを進行する。

## 構文

```
/wf0-remote <subcommand> [target...]
```

## サブコマンド

| サブコマンド | 説明 |
|--------------|------|
| `start [target...]` | リモート監視を開始（tmuxセッションで起動） |
| `stop [target...]` | リモート監視を停止 |
| `status` | 現在の監視状態を表示 |

## ターゲット指定

| 形式 | 説明 | 例 |
|------|------|-----|
| `work-id` | 単一のwork指定 | `FEAT-123-auth` |
| `work-id...` | 複数work指定（可変引数） | `FEAT-123 FIX-456 FEAT-789` |
| `--all` | 全対象work | start時: GitHub sourceのみ<br>stop時: 実行中のworkすべて |
| `PATTERN` | ワイルドカードパターン | `FEAT-*`, `*-auth`, `FIX-???-*` |
| (省略) | `active_work`を使用 | - |

## 使用例

### 基本操作

```bash
# 単一workの監視開始
/wf0-remote start FEAT-123-auth

# 監視状態確認
/wf0-remote status

# 監視停止
/wf0-remote stop FEAT-123-auth
```

### 複数work指定

```bash
# 複数のwork-idを直接指定
/wf0-remote start FEAT-123-auth FIX-456-login FEAT-789-export

# 停止も同様
/wf0-remote stop FEAT-123 FEAT-456
```

### 一括操作

```bash
# GitHub Issueをソースとする全workを監視
/wf0-remote start --all

# 実行中の全監視を停止
/wf0-remote stop --all
```

### ワイルドカードパターン

```bash
# FEAT-で始まるworkを監視
/wf0-remote start FEAT-*

# -authで終わるworkを監視
/wf0-remote start *-auth

# FIX-XXX-で始まるworkを停止（?は1文字にマッチ）
/wf0-remote stop FIX-???-*
```

## 仕組み

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   携帯/PC   │────▶│GitHub Issue │────▶│  PCデーモン  │
│  コメント投稿 │     │  コメント    │     │   (tmux)    │
│  /approve   │     │             │     │ /wf0-nextstep│
└─────────────┘     └─────────────┘     └──────┬──────┘
                                               │
                                               ▼
                                        [次のステップ実行]
```

## Issueコメントコマンド

監視開始後、GitHub Issueに以下のコマンドをコメントとして投稿できる:

| コマンド | 説明 |
|---------|------|
| `/approve` | 次のワークフローステップを実行 |
| `/next` | `/approve`と同じ |
| `/pause` | 監視を一時停止（`/approve`で再開） |
| `/stop` | 監視を完全停止 |

## セキュリティ

- **権限チェック**: `admin`, `write`, `maintain`権限を持つコラボレーターのみ
- **実行制限**: 最大10ステップ（無限ループ防止）
- **コマンド制限**: 認識されるのは`/approve`, `/next`, `/pause`, `/stop`のみ
- **実行内容**: `/wf0-nextstep`のみ（任意コマンド禁止）

## 注意事項

- `gh` CLIの認証が必要
- `tmux`が必要（デーモンセッション管理）
- GitHub Issueをソースとするworkのみ対象（local, jiraは対象外）
- 詳細なセキュリティルールは`rules/remote-operation.md`を参照
