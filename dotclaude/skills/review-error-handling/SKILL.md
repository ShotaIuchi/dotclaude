---
name: review-error-handling
description: >-
  Error handling and resilience-focused code review. Apply when reviewing
  exception handling, error propagation, retry logic, fallback strategies,
  graceful degradation, and failure recovery paths.
user-invocable: false
---

# Error Handling Review

Review code from an error handling and resilience perspective.

## Review Checklist

### Exception Handling
- Verify all throwable operations are properly caught
- Check catch blocks are specific (not bare catch-all)
- Ensure exceptions are not silently swallowed
- Verify error context is preserved when re-throwing

### Error Propagation
- Check errors propagate to appropriate handling layers
- Verify error types are meaningful (not generic strings)
- Ensure callers handle all possible error states
- Check Result/Either patterns are used consistently

### Retry & Recovery
- Verify retry logic has proper backoff strategy
- Check maximum retry limits are configured
- Ensure idempotency for retried operations
- Verify circuit breaker patterns where appropriate

### Graceful Degradation
- Check fallback behavior when dependencies fail
- Verify partial failure handling (some items succeed, some fail)
- Ensure timeouts are configured for all external calls
- Check user-facing error messages are helpful and safe

### Resource Cleanup
- Verify resources are released in error paths (finally/defer/use)
- Check database transactions are rolled back on failure
- Ensure temporary files are cleaned up on error
- Verify connection pools handle failed connections

## Output Format

| Severity | Description |
|----------|-------------|
| Critical | Unhandled error causes crash or data loss |
| High | Error silently swallowed, masking real problems |
| Medium | Error handled but with poor user experience |
| Low | Error handling works but could be more robust |
