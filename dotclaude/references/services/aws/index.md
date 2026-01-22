# AWS References

## Overview

Reference for serverless application development based on AWS official documentation.
Defines design patterns centered on AWS SAM, Lambda, API Gateway, and DynamoDB.

### Target Audience

- **Primary**: Developers with basic AWS knowledge building serverless applications
- **Prerequisites**: Familiarity with AWS Console, basic understanding of cloud concepts, experience with at least one programming language (Python, Node.js, or similar)

### Quick Start

1. Install [AWS SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html)
2. Configure AWS credentials (`aws configure`)
3. Start with [sam-template.md](sam-template.md) for SAM template patterns
4. Use the `aws-sam` skill for guided development

---

## File List and Priority

| File | Description | Priority |
|------|-------------|----------|
| [sam-template.md](sam-template.md) | AWS SAM templates and implementation patterns | ★★★ Foundation for serverless design |
| lambda-patterns.md | Lambda function implementation patterns (planned) | ★★★ Core function development |
| api-gateway-patterns.md | API Gateway design and configuration (planned) | ★★★ API design |
| dynamodb-modeling.md | DynamoDB data modeling patterns (planned) | ★★ Data layer design |

---

## External Links

> Last verified: 2026-01-22

### Official Documentation (Highest Priority)
- [AWS SAM Developer Guide (Official)](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/what-is-sam.html) - ★★★ SAM basics
- [AWS Lambda Developer Guide (Official)](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html) - ★★★ Lambda basics

### Related Services
- [Amazon API Gateway Developer Guide](https://docs.aws.amazon.com/apigateway/latest/developerguide/welcome.html) - ★★★ API design
- [Amazon DynamoDB Developer Guide](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Introduction.html) - ★★ NoSQL database
- [AWS CloudFormation User Guide](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/Welcome.html) - ★★ IaC basics

### Utilities
- [AWS Lambda Powertools for Python](https://docs.powertools.aws.dev/lambda/python/latest/) - ★★★ Lambda development productivity

---

## Related Skills

| Skill | Description | Path |
|-------|-------------|------|
| `aws-sam` | AWS SAM serverless application development | `dotclaude/skills/aws-sam.md` |

> Note: Additional skills for Lambda development and API design patterns are planned for future releases.
