---
name: AWS SAM
description: Skill for AWS SAM serverless application development, Lambda function implementation, template design, local testing, and deployment.
references:
  - path: ../../references/services/aws/sam-template.md
external:
  - id: aws-sam-docs
  - id: aws-lambda-docs
  - id: aws-api-gateway
  - id: lambda-powertools-python
---

# AWS SAM (Serverless Application Model)

AWS SAM is an IaC framework for building serverless applications.

## Core Principles

1. **Infrastructure as Code (IaC)** - Manage all resources in template.yaml
2. **Single Responsibility Function Design** - Each Lambda focuses on one function
3. **Principle of Least Privilege** - IAM policies should be minimal
4. **Local-First Development** - Test with sam local before deploying

## Architecture

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

## SAM CLI Commands

| Command | Purpose |
|---------|---------|
| `sam init` | Create new project |
| `sam build` | Build (resolve dependencies) |
| `sam deploy --guided` | Initial deployment (interactive) |
| `sam local invoke` | Run function locally |
| `sam local start-api` | Start local API server |
| `sam sync --watch` | Auto-sync changes (during development) |
| `sam logs -t` | Tail CloudWatch logs |

## Directory Structure

```
project/
├── template.yaml           # SAM template
├── samconfig.toml          # Deployment configuration
├── functions/
│   ├── function_a/
│   │   ├── app.py          # Handler
│   │   └── requirements.txt
│   └── function_b/
│       ├── index.js
│       └── package.json
├── layers/
│   └── shared/
│       └── python/
├── events/                 # Test events
│   └── event.json
└── tests/
    └── unit/
```

## Detailed References

- [AWS SAM Templates and Best Practices](../../references/services/aws/sam-template.md)
