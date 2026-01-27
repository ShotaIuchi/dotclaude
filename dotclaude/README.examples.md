# examples/

サンプルファイルディレクトリ。

## 概要

ワークフローで使用する設定ファイルやドキュメントのサンプルを格納。
新規プロジェクトのセットアップ時に参照またはコピーして使用。

## ファイル一覧

| ファイル | 目的 |
|----------|------|
| `config.example.json` | プロジェクト設定のサンプル |
| `local.json` | ローカル設定のサンプル |
| `state.json` | ワークフロー状態のサンプル |
| `memory.json` | セッション記憶のサンプル |
| `01_KICKOFF.md` | キックオフドキュメントのサンプル |
| `02_SPEC.md` | 仕様書のサンプル |
| `03_PLAN.md` | 実装計画のサンプル |
| `04_REVIEW.md` | レビュー記録のサンプル |
| `05_IMPLEMENT_LOG.md` | 実装ログのサンプル |
| `06_REVISIONS.md` | 修正記録のサンプル |
| `DOC_REVIEW.md` | ドキュメントレビューのサンプル |
| `rules/` | プロジェクト固有ルールのサンプル |

## 使用方法

```bash
# プロジェクトへコピー
cp examples/config.example.json .wf/config.json

# 内容を確認
cat examples/state.json
```

## 関連

- テンプレート: [`templates/`](templates/)
- 設定スキーマ: 各ファイル内のコメント参照
