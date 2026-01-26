# wf0-config コマンド

`.wf/config.json`の設定を対話的に編集するコマンド。

## 使用方法

```
/wf0-config                  # 対話モード（カテゴリ選択から開始）
/wf0-config show             # 現在の設定を表示
/wf0-config init             # config.jsonを初期化
/wf0-config <category>       # 特定カテゴリのみ編集
```

## 引数

| 引数 | 説明 |
|------|------|
| `show` | 現在の設定を整形して表示 |
| `init` | `.wf/config.json`を対話的に初期化 |
| `<category>` | 指定カテゴリのみ編集 |

### カテゴリ一覧

| カテゴリ | 設定内容 |
|----------|----------|
| `branch` | デフォルトベースブランチ、候補、プレフィックス |
| `worktree` | git worktreeの有効/無効、ルートディレクトリ |
| `commit` | コミットタイプ検出方法、デフォルトタイプ |
| `verify` | テスト・ビルド・Lintコマンド |
| `jira` | Jiraプロジェクト、ドメイン |

## 対話フロー

### 1. カテゴリ選択

引数なしで実行すると、まず編集するカテゴリを選択：

```
編集するカテゴリを選択してください:

[x] ブランチ設定
[ ] Worktree設定
[ ] コミット設定
[ ] 検証コマンド設定
[ ] Jira連携設定
```

### 2. 項目編集

選択したカテゴリの項目を順番に対話形式で設定。
現在値がある場合は表示され、変更するか確認。

### 3. 確認・保存

全項目編集後、変更内容のサマリーを表示し、保存確認。

## サブコマンド

### show

現在の設定を整形して表示：

```
⚙️  WF Configuration
═══════════════════════════════════════

🌿 Branch Settings:
   Default base branch: develop
   ...

🌳 Worktree Settings:
   Enabled: true
   ...
```

### init

新規プロジェクトで必須項目を対話設定。
既存ファイルがある場合は上書き確認。

## 設定項目

### ブランチ設定

| 項目 | 説明 | デフォルト |
|------|------|------------|
| `default_base_branch` | PRのベースブランチ | `develop` |
| `base_branch_candidates` | ベースブランチ候補 | `["develop", "main", "master"]` |
| `allow_pattern_candidates` | ベースとして許可するブランチパターン（正規表現） | `["release/.*", "hotfix/.*"]` |
| `branch_prefix` | Work種別ごとのブランチプレフィックス | `FEAT→feat, FIX→fix, ...` |

### Worktree設定

| 項目 | 説明 | デフォルト |
|------|------|------------|
| `worktree.enabled` | git worktreeを使用するか | `false` |
| `worktree.root_dir` | worktreeのルートディレクトリ | `.worktrees` |

### コミット設定

| 項目 | 説明 | デフォルト |
|------|------|------------|
| `commit.type_detection` | タイプ検出方法 (`auto`/`manual`/`fixed`) | `auto` |
| `commit.default_type` | デフォルトのコミットタイプ | `feat` |

### 検証コマンド設定

| 項目 | 説明 | デフォルト |
|------|------|------------|
| `verify.test` | テストコマンド | `npm test` |
| `verify.build` | ビルドコマンド | `npm run build` |
| `verify.lint` | Lintコマンド | `npm run lint` |

### Jira連携設定

| 項目 | 説明 | デフォルト |
|------|------|------------|
| `jira.project` | Jiraプロジェクトキー | `null` |
| `jira.domain` | Jiraドメイン | `null` |

## 使用例

### 新規プロジェクトでの初期化

```
/wf0-config init
```

### Worktree設定のみ変更

```
/wf0-config worktree
```

### 現在の設定確認

```
/wf0-config show
```

## 注意事項

- `.wf/config.json`が存在しない場合:
  - `show`: 「設定ファイルがありません」メッセージを表示
  - `init`: 初期化を続行
  - 引数なし: 自動的に`init`フローを開始
  - `<category>`: エラーを表示し、`init`を促す
- 編集しない項目は保持される
- 不正な値（存在しないブランチ名等）はバリデーションで警告
