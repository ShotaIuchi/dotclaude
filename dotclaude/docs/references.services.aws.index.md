# AWS リファレンス

## 概要

AWS 公式ドキュメントに基づいたサーバーレスアプリケーション開発のリファレンス。
AWS SAM、Lambda、API Gateway、DynamoDB を中心とした設計パターンを定義。

### 対象読者

- **主な対象**: AWS 基礎知識を持つサーバーレスアプリケーション構築者
- **前提条件**: AWS コンソール操作、クラウド基本概念、プログラミング言語（Python、Node.js等）経験

### クイックスタート

1. [AWS SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html) をインストール
2. AWS 認証情報を設定 (`aws configure`)
3. [sam-template.md](sam-template.md) で SAM テンプレートパターンを確認
4. `aws-sam` スキルでガイド付き開発

---

## ファイル一覧と優先度

| ファイル | 説明 | 優先度 |
|----------|------|--------|
| [sam-template.md](sam-template.md) | AWS SAM テンプレートと実装パターン | サーバーレス設計の基盤 |
| lambda-patterns.md | Lambda 関数実装パターン（予定） | コア関数開発 |
| api-gateway-patterns.md | API Gateway 設計と設定（予定） | API 設計 |
| dynamodb-modeling.md | DynamoDB データモデリング（予定） | データ層設計 |

---

## 外部リンク

> 最終確認日: 2026-01-22

### 公式ドキュメント（最優先）

| リンク | 説明 | 優先度 |
|--------|------|--------|
| [AWS SAM Developer Guide](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/what-is-sam.html) | SAM 基礎 | 必読 |
| [AWS Lambda Developer Guide](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html) | Lambda 基礎 | 必読 |

### 関連サービス

| リンク | 説明 |
|--------|------|
| [Amazon API Gateway](https://docs.aws.amazon.com/apigateway/latest/developerguide/welcome.html) | API 設計 |
| [Amazon DynamoDB](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Introduction.html) | NoSQL データベース |
| [AWS CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/Welcome.html) | IaC 基礎 |

### ユーティリティ

| リンク | 説明 |
|--------|------|
| [Lambda Powertools for Python](https://docs.powertools.aws.dev/lambda/python/latest/) | Lambda 開発生産性向上 |

---

## 関連スキル

| スキル | 説明 |
|--------|------|
| `aws-sam` | AWS SAM サーバーレスアプリケーション開発 |
