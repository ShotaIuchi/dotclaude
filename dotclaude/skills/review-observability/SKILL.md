---
name: review-observability
description: >-
  Observability and debugging-focused code review. Apply when reviewing
  logging, monitoring, metrics, tracing, alerting, structured logs,
  debug information, and production troubleshooting capability.
user-invocable: false
---

# Observability Review

Review code from an observability and debugging perspective.

## Review Checklist

### Logging
- Verify important operations are logged at appropriate levels
- Check log messages include sufficient context (IDs, parameters)
- Ensure structured logging format is used consistently
- Verify sensitive data is not logged (passwords, tokens, PII)

### Log Levels
- DEBUG: Detailed flow information for development
- INFO: Key business events and state transitions
- WARN: Recoverable issues that need attention
- ERROR: Failures requiring investigation
- Verify log level usage matches the above semantics

### Metrics & Monitoring
- Check key business metrics are tracked (request count, latency)
- Verify error rates are monitored with thresholds
- Ensure resource usage is tracked (memory, connections, queue depth)
- Check custom metrics for domain-specific health indicators

### Distributed Tracing
- Verify trace/correlation IDs propagate across service boundaries
- Check spans are created for significant operations
- Ensure trace context is included in log entries
- Verify async operations maintain trace context

### Alerting & Diagnostics
- Check health check endpoints exist and are meaningful
- Verify error conditions trigger appropriate alerts
- Ensure diagnostic information is accessible in production
- Check feature flags and configuration are observable

### Debugging Support
- Verify error messages help identify root cause
- Check stack traces are preserved through error handling
- Ensure request/response payloads are loggable (at debug level)
- Verify state transitions are traceable in logs

## Output Format

| Priority | Description |
|----------|-------------|
| Critical | No visibility into failure path, blind spot in production |
| High | Key operation not observable, hard to troubleshoot |
| Medium | Logging exists but lacks context or structure |
| Low | Enhancement for faster debugging |
