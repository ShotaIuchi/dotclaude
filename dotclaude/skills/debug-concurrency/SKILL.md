---
name: debug-concurrency
description: >-
  Concurrency and threading investigation. Apply when debugging race conditions,
  deadlocks, thread safety issues, shared mutable state, and timing-dependent
  failures.
user-invocable: false
---

# Concurrency Investigator Investigation

Investigate concurrency issues including race conditions, deadlocks, and thread safety violations.

## Investigation Checklist

### Race Condition Detection
- Identify shared mutable state accessed without synchronization
- Check for check-then-act patterns that allow interleaving
- Look for time-of-check to time-of-use (TOCTOU) vulnerabilities
- Verify atomic operations are used where required
- Detect read-modify-write sequences lacking proper guards

### Deadlock Analysis
- Map lock acquisition order across all code paths
- Identify circular wait conditions between threads or resources
- Check for nested lock acquisitions that invert ordering
- Verify timeout mechanisms exist for lock acquisition
- Look for resource starvation caused by unfair scheduling

### Thread Safety
- Verify collections and data structures are thread-safe or guarded
- Check that shared state is protected by consistent locking strategy
- Identify thread-local storage misuse or missing isolation
- Verify volatile/memory fence usage for visibility guarantees
- Check for safe publication of objects across thread boundaries

### Async/Await Correctness
- Verify async operations complete before dependent code executes
- Check for missing awaits that create fire-and-forget tasks
- Identify callback ordering assumptions that may not hold
- Verify cancellation tokens are checked and propagated
- Look for async void methods that swallow exceptions silently

## Output Format

Report findings with confidence ratings:

| Confidence | Description |
|------------|-------------|
| High | Root cause clearly identified with supporting evidence |
| Medium | Probable cause identified but needs verification |
| Low | Hypothesis formed but insufficient evidence |
| Inconclusive | Unable to determine from available information |
