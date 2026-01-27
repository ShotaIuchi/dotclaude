---
name: subask
description: Ask a question to a sub-agent
argument-hint: "<question> [--detailed] [--explore]"
context: fork
agent: general-purpose
model: haiku
---

# /subask

メインセッションのコンテキストを汚さずに、サブエージェントに質問を投げて回答を得る。

## Purpose

- 本筋の作業中に発生した脱線質問を処理
- メインセッションのトークン消費を抑制
- 作業コンテキストの集中を維持

## Usage

```
/subask <質問内容>
```

## Examples

```bash
# 技術的な質問
/subask Pythonの非同期処理でasyncioとthreadingの使い分けは？

# 概念の確認
/subask RESTとGraphQLの違いを簡潔に

# ベストプラクティス
/subask Goでのエラーハンドリングの一般的なパターン

# カレントディレクトリでの操作
/subask このディレクトリのファイル一覧を教えて
/subask コミットして
```

## Processing

Parse $ARGUMENTS and execute the following:

### 1. Validate Input

```
if $ARGUMENTS is empty:
  Display: "Usage: /subask <質問内容>"
  Exit
```

### 2. Launch Subagent

Use the Task tool with the following parameters:

| Parameter | Value |
|-----------|-------|
| `subagent_type` | `general-purpose` |
| `description` | `Answer question` |
| `prompt` | Always respond in Japanese. 現在のワーキングディレクトリは `$CWD` です。`$ARGUMENTS` に対して簡潔に回答してください。コードベースの探索は不要です。一般的な知識で回答してください。 |
| `model` | `haiku` (低コスト・高速) |

### 3. Return Result

サブエージェントの回答をそのままメインセッションに返す。

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--detailed` | 詳細な回答を求める | off |
| `--explore` | コードベースも参照して回答 | off |

### Option Handling

```
if --detailed in $ARGUMENTS:
  model = "sonnet"
  prompt に「詳細に説明してください」を追加

if --explore in $ARGUMENTS:
  subagent_type = "Explore"
  prompt に「必要に応じてコードベースを参照してください」を追加
```

## Notes

- デフォルトでは haiku モデルを使用（高速・低コスト）
- コードベースの探索が必要な場合は `--explore` オプションを使用
- 回答はメインセッションに返されるが、質問処理自体は独立したコンテキストで実行
- ワーキングディレクトリがプロンプトに含まれるため、ファイル操作やgit操作も可能
