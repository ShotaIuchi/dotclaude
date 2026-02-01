# Remote Operation Security Rules

リモートワークフロー操作のセキュリティルール。

## 概要

`wf0-remote`によるリモート操作は、GitHub Issueコメントを介してワークフローを制御する。
このルールは、不正な操作を防ぎ、安全な自動実行を保証する。

## セキュリティ要件

### 1. コメント発信者の検証

- **必須権限**: `admin`, `write`, `maintain`のいずれか
- **権限なし**: コメントは無視される（エラー通知なし）

### 2. 実行回数制限

- **最大ステップ数**: 10回/セッション
- **超過時**: 自動停止 & Issue通知
- **理由**: 無限ループ防止

### 3. 許可されるコマンド

| コマンド | 動作 |
|----------|------|
| `/approve` | 次ステップ実行 |
| `/next` | `/approve`と同じ |
| `/pause` | 一時停止 |
| `/stop` | 完全停止 |

**禁止**: 任意のシェルコマンド、ファイルパス指定

### 4. auto-to ラベル（ノンストップ実行）

指定ステップまで承認なしで連続実行する。

| ラベル | 停止ステップ |
|--------|-------------|
| `ghwf:auto-to-2` | step 2 (spec) |
| `ghwf:auto-to-3` | step 3 (plan) |
| `ghwf:auto-to-4` | step 4 (review) |
| `ghwf:auto-to-5` | step 5 (implement) |
| `ghwf:auto-to-6` | step 6 (verify) |
| `ghwf:auto-all` | step 7 (pr) |

**セキュリティルール**:
- 最小値採用: 複数ラベル時は最小 step を採用
- stop 優先: `ghwf:stop` は auto-to より常に優先
- 上限制限: セッション上限（10ステップ）は auto-to でも適用

### 4. 実行環境の制限

- 作業ディレクトリ: プロジェクトルートのみ
- 実行コマンド: `/wf0-nextstep`のみ
- Git操作: push only（force push禁止）

## プライバシー

### Issueに投稿してよいもの

- ワークフローフェーズ名
- ドキュメントファイル名
- 成功/失敗ステータス

### 投稿してはいけないもの

- ソースコードの内容
- 環境変数・シークレット
- 詳細なエラースタックトレース

## 緊急停止方法

1. **Issueコメント**: `/stop`
2. **tmuxセッション終了**: `tmux kill-session -t wf-remote-<work-id>`
3. **プロセス強制終了**: `pkill -f "remote-daemon.sh"`

## トラブルシューティング

### デーモンが応答しない

1. `tmux ls`でセッション確認
2. `tmux attach -t wf-remote-<work-id>`でログ確認
3. `/wf0-remote stop && /wf0-remote start`で再起動

### コメントが無視される

1. コラボレーター権限を確認
2. コメント形式を確認（`/approve`のみ）
3. 最大ステップ数に達していないか確認
