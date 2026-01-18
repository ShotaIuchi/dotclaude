---
name: AWS SAM
description: AWS SAMを使用したサーバーレスアプリケーションの開発、Lambda関数の実装、テンプレート設計、ローカルテスト、デプロイメント時に参照するスキル。
references:
  - path: ../../references/aws/sam-template.md
external:
  - id: aws-sam-docs
  - id: aws-lambda-docs
  - id: aws-api-gateway
  - id: lambda-powertools-python
---

# AWS SAM (Serverless Application Model)

AWS SAM は、サーバーレスアプリケーションを構築するための IaC フレームワーク。

## 基本原則

1. **Infrastructure as Code (IaC)** - すべてのリソースを template.yaml で管理
2. **単一責任の関数設計** - 各 Lambda は一つの機能に集中
3. **最小権限の原則** - IAM ポリシーは必要最小限に
4. **ローカルファースト開発** - sam local でテストしてからデプロイ

## アーキテクチャ

```
┌─────────────────────────────────────────────────────────────┐
│                       API Gateway                            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Lambda Functions                         │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐        │
│  │  Function A  │ │  Function B  │ │  Function C  │        │
│  └──────────────┘ └──────────────┘ └──────────────┘        │
└─────────────────────────────────────────────────────────────┘
                              │
           ┌──────────────────┼──────────────────┐
           ▼                  ▼                  ▼
    ┌────────────┐    ┌────────────┐    ┌────────────┐
    │  DynamoDB  │    │     S3     │    │    SQS     │
    └────────────┘    └────────────┘    └────────────┘
```

## SAM CLI コマンド

| コマンド | 用途 |
|---------|------|
| `sam init` | 新規プロジェクト作成 |
| `sam build` | ビルド（依存関係解決） |
| `sam deploy --guided` | 初回デプロイ（対話式） |
| `sam local invoke` | ローカルで関数を実行 |
| `sam local start-api` | ローカル API サーバー起動 |
| `sam sync --watch` | 変更を自動同期（開発時） |
| `sam logs -t` | CloudWatch ログをテール |

## ディレクトリ構造

```
project/
├── template.yaml           # SAMテンプレート
├── samconfig.toml          # デプロイ設定
├── functions/
│   ├── function_a/
│   │   ├── app.py          # ハンドラー
│   │   └── requirements.txt
│   └── function_b/
│       ├── index.js
│       └── package.json
├── layers/
│   └── shared/
│       └── python/
├── events/                 # テスト用イベント
│   └── event.json
└── tests/
    └── unit/
```

## 詳細リファレンス

- [AWS SAM テンプレートとベストプラクティス](../../references/aws/sam-template.md)
