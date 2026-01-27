# AWS Technology Decisions

## Adopted Technologies

| Technology | Purpose | Adoption Reason | Alternatives |
|------------|---------|----------------|-------------|
| AWS SAM | IaC/Deploy | Lambda-focused, local testing support | CDK, Serverless Framework, Terraform |
| Lambda (Python) | Compute | Cost efficiency, scalability | ECS, App Runner |
| API Gateway | HTTP endpoints | Lambda integration, SAM template support | ALB, AppSync |
| DynamoDB | NoSQL DB | Serverless affinity, scalability | Aurora Serverless, RDS |
| Lambda Powertools | Cross-cutting concerns | Integrated Logging/Tracing/Metrics | Manual implementation |
| CloudFormation | IaC foundation | SAM foundation, AWS native | Terraform |

## Rejected Options

| Technology | Rejection Reason |
|------------|-----------------|
| CDK | Prefer SAM's simplicity; rich Lambda-specific features |
| Serverless Framework | Prefer AWS-native toolchain |
| Terraform | CloudFormation/SAM is sufficient |
| ECS/Fargate | Lambda fits the serverless requirements |
| Aurora Serverless | DynamoDB offers better scalability and cost |
| AppSync | REST API is sufficient; no GraphQL requirement |

## Related Documents

- [conventions.md](conventions.md) — Template conventions and IAM policies
- [sam-architecture-patterns.md](sam-architecture-patterns.md) — SAM architecture patterns
