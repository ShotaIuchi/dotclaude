---
name: debug-stacktrace
description: >-
  Stack trace and error message analysis. Apply when investigating exceptions,
  error chains, failure propagation paths, and crash logs to pinpoint failure
  locations.
user-invocable: false
---

# Stack Trace Analyzer Investigation

Analyze stack traces and error messages to pinpoint the root cause of failures.

## Investigation Checklist

### Exception Chain Analysis
- Identify the root cause exception in nested/chained exceptions
- Check for swallowed exceptions that hide the real failure
- Verify exception types match the actual error condition
- Trace cause-effect relationships through exception wrappers
- Look for generic catch blocks that obscure specific errors

### Error Propagation
- Map the full propagation path from origin to surface
- Check if error context is preserved through rethrows
- Identify where error information is lost or transformed
- Verify error codes and messages remain consistent across layers
- Detect silent failures that produce misleading downstream errors

### Stack Frame Inspection
- Locate the exact frame where the failure originates
- Distinguish application code frames from library/framework frames
- Check for missing frames due to inlining or tail-call optimization
- Identify async boundaries that split the logical call path
- Correlate frame variables with expected state at each level

### Log Correlation
- Match stack traces with surrounding log entries by timestamp
- Identify preceding warnings or errors that indicate preconditions
- Cross-reference thread/request IDs across distributed components
- Check for log level filtering that may hide relevant context
- Reconstruct the timeline of events leading to the failure

## Output Format

Report findings with confidence ratings:

| Confidence | Description |
|------------|-------------|
| High | Root cause clearly identified with supporting evidence |
| Medium | Probable cause identified but needs verification |
| Low | Hypothesis formed but insufficient evidence |
| Inconclusive | Unable to determine from available information |
