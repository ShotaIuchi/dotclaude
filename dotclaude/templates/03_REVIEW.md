# Review: {{WORK_ID}}

> Plan: [02_PLAN.md](./02_PLAN.md)
> Reviewed: {{REVIEWED_AT}}
> Reviewer: {{REVIEWER}}

## Review Summary

<!-- レビュー全体の所見 -->
{{SUMMARY}}

## Checklist

<!-- レビュー観点のチェックリスト -->

### Code Quality
- [ ] コードスタイルがプロジェクト規約に準拠
- [ ] 適切なエラーハンドリング
- [ ] 不要なコメント・デバッグコードの除去

### Functionality
- [ ] 仕様通りに動作する
- [ ] エッジケースが考慮されている
- [ ] パフォーマンスに問題がない

### Security
- [ ] セキュリティ上の問題がない
- [ ] 機密情報の適切な取り扱い

### Testing
- [ ] テストカバレッジが十分
- [ ] テストが正しく動作する

## Findings

<!-- レビューで発見した問題点 -->

### Must Fix (Blocking)

<!-- 修正必須の指摘。これが解決されるまでマージ不可 -->
| # | Location | Issue | Suggestion |
|---|----------|-------|------------|
| 1 | {{LOCATION_1}} | {{ISSUE_1}} | {{SUGGESTION_1}} |

### Should Fix (Non-blocking)

<!-- 修正推奨の指摘。今回のスコープで対応が望ましい -->
| # | Location | Issue | Suggestion |
|---|----------|-------|------------|
| 1 | {{LOCATION_2}} | {{ISSUE_2}} | {{SUGGESTION_2}} |

### Nice-to-have

<!-- 改善提案。次回以降でも可 -->
- {{NICE_TO_HAVE_1}}
- {{NICE_TO_HAVE_2}}

## Decision

<!-- レビュー結果の判定 -->
**Status:** {{STATUS}}

<!-- approved / request-changes / needs-discussion -->

**Comments:**
{{DECISION_COMMENTS}}

## Follow-up Actions

<!-- フォローアップが必要なアクション -->
- [ ] {{FOLLOW_UP_1}}
- [ ] {{FOLLOW_UP_2}}

## Notes

<!-- レビューコメント、補足情報 -->
{{NOTES}}
