# Parallel Execution Rule

並列実行による効率化ルール。

## 原則

**独立したタスクは常に並列実行する。**

```
# GOOD: 並列実行
3つのエージェントを同時起動:
1. セキュリティ分析
2. パフォーマンスレビュー
3. 型チェック

# BAD: 不必要な順次実行
まずエージェント1、次にエージェント2、最後にエージェント3
```

## 並列実行すべきケース

### 1. 複数ファイルの読み込み

```
# GOOD
Read: src/auth/login.kt
Read: src/auth/token.kt
Read: src/auth/session.kt
（同時に3ファイル読み込み）

# BAD
Read: src/auth/login.kt → 結果を見て → Read: token.kt → ...
```

### 2. 独立した調査タスク

```
# GOOD: Task toolで並列起動
Task 1: 「認証フローの実装箇所を調査」
Task 2: 「エラーハンドリングのパターンを調査」
Task 3: 「テストカバレッジを確認」

# BAD: 順番に調査
```

### 3. 複数のagent起動

```
# GOOD
/agent reviewer files="src/auth/*.kt"
/agent security-reviewer files="src/auth/*.kt"
（同時にレビュー）

# BAD
レビュー完了を待ってからセキュリティレビュー
```

### 4. Glob/Grep検索

```
# GOOD
Glob: **/*.kt
Glob: **/*.swift
Grep: "suspend fun"
（同時に検索）
```

## 順次実行すべきケース

依存関係がある場合のみ順次実行：

```
# 依存関係あり → 順次実行
1. ファイル作成 (Write)
2. そのファイルをgit add
3. commit

# 依存関係なし → 並列実行
1. ファイルA作成
2. ファイルB作成
3. ファイルC作成
→ 全部同時に実行可能
```

## Multi-Perspective Analysis

複雑な問題には複数視点でのサブエージェント分析を行う：

| 視点 | 役割 |
|------|------|
| Factual Reviewer | 事実確認、仕様との整合性 |
| Senior Engineer | アーキテクチャ、設計判断 |
| Security Expert | 脆弱性、セキュリティリスク |
| Consistency Reviewer | 既存コードとの一貫性 |
| Redundancy Checker | 重複コード、不要な処理 |

```
# 複雑なPRレビュー時
Task 1 (Explore): 変更の影響範囲を調査
Task 2 (Plan): アーキテクチャ観点でレビュー
Task 3 (Bash): テスト実行
→ 全て並列実行
```

## dotclaude agentとの関連

agentカテゴリ別の並列実行可否：

| カテゴリ | 並列実行 | 理由 |
|----------|----------|------|
| analysis/* | ✅ 可能 | 読み取り専用、副作用なし |
| task/reviewer | ✅ 可能 | 読み取り専用 |
| task/doc-reviewer | ✅ 可能 | 読み取り専用 |
| workflow/* | ⚠️ 注意 | state.json更新の競合に注意 |
| task/doc-fixer | ❌ 順次 | ファイル編集の競合回避 |

## 実践例

### ワークフロー開始時

```
/wf2-kickoff 実行時:

並列:
- Issue情報取得 (gh issue view)
- 関連コード調査 (research agent)
- 依存関係確認 (dependency agent)

順次:
- 上記完了後 → 00_KICKOFF.md作成
```

### コードレビュー時

```
並列:
- reviewer agent: コード品質
- security-reviewer agent: セキュリティ
- impact agent: 影響範囲

順次:
- 上記完了後 → 03_REVIEW.md作成
```

## 注意事項

- 並列実行はトークン消費が増える可能性がある
- 同一ファイルへの書き込みは必ず順次実行
- state.json/memory.jsonの更新は競合に注意
