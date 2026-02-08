---
name: test-edge
description: >-
  Edge case test creation. Apply when identifying and testing boundary
  conditions, null inputs, empty collections, overflow scenarios, unicode
  handling, and error path coverage.
user-invocable: false
---

# Edge Case Tests

Identify and write tests for boundary conditions and unusual input scenarios.

## Test Creation Checklist

### Boundary Conditions
- Test minimum and maximum allowed values (0, 1, MAX_INT, etc.)
- Verify off-by-one behavior at array/collection boundaries
- Check date/time edge cases (leap years, timezone transitions, epoch)
- Test string length limits (empty, single char, maximum length)
- Validate range boundaries for numeric parameters

### Null & Empty Handling
- Test null inputs for all nullable parameters
- Verify behavior with empty strings, collections, and maps
- Check optional/missing fields in structured data
- Test default value fallback when inputs are absent
- Validate graceful handling of uninitialized state

### Overflow & Limits
- Test integer overflow and underflow conditions
- Verify behavior at file size and memory allocation limits
- Check stack depth for recursive operations
- Test rate limiting and throttling thresholds
- Validate behavior when storage or quota is exhausted

### Malformed Input
- Test with invalid encoding (broken UTF-8, mixed encodings)
- Verify handling of special characters and unicode edge cases
- Check behavior with unexpected data types or formats
- Test truncated, corrupted, or partial input data
- Validate rejection of injection payloads in all input channels

## Output Format

Report test plan with priority ratings:

| Priority | Description |
|----------|-------------|
| Must | Boundary tests that prevent crashes and data corruption |
| Should | Edge cases likely encountered in production usage |
| Could | Unusual scenarios with low probability but high impact |
| Won't | Theoretical edge cases with negligible real-world risk |
