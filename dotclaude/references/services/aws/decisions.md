# AWS Technology Decisions

## 採用技術

| 技術 | 用途 | 採用理由 | 代替候補 |
|------|------|---------|---------|
| AWS SAM | IaC/デプロイ | Lambda特化、ローカルテスト対応 | CDK, Serverless Framework, Terraform |
| Lambda (Python) | コンピュート | コスト効率、スケーラビリティ | ECS, App Runner |
| API Gateway | HTTPエンドポイント | Lambda統合、SAMテンプレート対応 | ALB, AppSync |
| DynamoDB | NoSQL DB | サーバーレス親和性、スケーラビリティ | Aurora Serverless, RDS |
| Lambda Powertools | 横断的関心事 | Logging/Tracing/Metrics統合 | 手動実装 |
| CloudFormation | IaC基盤 | SAMの基盤、AWSネイティブ | Terraform |

## 不採用とした選択肢

| 技術 | 不採用理由 |
|------|-----------|
| CDK | SAMのシンプルさを優先、Lambda特化の機能が豊富 |
| Serverless Framework | AWS純正ツールチェインを優先 |
| Terraform | CloudFormation/SAMで十分 |
| ECS/Fargate | サーバーレスの要件にLambdaが適合 |
| Aurora Serverless | DynamoDBのスケーラビリティとコスト優位 |
| AppSync | REST APIで十分、GraphQLの要件なし |

## 関連ドキュメント

- [conventions.md](conventions.md) — テンプレート規約・IAMポリシー
- [sam-architecture-patterns.md](sam-architecture-patterns.md) — SAMアーキテクチャ
