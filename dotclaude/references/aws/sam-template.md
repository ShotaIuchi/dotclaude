# AWS SAM Architecture Guide

AWS SAM（Serverless Application Model）を使用したサーバーレスアプリケーション開発のベストプラクティス集。

---

## 目次

1. [AWS SAM 概要](#aws-sam-概要)
2. [SAM CLI コマンドリファレンス](#sam-cli-コマンドリファレンス)
3. [SAM テンプレート構造](#sam-テンプレート構造)
4. [リソースタイプ](#リソースタイプ)
5. [Lambda 関数の設計](#lambda-関数の設計)
6. [API Gateway 統合](#api-gateway-統合)
7. [イベントソース設計](#イベントソース設計)
8. [Lambda Layers](#lambda-layers)
9. [環境変数と設定管理](#環境変数と設定管理)
10. [IAM とセキュリティ](#iam-とセキュリティ)
11. [ローカル開発とテスト](#ローカル開発とテスト)
12. [CI/CD パイプライン](#cicd-パイプライン)
13. [ディレクトリ構造](#ディレクトリ構造)
14. [ベストプラクティス一覧](#ベストプラクティス一覧)

---

## AWS SAM 概要

### SAM とは

AWS SAM は、サーバーレスアプリケーションを構築・デプロイするためのオープンソースフレームワーク。
CloudFormation の拡張であり、Lambda、API Gateway、DynamoDB などのリソースを簡潔に定義できる。

### 主な特徴

1. **簡潔なテンプレート記法** - CloudFormation より短い記述でリソース定義
2. **ローカル開発環境** - Docker を使用してローカルでテスト可能
3. **ビルトインベストプラクティス** - セキュリティ設定やロギングが標準で組み込み
4. **CI/CD 統合** - GitHub Actions、CodePipeline との連携が容易

### SAM vs CloudFormation

| 項目 | SAM | CloudFormation |
|------|-----|----------------|
| 記述量 | 少ない | 多い |
| サーバーレス特化 | ○ | × |
| ローカルテスト | ○ | × |
| Transform | 必須 | 不要 |
| リソースタイプ | AWS::Serverless::* | AWS::* |

---

## SAM CLI コマンドリファレンス

### プロジェクト初期化

```bash
# 対話式でプロジェクト作成
sam init

# テンプレート指定で作成
sam init --runtime python3.12 --name my-app --app-template hello-world

# カスタムテンプレートから作成
sam init --location https://github.com/example/sam-template
```

### ビルド

```bash
# 標準ビルド
sam build

# コンテナ内でビルド（ネイティブ依存関係がある場合）
sam build --use-container

# 特定の関数のみビルド
sam build MyFunction

# 並列ビルド
sam build --parallel

# キャッシュを使用したビルド
sam build --cached
```

### デプロイ

```bash
# 対話式デプロイ（初回推奨）
sam deploy --guided

# 設定ファイルを使用したデプロイ
sam deploy

# スタック名とリージョン指定
sam deploy --stack-name my-stack --region ap-northeast-1

# パラメータ上書き
sam deploy --parameter-overrides Environment=prod ApiKey=xxx

# 変更セットの確認をスキップ
sam deploy --no-confirm-changeset

# IAM 権限の自動承認
sam deploy --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM
```

### ローカル実行

```bash
# 関数をローカルで実行
sam local invoke MyFunction

# イベントファイルを指定して実行
sam local invoke MyFunction -e events/event.json

# 環境変数ファイルを指定
sam local invoke MyFunction --env-vars env.json

# ローカル API サーバー起動
sam local start-api

# ポート指定
sam local start-api --port 3000

# ホット リロード有効
sam local start-api --warm-containers EAGER

# Lambda エンドポイント起動（API Gateway なし）
sam local start-lambda
```

### 同期（開発時）

```bash
# 変更を AWS に自動同期
sam sync --watch

# コードのみ同期（インフラ変更なし）
sam sync --watch --code

# スタック指定
sam sync --watch --stack-name my-stack
```

### ログ確認

```bash
# ログをテール
sam logs -n MyFunction --tail

# 時間範囲指定
sam logs -n MyFunction --start-time '5min ago'

# フィルター
sam logs -n MyFunction --filter "ERROR"

# CloudWatch Insights クエリ
sam logs --cw-log-group /aws/lambda/my-function
```

### パイプライン

```bash
# パイプライン設定の初期化
sam pipeline init

# パイプライン用ブートストラップ
sam pipeline bootstrap

# GitHub Actions 用設定
sam pipeline init --bootstrap
```

### その他

```bash
# テンプレート検証
sam validate

# リソース一覧
sam list resources --stack-name my-stack

# エンドポイント一覧
sam list endpoints --stack-name my-stack

# スタック削除
sam delete --stack-name my-stack
```

---

## SAM テンプレート構造

### 基本構造

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31
Description: サンプルサーバーレスアプリケーション

# グローバル設定（全関数に適用）
Globals:
  Function:
    Timeout: 30
    MemorySize: 256
    Runtime: python3.12
    Architectures:
      - arm64
    Environment:
      Variables:
        LOG_LEVEL: INFO

# パラメータ
Parameters:
  Environment:
    Type: String
    Default: dev
    AllowedValues:
      - dev
      - stg
      - prod

# 条件
Conditions:
  IsProd: !Equals [!Ref Environment, prod]

# リソース定義
Resources:
  # Lambda 関数
  MyFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: functions/my_function/
      Handler: app.lambda_handler
      Events:
        ApiEvent:
          Type: Api
          Properties:
            Path: /hello
            Method: get

# 出力
Outputs:
  ApiEndpoint:
    Description: API Gateway エンドポイント URL
    Value: !Sub "https://${ServerlessRestApi}.execute-api.${AWS::Region}.amazonaws.com/Prod/"
```

### Globals セクション

```yaml
Globals:
  Function:
    # ランタイム設定
    Runtime: python3.12
    Architectures:
      - arm64
    Timeout: 30
    MemorySize: 256

    # ログ設定
    LoggingConfig:
      LogFormat: JSON
      ApplicationLogLevel: INFO
      SystemLogLevel: WARN

    # トレーシング
    Tracing: Active

    # VPC 設定
    VpcConfig:
      SecurityGroupIds:
        - !Ref LambdaSecurityGroup
      SubnetIds:
        - !Ref PrivateSubnet1
        - !Ref PrivateSubnet2

    # 環境変数
    Environment:
      Variables:
        POWERTOOLS_SERVICE_NAME: my-service
        LOG_LEVEL: INFO

  Api:
    # CORS 設定
    Cors:
      AllowMethods: "'GET,POST,PUT,DELETE,OPTIONS'"
      AllowHeaders: "'Content-Type,Authorization'"
      AllowOrigin: "'*'"

    # ステージ設定
    OpenApiVersion: 3.0.1

    # 認証設定
    Auth:
      DefaultAuthorizer: MyCognitoAuthorizer
```

### Parameters セクション

```yaml
Parameters:
  Environment:
    Type: String
    Default: dev
    AllowedValues:
      - dev
      - stg
      - prod
    Description: デプロイ環境

  LogLevel:
    Type: String
    Default: INFO
    AllowedValues:
      - DEBUG
      - INFO
      - WARNING
      - ERROR

  DatabaseTableName:
    Type: String
    Default: MyTable
    MinLength: 3
    MaxLength: 255

  ApiKey:
    Type: String
    NoEcho: true
    Description: 外部 API キー（機密情報）
```

### Conditions セクション

```yaml
Conditions:
  IsProd: !Equals [!Ref Environment, prod]
  IsNotProd: !Not [!Equals [!Ref Environment, prod]]
  EnableTracing: !Or
    - !Equals [!Ref Environment, prod]
    - !Equals [!Ref Environment, stg]
```

### Mappings セクション

```yaml
Mappings:
  EnvironmentConfig:
    dev:
      MemorySize: 256
      Timeout: 30
      LogLevel: DEBUG
    stg:
      MemorySize: 512
      Timeout: 30
      LogLevel: INFO
    prod:
      MemorySize: 1024
      Timeout: 60
      LogLevel: WARNING
```

---

## リソースタイプ

### AWS::Serverless::Function

```yaml
MyFunction:
  Type: AWS::Serverless::Function
  Properties:
    # 基本設定
    FunctionName: !Sub "${AWS::StackName}-my-function"
    Description: サンプル Lambda 関数
    CodeUri: functions/my_function/
    Handler: app.lambda_handler
    Runtime: python3.12
    Architectures:
      - arm64

    # リソース設定
    MemorySize: 256
    Timeout: 30
    ReservedConcurrentExecutions: 100

    # 環境変数
    Environment:
      Variables:
        TABLE_NAME: !Ref MyTable
        BUCKET_NAME: !Ref MyBucket

    # IAM ロール（自動生成または指定）
    Role: !GetAtt MyFunctionRole.Arn
    # または SAM ポリシーテンプレート
    Policies:
      - DynamoDBCrudPolicy:
          TableName: !Ref MyTable
      - S3ReadPolicy:
          BucketName: !Ref MyBucket

    # イベントソース
    Events:
      ApiEvent:
        Type: Api
        Properties:
          Path: /items
          Method: get
      ScheduleEvent:
        Type: Schedule
        Properties:
          Schedule: rate(1 hour)

    # レイヤー
    Layers:
      - !Ref SharedLayer
      - arn:aws:lambda:ap-northeast-1:123456789012:layer:my-layer:1

    # デッドレターキュー
    DeadLetterQueue:
      Type: SQS
      TargetArn: !GetAtt DeadLetterQueue.Arn

    # VPC 設定
    VpcConfig:
      SecurityGroupIds:
        - !Ref LambdaSecurityGroup
      SubnetIds:
        - !Ref PrivateSubnet1
        - !Ref PrivateSubnet2

    # トレーシング
    Tracing: Active

    # ログ設定
    LoggingConfig:
      LogFormat: JSON
      LogGroup: !Ref MyFunctionLogGroup
      ApplicationLogLevel: INFO
      SystemLogLevel: WARN

    # Ephemeral Storage
    EphemeralStorage:
      Size: 1024

    # SnapStart（Java のみ）
    SnapStart:
      ApplyOn: PublishedVersions

  # Metadata（ビルド設定）
  Metadata:
    BuildMethod: python3.12
    BuildProperties:
      Format: zip
```

### AWS::Serverless::Api

```yaml
MyApi:
  Type: AWS::Serverless::Api
  Properties:
    Name: !Sub "${AWS::StackName}-api"
    StageName: !Ref Environment
    Description: REST API

    # OpenAPI 定義
    DefinitionBody:
      openapi: "3.0.1"
      info:
        title: My API
        version: "1.0"
      paths:
        /items:
          get:
            x-amazon-apigateway-integration:
              uri: !Sub "arn:aws:apigateway:${AWS::Region}:lambda:path/2015-03-31/functions/${GetItemsFunction.Arn}/invocations"
              httpMethod: POST
              type: aws_proxy

    # CORS
    Cors:
      AllowMethods: "'GET,POST,PUT,DELETE,OPTIONS'"
      AllowHeaders: "'Content-Type,Authorization,X-Amz-Date,X-Api-Key'"
      AllowOrigin: "'*'"
      MaxAge: "'600'"

    # 認証
    Auth:
      DefaultAuthorizer: CognitoAuthorizer
      Authorizers:
        CognitoAuthorizer:
          UserPoolArn: !GetAtt UserPool.Arn

    # アクセスログ
    AccessLogSetting:
      DestinationArn: !GetAtt ApiAccessLogGroup.Arn
      Format: '{"requestId":"$context.requestId","ip":"$context.identity.sourceIp","requestTime":"$context.requestTime","httpMethod":"$context.httpMethod","path":"$context.path","status":"$context.status","responseLength":"$context.responseLength"}'

    # スロットリング
    MethodSettings:
      - ResourcePath: "/*"
        HttpMethod: "*"
        ThrottlingBurstLimit: 100
        ThrottlingRateLimit: 50

    # キャッシュ
    CacheClusterEnabled: true
    CacheClusterSize: "0.5"

    # カスタムドメイン
    Domain:
      DomainName: api.example.com
      CertificateArn: !Ref Certificate
      EndpointConfiguration: REGIONAL
      Route53:
        HostedZoneId: Z1234567890
```

### AWS::Serverless::HttpApi

```yaml
MyHttpApi:
  Type: AWS::Serverless::HttpApi
  Properties:
    StageName: !Ref Environment
    Description: HTTP API（REST API より低コスト）

    # CORS
    CorsConfiguration:
      AllowOrigins:
        - "https://example.com"
      AllowMethods:
        - GET
        - POST
        - PUT
        - DELETE
      AllowHeaders:
        - Content-Type
        - Authorization
      MaxAge: 600

    # 認証
    Auth:
      DefaultAuthorizer: OAuth2Authorizer
      Authorizers:
        OAuth2Authorizer:
          AuthorizationScopes:
            - read
            - write
          IdentitySource: $request.header.Authorization
          JwtConfiguration:
            issuer: !Sub "https://cognito-idp.${AWS::Region}.amazonaws.com/${UserPool}"
            audience:
              - !Ref UserPoolClient

    # アクセスログ
    AccessLogSettings:
      DestinationArn: !GetAtt HttpApiAccessLogGroup.Arn
      Format: '{"requestId":"$context.requestId","ip":"$context.identity.sourceIp","requestTime":"$context.requestTime","httpMethod":"$context.httpMethod","path":"$context.path","status":"$context.status"}'

    # ルート設定
    RouteSettings:
      "GET /items":
        ThrottlingBurstLimit: 100
        ThrottlingRateLimit: 50
```

### AWS::Serverless::SimpleTable

```yaml
MyTable:
  Type: AWS::Serverless::SimpleTable
  Properties:
    TableName: !Sub "${AWS::StackName}-items"
    PrimaryKey:
      Name: id
      Type: String
    ProvisionedThroughput:
      ReadCapacityUnits: 5
      WriteCapacityUnits: 5
    # または オンデマンド
    # BillingMode: PAY_PER_REQUEST
    SSESpecification:
      SSEEnabled: true
    Tags:
      Environment: !Ref Environment
```

### AWS::Serverless::LayerVersion

```yaml
SharedLayer:
  Type: AWS::Serverless::LayerVersion
  Properties:
    LayerName: !Sub "${AWS::StackName}-shared-layer"
    Description: 共有ライブラリレイヤー
    ContentUri: layers/shared/
    CompatibleRuntimes:
      - python3.11
      - python3.12
    CompatibleArchitectures:
      - arm64
      - x86_64
    LicenseInfo: MIT
    RetentionPolicy: Retain
  Metadata:
    BuildMethod: python3.12
    BuildArchitecture: arm64
```

### AWS::Serverless::Application（ネストスタック）

```yaml
PaymentService:
  Type: AWS::Serverless::Application
  Properties:
    Location:
      ApplicationId: arn:aws:serverlessrepo:us-east-1:123456789012:applications/payment-service
      SemanticVersion: 1.0.0
    Parameters:
      Environment: !Ref Environment
      TableName: !Ref PaymentTable
```

### AWS::Serverless::Connector

```yaml
# Lambda から DynamoDB への接続
FunctionToTableConnector:
  Type: AWS::Serverless::Connector
  Properties:
    Source:
      Id: MyFunction
    Destination:
      Id: MyTable
    Permissions:
      - Read
      - Write

# Lambda から S3 への接続
FunctionToBucketConnector:
  Type: AWS::Serverless::Connector
  Properties:
    Source:
      Id: MyFunction
    Destination:
      Id: MyBucket
    Permissions:
      - Read

# Lambda から SQS への接続
FunctionToQueueConnector:
  Type: AWS::Serverless::Connector
  Properties:
    Source:
      Id: MyFunction
    Destination:
      Id: MyQueue
    Permissions:
      - Write
```

---

## Lambda 関数の設計

### Python ハンドラー実装

```python
"""
Lambda 関数ハンドラー

アイテム取得 API のエントリーポイント
"""
import json
import logging
import os
from typing import Any

import boto3
from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.event_handler import APIGatewayRestResolver
from aws_lambda_powertools.logging import correlation_paths
from aws_lambda_powertools.utilities.typing import LambdaContext

# ロガーとトレーサーの初期化
logger = Logger()
tracer = Tracer()
app = APIGatewayRestResolver()

# DynamoDB クライアント
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])


@app.get("/items")
@tracer.capture_method
def get_items() -> dict[str, Any]:
    """
    アイテム一覧を取得する
    """
    logger.info("アイテム一覧取得開始")

    try:
        response = table.scan()
        items = response.get("Items", [])
        logger.info(f"取得件数: {len(items)}")
        return {"items": items}
    except Exception as e:
        logger.exception("アイテム取得エラー")
        raise


@app.get("/items/<item_id>")
@tracer.capture_method
def get_item(item_id: str) -> dict[str, Any]:
    """
    指定されたアイテムを取得する
    """
    logger.info(f"アイテム取得: {item_id}")

    response = table.get_item(Key={"id": item_id})
    item = response.get("Item")

    if not item:
        logger.warning(f"アイテムが見つかりません: {item_id}")
        return {"statusCode": 404, "body": json.dumps({"error": "Item not found"})}

    return item


@app.post("/items")
@tracer.capture_method
def create_item() -> dict[str, Any]:
    """
    新しいアイテムを作成する
    """
    import uuid

    body = app.current_event.json_body
    logger.info(f"アイテム作成: {body}")

    item = {
        "id": str(uuid.uuid4()),
        "name": body.get("name"),
        "description": body.get("description"),
    }

    table.put_item(Item=item)
    logger.info(f"アイテム作成完了: {item['id']}")

    return {"statusCode": 201, "body": json.dumps(item)}


@logger.inject_lambda_context(correlation_id_path=correlation_paths.API_GATEWAY_REST)
@tracer.capture_lambda_handler
def lambda_handler(event: dict[str, Any], context: LambdaContext) -> dict[str, Any]:
    """
    Lambda エントリーポイント
    """
    return app.resolve(event, context)
```

### Node.js ハンドラー実装

```javascript
/**
 * Lambda 関数ハンドラー
 *
 * アイテム取得 API のエントリーポイント
 */
const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  ScanCommand,
  GetCommand,
  PutCommand,
} = require("@aws-sdk/lib-dynamodb");
const { v4: uuidv4 } = require("uuid");

// DynamoDB クライアント
const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);
const TABLE_NAME = process.env.TABLE_NAME;

/**
 * アイテム一覧を取得する
 */
async function getItems() {
  console.log("アイテム一覧取得開始");

  const command = new ScanCommand({ TableName: TABLE_NAME });
  const response = await docClient.send(command);

  console.log(`取得件数: ${response.Items?.length || 0}`);
  return {
    statusCode: 200,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ items: response.Items || [] }),
  };
}

/**
 * 指定されたアイテムを取得する
 */
async function getItem(itemId) {
  console.log(`アイテム取得: ${itemId}`);

  const command = new GetCommand({
    TableName: TABLE_NAME,
    Key: { id: itemId },
  });
  const response = await docClient.send(command);

  if (!response.Item) {
    console.warn(`アイテムが見つかりません: ${itemId}`);
    return {
      statusCode: 404,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ error: "Item not found" }),
    };
  }

  return {
    statusCode: 200,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(response.Item),
  };
}

/**
 * 新しいアイテムを作成する
 */
async function createItem(body) {
  const data = JSON.parse(body);
  console.log("アイテム作成:", data);

  const item = {
    id: uuidv4(),
    name: data.name,
    description: data.description,
    createdAt: new Date().toISOString(),
  };

  const command = new PutCommand({
    TableName: TABLE_NAME,
    Item: item,
  });
  await docClient.send(command);

  console.log(`アイテム作成完了: ${item.id}`);
  return {
    statusCode: 201,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(item),
  };
}

/**
 * Lambda エントリーポイント
 */
exports.handler = async (event, context) => {
  console.log("Event:", JSON.stringify(event, null, 2));

  try {
    const { httpMethod, path, pathParameters, body } = event;

    // ルーティング
    if (path === "/items" && httpMethod === "GET") {
      return await getItems();
    }

    if (path.startsWith("/items/") && httpMethod === "GET") {
      const itemId = pathParameters?.id;
      return await getItem(itemId);
    }

    if (path === "/items" && httpMethod === "POST") {
      return await createItem(body);
    }

    return {
      statusCode: 404,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ error: "Not Found" }),
    };
  } catch (error) {
    console.error("Error:", error);
    return {
      statusCode: 500,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ error: "Internal Server Error" }),
    };
  }
};
```

### エラーハンドリングパターン

```python
"""
エラーハンドリングユーティリティ
"""
import json
from functools import wraps
from typing import Any, Callable

from aws_lambda_powertools import Logger

logger = Logger()


class AppError(Exception):
    """
    アプリケーションエラー基底クラス
    """

    def __init__(self, message: str, status_code: int = 500, error_code: str = "INTERNAL_ERROR"):
        self.message = message
        self.status_code = status_code
        self.error_code = error_code
        super().__init__(self.message)


class NotFoundError(AppError):
    """リソースが見つからないエラー"""

    def __init__(self, resource: str, resource_id: str):
        super().__init__(
            message=f"{resource} not found: {resource_id}",
            status_code=404,
            error_code="NOT_FOUND",
        )


class ValidationError(AppError):
    """バリデーションエラー"""

    def __init__(self, message: str):
        super().__init__(
            message=message,
            status_code=400,
            error_code="VALIDATION_ERROR",
        )


class UnauthorizedError(AppError):
    """認証エラー"""

    def __init__(self, message: str = "Unauthorized"):
        super().__init__(
            message=message,
            status_code=401,
            error_code="UNAUTHORIZED",
        )


def error_handler(func: Callable) -> Callable:
    """
    エラーハンドリングデコレータ
    """

    @wraps(func)
    def wrapper(*args, **kwargs) -> dict[str, Any]:
        try:
            return func(*args, **kwargs)
        except AppError as e:
            logger.warning(f"AppError: {e.error_code} - {e.message}")
            return {
                "statusCode": e.status_code,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps(
                    {
                        "error": {
                            "code": e.error_code,
                            "message": e.message,
                        }
                    }
                ),
            }
        except Exception as e:
            logger.exception("Unexpected error")
            return {
                "statusCode": 500,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps(
                    {
                        "error": {
                            "code": "INTERNAL_ERROR",
                            "message": "Internal server error",
                        }
                    }
                ),
            }

    return wrapper
```

### 入力バリデーション

```python
"""
入力バリデーションユーティリティ
"""
from typing import Any

from pydantic import BaseModel, Field, ValidationError as PydanticValidationError


class CreateItemRequest(BaseModel):
    """アイテム作成リクエスト"""

    name: str = Field(..., min_length=1, max_length=100)
    description: str | None = Field(None, max_length=500)
    price: int = Field(..., ge=0)
    category: str = Field(..., pattern=r"^[a-z_]+$")


class UpdateItemRequest(BaseModel):
    """アイテム更新リクエスト"""

    name: str | None = Field(None, min_length=1, max_length=100)
    description: str | None = Field(None, max_length=500)
    price: int | None = Field(None, ge=0)


def validate_request(model: type[BaseModel], data: dict[str, Any]) -> BaseModel:
    """
    リクエストデータをバリデーションする
    """
    try:
        return model(**data)
    except PydanticValidationError as e:
        errors = []
        for error in e.errors():
            field = ".".join(str(loc) for loc in error["loc"])
            errors.append(f"{field}: {error['msg']}")
        raise ValidationError("; ".join(errors))
```

---

## API Gateway 統合

### REST API イベント

```yaml
Resources:
  GetItemsFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: functions/items/
      Handler: app.get_items_handler
      Events:
        GetItems:
          Type: Api
          Properties:
            Path: /items
            Method: GET
            RestApiId: !Ref MyApi

        GetItem:
          Type: Api
          Properties:
            Path: /items/{id}
            Method: GET
            RestApiId: !Ref MyApi
            RequestParameters:
              - method.request.path.id:
                  Required: true

        CreateItem:
          Type: Api
          Properties:
            Path: /items
            Method: POST
            RestApiId: !Ref MyApi
            RequestModel:
              Model: CreateItemModel
              Required: true
```

### HTTP API イベント

```yaml
Resources:
  GetItemsFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: functions/items/
      Handler: app.handler
      Events:
        GetItems:
          Type: HttpApi
          Properties:
            Path: /items
            Method: GET
            ApiId: !Ref MyHttpApi

        GetItem:
          Type: HttpApi
          Properties:
            Path: /items/{id}
            Method: GET
            ApiId: !Ref MyHttpApi
```

### Lambda 関数 URL

```yaml
Resources:
  MyFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: functions/my_function/
      Handler: app.handler
      FunctionUrlConfig:
        AuthType: NONE
        # または IAM 認証
        # AuthType: AWS_IAM
        Cors:
          AllowOrigins:
            - "https://example.com"
          AllowMethods:
            - GET
            - POST
          AllowHeaders:
            - Content-Type
```

### API Gateway 認証

```yaml
Resources:
  MyApi:
    Type: AWS::Serverless::Api
    Properties:
      StageName: !Ref Environment
      Auth:
        DefaultAuthorizer: CognitoAuthorizer
        Authorizers:
          # Cognito 認証
          CognitoAuthorizer:
            UserPoolArn: !GetAtt UserPool.Arn
            Identity:
              Header: Authorization

          # Lambda 認証
          LambdaAuthorizer:
            FunctionArn: !GetAtt AuthorizerFunction.Arn
            Identity:
              Header: Authorization
              ReauthorizeEvery: 300

  # 認証なしエンドポイント
  PublicFunction:
    Type: AWS::Serverless::Function
    Properties:
      Events:
        PublicApi:
          Type: Api
          Properties:
            RestApiId: !Ref MyApi
            Path: /public
            Method: GET
            Auth:
              Authorizer: NONE
```

### カスタム Lambda オーソライザー

```python
"""
Lambda オーソライザー
"""
import json
from typing import Any


def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    """
    トークンベースのオーソライザー
    """
    token = event.get("authorizationToken", "")
    method_arn = event["methodArn"]

    # トークン検証ロジック
    if validate_token(token):
        principal_id = extract_user_id(token)
        return generate_policy(principal_id, "Allow", method_arn)

    return generate_policy("user", "Deny", method_arn)


def validate_token(token: str) -> bool:
    """トークンを検証する"""
    # 実際の検証ロジックを実装
    return token.startswith("Bearer ")


def extract_user_id(token: str) -> str:
    """トークンからユーザー ID を抽出する"""
    # 実際の抽出ロジックを実装
    return "user-123"


def generate_policy(principal_id: str, effect: str, resource: str) -> dict[str, Any]:
    """IAM ポリシードキュメントを生成する"""
    return {
        "principalId": principal_id,
        "policyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Action": "execute-api:Invoke",
                    "Effect": effect,
                    "Resource": resource,
                }
            ],
        },
        "context": {
            "userId": principal_id,
        },
    }
```

---

## イベントソース設計

### SQS イベント

```yaml
Resources:
  ProcessQueueFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: functions/process_queue/
      Handler: app.handler
      Events:
        SQSEvent:
          Type: SQS
          Properties:
            Queue: !GetAtt MyQueue.Arn
            BatchSize: 10
            MaximumBatchingWindowInSeconds: 5
            FunctionResponseTypes:
              - ReportBatchItemFailures
            ScalingConfig:
              MaximumConcurrency: 10

  MyQueue:
    Type: AWS::SQS::Queue
    Properties:
      QueueName: !Sub "${AWS::StackName}-queue"
      VisibilityTimeoutSeconds: 180
      MessageRetentionPeriod: 1209600
      RedrivePolicy:
        deadLetterTargetArn: !GetAtt DeadLetterQueue.Arn
        maxReceiveCount: 3

  DeadLetterQueue:
    Type: AWS::SQS::Queue
    Properties:
      QueueName: !Sub "${AWS::StackName}-dlq"
      MessageRetentionPeriod: 1209600
```

```python
"""
SQS イベントハンドラー
"""
from typing import Any

from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.batch import (
    BatchProcessor,
    EventType,
    process_partial_response,
)
from aws_lambda_powertools.utilities.data_classes.sqs_event import SQSRecord

logger = Logger()
processor = BatchProcessor(event_type=EventType.SQS)


def record_handler(record: SQSRecord) -> None:
    """
    個別レコードを処理する
    """
    payload = record.json_body
    logger.info(f"Processing message: {payload}")

    # ビジネスロジック
    process_message(payload)


def process_message(payload: dict[str, Any]) -> None:
    """メッセージを処理する"""
    # 実際の処理ロジック
    pass


@logger.inject_lambda_context
def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    """
    Lambda エントリーポイント（バッチ処理）
    """
    return process_partial_response(
        event=event,
        record_handler=record_handler,
        processor=processor,
        context=context,
    )
```

### S3 イベント

```yaml
Resources:
  ProcessS3Function:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: functions/process_s3/
      Handler: app.handler
      Policies:
        - S3ReadPolicy:
            BucketName: !Ref UploadBucket
      Events:
        S3Event:
          Type: S3
          Properties:
            Bucket: !Ref UploadBucket
            Events:
              - s3:ObjectCreated:*
            Filter:
              S3Key:
                Rules:
                  - Name: prefix
                    Value: uploads/
                  - Name: suffix
                    Value: .json

  UploadBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub "${AWS::StackName}-uploads"
```

```python
"""
S3 イベントハンドラー
"""
import json
from typing import Any
from urllib.parse import unquote_plus

import boto3
from aws_lambda_powertools import Logger

logger = Logger()
s3 = boto3.client("s3")


@logger.inject_lambda_context
def lambda_handler(event: dict[str, Any], context: Any) -> None:
    """
    S3 イベントを処理する
    """
    for record in event["Records"]:
        bucket = record["s3"]["bucket"]["name"]
        key = unquote_plus(record["s3"]["object"]["key"])

        logger.info(f"Processing: s3://{bucket}/{key}")

        # オブジェクト取得
        response = s3.get_object(Bucket=bucket, Key=key)
        content = json.loads(response["Body"].read().decode("utf-8"))

        # ビジネスロジック
        process_file(content)


def process_file(content: dict[str, Any]) -> None:
    """ファイル内容を処理する"""
    pass
```

### DynamoDB Streams

```yaml
Resources:
  ProcessStreamFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: functions/process_stream/
      Handler: app.handler
      Events:
        DynamoDBEvent:
          Type: DynamoDB
          Properties:
            Stream: !GetAtt MyTable.StreamArn
            StartingPosition: TRIM_HORIZON
            BatchSize: 100
            MaximumBatchingWindowInSeconds: 5
            MaximumRetryAttempts: 3
            ParallelizationFactor: 2
            FunctionResponseTypes:
              - ReportBatchItemFailures
            FilterCriteria:
              Filters:
                - Pattern: '{"eventName": ["INSERT", "MODIFY"]}'

  MyTable:
    Type: AWS::DynamoDB::Table
    Properties:
      TableName: !Sub "${AWS::StackName}-table"
      AttributeDefinitions:
        - AttributeName: id
          AttributeType: S
      KeySchema:
        - AttributeName: id
          KeyType: HASH
      BillingMode: PAY_PER_REQUEST
      StreamSpecification:
        StreamViewType: NEW_AND_OLD_IMAGES
```

### EventBridge スケジュール

```yaml
Resources:
  ScheduledFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: functions/scheduled/
      Handler: app.handler
      Events:
        # cron 式
        DailySchedule:
          Type: Schedule
          Properties:
            Schedule: cron(0 9 * * ? *)
            Description: 毎日 9:00 JST に実行
            Enabled: true
            Input: '{"type": "daily"}'

        # rate 式
        HourlySchedule:
          Type: Schedule
          Properties:
            Schedule: rate(1 hour)
            Description: 1時間ごとに実行

        # EventBridge Scheduler
        SchedulerEvent:
          Type: ScheduleV2
          Properties:
            ScheduleExpression: rate(5 minutes)
            FlexibleTimeWindow:
              Mode: FLEXIBLE
              MaximumWindowInMinutes: 5
```

### EventBridge ルール

```yaml
Resources:
  EventRuleFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: functions/event_rule/
      Handler: app.handler
      Events:
        EventBridgeRule:
          Type: EventBridgeRule
          Properties:
            Pattern:
              source:
                - "my.application"
              detail-type:
                - "OrderCreated"
              detail:
                status:
                  - "CONFIRMED"
            Target:
              Id: MyTarget

        # CloudTrail イベント
        CloudTrailEvent:
          Type: CloudWatchEvent
          Properties:
            Pattern:
              source:
                - "aws.s3"
              detail-type:
                - "AWS API Call via CloudTrail"
              detail:
                eventSource:
                  - "s3.amazonaws.com"
                eventName:
                  - "PutObject"
```

### Kinesis Data Streams

```yaml
Resources:
  ProcessStreamFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: functions/kinesis/
      Handler: app.handler
      Events:
        KinesisEvent:
          Type: Kinesis
          Properties:
            Stream: !GetAtt MyStream.Arn
            StartingPosition: LATEST
            BatchSize: 100
            MaximumBatchingWindowInSeconds: 5
            ParallelizationFactor: 2
            FunctionResponseTypes:
              - ReportBatchItemFailures

  MyStream:
    Type: AWS::Kinesis::Stream
    Properties:
      Name: !Sub "${AWS::StackName}-stream"
      ShardCount: 1
```

---

## Lambda Layers

### レイヤー構造

```
layers/
└── shared/
    └── python/
        └── lib/
            └── python3.12/
                └── site-packages/
                    ├── myutils/
                    │   ├── __init__.py
                    │   ├── db.py
                    │   └── validation.py
                    └── requirements.txt
```

### レイヤー定義

```yaml
Resources:
  SharedLayer:
    Type: AWS::Serverless::LayerVersion
    Properties:
      LayerName: !Sub "${AWS::StackName}-shared"
      Description: 共有ユーティリティレイヤー
      ContentUri: layers/shared/
      CompatibleRuntimes:
        - python3.11
        - python3.12
      CompatibleArchitectures:
        - arm64
        - x86_64
      RetentionPolicy: Retain
    Metadata:
      BuildMethod: python3.12
      BuildArchitecture: arm64

  # 関数からレイヤーを参照
  MyFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: functions/my_function/
      Handler: app.handler
      Layers:
        - !Ref SharedLayer
        # 外部レイヤーも参照可能
        - arn:aws:lambda:ap-northeast-1:017000801446:layer:AWSLambdaPowertoolsPythonV3-python312-arm64:3
```

### レイヤー用 requirements.txt

```
# layers/shared/requirements.txt
boto3>=1.34.0
pydantic>=2.0.0
httpx>=0.27.0
```

### レイヤーのビルド

```bash
# レイヤーをビルド
sam build SharedLayer

# コンテナ内でビルド（ネイティブ依存関係がある場合）
sam build SharedLayer --use-container
```

### Python レイヤーからのインポート

```python
"""
レイヤーからユーティリティをインポートする例
"""
# レイヤーに含まれるモジュールをインポート
from myutils.db import get_connection
from myutils.validation import validate_input
```

---

## 環境変数と設定管理

### 環境変数の定義

```yaml
Globals:
  Function:
    Environment:
      Variables:
        # 共通環境変数
        LOG_LEVEL: !If [IsProd, WARNING, INFO]
        POWERTOOLS_SERVICE_NAME: !Ref AWS::StackName

Resources:
  MyFunction:
    Type: AWS::Serverless::Function
    Properties:
      Environment:
        Variables:
          # 関数固有の環境変数
          TABLE_NAME: !Ref MyTable
          BUCKET_NAME: !Ref MyBucket
          # Secrets Manager 参照
          DB_PASSWORD: "{{resolve:secretsmanager:my-secret:SecretString:password}}"
          # SSM Parameter Store 参照
          API_KEY: "{{resolve:ssm:/my-app/api-key:1}}"
```

### Secrets Manager との統合

```yaml
Resources:
  # シークレットの定義
  DatabaseSecret:
    Type: AWS::SecretsManager::Secret
    Properties:
      Name: !Sub "${AWS::StackName}/database"
      GenerateSecretString:
        SecretStringTemplate: '{"username": "admin"}'
        GenerateStringKey: password
        PasswordLength: 32
        ExcludeCharacters: '"@/\'

  # シークレットを参照する関数
  MyFunction:
    Type: AWS::Serverless::Function
    Properties:
      Environment:
        Variables:
          SECRET_ARN: !Ref DatabaseSecret
      Policies:
        - AWSSecretsManagerGetSecretValuePolicy:
            SecretArn: !Ref DatabaseSecret
```

```python
"""
Secrets Manager からシークレットを取得する
"""
import json
import os

import boto3
from aws_lambda_powertools import Logger

logger = Logger()

# キャッシュ
_secrets_cache = {}


def get_secret(secret_arn: str) -> dict:
    """
    シークレットを取得する（キャッシュ付き）
    """
    if secret_arn in _secrets_cache:
        return _secrets_cache[secret_arn]

    client = boto3.client("secretsmanager")
    response = client.get_secret_value(SecretId=secret_arn)
    secret = json.loads(response["SecretString"])

    _secrets_cache[secret_arn] = secret
    return secret


def lambda_handler(event, context):
    secret_arn = os.environ["SECRET_ARN"]
    secret = get_secret(secret_arn)

    db_password = secret["password"]
    # データベース接続処理
```

### SSM Parameter Store との統合

```yaml
Resources:
  # パラメータの定義
  ApiKeyParameter:
    Type: AWS::SSM::Parameter
    Properties:
      Name: !Sub "/${AWS::StackName}/api-key"
      Type: SecureString
      Value: "{{resolve:secretsmanager:api-keys:SecretString:my-api-key}}"

  MyFunction:
    Type: AWS::Serverless::Function
    Properties:
      Environment:
        Variables:
          PARAMETER_NAME: !Sub "/${AWS::StackName}/api-key"
      Policies:
        - SSMParameterReadPolicy:
            ParameterName: !Sub "${AWS::StackName}/*"
```

### AWS AppConfig との統合

```yaml
Resources:
  MyFunction:
    Type: AWS::Serverless::Function
    Properties:
      Layers:
        - arn:aws:lambda:ap-northeast-1:980059726660:layer:AWS-AppConfig-Extension-Arm64:1
      Environment:
        Variables:
          AWS_APPCONFIG_EXTENSION_POLL_INTERVAL_SECONDS: 45
          AWS_APPCONFIG_EXTENSION_POLL_TIMEOUT_MILLIS: 3000
```

---

## IAM とセキュリティ

### SAM ポリシーテンプレート

```yaml
Resources:
  MyFunction:
    Type: AWS::Serverless::Function
    Properties:
      Policies:
        # DynamoDB
        - DynamoDBCrudPolicy:
            TableName: !Ref MyTable
        - DynamoDBReadPolicy:
            TableName: !Ref ReadOnlyTable

        # S3
        - S3ReadPolicy:
            BucketName: !Ref ReadBucket
        - S3WritePolicy:
            BucketName: !Ref WriteBucket
        - S3CrudPolicy:
            BucketName: !Ref CrudBucket

        # SQS
        - SQSSendMessagePolicy:
            QueueName: !GetAtt MyQueue.QueueName
        - SQSPollerPolicy:
            QueueName: !GetAtt MyQueue.QueueName

        # SNS
        - SNSPublishMessagePolicy:
            TopicArn: !Ref MyTopic

        # Secrets Manager
        - AWSSecretsManagerGetSecretValuePolicy:
            SecretArn: !Ref MySecret

        # SSM Parameter Store
        - SSMParameterReadPolicy:
            ParameterName: !Sub "${AWS::StackName}/*"

        # Step Functions
        - StepFunctionsExecutionPolicy:
            StateMachineName: !GetAtt MyStateMachine.Name

        # Lambda
        - LambdaInvokePolicy:
            FunctionName: !Ref OtherFunction

        # EventBridge
        - EventBridgePutEventsPolicy:
            EventBusName: !Ref MyEventBus

        # Kinesis
        - KinesisStreamReadPolicy:
            StreamName: !Ref MyStream
        - KinesisCrudPolicy:
            StreamName: !Ref MyStream

        # CloudWatch
        - CloudWatchPutMetricPolicy: {}

        # VPC
        - VPCAccessPolicy: {}

        # カスタムポリシー
        - Version: "2012-10-17"
          Statement:
            - Effect: Allow
              Action:
                - cognito-idp:AdminGetUser
              Resource: !GetAtt UserPool.Arn
```

### SAM Connectors

```yaml
Resources:
  # Lambda → DynamoDB
  FunctionToTableConnector:
    Type: AWS::Serverless::Connector
    Properties:
      Source:
        Id: MyFunction
      Destination:
        Id: MyTable
      Permissions:
        - Read
        - Write

  # Lambda → S3（読み取りのみ）
  FunctionToBucketConnector:
    Type: AWS::Serverless::Connector
    Properties:
      Source:
        Id: MyFunction
      Destination:
        Id: MyBucket
      Permissions:
        - Read

  # Lambda → SQS
  FunctionToQueueConnector:
    Type: AWS::Serverless::Connector
    Properties:
      Source:
        Id: MyFunction
      Destination:
        Id: MyQueue
      Permissions:
        - Write

  # API Gateway → Lambda
  ApiToFunctionConnector:
    Type: AWS::Serverless::Connector
    Properties:
      Source:
        Id: MyApi
      Destination:
        Id: MyFunction
      Permissions:
        - Write

  # SNS → Lambda
  TopicToFunctionConnector:
    Type: AWS::Serverless::Connector
    Properties:
      Source:
        Id: MyTopic
      Destination:
        Id: MyFunction
      Permissions:
        - Write
```

### リソースベースポリシー

```yaml
Resources:
  # S3 バケットポリシー
  BucketPolicy:
    Type: AWS::S3::BucketPolicy
    Properties:
      Bucket: !Ref MyBucket
      PolicyDocument:
        Version: "2012-10-17"
        Statement:
          - Effect: Allow
            Principal:
              Service: lambda.amazonaws.com
            Action: s3:GetObject
            Resource: !Sub "${MyBucket.Arn}/*"
            Condition:
              StringEquals:
                aws:SourceAccount: !Ref AWS::AccountId

  # Lambda 実行ロール（カスタム）
  MyFunctionRole:
    Type: AWS::IAM::Role
    Properties:
      RoleName: !Sub "${AWS::StackName}-function-role"
      AssumeRolePolicyDocument:
        Version: "2012-10-17"
        Statement:
          - Effect: Allow
            Principal:
              Service: lambda.amazonaws.com
            Action: sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
      Policies:
        - PolicyName: CustomPolicy
          PolicyDocument:
            Version: "2012-10-17"
            Statement:
              - Effect: Allow
                Action:
                  - dynamodb:GetItem
                  - dynamodb:PutItem
                Resource: !GetAtt MyTable.Arn
```

### セキュリティベストプラクティス

```yaml
Resources:
  # 暗号化された DynamoDB テーブル
  SecureTable:
    Type: AWS::DynamoDB::Table
    Properties:
      SSESpecification:
        SSEEnabled: true
        SSEType: KMS
        KMSMasterKeyId: !Ref TableEncryptionKey

  # 暗号化された S3 バケット
  SecureBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketEncryption:
        ServerSideEncryptionConfiguration:
          - ServerSideEncryptionByDefault:
              SSEAlgorithm: aws:kms
              KMSMasterKeyID: !Ref BucketEncryptionKey
      PublicAccessBlockConfiguration:
        BlockPublicAcls: true
        BlockPublicPolicy: true
        IgnorePublicAcls: true
        RestrictPublicBuckets: true

  # VPC 内の Lambda
  VpcFunction:
    Type: AWS::Serverless::Function
    Properties:
      VpcConfig:
        SecurityGroupIds:
          - !Ref LambdaSecurityGroup
        SubnetIds:
          - !Ref PrivateSubnet1
          - !Ref PrivateSubnet2
      Policies:
        - VPCAccessPolicy: {}

  # セキュリティグループ
  LambdaSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Lambda Security Group
      VpcId: !Ref VPC
      SecurityGroupEgress:
        - IpProtocol: tcp
          FromPort: 443
          ToPort: 443
          CidrIp: 0.0.0.0/0
```

---

## ローカル開発とテスト

### Docker 環境設定

```yaml
# docker-compose.yml
version: "3.8"
services:
  dynamodb-local:
    image: amazon/dynamodb-local:latest
    container_name: dynamodb-local
    ports:
      - "8000:8000"
    command: ["-jar", "DynamoDBLocal.jar", "-sharedDb", "-inMemory"]

  localstack:
    image: localstack/localstack:latest
    container_name: localstack
    ports:
      - "4566:4566"
    environment:
      - SERVICES=s3,sqs,sns,secretsmanager
      - DEBUG=1
      - DATA_DIR=/tmp/localstack/data
    volumes:
      - "./localstack:/tmp/localstack"
```

### sam local invoke

```bash
# 基本実行
sam local invoke MyFunction

# イベントファイルを指定
sam local invoke MyFunction -e events/api-event.json

# 環境変数ファイルを指定
sam local invoke MyFunction --env-vars env.json

# Docker ネットワーク指定（LocalStack 接続用）
sam local invoke MyFunction --docker-network host

# デバッグモード（VS Code 接続用）
sam local invoke MyFunction -d 5858
```

### sam local start-api

```bash
# API サーバー起動
sam local start-api

# ポート指定
sam local start-api --port 3000

# ホットリロード
sam local start-api --warm-containers EAGER

# Docker ネットワーク指定
sam local start-api --docker-network host

# 環境変数ファイル指定
sam local start-api --env-vars env.json
```

### イベントファイル

```json
// events/api-get-event.json
{
  "httpMethod": "GET",
  "path": "/items",
  "queryStringParameters": {
    "limit": "10"
  },
  "headers": {
    "Content-Type": "application/json",
    "Authorization": "Bearer token123"
  },
  "requestContext": {
    "authorizer": {
      "claims": {
        "sub": "user-123"
      }
    }
  }
}
```

```json
// events/api-post-event.json
{
  "httpMethod": "POST",
  "path": "/items",
  "headers": {
    "Content-Type": "application/json"
  },
  "body": "{\"name\": \"Test Item\", \"price\": 100}"
}
```

```json
// events/sqs-event.json
{
  "Records": [
    {
      "messageId": "msg-1",
      "receiptHandle": "handle-1",
      "body": "{\"id\": \"123\", \"action\": \"process\"}",
      "attributes": {
        "ApproximateReceiveCount": "1",
        "SentTimestamp": "1234567890"
      },
      "messageAttributes": {},
      "md5OfBody": "abc123",
      "eventSource": "aws:sqs",
      "eventSourceARN": "arn:aws:sqs:ap-northeast-1:123456789012:my-queue",
      "awsRegion": "ap-northeast-1"
    }
  ]
}
```

```json
// events/s3-event.json
{
  "Records": [
    {
      "eventSource": "aws:s3",
      "eventTime": "2024-01-01T00:00:00.000Z",
      "eventName": "ObjectCreated:Put",
      "s3": {
        "bucket": {
          "name": "my-bucket"
        },
        "object": {
          "key": "uploads/test.json",
          "size": 1024
        }
      }
    }
  ]
}
```

### イベント生成コマンド

```bash
# API Gateway イベント生成
sam local generate-event apigateway aws-proxy \
  --method GET \
  --path /items \
  > events/api-get.json

# S3 イベント生成
sam local generate-event s3 put \
  --bucket my-bucket \
  --key uploads/test.json \
  > events/s3-put.json

# SQS イベント生成
sam local generate-event sqs receive-message \
  --body '{"id": "123"}' \
  > events/sqs.json

# DynamoDB Streams イベント生成
sam local generate-event dynamodb update \
  > events/dynamodb.json
```

### 環境変数ファイル

```json
// env.json
{
  "MyFunction": {
    "TABLE_NAME": "local-table",
    "BUCKET_NAME": "local-bucket",
    "LOG_LEVEL": "DEBUG",
    "AWS_ENDPOINT_URL": "http://localhost:4566"
  },
  "OtherFunction": {
    "API_KEY": "test-key"
  }
}
```

### ユニットテスト

```python
"""
Lambda 関数のユニットテスト
"""
import json
import os
from unittest.mock import MagicMock, patch

import pytest

# 環境変数を設定
os.environ["TABLE_NAME"] = "test-table"
os.environ["AWS_DEFAULT_REGION"] = "ap-northeast-1"


@pytest.fixture
def api_gateway_event():
    """API Gateway イベントフィクスチャ"""
    return {
        "httpMethod": "GET",
        "path": "/items",
        "queryStringParameters": None,
        "headers": {"Content-Type": "application/json"},
        "body": None,
        "requestContext": {},
    }


@pytest.fixture
def mock_dynamodb():
    """DynamoDB モック"""
    with patch("boto3.resource") as mock:
        table = MagicMock()
        mock.return_value.Table.return_value = table
        yield table


class TestGetItems:
    """アイテム取得のテスト"""

    def test_get_items_success(self, api_gateway_event, mock_dynamodb):
        """正常系: アイテム一覧を取得"""
        # モックの設定
        mock_dynamodb.scan.return_value = {
            "Items": [
                {"id": "1", "name": "Item 1"},
                {"id": "2", "name": "Item 2"},
            ]
        }

        # ハンドラーをインポート（環境変数設定後）
        from functions.items import app

        # 実行
        response = app.lambda_handler(api_gateway_event, None)

        # 検証
        assert response["statusCode"] == 200
        body = json.loads(response["body"])
        assert len(body["items"]) == 2

    def test_get_items_empty(self, api_gateway_event, mock_dynamodb):
        """正常系: アイテムが空"""
        mock_dynamodb.scan.return_value = {"Items": []}

        from functions.items import app

        response = app.lambda_handler(api_gateway_event, None)

        assert response["statusCode"] == 200
        body = json.loads(response["body"])
        assert len(body["items"]) == 0


class TestCreateItem:
    """アイテム作成のテスト"""

    def test_create_item_success(self, mock_dynamodb):
        """正常系: アイテムを作成"""
        event = {
            "httpMethod": "POST",
            "path": "/items",
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"name": "New Item", "price": 100}),
        }

        from functions.items import app

        response = app.lambda_handler(event, None)

        assert response["statusCode"] == 201
        mock_dynamodb.put_item.assert_called_once()

    def test_create_item_validation_error(self, mock_dynamodb):
        """異常系: バリデーションエラー"""
        event = {
            "httpMethod": "POST",
            "path": "/items",
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"name": ""}),  # 空の名前
        }

        from functions.items import app

        response = app.lambda_handler(event, None)

        assert response["statusCode"] == 400
```

### 統合テスト

```python
"""
統合テスト（LocalStack 使用）
"""
import json
import os

import boto3
import pytest
from moto import mock_aws

# LocalStack エンドポイント
LOCALSTACK_ENDPOINT = os.environ.get("AWS_ENDPOINT_URL", "http://localhost:4566")


@pytest.fixture(scope="module")
def dynamodb_table():
    """DynamoDB テーブルをセットアップ"""
    dynamodb = boto3.resource(
        "dynamodb",
        endpoint_url=LOCALSTACK_ENDPOINT,
        region_name="ap-northeast-1",
    )

    # テーブル作成
    table = dynamodb.create_table(
        TableName="test-items",
        KeySchema=[{"AttributeName": "id", "KeyType": "HASH"}],
        AttributeDefinitions=[{"AttributeName": "id", "AttributeType": "S"}],
        BillingMode="PAY_PER_REQUEST",
    )
    table.wait_until_exists()

    yield table

    # クリーンアップ
    table.delete()


class TestIntegration:
    """統合テスト"""

    def test_crud_operations(self, dynamodb_table):
        """CRUD 操作のテスト"""
        # Create
        item = {"id": "test-1", "name": "Test Item", "price": 100}
        dynamodb_table.put_item(Item=item)

        # Read
        response = dynamodb_table.get_item(Key={"id": "test-1"})
        assert response["Item"]["name"] == "Test Item"

        # Update
        dynamodb_table.update_item(
            Key={"id": "test-1"},
            UpdateExpression="SET price = :p",
            ExpressionAttributeValues={":p": 200},
        )
        response = dynamodb_table.get_item(Key={"id": "test-1"})
        assert response["Item"]["price"] == 200

        # Delete
        dynamodb_table.delete_item(Key={"id": "test-1"})
        response = dynamodb_table.get_item(Key={"id": "test-1"})
        assert "Item" not in response
```

### pytest 設定

```ini
# pytest.ini
[pytest]
testpaths = tests
python_files = test_*.py
python_functions = test_*
addopts = -v --cov=functions --cov-report=html --cov-report=term-missing
filterwarnings =
    ignore::DeprecationWarning
env =
    AWS_DEFAULT_REGION=ap-northeast-1
    TABLE_NAME=test-table
```

---

## CI/CD パイプライン

### GitHub Actions ワークフロー

```yaml
# .github/workflows/sam-pipeline.yml
name: SAM Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

permissions:
  id-token: write
  contents: read

env:
  AWS_REGION: ap-northeast-1
  SAM_CLI_TELEMETRY: 0

jobs:
  # テストジョブ
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"

      - name: Install dependencies
        run: |
          pip install -r requirements-dev.txt

      - name: Run linter
        run: |
          ruff check .
          ruff format --check .

      - name: Run tests
        run: |
          pytest tests/ -v --cov=functions --cov-report=xml

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          files: coverage.xml

  # ビルドジョブ
  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up SAM CLI
        uses: aws-actions/setup-sam@v2

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"

      - name: Build
        run: sam build --use-container

      - name: Validate template
        run: sam validate --lint

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: sam-artifact
          path: .aws-sam/

  # 開発環境デプロイ
  deploy-dev:
    if: github.ref == 'refs/heads/develop'
    needs: build
    runs-on: ubuntu-latest
    environment: development
    steps:
      - uses: actions/checkout@v4

      - name: Download artifact
        uses: actions/download-artifact@v4
        with:
          name: sam-artifact
          path: .aws-sam/

      - name: Set up SAM CLI
        uses: aws-actions/setup-sam@v2

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN_DEV }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Deploy to dev
        run: |
          sam deploy \
            --stack-name my-app-dev \
            --parameter-overrides Environment=dev \
            --no-confirm-changeset \
            --no-fail-on-empty-changeset

  # 本番環境デプロイ
  deploy-prod:
    if: github.ref == 'refs/heads/main'
    needs: build
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4

      - name: Download artifact
        uses: actions/download-artifact@v4
        with:
          name: sam-artifact
          path: .aws-sam/

      - name: Set up SAM CLI
        uses: aws-actions/setup-sam@v2

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN_PROD }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Deploy to prod
        run: |
          sam deploy \
            --stack-name my-app-prod \
            --parameter-overrides Environment=prod \
            --no-confirm-changeset \
            --no-fail-on-empty-changeset
```

### OIDC 認証設定

```yaml
# oidc-role.yaml（CloudFormation テンプレート）
AWSTemplateFormatVersion: "2010-09-09"
Description: GitHub Actions OIDC Role

Parameters:
  GitHubOrg:
    Type: String
    Description: GitHub 組織名
  GitHubRepo:
    Type: String
    Description: GitHub リポジトリ名

Resources:
  # OIDC プロバイダー
  GitHubOIDCProvider:
    Type: AWS::IAM::OIDCProvider
    Properties:
      Url: https://token.actions.githubusercontent.com
      ClientIdList:
        - sts.amazonaws.com
      ThumbprintList:
        - 6938fd4d98bab03faadb97b34396831e3780aea1
        - 1c58a3a8518e8759bf075b76b750d4f2df264fcd

  # デプロイ用ロール
  GitHubActionsRole:
    Type: AWS::IAM::Role
    Properties:
      RoleName: github-actions-sam-deploy
      AssumeRolePolicyDocument:
        Version: "2012-10-17"
        Statement:
          - Effect: Allow
            Principal:
              Federated: !Ref GitHubOIDCProvider
            Action: sts:AssumeRoleWithWebIdentity
            Condition:
              StringEquals:
                token.actions.githubusercontent.com:aud: sts.amazonaws.com
              StringLike:
                token.actions.githubusercontent.com:sub: !Sub "repo:${GitHubOrg}/${GitHubRepo}:*"
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/AWSCloudFormationFullAccess
        - arn:aws:iam::aws:policy/IAMFullAccess
        - arn:aws:iam::aws:policy/AmazonS3FullAccess
        - arn:aws:iam::aws:policy/AWSLambda_FullAccess
        - arn:aws:iam::aws:policy/AmazonAPIGatewayAdministrator
        - arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess

Outputs:
  RoleArn:
    Description: GitHub Actions 用 IAM ロール ARN
    Value: !GetAtt GitHubActionsRole.Arn
```

### sam pipeline init

```bash
# パイプライン設定の初期化
sam pipeline init --bootstrap

# 対話式で以下を設定:
# 1. パイプラインテンプレート（GitHub Actions）
# 2. ステージ（dev, prod）
# 3. AWS 認証（OIDC）
# 4. S3 バケット（アーティファクト用）
# 5. ECR リポジトリ（コンテナイメージ用、オプション）
```

### samconfig.toml

```toml
# samconfig.toml
version = 0.1

[default.global.parameters]
stack_name = "my-app"

[default.build.parameters]
cached = true
parallel = true

[default.validate.parameters]
lint = true

[default.deploy.parameters]
capabilities = "CAPABILITY_IAM CAPABILITY_NAMED_IAM"
confirm_changeset = true
resolve_s3 = true
s3_prefix = "my-app"
region = "ap-northeast-1"
image_repositories = []

[default.sync.parameters]
watch = true

[dev]
[dev.deploy.parameters]
stack_name = "my-app-dev"
parameter_overrides = "Environment=dev"
confirm_changeset = false

[prod]
[prod.deploy.parameters]
stack_name = "my-app-prod"
parameter_overrides = "Environment=prod"
confirm_changeset = true
```

---

## ディレクトリ構造

### 推奨構造（小〜中規模）

```
my-sam-app/
├── template.yaml              # SAM テンプレート
├── samconfig.toml             # デプロイ設定
├── README.md                  # プロジェクト説明
│
├── functions/                 # Lambda 関数
│   ├── get_items/
│   │   ├── app.py             # ハンドラー
│   │   ├── requirements.txt   # 依存関係
│   │   └── __init__.py
│   ├── create_item/
│   │   ├── app.py
│   │   └── requirements.txt
│   └── shared/                # 関数間共有コード
│       ├── __init__.py
│       ├── db.py
│       └── models.py
│
├── layers/                    # Lambda Layers
│   └── common/
│       ├── requirements.txt
│       └── python/
│           └── common_utils/
│               └── __init__.py
│
├── events/                    # テスト用イベント
│   ├── api-get.json
│   ├── api-post.json
│   └── sqs-event.json
│
├── tests/                     # テスト
│   ├── unit/
│   │   ├── test_get_items.py
│   │   └── test_create_item.py
│   ├── integration/
│   │   └── test_api.py
│   └── conftest.py
│
├── scripts/                   # ユーティリティスクリプト
│   ├── setup-local.sh
│   └── seed-data.py
│
├── .github/
│   └── workflows/
│       └── sam-pipeline.yml
│
├── docker-compose.yml         # ローカル開発用
├── env.json                   # ローカル環境変数
├── requirements-dev.txt       # 開発用依存関係
├── pyproject.toml             # Python プロジェクト設定
└── .gitignore
```

### 推奨構造（大規模・マイクロサービス）

```
my-sam-app/
├── template.yaml              # ルートテンプレート
├── samconfig.toml
│
├── services/                  # マイクロサービス
│   ├── users/
│   │   ├── template.yaml      # サービス固有テンプレート
│   │   ├── functions/
│   │   │   ├── get_user/
│   │   │   ├── create_user/
│   │   │   └── update_user/
│   │   └── tests/
│   │
│   ├── orders/
│   │   ├── template.yaml
│   │   ├── functions/
│   │   └── tests/
│   │
│   └── payments/
│       ├── template.yaml
│       ├── functions/
│       └── tests/
│
├── shared/                    # 共有リソース
│   ├── layers/
│   │   └── common/
│   ├── api-gateway/
│   │   └── openapi.yaml
│   └── events/
│
├── infrastructure/            # インフラ定義
│   ├── vpc/
│   │   └── template.yaml
│   ├── database/
│   │   └── template.yaml
│   └── monitoring/
│       └── template.yaml
│
└── tests/
    ├── e2e/
    └── load/
```

### .gitignore

```gitignore
# SAM
.aws-sam/
samconfig.toml.bak

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
.venv/
ENV/
.eggs/
*.egg-info/
.installed.cfg
*.egg

# Node.js
node_modules/
package-lock.json

# IDE
.idea/
.vscode/
*.swp
*.swo

# Testing
.coverage
htmlcov/
.pytest_cache/
.tox/

# Local development
env.json
*.local.json
docker-compose.override.yml

# OS
.DS_Store
Thumbs.db

# Secrets
.env
*.pem
credentials.json
```

---

## ベストプラクティス一覧

### テンプレート設計

| カテゴリ | ベストプラクティス |
|---------|-------------------|
| 構造 | Globals でデフォルト値を設定し、関数ごとの重複を削減 |
| パラメータ | 環境（dev/stg/prod）を Parameters で切り替え |
| 命名 | `${AWS::StackName}-` プレフィックスでリソース名を一意に |
| 出力 | API エンドポイントやリソース ARN を Outputs に定義 |
| セキュリティ | NoEcho で機密パラメータを保護 |

### Lambda 関数設計

| カテゴリ | ベストプラクティス |
|---------|-------------------|
| アーキテクチャ | arm64（Graviton2）を使用してコスト削減 |
| メモリ | Power Tuning で最適なメモリサイズを決定 |
| タイムアウト | API Gateway 連携時は 29 秒以内に設定 |
| ハンドラー | 初期化コードはハンドラー外に配置 |
| エラー | 構造化ロギングと適切なエラーハンドリング |
| 依存関係 | Lambda Layers で共通ライブラリを共有 |

### セキュリティ

| カテゴリ | ベストプラクティス |
|---------|-------------------|
| IAM | 最小権限の原則、SAM ポリシーテンプレート使用 |
| シークレット | Secrets Manager または SSM Parameter Store |
| 暗号化 | S3、DynamoDB の保存時暗号化を有効化 |
| ネットワーク | 必要に応じて VPC 内で実行 |
| API | 認証・認可を適切に設定（Cognito、Lambda Authorizer） |

### ローカル開発

| カテゴリ | ベストプラクティス |
|---------|-------------------|
| テスト | sam local invoke でローカルテスト |
| API | sam local start-api で API サーバー起動 |
| イベント | sam local generate-event でイベント生成 |
| 環境 | LocalStack または DynamoDB Local を使用 |
| Docker | --docker-network でローカルサービスに接続 |

### CI/CD

| カテゴリ | ベストプラクティス |
|---------|-------------------|
| 認証 | GitHub Actions OIDC でシークレットレス認証 |
| ビルド | sam build --cached で高速化 |
| テスト | PR 時にユニットテスト、マージ時に統合テスト |
| デプロイ | dev → stg → prod の段階的デプロイ |
| ロールバック | CloudFormation のロールバック機能を活用 |

### 監視・運用

| カテゴリ | ベストプラクティス |
|---------|-------------------|
| ログ | 構造化ロギング（JSON 形式）を使用 |
| トレース | X-Ray トレーシングを有効化 |
| メトリクス | CloudWatch Embedded Metrics Format 使用 |
| アラート | エラー率、レイテンシに対するアラーム設定 |
| コスト | Lambda Power Tools でコスト最適化 |

### パフォーマンス

| カテゴリ | ベストプラクティス |
|---------|-------------------|
| コールドスタート | Provisioned Concurrency または SnapStart |
| 接続 | データベース接続の再利用（グローバル変数） |
| バッチ | SQS バッチ処理で効率化 |
| キャッシュ | API Gateway キャッシュ、Lambda 内キャッシュ |
| 並列 | 適切な並列度設定（ReservedConcurrentExecutions） |
