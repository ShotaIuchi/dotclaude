# Remote Operation Security Rules

リモートワークフロー操作のセキュリティルール。

## 概要

`wf0-remote`によるリモート操作は、GitHub Issueコメントを介してワークフローを制御する。
このルールは、不正な操作を防ぎ、安全な自動実行を保証する。

## セキュリティ要件

### 1. コメント発信者の検証

| 検証項目 | 内容 |
|----------|------|
| コラボレーター権限 | `admin`, `write`, `maintain`のいずれかが必要 |
| 権限なし | コメントは無視（エラー通知なし） |

```bash
# 権限確認の例（gh cliは現在のリポジトリコンテキストを自動検出）
permission=$(gh api "repos/{owner}/{repo}/collaborators/$username/permission" \
    --jq '.permission')

case "$permission" in
    admin|write|maintain) echo "allowed" ;;
    *) echo "denied" ;;
esac
```

> **Note**: `{owner}/{repo}`はgh cliが現在のリポジトリから自動解決するプレースホルダ。
> 環境変数を使用する場合: `gh api "repos/$GITHUB_REPOSITORY/collaborators/..."`

### 2. 実行回数制限

| 設定 | 値 | 理由 |
|------|------|------|
| 最大ステップ数 | 10 | 無限ループ防止 |
| 超過時 | 停止 & Issue通知 | 手動再起動を要求 |

### 3. 許可されるコマンド

| コマンド | 動作 | リスク |
|----------|------|--------|
| `/approve` | 次ステップ実行 | 低 |
| `/next` | `/approve`と同じ | 低 |
| `/pause` | 一時停止 | なし |
| `/stop` | 完全停止 | なし |

**禁止**: 任意のシェルコマンド実行、ファイルパス指定など

### 4. 実行環境の制限

| 制限 | 内容 |
|------|------|
| 作業ディレクトリ | プロジェクトルートのみ |
| 実行コマンド | `/wf0-nextstep`のみ |
| Git操作 | push only（force push禁止） |

## プライバシー

### Issueへの投稿内容

投稿してよいもの:
- ワークフローフェーズ名
- ドキュメントファイル名（パス）
- 成功/失敗ステータス

投稿してはいけないもの:
- ソースコードの内容
- 環境変数・シークレット
- 詳細なエラースタックトレース

```markdown
## 🤖 wf3-plan 完了

**ステータス**: 待機中（承認待ち）
**次のステップ**: wf4-review

### 成果物
- `docs/wf/FEAT-123/03_PLAN.md` 作成

---
💡 `/approve` で次のステップを実行
```

## 監視と監査

### ログ記録

デーモンは以下をログに記録する:

```
[2026-01-24 10:00:00] Polling issue #123...
[2026-01-24 10:00:05] Command detected: approve (by @username)
[2026-01-24 10:00:06] Executing step 1 of 10
[2026-01-24 10:05:00] Step completed, pushing changes...
```

### state.jsonの更新

```json
{
  "remote": {
    "enabled": true,
    "source_issue": 123,
    "poll_interval": 60,
    "last_check": "2026-01-24T10:05:00Z",
    "status": "waiting_approval",
    "tmux_session": "wf-remote-FEAT-123"
  }
}
```

| フィールド | 型 | 説明 |
|------------|------|------|
| `enabled` | boolean | リモート監視が有効か |
| `source_issue` | number | 監視対象のGitHub Issue番号 |
| `poll_interval` | number | ポーリング間隔（秒） |
| `last_check` | string | 最後のポーリング時刻（ISO8601） |
| `status` | string | `waiting_approval`, `executing`, `paused`, `stopped` |
| `tmux_session` | string | tmuxセッション名 |

## 緊急停止

以下の方法を**優先順位順**に試す:

### 方法1: Issue コメント（推奨）

**ユースケース**: 携帯・外出先から停止したい場合

```
/stop
```

- 最も安全で追跡可能
- Issueに停止記録が残る
- 次回ポーリングまで最大60秒かかる

### 方法2: tmux セッション終了

**ユースケース**: PC操作可能で即時停止が必要な場合

```bash
tmux kill-session -t wf-remote-FEAT-123
```

- 即時停止
- state.jsonは`enabled: true`のまま（次回起動時に注意）

### 方法3: プロセス強制終了

**ユースケース**: tmuxセッションが応答しない場合の最終手段

```bash
pkill -f "remote-daemon.sh FEAT-123"
```

- 他のプロセスに影響しないよう、work-idを必ず指定

## ネットワーク要件

| 要件 | 詳細 |
|------|------|
| GitHub API | 60秒ごとにポーリング |
| レート制限 | 1時間あたり60回（認証済み: 5000回） |
| タイムアウト | API呼び出し: 30秒 |

## トラブルシューティング

### デーモンが応答しない

1. tmuxセッション確認: `tmux ls`
2. ログ確認: `tmux attach -t wf-remote-<work-id>`
3. 再起動: `/wf0-remote stop && /wf0-remote start`

### コメントが無視される

1. コラボレーター権限を確認
2. コメント形式を確認（`/approve`のみ、追加テキスト不可）
3. 最大ステップ数に達していないか確認

### Pushが失敗する

1. 未コミット変更がないか確認
2. リモートとの差分を確認
3. 認証状態を確認（`gh auth status`）

## Auto Mode

### 概要

`/wf0-remote auto`は、GitHubから自動的にIssueを検出してワークフローを実行するモード。

### セキュリティ要件

| 要件 | 内容 |
|------|------|
| ラベル検証 | `auto-workflow`ラベルが必要 |
| 除外ラベル | `blocked`, `wip`は自動スキップ |
| 処理上限 | デフォルト5件/セッション |
| クールダウン | Issue間5分の待機 |

### 実行フロー

```
1. GitHub Issue クエリ (label:auto-workflow)
2. 未処理Issue選択（古い順）
3. ブランチ作成
4. /wf1-kickoff → /wf0-nextstep ループ
5. 成功: completedラベル追加
6. 失敗: Issueコメント、スキップ
7. クールダウン後、次のIssueへ
```

### state.json (auto.json)

```json
{
  "enabled": true,
  "session_start": "2026-01-30T10:00:00Z",
  "processed_count": 2,
  "current_issue": 456,
  "tmux_session": "wf-auto"
}
```

### 権限と制限

| 制限 | 内容 |
|------|------|
| Issueの条件 | open状態、指定ラベル付き |
| ブランチ操作 | 新規作成のみ（既存上書き禁止） |
| Git操作 | push only（force push禁止） |
| 実行コマンド | `/wf1-kickoff`, `/wf0-nextstep`のみ |

### 緊急停止

```bash
# 方法1: tmuxセッション終了
tmux kill-session -t wf-auto

# 方法2: プロセス強制終了
pkill -f "auto-daemon.sh"
```

## CONSTITUTIONとの関連

### Article 6: コマンド実行前検証

リモート操作でも、実行されるコマンドは`/wf0-nextstep`に限定され、Article 6の検証は維持される。

### Article 2: 同時ドキュメント作成

各ステップ完了時のIssueコメントは、ドキュメント作成の記録として機能する。
