# AWS SAM Project Conventions

公式ドキュメントを補完するプロジェクト固有の規約・パターン。

---

## 環境変数命名規則

| Pattern | Example | Description |
|---------|---------|-------------|
| `TABLE_NAME` | `TABLE_NAME: !Ref ItemsTable` | DynamoDBテーブル名 |
| `BUCKET_NAME` | `BUCKET_NAME: !Ref AssetsBucket` | S3バケット名 |
| `QUEUE_URL` | `QUEUE_URL: !Ref ProcessQueue` | SQSキューURL |
| `{SERVICE}_API_KEY` | `STRIPE_API_KEY` | 外部サービスAPIキー（SSM経由） |
| `LOG_LEVEL` | `LOG_LEVEL: INFO` | ログレベル（DEBUG/INFO/WARN/ERROR） |

- 全て大文字スネークケース
- AWS リソース参照には `!Ref` または `!GetAtt` を使用
- シークレットは `AWS::SSM::Parameter::Value` または Secrets Manager 経由

## テンプレート構成規約

### Globals セクション

```yaml
Globals:
  Function:
    Runtime: python3.12
    Architectures: [arm64]
    Timeout: 29           # API Gateway統合時の上限
    MemorySize: 256
    Tracing: Active
    Environment:
      Variables:
        LOG_LEVEL: !If [IsProd, INFO, DEBUG]
        POWERTOOLS_SERVICE_NAME: !Ref AWS::StackName
```

- Runtime: `python3.12` を標準とする
- Architecture: コスト削減のため `arm64` を標準
- Timeout: API Gateway統合時は29秒以下
- Tracing: 常に `Active`（X-Ray有効）

### Parameters

```yaml
Parameters:
  Environment:
    Type: String
    Default: dev
    AllowedValues: [dev, stg, prod]
```

- 環境は `dev` / `stg` / `prod` の3段階
- 機密パラメータには `NoEcho: true`

### リソース命名

- `${AWS::StackName}-` プレフィックスでリソース名をユニーク化
- 論理ID は PascalCase（例: `ItemsTable`, `GetItemsFunction`）

## IAMポリシー構成

### SAM Policy Templates を優先

```yaml
Policies:
  - DynamoDBCrudPolicy:
      TableName: !Ref ItemsTable
  - S3ReadPolicy:
      BucketName: !Ref AssetsBucket
```

- カスタムポリシーより SAM Policy Templates を優先使用
- `*` リソース指定は禁止（最小権限原則）

## Lambda Layer 構成

```
layers/
└── common/
    ├── requirements.txt
    └── python/
        └── common_utils/
            └── __init__.py
```

- 共通ライブラリは Layer で共有
- Layer は `python/` ディレクトリ配下に配置（Python ランタイム規約）

## エラーハンドリング / ロギング標準

### 構造化ログ（JSON形式）

```python
from aws_lambda_powertools import Logger, Tracer, Metrics

logger = Logger()
tracer = Tracer()
metrics = Metrics()

@logger.inject_lambda_context
@tracer.capture_lambda_handler
@metrics.log_metrics
def lambda_handler(event, context):
    logger.info("Processing request", extra={"path": event.get("path")})
```

- Lambda Powertools を標準採用
- `Logger`, `Tracer`, `Metrics` の3点セットをデコレータで適用
- ログレベルは環境変数 `LOG_LEVEL` で制御

### API レスポンス形式

```python
def success_response(body, status_code=200):
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }

def error_response(message, status_code=500):
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"error": message}),
    }
```

## ディレクトリ構成

```
project/
├── template.yaml
├── samconfig.toml
├── functions/
│   ├── {function_name}/
│   │   ├── app.py
│   │   └── requirements.txt
│   └── shared/
│       ├── __init__.py
│       ├── db.py
│       └── models.py
├── layers/
│   └── common/
├── events/
├── tests/
│   ├── unit/
│   ├── integration/
│   └── conftest.py
└── .github/
    └── workflows/
```

## CI/CD 規約

- GitHub Actions OIDC 認証（シークレットレス）
- ビルド: `sam build --cached --parallel`
- テスト: PR時にunit、マージ時にintegration
- デプロイ: dev → stg → prod の段階的デプロイ
- samconfig.toml で環境別設定を管理
