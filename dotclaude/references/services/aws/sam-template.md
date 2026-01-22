# AWS SAM Architecture Guide

A collection of best practices for serverless application development using AWS SAM (Serverless Application Model).

---

## Table of Contents

1. [AWS SAM Overview](#aws-sam-overview)
2. [SAM CLI Command Reference](#sam-cli-command-reference)
3. [SAM Template Structure](#sam-template-structure)
4. [Resource Types](#resource-types)
5. [Lambda Function Design](#lambda-function-design)
6. [API Gateway Integration](#api-gateway-integration)
7. [Event Source Design](#event-source-design)
8. [Lambda Layers](#lambda-layers)
9. [Environment Variables and Configuration Management](#environment-variables-and-configuration-management)
10. [IAM and Security](#iam-and-security)
11. [Local Development and Testing](#local-development-and-testing)
12. [CI/CD Pipeline](#cicd-pipeline)
13. [Directory Structure](#directory-structure)
14. [Best Practices Checklist](#best-practices-checklist)

---

## AWS SAM Overview

### What is SAM

AWS SAM is an open-source framework for building and deploying serverless applications.
It is an extension of CloudFormation and allows you to define resources such as Lambda, API Gateway, and DynamoDB concisely.

### Key Features

1. **Concise template syntax** - Define resources with less code than CloudFormation
2. **Local development environment** - Test locally using Docker
3. **Built-in best practices** - Security settings and logging are included by default
4. **CI/CD integration** - Easy integration with GitHub Actions and CodePipeline

### SAM vs CloudFormation

| Item | SAM | CloudFormation |
|------|-----|----------------|
| Code volume | Less | More |
| Serverless-focused | Yes | No |
| Local testing | Yes | No |
| Transform | Required | Not required |
| Resource types | AWS::Serverless::* | AWS::* |

### SAM Transform Processing

SAM templates are converted to standard CloudFormation templates through the `AWS::Serverless-2016-10-31` transform. Here's what happens:

**Resource Transformation Examples:**

| SAM Resource | Transforms To |
|--------------|---------------|
| `AWS::Serverless::Function` | `AWS::Lambda::Function` + `AWS::IAM::Role` + `AWS::Lambda::Permission` (per event) |
| `AWS::Serverless::Api` | `AWS::ApiGateway::RestApi` + `AWS::ApiGateway::Stage` + `AWS::ApiGateway::Deployment` |
| `AWS::Serverless::SimpleTable` | `AWS::DynamoDB::Table` |
| `AWS::Serverless::HttpApi` | `AWS::ApiGatewayV2::Api` + `AWS::ApiGatewayV2::Stage` |

**SAM-Specific Features:**

1. **Policy Templates** - Pre-defined IAM policies (e.g., `DynamoDBCrudPolicy`, `S3ReadPolicy`) that expand to full IAM policy documents
2. **Globals Section** - Define default values inherited by all resources of the same type
3. **Implicit APIs** - Functions with `Api` events automatically create API Gateway resources
4. **Connectors** - `AWS::Serverless::Connector` generates least-privilege IAM policies between resources

**Viewing Transformed Template:**

```bash
# View the expanded CloudFormation template
sam validate --lint
aws cloudformation get-template --stack-name my-stack --template-stage Processed
```

---

## SAM CLI Command Reference

### Project Initialization

```bash
# Create project interactively
sam init

# Create with template specification
sam init --runtime python3.12 --name my-app --app-template hello-world

# Create from custom template
sam init --location https://github.com/example/sam-template
```

### Build

```bash
# Standard build
sam build

# Build inside container (for native dependencies)
sam build --use-container

# Build specific function only
sam build MyFunction

# Parallel build
sam build --parallel

# Build with cache
sam build --cached
```

### Deploy

```bash
# Interactive deploy (recommended for first time)
sam deploy --guided

# Deploy using configuration file
sam deploy

# Specify stack name and region
sam deploy --stack-name my-stack --region ap-northeast-1

# Parameter overrides
sam deploy --parameter-overrides Environment=prod ApiKey=xxx

# Skip change set confirmation
sam deploy --no-confirm-changeset

# Auto-approve IAM permissions
sam deploy --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM
```

### Local Execution

```bash
# Execute function locally
sam local invoke MyFunction

# Execute with event file
sam local invoke MyFunction -e events/event.json

# Specify environment variables file
sam local invoke MyFunction --env-vars env.json

# Start local API server
sam local start-api

# Specify port
sam local start-api --port 3000

# Enable hot reload
sam local start-api --warm-containers EAGER

# Start Lambda endpoint (without API Gateway)
sam local start-lambda
```

### Sync (for development)

```bash
# Auto-sync changes to AWS
sam sync --watch

# Sync code only (no infrastructure changes)
sam sync --watch --code

# Specify stack
sam sync --watch --stack-name my-stack
```

### Log Viewing

```bash
# Tail logs
sam logs -n MyFunction --tail

# Specify time range
sam logs -n MyFunction --start-time '5min ago'

# Filter
sam logs -n MyFunction --filter "ERROR"

# CloudWatch Insights query
sam logs --cw-log-group /aws/lambda/my-function
```

### Pipeline

```bash
# Initialize pipeline configuration
sam pipeline init

# Bootstrap for pipeline
sam pipeline bootstrap

# GitHub Actions configuration
sam pipeline init --bootstrap
```

### Other Commands

```bash
# Validate template
sam validate

# List resources
sam list resources --stack-name my-stack

# List endpoints
sam list endpoints --stack-name my-stack

# Delete stack
sam delete --stack-name my-stack
```

---

## SAM Template Structure

### Basic Structure

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31
Description: Sample serverless application

# Global settings (applied to all functions)
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

# Parameters
Parameters:
  Environment:
    Type: String
    Default: dev
    AllowedValues:
      - dev
      - stg
      - prod

# Conditions
Conditions:
  IsProd: !Equals [!Ref Environment, prod]

# Resource definitions
Resources:
  # Lambda function
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

# Outputs
Outputs:
  ApiEndpoint:
    Description: API Gateway endpoint URL
    Value: !Sub "https://${ServerlessRestApi}.execute-api.${AWS::Region}.amazonaws.com/Prod/"
```

### Globals Section

```yaml
Globals:
  Function:
    # Runtime settings
    Runtime: python3.12
    Architectures:
      - arm64
    Timeout: 30
    MemorySize: 256

    # Logging settings
    LoggingConfig:
      LogFormat: JSON
      ApplicationLogLevel: INFO
      SystemLogLevel: WARN

    # Tracing
    Tracing: Active

    # VPC settings
    VpcConfig:
      SecurityGroupIds:
        - !Ref LambdaSecurityGroup
      SubnetIds:
        - !Ref PrivateSubnet1
        - !Ref PrivateSubnet2

    # Environment variables
    Environment:
      Variables:
        POWERTOOLS_SERVICE_NAME: my-service
        LOG_LEVEL: INFO

  Api:
    # CORS settings
    Cors:
      AllowMethods: "'GET,POST,PUT,DELETE,OPTIONS'"
      AllowHeaders: "'Content-Type,Authorization'"
      AllowOrigin: "'*'"

    # Stage settings
    OpenApiVersion: 3.0.1

    # Authentication settings
    Auth:
      DefaultAuthorizer: MyCognitoAuthorizer
```

### Parameters Section

```yaml
Parameters:
  Environment:
    Type: String
    Default: dev
    AllowedValues:
      - dev
      - stg
      - prod
    Description: Deployment environment

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
    Description: External API key (sensitive information)
```

### Conditions Section

```yaml
Conditions:
  IsProd: !Equals [!Ref Environment, prod]
  IsNotProd: !Not [!Equals [!Ref Environment, prod]]
  EnableTracing: !Or
    - !Equals [!Ref Environment, prod]
    - !Equals [!Ref Environment, stg]
```

### Mappings Section

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

## Resource Types

### AWS::Serverless::Function

```yaml
MyFunction:
  Type: AWS::Serverless::Function
  Properties:
    # Basic settings
    FunctionName: !Sub "${AWS::StackName}-my-function"
    Description: Sample Lambda function
    CodeUri: functions/my_function/
    Handler: app.lambda_handler
    Runtime: python3.12
    Architectures:
      - arm64

    # Resource settings
    MemorySize: 256
    Timeout: 30
    ReservedConcurrentExecutions: 100

    # Environment variables
    Environment:
      Variables:
        TABLE_NAME: !Ref MyTable
        BUCKET_NAME: !Ref MyBucket

    # IAM role (auto-generated or specified)
    Role: !GetAtt MyFunctionRole.Arn
    # Or SAM policy templates
    Policies:
      - DynamoDBCrudPolicy:
          TableName: !Ref MyTable
      - S3ReadPolicy:
          BucketName: !Ref MyBucket

    # Event sources
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

    # Layers
    Layers:
      - !Ref SharedLayer
      - arn:aws:lambda:ap-northeast-1:123456789012:layer:my-layer:1

    # Dead letter queue
    DeadLetterQueue:
      Type: SQS
      TargetArn: !GetAtt DeadLetterQueue.Arn

    # VPC settings
    VpcConfig:
      SecurityGroupIds:
        - !Ref LambdaSecurityGroup
      SubnetIds:
        - !Ref PrivateSubnet1
        - !Ref PrivateSubnet2

    # Tracing
    Tracing: Active

    # Logging settings
    LoggingConfig:
      LogFormat: JSON
      LogGroup: !Ref MyFunctionLogGroup
      ApplicationLogLevel: INFO
      SystemLogLevel: WARN

    # Ephemeral Storage
    EphemeralStorage:
      Size: 1024

    # SnapStart (Java only)
    SnapStart:
      ApplyOn: PublishedVersions

  # Metadata (build settings)
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

    # OpenAPI definition
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

    # Authentication
    Auth:
      DefaultAuthorizer: CognitoAuthorizer
      Authorizers:
        CognitoAuthorizer:
          UserPoolArn: !GetAtt UserPool.Arn

    # Access logging
    AccessLogSetting:
      DestinationArn: !GetAtt ApiAccessLogGroup.Arn
      Format: '{"requestId":"$context.requestId","ip":"$context.identity.sourceIp","requestTime":"$context.requestTime","httpMethod":"$context.httpMethod","path":"$context.path","status":"$context.status","responseLength":"$context.responseLength"}'

    # Throttling
    MethodSettings:
      - ResourcePath: "/*"
        HttpMethod: "*"
        ThrottlingBurstLimit: 100
        ThrottlingRateLimit: 50

    # Cache
    CacheClusterEnabled: true
    CacheClusterSize: "0.5"

    # Custom domain
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
    Description: HTTP API (lower cost than REST API)

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

    # Authentication
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

    # Access logging
    AccessLogSettings:
      DestinationArn: !GetAtt HttpApiAccessLogGroup.Arn
      Format: '{"requestId":"$context.requestId","ip":"$context.identity.sourceIp","requestTime":"$context.requestTime","httpMethod":"$context.httpMethod","path":"$context.path","status":"$context.status"}'

    # Route settings
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
    # Or on-demand
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
    Description: Shared library layer
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

### AWS::Serverless::Application (Nested Stack)

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
# Lambda to DynamoDB connection
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

# Lambda to S3 connection
FunctionToBucketConnector:
  Type: AWS::Serverless::Connector
  Properties:
    Source:
      Id: MyFunction
    Destination:
      Id: MyBucket
    Permissions:
      - Read

# Lambda to SQS connection
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

## Lambda Function Design

### Python Handler Implementation

```python
"""
Lambda function handler

Entry point for item retrieval API
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

# Initialize logger and tracer
logger = Logger()
tracer = Tracer()
app = APIGatewayRestResolver()

# DynamoDB client
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])


@app.get("/items")
@tracer.capture_method
def get_items() -> dict[str, Any]:
    """
    Retrieve item list
    """
    logger.info("Starting item list retrieval")

    try:
        response = table.scan()
        items = response.get("Items", [])
        logger.info(f"Retrieved count: {len(items)}")
        return {"items": items}
    except Exception as e:
        logger.exception("Item retrieval error")
        raise


@app.get("/items/<item_id>")
@tracer.capture_method
def get_item(item_id: str) -> dict[str, Any]:
    """
    Retrieve specified item
    """
    logger.info(f"Retrieving item: {item_id}")

    response = table.get_item(Key={"id": item_id})
    item = response.get("Item")

    if not item:
        logger.warning(f"Item not found: {item_id}")
        return {"statusCode": 404, "body": json.dumps({"error": "Item not found"})}

    return item


@app.post("/items")
@tracer.capture_method
def create_item() -> dict[str, Any]:
    """
    Create new item
    """
    import uuid

    body = app.current_event.json_body
    logger.info(f"Creating item: {body}")

    item = {
        "id": str(uuid.uuid4()),
        "name": body.get("name"),
        "description": body.get("description"),
    }

    table.put_item(Item=item)
    logger.info(f"Item creation complete: {item['id']}")

    return {"statusCode": 201, "body": json.dumps(item)}


@logger.inject_lambda_context(correlation_id_path=correlation_paths.API_GATEWAY_REST)
@tracer.capture_lambda_handler
def lambda_handler(event: dict[str, Any], context: LambdaContext) -> dict[str, Any]:
    """
    Lambda entry point
    """
    return app.resolve(event, context)
```

### Node.js Handler Implementation

```javascript
/**
 * Lambda function handler
 *
 * Entry point for item retrieval API
 */
const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const {
  DynamoDBDocumentClient,
  ScanCommand,
  GetCommand,
  PutCommand,
} = require("@aws-sdk/lib-dynamodb");
const { v4: uuidv4 } = require("uuid");

// DynamoDB client
const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);
const TABLE_NAME = process.env.TABLE_NAME;

/**
 * Retrieve item list
 */
async function getItems() {
  console.log("Starting item list retrieval");

  const command = new ScanCommand({ TableName: TABLE_NAME });
  const response = await docClient.send(command);

  console.log(`Retrieved count: ${response.Items?.length || 0}`);
  return {
    statusCode: 200,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ items: response.Items || [] }),
  };
}

/**
 * Retrieve specified item
 */
async function getItem(itemId) {
  console.log(`Retrieving item: ${itemId}`);

  const command = new GetCommand({
    TableName: TABLE_NAME,
    Key: { id: itemId },
  });
  const response = await docClient.send(command);

  if (!response.Item) {
    console.warn(`Item not found: ${itemId}`);
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
 * Create new item
 */
async function createItem(body) {
  const data = JSON.parse(body);
  console.log("Creating item:", data);

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

  console.log(`Item creation complete: ${item.id}`);
  return {
    statusCode: 201,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(item),
  };
}

/**
 * Lambda entry point
 */
exports.handler = async (event, context) => {
  console.log("Event:", JSON.stringify(event, null, 2));

  try {
    const { httpMethod, path, pathParameters, body } = event;

    // Routing
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

### Error Handling Pattern

```python
"""
Error handling utilities
"""
import json
from functools import wraps
from typing import Any, Callable

from aws_lambda_powertools import Logger

logger = Logger()


class AppError(Exception):
    """
    Application error base class
    """

    def __init__(
        self,
        message: str,
        status_code: int = 500,
        error_code: str = "INTERNAL_ERROR",
        cause: Exception | None = None,
    ):
        self.message = message
        self.status_code = status_code
        self.error_code = error_code
        self.cause = cause
        super().__init__(self.message)

    @classmethod
    def from_exception(
        cls,
        e: Exception,
        message: str | None = None,
        status_code: int = 500,
        error_code: str = "INTERNAL_ERROR",
    ) -> "AppError":
        """
        Create AppError from an existing exception, preserving the chain.
        """
        error = cls(
            message=message or str(e),
            status_code=status_code,
            error_code=error_code,
            cause=e,
        )
        # Use raise ... from e pattern when raising this error
        return error


class NotFoundError(AppError):
    """Resource not found error"""

    def __init__(self, resource: str, resource_id: str):
        super().__init__(
            message=f"{resource} not found: {resource_id}",
            status_code=404,
            error_code="NOT_FOUND",
        )


class ValidationError(AppError):
    """Validation error"""

    def __init__(self, message: str):
        super().__init__(
            message=message,
            status_code=400,
            error_code="VALIDATION_ERROR",
        )


class UnauthorizedError(AppError):
    """Authentication error"""

    def __init__(self, message: str = "Unauthorized"):
        super().__init__(
            message=message,
            status_code=401,
            error_code="UNAUTHORIZED",
        )


def error_handler(func: Callable) -> Callable:
    """
    Error handling decorator
    """

    @wraps(func)
    def wrapper(*args, **kwargs) -> dict[str, Any]:
        try:
            return func(*args, **kwargs)
        except AppError as e:
            logger.warning(f"AppError: {e.error_code} - {e.message}")
            if e.cause:
                logger.debug(f"Caused by: {e.cause}")
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
            # Wrap and preserve exception chain for debugging
            wrapped = AppError.from_exception(e)
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


def handle_external_service_error(func: Callable) -> Callable:
    """
    Decorator for handling external service errors with exception chaining.

    Usage:
        @handle_external_service_error
        def call_external_api():
            response = httpx.get(url)
            response.raise_for_status()
            return response.json()
    """

    @wraps(func)
    def wrapper(*args, **kwargs) -> Any:
        try:
            return func(*args, **kwargs)
        except Exception as e:
            # Preserve original exception chain using 'from e'
            raise AppError(
                message=f"External service error: {str(e)}",
                status_code=502,
                error_code="EXTERNAL_SERVICE_ERROR",
                cause=e,
            ) from e

    return wrapper

    return wrapper
```

### Input Validation

```python
"""
Input validation utilities (Pydantic v2)
"""
from datetime import datetime
from typing import Any, Self

from pydantic import (
    BaseModel,
    ConfigDict,
    Field,
    field_serializer,
    field_validator,
    model_validator,
    ValidationError as PydanticValidationError,
)


class CreateItemRequest(BaseModel):
    """Item creation request"""

    # Pydantic v2: Use model_config instead of Config class
    model_config = ConfigDict(
        str_strip_whitespace=True,
        str_min_length=1,
        extra="forbid",
    )

    name: str = Field(..., min_length=1, max_length=100)
    description: str | None = Field(None, max_length=500)
    price: int = Field(..., ge=0)
    category: str = Field(..., pattern=r"^[a-z_]+$")
    tags: list[str] = Field(default_factory=list, max_length=10)
    created_at: datetime | None = None

    # Pydantic v2: field_validator with mode="before" for preprocessing
    @field_validator("tags", mode="before")
    @classmethod
    def normalize_tags(cls, v: Any) -> list[str]:
        """Normalize tags to lowercase"""
        if isinstance(v, list):
            return [tag.lower().strip() for tag in v if tag]
        return v

    # Pydantic v2: model_validator for cross-field validation
    @model_validator(mode="after")
    def validate_business_rules(self) -> Self:
        """Validate business rules across fields"""
        if self.category == "premium" and self.price < 1000:
            raise ValueError("Premium items must have price >= 1000")
        return self

    # Pydantic v2: field_serializer for custom output format
    @field_serializer("created_at")
    def serialize_datetime(self, dt: datetime | None) -> str | None:
        """Serialize datetime to ISO format string"""
        return dt.isoformat() if dt else None


class UpdateItemRequest(BaseModel):
    """Item update request"""

    model_config = ConfigDict(
        str_strip_whitespace=True,
        extra="forbid",
    )

    name: str | None = Field(None, min_length=1, max_length=100)
    description: str | None = Field(None, max_length=500)
    price: int | None = Field(None, ge=0)

    # Pydantic v2: Ensure at least one field is provided for update
    @model_validator(mode="after")
    def check_at_least_one_field(self) -> Self:
        """Ensure at least one field is provided"""
        if all(v is None for v in [self.name, self.description, self.price]):
            raise ValueError("At least one field must be provided for update")
        return self


def validate_request(model: type[BaseModel], data: dict[str, Any]) -> BaseModel:
    """
    Validate request data
    """
    try:
        return model.model_validate(data)  # Pydantic v2: use model_validate
    except PydanticValidationError as e:
        errors = []
        for error in e.errors():
            field = ".".join(str(loc) for loc in error["loc"])
            errors.append(f"{field}: {error['msg']}")
        raise ValidationError("; ".join(errors)) from e
```

---

## API Gateway Integration

### REST API Events

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

### HTTP API Events

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

### Lambda Function URL

```yaml
Resources:
  MyFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: functions/my_function/
      Handler: app.handler
      FunctionUrlConfig:
        AuthType: NONE
        # Or IAM authentication
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

### API Gateway Authentication

```yaml
Resources:
  MyApi:
    Type: AWS::Serverless::Api
    Properties:
      StageName: !Ref Environment
      Auth:
        DefaultAuthorizer: CognitoAuthorizer
        Authorizers:
          # Cognito authentication
          CognitoAuthorizer:
            UserPoolArn: !GetAtt UserPool.Arn
            Identity:
              Header: Authorization

          # Lambda authentication
          LambdaAuthorizer:
            FunctionArn: !GetAtt AuthorizerFunction.Arn
            Identity:
              Header: Authorization
              ReauthorizeEvery: 300

  # Endpoint without authentication
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

### Custom Lambda Authorizer

```python
"""
Lambda Authorizer
"""
import json
from typing import Any


def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    """
    Token-based authorizer
    """
    token = event.get("authorizationToken", "")
    method_arn = event["methodArn"]

    # Token validation logic
    if validate_token(token):
        principal_id = extract_user_id(token)
        return generate_policy(principal_id, "Allow", method_arn)

    return generate_policy("user", "Deny", method_arn)


def validate_token(token: str) -> bool:
    """Validate token"""
    # Implement actual validation logic
    return token.startswith("Bearer ")


def extract_user_id(token: str) -> str:
    """Extract user ID from token"""
    # Implement actual extraction logic
    return "user-123"


def generate_policy(principal_id: str, effect: str, resource: str) -> dict[str, Any]:
    """Generate IAM policy document"""
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

## Event Source Design

### SQS Events

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
SQS event handler
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
    Process individual record
    """
    payload = record.json_body
    logger.info(f"Processing message: {payload}")

    # Business logic
    process_message(payload)


def process_message(payload: dict[str, Any]) -> None:
    """Process message"""
    # Actual processing logic
    pass


@logger.inject_lambda_context
def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    """
    Lambda entry point (batch processing)
    """
    return process_partial_response(
        event=event,
        record_handler=record_handler,
        processor=processor,
        context=context,
    )
```

### S3 Events

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
S3 event handler
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
    Process S3 event
    """
    for record in event["Records"]:
        bucket = record["s3"]["bucket"]["name"]
        key = unquote_plus(record["s3"]["object"]["key"])

        logger.info(f"Processing: s3://{bucket}/{key}")

        # Get object
        response = s3.get_object(Bucket=bucket, Key=key)
        content = json.loads(response["Body"].read().decode("utf-8"))

        # Business logic
        process_file(content)


def process_file(content: dict[str, Any]) -> None:
    """Process file content"""
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

### EventBridge Schedule

```yaml
Resources:
  ScheduledFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: functions/scheduled/
      Handler: app.handler
      Events:
        # cron expression
        DailySchedule:
          Type: Schedule
          Properties:
            Schedule: cron(0 9 * * ? *)
            Description: Execute daily at 9:00 JST
            Enabled: true
            Input: '{"type": "daily"}'

        # rate expression
        HourlySchedule:
          Type: Schedule
          Properties:
            Schedule: rate(1 hour)
            Description: Execute every hour

        # EventBridge Scheduler
        SchedulerEvent:
          Type: ScheduleV2
          Properties:
            ScheduleExpression: rate(5 minutes)
            FlexibleTimeWindow:
              Mode: FLEXIBLE
              MaximumWindowInMinutes: 5
```

### EventBridge Rules

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

        # CloudTrail event
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

### Layer Structure

**Python Layer:**

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

**Node.js Layer:**

```
layers/
└── shared/
    └── nodejs/
        └── node_modules/
            ├── my-utils/
            │   ├── index.js
            │   ├── db.js
            │   └── validation.js
            └── package.json
```

**Other Runtimes:**

| Runtime | Layer Path |
|---------|------------|
| Python | `python/` or `python/lib/python3.x/site-packages/` |
| Node.js | `nodejs/node_modules/` |
| Ruby | `ruby/gems/<version>/` |
| Java | `java/lib/` |
| .NET | `dotnet/` |
| Custom | `bin/` (must be executable) |

### Layer Definition

```yaml
Resources:
  SharedLayer:
    Type: AWS::Serverless::LayerVersion
    Properties:
      LayerName: !Sub "${AWS::StackName}-shared"
      Description: Shared utility layer
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

  # Reference layer from function
  MyFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: functions/my_function/
      Handler: app.handler
      Layers:
        - !Ref SharedLayer
        # External layers can also be referenced
        - arn:aws:lambda:ap-northeast-1:017000801446:layer:AWSLambdaPowertoolsPythonV3-python312-arm64:3
```

### Layer requirements.txt

```
# layers/shared/requirements.txt
boto3>=1.34.0
pydantic>=2.0.0
httpx>=0.27.0
```

### Building Layers

```bash
# Build layer
sam build SharedLayer

# Build inside container (for native dependencies)
sam build SharedLayer --use-container
```

### Importing from Python Layer

```python
"""
Example of importing utilities from layer
"""
# Import modules included in layer
from myutils.db import get_connection
from myutils.validation import validate_input
```

---

## Environment Variables and Configuration Management

### Defining Environment Variables

```yaml
Globals:
  Function:
    Environment:
      Variables:
        # Common environment variables
        LOG_LEVEL: !If [IsProd, WARNING, INFO]
        POWERTOOLS_SERVICE_NAME: !Ref AWS::StackName

Resources:
  MyFunction:
    Type: AWS::Serverless::Function
    Properties:
      Environment:
        Variables:
          # Function-specific environment variables
          TABLE_NAME: !Ref MyTable
          BUCKET_NAME: !Ref MyBucket
          # Secrets Manager reference
          DB_PASSWORD: "{{resolve:secretsmanager:my-secret:SecretString:password}}"
          # SSM Parameter Store reference
          API_KEY: "{{resolve:ssm:/my-app/api-key:1}}"
```

### Secrets Manager Integration

```yaml
Resources:
  # Secret definition
  DatabaseSecret:
    Type: AWS::SecretsManager::Secret
    Properties:
      Name: !Sub "${AWS::StackName}/database"
      GenerateSecretString:
        SecretStringTemplate: '{"username": "admin"}'
        GenerateStringKey: password
        PasswordLength: 32
        ExcludeCharacters: '"@/\'

  # Function that references secret
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
Retrieve secret from Secrets Manager
"""
import json
import os

import boto3
from aws_lambda_powertools import Logger

logger = Logger()

# Cache
_secrets_cache = {}


def get_secret(secret_arn: str) -> dict:
    """
    Retrieve secret (with caching)
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
    # Database connection processing
```

### SSM Parameter Store Integration

```yaml
Resources:
  # Parameter definition
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

### AWS AppConfig Integration

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

## IAM and Security

### SAM Policy Templates

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

        # Custom policy
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
  # Lambda -> DynamoDB
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

  # Lambda -> S3 (read only)
  FunctionToBucketConnector:
    Type: AWS::Serverless::Connector
    Properties:
      Source:
        Id: MyFunction
      Destination:
        Id: MyBucket
      Permissions:
        - Read

  # Lambda -> SQS
  FunctionToQueueConnector:
    Type: AWS::Serverless::Connector
    Properties:
      Source:
        Id: MyFunction
      Destination:
        Id: MyQueue
      Permissions:
        - Write

  # API Gateway -> Lambda
  ApiToFunctionConnector:
    Type: AWS::Serverless::Connector
    Properties:
      Source:
        Id: MyApi
      Destination:
        Id: MyFunction
      Permissions:
        - Write

  # SNS -> Lambda
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

### Resource-Based Policies

```yaml
Resources:
  # S3 bucket policy
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

  # Lambda execution role (custom)
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

### Security Best Practices

```yaml
Resources:
  # Encrypted DynamoDB table
  SecureTable:
    Type: AWS::DynamoDB::Table
    Properties:
      SSESpecification:
        SSEEnabled: true
        SSEType: KMS
        KMSMasterKeyId: !Ref TableEncryptionKey

  # Encrypted S3 bucket
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

  # Lambda in VPC
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

  # Security group
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

### WAF Integration

Protect your API Gateway endpoints with AWS WAF (Web Application Firewall):

```yaml
Resources:
  # WAF Web ACL
  ApiWafWebAcl:
    Type: AWS::WAFv2::WebACL
    Properties:
      Name: !Sub "${AWS::StackName}-api-waf"
      Scope: REGIONAL
      DefaultAction:
        Allow: {}
      Description: WAF for API Gateway
      VisibilityConfig:
        CloudWatchMetricsEnabled: true
        MetricName: !Sub "${AWS::StackName}-api-waf"
        SampledRequestsEnabled: true
      Rules:
        # AWS Managed Rules - Common Rule Set
        - Name: AWSManagedRulesCommonRuleSet
          Priority: 1
          OverrideAction:
            None: {}
          Statement:
            ManagedRuleGroupStatement:
              VendorName: AWS
              Name: AWSManagedRulesCommonRuleSet
          VisibilityConfig:
            CloudWatchMetricsEnabled: true
            MetricName: AWSManagedRulesCommonRuleSet
            SampledRequestsEnabled: true

        # AWS Managed Rules - Known Bad Inputs
        - Name: AWSManagedRulesKnownBadInputsRuleSet
          Priority: 2
          OverrideAction:
            None: {}
          Statement:
            ManagedRuleGroupStatement:
              VendorName: AWS
              Name: AWSManagedRulesKnownBadInputsRuleSet
          VisibilityConfig:
            CloudWatchMetricsEnabled: true
            MetricName: AWSManagedRulesKnownBadInputsRuleSet
            SampledRequestsEnabled: true

        # Rate limiting rule
        - Name: RateLimitRule
          Priority: 3
          Action:
            Block: {}
          Statement:
            RateBasedStatement:
              Limit: 2000
              AggregateKeyType: IP
          VisibilityConfig:
            CloudWatchMetricsEnabled: true
            MetricName: RateLimitRule
            SampledRequestsEnabled: true

  # Associate WAF with API Gateway
  ApiWafAssociation:
    Type: AWS::WAFv2::WebACLAssociation
    Properties:
      ResourceArn: !Sub "arn:aws:apigateway:${AWS::Region}::/restapis/${MyApi}/stages/${Environment}"
      WebACLArn: !GetAtt ApiWafWebAcl.Arn

  # WAF logging (optional)
  WafLogGroup:
    Type: AWS::Logs::LogGroup
    Properties:
      LogGroupName: !Sub "aws-waf-logs-${AWS::StackName}"
      RetentionInDays: 30

  WafLoggingConfiguration:
    Type: AWS::WAFv2::LoggingConfiguration
    Properties:
      LogDestinationConfigs:
        - !Sub "arn:aws:logs:${AWS::Region}:${AWS::AccountId}:log-group:aws-waf-logs-${AWS::StackName}"
      ResourceArn: !GetAtt ApiWafWebAcl.Arn
```

---

## Local Development and Testing

### Docker Environment Setup

```yaml
# docker-compose.yml
# Note: The 'version' field is obsolete in Docker Compose V2 and can be omitted.
# See: https://docs.docker.com/compose/compose-file/04-version-and-name/
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
# Basic execution
sam local invoke MyFunction

# Specify event file
sam local invoke MyFunction -e events/api-event.json

# Specify environment variables file
sam local invoke MyFunction --env-vars env.json

# Specify Docker network (for LocalStack connection)
sam local invoke MyFunction --docker-network host

# Debug mode (for VS Code connection)
sam local invoke MyFunction -d 5858
```

### sam local start-api

```bash
# Start API server
sam local start-api

# Specify port
sam local start-api --port 3000

# Hot reload
sam local start-api --warm-containers EAGER

# Specify Docker network
sam local start-api --docker-network host

# Specify environment variables file
sam local start-api --env-vars env.json
```

### Event Files

```json
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

### Event Generation Commands

```bash
# Generate API Gateway event
sam local generate-event apigateway aws-proxy \
  --method GET \
  --path /items \
  > events/api-get.json

# Generate S3 event
sam local generate-event s3 put \
  --bucket my-bucket \
  --key uploads/test.json \
  > events/s3-put.json

# Generate SQS event
sam local generate-event sqs receive-message \
  --body '{"id": "123"}' \
  > events/sqs.json

# Generate DynamoDB Streams event
sam local generate-event dynamodb update \
  > events/dynamodb.json
```

### Environment Variables File

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

### Unit Testing

```python
"""
Lambda function unit tests
"""
import json
import os
from unittest.mock import MagicMock, patch

import pytest

# Set environment variables
os.environ["TABLE_NAME"] = "test-table"
os.environ["AWS_DEFAULT_REGION"] = "ap-northeast-1"


@pytest.fixture
def api_gateway_event():
    """API Gateway event fixture"""
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
    """DynamoDB mock"""
    with patch("boto3.resource") as mock:
        table = MagicMock()
        mock.return_value.Table.return_value = table
        yield table


class TestGetItems:
    """Item retrieval tests"""

    def test_get_items_success(self, api_gateway_event, mock_dynamodb):
        """Success case: Retrieve item list"""
        # Mock setup
        mock_dynamodb.scan.return_value = {
            "Items": [
                {"id": "1", "name": "Item 1"},
                {"id": "2", "name": "Item 2"},
            ]
        }

        # Import handler (after environment variable setup)
        from functions.items import app

        # Execute
        response = app.lambda_handler(api_gateway_event, None)

        # Verify
        assert response["statusCode"] == 200
        body = json.loads(response["body"])
        assert len(body["items"]) == 2

    def test_get_items_empty(self, api_gateway_event, mock_dynamodb):
        """Success case: Empty items"""
        mock_dynamodb.scan.return_value = {"Items": []}

        from functions.items import app

        response = app.lambda_handler(api_gateway_event, None)

        assert response["statusCode"] == 200
        body = json.loads(response["body"])
        assert len(body["items"]) == 0


class TestCreateItem:
    """Item creation tests"""

    def test_create_item_success(self, mock_dynamodb):
        """Success case: Create item"""
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
        """Error case: Validation error"""
        event = {
            "httpMethod": "POST",
            "path": "/items",
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"name": ""}),  # Empty name
        }

        from functions.items import app

        response = app.lambda_handler(event, None)

        assert response["statusCode"] == 400
```

### Integration Testing

```python
"""
Integration tests (using LocalStack)
"""
import json
import os

import boto3
import pytest
from moto import mock_aws

# LocalStack endpoint
LOCALSTACK_ENDPOINT = os.environ.get("AWS_ENDPOINT_URL", "http://localhost:4566")


@pytest.fixture(scope="module")
def dynamodb_table():
    """Set up DynamoDB table"""
    dynamodb = boto3.resource(
        "dynamodb",
        endpoint_url=LOCALSTACK_ENDPOINT,
        region_name="ap-northeast-1",
    )

    # Create table
    table = dynamodb.create_table(
        TableName="test-items",
        KeySchema=[{"AttributeName": "id", "KeyType": "HASH"}],
        AttributeDefinitions=[{"AttributeName": "id", "AttributeType": "S"}],
        BillingMode="PAY_PER_REQUEST",
    )
    table.wait_until_exists()

    yield table

    # Cleanup
    table.delete()


class TestIntegration:
    """Integration tests"""

    def test_crud_operations(self, dynamodb_table):
        """CRUD operations test"""
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

### pytest Configuration

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

## CI/CD Pipeline

### GitHub Actions Workflow

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
  # Test job
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

  # Build job
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

  # Development environment deploy
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

  # Production environment deploy
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

### OIDC Authentication Setup

```yaml
# oidc-role.yaml (CloudFormation template)
AWSTemplateFormatVersion: "2010-09-09"
Description: GitHub Actions OIDC Role

Parameters:
  GitHubOrg:
    Type: String
    Description: GitHub organization name
  GitHubRepo:
    Type: String
    Description: GitHub repository name

Resources:
  # OIDC Provider
  # Note: AWS now automatically manages thumbprints for GitHub Actions OIDC.
  # The ThumbprintList can be set to any valid 40-character hex string as AWS
  # verifies the certificate chain directly. See:
  # https://github.blog/changelog/2023-06-27-github-actions-update-on-oidc-integration-with-aws/
  GitHubOIDCProvider:
    Type: AWS::IAM::OIDCProvider
    Properties:
      Url: https://token.actions.githubusercontent.com
      ClientIdList:
        - sts.amazonaws.com
      ThumbprintList:
        # AWS ignores this value for github actions but requires a valid format
        - 6938fd4d98bab03faadb97b34396831e3780aea1

  # Deploy role
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
    Description: IAM role ARN for GitHub Actions
    Value: !GetAtt GitHubActionsRole.Arn
```

### sam pipeline init

```bash
# Initialize pipeline configuration
sam pipeline init --bootstrap

# Interactive setup for:
# 1. Pipeline template (GitHub Actions)
# 2. Stages (dev, prod)
# 3. AWS authentication (OIDC)
# 4. S3 bucket (for artifacts)
# 5. ECR repository (for container images, optional)
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

## Directory Structure

### Recommended Structure (Small to Medium Scale)

```
my-sam-app/
├── template.yaml              # SAM template
├── samconfig.toml             # Deploy configuration
├── README.md                  # Project description
│
├── functions/                 # Lambda functions
│   ├── get_items/
│   │   ├── app.py             # Handler
│   │   ├── requirements.txt   # Dependencies
│   │   └── __init__.py
│   ├── create_item/
│   │   ├── app.py
│   │   └── requirements.txt
│   └── shared/                # Shared code between functions
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
├── events/                    # Test events
│   ├── api-get.json
│   ├── api-post.json
│   └── sqs-event.json
│
├── tests/                     # Tests
│   ├── unit/
│   │   ├── test_get_items.py
│   │   └── test_create_item.py
│   ├── integration/
│   │   └── test_api.py
│   └── conftest.py
│
├── scripts/                   # Utility scripts
│   ├── setup-local.sh
│   └── seed-data.py
│
├── .github/
│   └── workflows/
│       └── sam-pipeline.yml
│
├── docker-compose.yml         # Local development
├── env.json                   # Local environment variables
├── requirements-dev.txt       # Development dependencies
├── pyproject.toml             # Python project settings
└── .gitignore
```

### Recommended Structure (Large Scale / Microservices)

```
my-sam-app/
├── template.yaml              # Root template
├── samconfig.toml
│
├── services/                  # Microservices
│   ├── users/
│   │   ├── template.yaml      # Service-specific template
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
├── shared/                    # Shared resources
│   ├── layers/
│   │   └── common/
│   ├── api-gateway/
│   │   └── openapi.yaml
│   └── events/
│
├── infrastructure/            # Infrastructure definitions
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

## Best Practices Checklist

### Template Design

| Category | Best Practice |
|---------|---------------|
| Structure | Set default values in Globals to reduce duplication per function |
| Parameters | Switch environments (dev/stg/prod) using Parameters |
| Naming | Use `${AWS::StackName}-` prefix to make resource names unique |
| Outputs | Define API endpoints and resource ARNs in Outputs |
| Security | Protect sensitive parameters with NoEcho |

### Lambda Function Design

| Category | Best Practice |
|---------|---------------|
| Architecture | Use arm64 (Graviton2) for cost reduction |
| Memory | Use Power Tuning to determine optimal memory size |
| Timeout | Set to 29 seconds or less when integrating with API Gateway |
| Handler | Place initialization code outside the handler |
| Error | Use structured logging and proper error handling |
| Dependencies | Share common libraries using Lambda Layers |

### Security

| Category | Best Practice |
|---------|---------------|
| IAM | Principle of least privilege, use SAM policy templates |
| Secrets | Use Secrets Manager or SSM Parameter Store |
| Encryption | Enable encryption at rest for S3 and DynamoDB |
| Network | Run in VPC when necessary |
| API | Configure authentication/authorization properly (Cognito, Lambda Authorizer) |

### Local Development

| Category | Best Practice |
|---------|---------------|
| Test | Local testing with sam local invoke |
| API | Start API server with sam local start-api |
| Events | Generate events with sam local generate-event |
| Environment | Use LocalStack or DynamoDB Local |
| Docker | Connect to local services with --docker-network |

### CI/CD

| Category | Best Practice |
|---------|---------------|
| Authentication | Secretless authentication with GitHub Actions OIDC |
| Build | Speed up with sam build --cached |
| Test | Unit tests on PR, integration tests on merge |
| Deploy | Gradual deployment: dev -> stg -> prod |
| Rollback | Utilize CloudFormation rollback capability |

### Monitoring & Operations

| Category | Best Practice |
|---------|---------------|
| Logging | Use structured logging (JSON format) |
| Tracing | Enable X-Ray tracing |
| Metrics | Use CloudWatch Embedded Metrics Format |
| Alerts | Set alarms for error rates and latency |
| Cost | Optimize costs with Lambda Power Tools |

### Performance

| Category | Best Practice |
|---------|---------------|
| Cold Start | Use Provisioned Concurrency or SnapStart |
| Connections | Reuse database connections (global variables) |
| Batch | Improve efficiency with SQS batch processing |
| Cache | API Gateway cache, in-Lambda caching |
| Parallelism | Set appropriate concurrency (ReservedConcurrentExecutions) |
