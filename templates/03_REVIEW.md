# Review: {{WORK_ID}}

> Plan: [02_PLAN.md](./02_PLAN.md)
> Reviewed: {{REVIEWED_AT}}
> Reviewer: {{REVIEWER}}

## Review Summary

<!-- レビュー全体の所見 -->
{{SUMMARY}}

## Checklist

### Code Quality
- [ ] コードスタイルがプロジェクト規約に準拠
- [ ] 適切なエラーハンドリング
- [ ] 不要なコメント・デバッグコードの除去

### Functionality
- [ ] 仕様通りに動作する
- [ ] エッジケースが考慮されている
- [ ] パフォーマンスに問題がない

### Testing
- [ ] テストが追加されている
- [ ] テストがパスする
- [ ] テストカバレッジが十分

### Documentation
- [ ] 必要なドキュメントが更新されている
- [ ] API ドキュメントが最新

### Security
- [ ] セキュリティ上の問題がない
- [ ] 機密情報がハードコードされていない

## Findings

### Must Fix (Blocking)

<!-- 修正必須の指摘 -->
| # | Location | Issue | Suggestion |
|---|----------|-------|------------|
| 1 | {{LOCATION_1}} | {{ISSUE_1}} | {{SUGGESTION_1}} |

### Should Fix (Non-blocking)

<!-- 修正推奨の指摘 -->
| # | Location | Issue | Suggestion |
|---|----------|-------|------------|
| 1 | {{LOCATION_2}} | {{ISSUE_2}} | {{SUGGESTION_2}} |

### Suggestions (Optional)

<!-- 改善提案 -->
- {{SUGGESTION_3}}

## Decision

<!-- Approved / Request Changes / Needs Discussion -->
**Status:** {{STATUS}}

**Comments:**
{{COMMENTS}}

## Follow-up Actions

<!-- レビュー後の対応事項 -->
- [ ] {{ACTION_1}}
