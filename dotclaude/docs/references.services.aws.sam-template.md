# AWS SAM テンプレートガイド

## 概要

AWS SAM (Serverless Application Model) はサーバーレスアプリケーション構築のための IaC フレームワーク。
CloudFormation を拡張し、Lambda、API Gateway、DynamoDB などのリソースを簡潔に定義。

---

## 基本原則

1. **Infrastructure as Code (IaC)** - 全リソースを template.yaml で管理
2. **単一責任の関数設計** - 各 Lambda は 1 つの機能に集中
3. **最小権限の原則** - IAM ポリシーは必要最小限
4. **Local-First 開発** - デプロイ前に `sam local` でテスト

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
│   ├── function_a/
│   │   ├── app.py          # ハンドラ
│   │   └── requirements.txt
│   └── function_b/
│       ├── index.js
│       └── package.json
├── layers/
│   └── shared/
│       └── python/
├── events/                 # テストイベント
│   └── event.json
└── tests/
    └── unit/
```

---

## テンプレート基本構造

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31
Description: SAM Application

Globals:
  Function:
    Timeout: 30
    Runtime: python3.12
    Architectures:
      - arm64

Resources:
  MyFunction:
    Type: AWS::Serverless::Function
    Properties:
      Handler: app.lambda_handler
      CodeUri: functions/my_function/
      Events:
        ApiEvent:
          Type: Api
          Properties:
            Path: /resource
            Method: get
```

---

## Lambda 関数パターン

### API Gateway 統合

```yaml
GetUsersFunction:
  Type: AWS::Serverless::Function
  Properties:
    Handler: app.get_users_handler
    CodeUri: functions/users/
    Events:
      GetUsers:
        Type: Api
        Properties:
          Path: /users
          Method: get
```

### DynamoDB 統合

```yaml
UsersTable:
  Type: AWS::DynamoDB::Table
  Properties:
    TableName: !Sub "${AWS::StackName}-users"
    BillingMode: PAY_PER_REQUEST
    AttributeDefinitions:
      - AttributeName: pk
        AttributeType: S
    KeySchema:
      - AttributeName: pk
        KeyType: HASH
```

---

## 使用例

### ローカル開発

```bash
# 新規プロジェクト作成
sam init --runtime python3.12 --app-template hello-world

# ビルドとローカルテスト
sam build
sam local invoke MyFunction -e events/event.json

# ローカル API サーバー
sam local start-api
curl http://localhost:3000/users
```

### デプロイ

```bash
# 初回デプロイ（対話式）
sam deploy --guided

# 以降のデプロイ
sam deploy

# 開発時の自動同期
sam sync --watch
```

---

## 詳細リファレンス

- [AWS SAM Documentation](https://docs.aws.amazon.com/serverless-application-model/)
- [Lambda Powertools](https://docs.powertools.aws.dev/lambda/python/)
