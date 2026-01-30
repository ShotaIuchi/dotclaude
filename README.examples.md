# examples/

サンプルファイルディレクトリ。

## 概要

ワークフローで使用する設定ファイルのサンプルを格納。
新規プロジェクトのセットアップ時に参照またはコピーして使用。

## ファイル一覧

| ファイル | 目的 |
|----------|------|
| `config.json` | プロジェクト設定のサンプル |
| `local.json` | ローカル設定のサンプル |
| `state.json` | ワークフロー状態のサンプル |

## 使用方法

```bash
# プロジェクトへコピー
cp examples/config.json .wf/config.json

# 内容を確認
cat examples/state.json
```

## 関連

- テンプレート: [`templates/`](dotclaude/templates/)
- 設定スキーマ: 各ファイル内のコメント参照
