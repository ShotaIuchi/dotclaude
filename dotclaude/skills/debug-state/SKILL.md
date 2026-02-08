---
name: debug-state
description: >-
  Application state investigation. Apply when debugging unexpected state,
  variable corruption, stale caches, data inconsistencies, and state
  transition failures.
user-invocable: false
---

# State Inspector Investigation

Investigate application state to identify corruption, inconsistencies, and unexpected mutations.

## Investigation Checklist

### State Snapshot Analysis
- Capture and compare actual state against expected state
- Identify fields with unexpected or invalid values
- Check for partially initialized objects or incomplete state
- Verify invariants and business rules hold at each checkpoint
- Look for default values that should have been overwritten

### State Transitions
- Trace the sequence of state changes leading to the current state
- Verify each transition follows valid state machine rules
- Identify out-of-order transitions that violate preconditions
- Check for missing transitions that leave state in limbo
- Detect duplicate transitions that corrupt accumulated state

### Cache & Memoization
- Check if cached values are stale or inconsistent with source
- Verify cache invalidation triggers fire correctly
- Identify cache key collisions that return wrong data
- Check TTL and expiration logic for off-by-one errors
- Look for cache poisoning from failed or partial updates

### Side Effects
- Identify unintended mutations to shared or global state
- Check for closure captures that hold stale references
- Verify cleanup and teardown restore state properly
- Detect event handlers that modify state unexpectedly
- Look for implicit state changes in getters or property accessors

## Output Format

Report findings with confidence ratings:

| Confidence | Description |
|------------|-------------|
| High | Root cause clearly identified with supporting evidence |
| Medium | Probable cause identified but needs verification |
| Low | Hypothesis formed but insufficient evidence |
| Inconclusive | Unable to determine from available information |
