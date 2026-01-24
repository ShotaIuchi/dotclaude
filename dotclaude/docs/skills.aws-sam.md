# AWS SAM スキル

## 概要

AWS SAM によるサーバーレスアプリケーション開発、Lambda 関数実装、テンプレート設計、ローカルテスト、デプロイのためのスキル。

---

## 使用場面

以下の場面で使用：

- AWS SAM サーバーレスアプリケーション開発
- Lambda 関数の実装
- SAM テンプレート設計
- ローカルテスト実行
- サーバーレスアプリケーションのデプロイ

---

## 基本原則

1. **Infrastructure as Code (IaC)** - 全リソースを template.yaml で管理
2. **単一責任の関数設計** - 各 Lambda は 1 つの機能に集中
3. **最小権限の原則** - IAM ポリシーは必要最小限
4. **Local-First 開発** - デプロイ前に `sam local` でテスト

---

## アーキテクチャ

```
┌──────────────────────────────────────────────┐
│                 API Gateway                    │
└──────────────────────────────────────────────┘
                      │
                      v
┌──────────────────────────────────────────────┐
│               Lambda Functions                 │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐│
│  │ Function A │ │ Function B │ │ Function C ││
│  └────────────┘ └────────────┘ └────────────┘│
└──────────────────────────────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        v             v             v
   ┌─────────┐  ┌─────────┐  ┌─────────┐
   │DynamoDB │  │   S3    │  │   SQS   │
   └─────────┘  └─────────┘  └─────────┘
```

---

## SAM CLI コマンド

| コマンド | 目的 |
|----------|------|
| `sam init` | 新規プロジェクト作成 |
| `sam build` | ビルド（依存関係解決） |
| `sam deploy --guided` | 初回デプロイ（対話式） |
| `sam local invoke` | ローカルで関数実行 |
| `sam local start-api` | ローカル API サーバー起動 |
| `sam sync --watch` | 変更自動同期（開発時） |
| `sam logs -t` | CloudWatch ログ監視 |
| `sam delete` | スタックとリソース削除 |

---

## ディレクトリ構成

```
project/
├── template.yaml           # SAM テンプレート
├── samconfig.toml          # デプロイ設定
├── functions/
│   └── function_a/
│       ├── app.py          # ハンドラ
│       └── requirements.txt
├── layers/
│   └── shared/
│       └── python/
├── events/                 # テストイベント
│   └── event.json
└── tests/
    └── unit/
```

---

## 使用例

### ローカル開発

```bash
sam init --runtime python3.12 --app-template hello-world
sam build
sam local invoke MyFunction -e events/event.json
```

### デプロイ

```bash
sam deploy --guided  # 初回
sam deploy           # 以降
sam sync --watch     # 開発時自動同期
```

---

## 詳細リファレンス

- [AWS SAM Templates and Best Practices](../../references/services/aws/sam-template.md)
