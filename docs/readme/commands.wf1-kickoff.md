# wf1-kickoff - ワークスペースとKickoff作成

新しいワークスペースとKickoffドキュメントを作成するコマンド。

## 構文

```
/wf1-kickoff github=<number>
/wf1-kickoff jira=<jira-id> [title="title"]
/wf1-kickoff local=<id> title="title" [type=<TYPE>]
/wf1-kickoff [update | revise "<instruction>" | chat]
```

## 引数

### ソース指定（新規作成時）

以下のいずれか1つを指定（排他）:

| 引数 | 説明 | 例 |
|------|------|-----|
| `github` | GitHub Issue番号 | `github=123` |
| `jira` | JiraチケットID | `jira=ABC-123` |
| `local` | ローカルID（任意の文字列） | `local=myid` |

オプション引数:

| 引数 | 説明 |
|------|------|
| `title` | タイトル（jira/localでは必須、githubでは無視） |
| `type` | 作業タイプ（localのみ。FEAT/FIX/REFACTOR/CHORE/RFC。デフォルト: FEAT） |

### サブコマンド（既存ワークスペース用）

| サブコマンド | 説明 |
|-------------|------|
| (なし) | 新規ワークスペースとKickoff作成 |
| `update` | 既存Kickoffを対話で更新 |
| `revise "<指示>"` | 指示に基づいて自動修正 |
| `chat` | ブレインストーミング対話モード |

## 使用例

```bash
# GitHub Issueから作成
/wf1-kickoff github=123

# Jiraから作成
/wf1-kickoff jira=ABC-123 title="ログイン機能追加"

# ローカルで作成
/wf1-kickoff local=auth title="認証機能の実装" type=FEAT

# 既存Kickoffを更新
/wf1-kickoff update

# 指示で修正
/wf1-kickoff revise "スコープを縮小して"
```

## 処理の流れ

### Phase 1: ワークスペース作成

1. **前提条件チェック**: jq, gh（githubモード時）の確認
2. **work-id生成**: `<TYPE>-<id>-<slug>` 形式
3. **ベースブランチ選択**: ユーザーに確認
4. **作業ブランチ作成**: `git checkout -b <branch>`
5. **WFディレクトリ初期化**: `.wf/` 作成
6. **ドキュメントディレクトリ作成**: `docs/wf/<work-id>/`

### Phase 2: Kickoff作成

7. **ソース情報取得**: Issue/チケット情報を取得
8. **ブレインストーミング対話**: Goal、成功条件、制約などを対話で決定
9. **00_KICKOFF.md作成**: テンプレートから生成

### Phase 3: 完了処理

10. **state.json更新**: ワーク情報を記録
11. **コミット**: ワークスペースとKickoffをコミット

## localモード: Issue/Jira作成オプション

`local=<id>`で作成時、外部システムへの作成を尋ねる:

```
ローカルワークフローを作成します。
外部システムにも作成しますか？

1. ローカルのみ (後で /wf0-promote で昇格可能)
2. GitHub Issue も作成
3. Jira チケットも作成
```

- **GitHub Issue選択時**: `gh issue create`でIssue作成、source.typeを`github`に更新
- **Jira選択時**: Jiraチケット作成、source.typeを`jira`に更新
- **ローカルのみ**: 後から`/wf0-promote`で昇格可能

## localモード: Plan Mode

`local=<id>`で新規Kickoff作成時、Plan Modeで要件を対話的に整理:

1. 問題の定義
2. 目標の明確化
3. 制約の特定
4. スコープ外の明示
5. 依存関係の確認

結果は`.wf/<work-id>/plan.md`に保存され、Kickoff作成の入力となる。

## work-id形式

| ソース | 形式 | 例 |
|--------|------|-----|
| github | `<TYPE>-<issue>-<slug>` | `FEAT-123-add-login` |
| jira | `JIRA-<id>-<slug>` | `JIRA-ABC-123-add-login` |
| local | `<TYPE>-<id>-<slug>` | `FEAT-myid-add-feature` |

TYPE判定（githubの場合）:
- `feature`, `enhancement` → FEAT
- `bug` → FIX
- `refactor` → REFACTOR
- `chore` → CHORE
- `rfc` → RFC

## 成果物

- `.wf/state.json` - ワークフロー状態
- `docs/wf/<work-id>/00_KICKOFF.md` - Kickoffドキュメント

## 関連コマンド

- `/wf0-promote` - ローカルワークフローをIssue/Jiraに昇格
- `/wf0-status` - ワークフロー状態確認
- `/wf2-spec` - 次のステップ（仕様作成）
