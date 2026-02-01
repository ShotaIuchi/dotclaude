# /wf0-remote

GitHub Issueコメント経由でのリモートワークフロー操作コマンド。モバイルからの承認をPCデーモンが実行。

## 使用方法

```
/wf0-remote start [target...]
/wf0-remote stop [target...]
/wf0-remote status
```

## ターゲット指定

- `<work-id>...`: 1つ以上のwork ID
- `--all`: GitHub sourceの全work
- `<pattern>`: ワイルドカード（例: `FEAT-*`）
- 省略時: active_workを使用

## リモートコマンド（Issueコメント）

| コマンド | 説明 |
|---------|------|
| `/approve` or `/next` | 次のワークフローステップを実行 |
| `/pause` | 監視を一時停止 |
| `/stop` | 監視を完全停止 |

## Auto モード

未対応のGitHub Issueを自動検出してノンストップで実行するモード。**再実行モード**もサポートし、PRレビュー後のフィードバックを自動で取り込む。

### 使用方法

```
/wf0-remote auto              # 自動検出モード開始
/wf0-remote auto stop         # 停止
/wf0-remote auto status       # 状態確認
/wf0-remote auto --max 3      # 最大3件処理
/wf0-remote auto --dry-run    # 実行せずIssue一覧表示
/wf0-remote auto --once       # 1件だけ処理して終了
```

### オプション

| オプション | 説明 |
|-----------|------|
| `--max <N>` | 最大処理件数（デフォルト: 5） |
| `--cooldown <MIN>` | Issue間の待機分（デフォルト: 5） |
| `--dry-run` | 実行せずにIssue確認のみ |
| `--once` | 1件処理後終了 |

### 動作フロー（新規Issue）

1. `auto-workflow` ラベル付きのIssueを検索
2. 古い順に1件選択、ブランチ作成
3. `/wf1-kickoff` → `/wf0-nextstep` ループ実行
4. 成功時: `completed` ラベル追加
5. 失敗時: Issueにエラーコメント、スキップ
6. クールダウン後、次のIssueへ

### 再実行モード

PRレビュー後のフィードバックを取り込み、既存PRに追加修正をプッシュする。

#### トリガー

`completed` ラベルが付いたIssueに `needs-revision` ラベルを追加する（人間が手動で付与）。

#### 再実行フロー

```
[人間] PRをレビュー、フィードバックコメント追加
    ↓
[人間] Issue/PRに `needs-revision` ラベル追加
    ↓
[auto-daemon] 検知: completed + needs-revision
    ↓
[auto-daemon] wf0-restore で既存work-id復元
    ↓
[auto-daemon] wf1-kickoff revise (PR/Issueフィードバック反映)
    ↓
[auto-daemon] wf0-nextstep ループ (wf2 → ... → wf6)
    ↓
[auto-daemon] wf7-pr update (既存PRに追加コミット)
    ↓
[auto-daemon] needs-revision ラベル削除
```

#### 優先順位

再実行対象は新規Issueより優先して処理される。

### 設定

`.wf/config.json`:

```json
{
  "auto": {
    "query": "auto-workflow",
    "exclude_labels": ["blocked", "wip"],
    "complete_label": "completed",
    "revision_label": "needs-revision",
    "max_issues": 5,
    "cooldown_minutes": 5
  }
}
```

## ノンストップ実行（auto-to ラベル）

指定したステップまで承認なしで連続実行する機能。

### 利用可能なラベル

| ラベル | 停止ステップ | 説明 |
|--------|-------------|------|
| `ghwf:auto-to-2` | step 2 | spec まで自動実行 |
| `ghwf:auto-to-3` | step 3 | plan まで自動実行 |
| `ghwf:auto-to-4` | step 4 | review まで自動実行 |
| `ghwf:auto-to-5` | step 5 | implement まで自動実行 |
| `ghwf:auto-to-6` | step 6 | verify まで自動実行 |
| `ghwf:auto-all` | step 7 | 全ステップを自動実行 |

### 使用方法

1. Issue に auto-to ラベルを付与
2. `ghwf:approve` で開始
3. 指定ステップまで自動で連続実行
4. 指定ステップ完了後に `ghwf:waiting` 状態になる

### ルール

- **最小値採用**: 複数の auto-to ラベルがある場合、最小の step を採用
  - 例: `auto-to-3` + `auto-to-6` → step 3 まで自動
- **stop 優先**: `ghwf:stop` は auto-to より常に優先（即時停止）
- **最大ステップ制限**: セッション上限（10ステップ）に達すると自動停止

### 例

```
Issue に ghwf:auto-to-3 を付与
↓
ghwf:approve で開始
↓
step 1 (kickoff) → step 2 (spec) → step 3 (plan) 自動実行
↓
step 3 完了後に ghwf:waiting になる
↓
続行するには再度 ghwf:approve を付与
```

## セキュリティ

- コラボレーター権限（admin/write/maintain）のみ処理
- セッション最大10ステップ
- 実行は `/wf0-nextstep`, `/wf0-restore` のみ
- 再実行時はブランチ新規作成禁止（既存ブランチ継続）
- `ghwf:stop` は auto-to より常に優先（即時停止）
- 詳細は `rules/remote-operation.md` 参照
