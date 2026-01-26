# Plan: wf0-config コマンドの実装

## 概要

`.wf/config.json`の設定を対話的に編集できる`wf0-config`コマンドを新規作成する。

## 設計方針

### 2段階対話フロー

```
Step 1: カテゴリ選択（チェックボックス）
┌─────────────────────────────────────────┐
│ 編集するカテゴリを選択してください:      │
│                                         │
│ [x] ブランチ設定                         │
│ [ ] Worktree設定                        │
│ [ ] コミット設定                         │
│ [ ] 検証コマンド設定                     │
│ [ ] Jira連携設定                        │
└─────────────────────────────────────────┘

Step 2: 選択カテゴリのみ対話
→ ブランチ設定の項目だけを順番に質問
```

### 設定カテゴリ

| カテゴリ | 設定項目 | 説明 |
|----------|----------|------|
| ブランチ | `default_base_branch`, `base_branch_candidates`, `branch_prefix` | ブランチ命名規則 |
| Worktree | `worktree.enabled`, `worktree.root_dir` | git worktree設定 |
| コミット | `commit.type_detection`, `commit.default_type` | コミットメッセージ設定 |
| 検証 | `verify.test`, `verify.build`, `verify.lint` | 検証コマンド |
| Jira | `jira.project`, `jira.domain` | Jira連携 |

## 成果物

### 1. コマンド定義
- `commands/wf0-config.md`

### 2. 設定スキーマ
- `examples/config.json` の更新（全項目のサンプル）

## 実装詳細

### Usage

```
/wf0-config                  # 対話モード（カテゴリ選択から）
/wf0-config show             # 現在の設定を表示
/wf0-config init             # config.jsonを初期化
/wf0-config <category>       # 特定カテゴリのみ編集
```

### 対話フロー詳細

#### init サブコマンド
- `.wf/config.json`が存在しない場合に必須項目を対話で設定
- 存在する場合は確認してから上書き

#### show サブコマンド
- 現在の設定を整形して表示
- デフォルト値との差分をハイライト

#### 引数なし（対話モード）
1. `AskUserQuestion`でカテゴリをmultiSelect
2. 選択されたカテゴリを順番に処理
3. 各項目は現在値を表示し、変更するか確認
4. 最後に変更内容サマリーを表示して確認

### 各カテゴリの対話例

#### ブランチ設定
```
現在のデフォルトベースブランチ: develop

変更しますか？
1. そのまま (develop)
2. main
3. master
4. その他（入力）
```

#### Worktree設定
```
git worktreeを有効にしますか？

有効にすると、各ワークフローが独立したディレクトリで作業できます。
現在: 無効

1. 有効にする (推奨)
2. 無効のまま
```

## 修正対象ファイル

| ファイル | 変更内容 |
|----------|----------|
| `commands/wf0-config.md` | 新規作成 |
| `examples/config.json` | 全設定項目を追加 |
| `docs/readme/commands.wf0-config.md` | 日本語訳（docs-sync rule） |

## 検証方法

1. `/wf0-config init` で新規config作成を確認
2. `/wf0-config show` で設定表示を確認
3. `/wf0-config` でカテゴリ選択→対話編集を確認
4. `/wf0-config worktree` で単一カテゴリ編集を確認
