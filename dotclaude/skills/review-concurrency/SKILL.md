---
name: review-concurrency
description: >-
  Concurrency and thread safety-focused code review. Apply when reviewing
  multi-threaded code, coroutines, async/await, shared mutable state,
  race conditions, deadlocks, and synchronization.
user-invocable: false
---

# Concurrency Review

Review code from a concurrency and thread safety perspective.

## Review Checklist

### Shared Mutable State
- Verify mutable state accessed from multiple threads is protected
- Check for proper use of synchronization primitives (mutex, lock, atomic)
- Look for unprotected read-modify-write sequences
- Verify thread-safe collections are used where needed

### Race Conditions
- Check for time-of-check-to-time-of-use (TOCTOU) bugs
- Verify initialization is thread-safe (lazy init, singleton)
- Look for ordering assumptions without proper synchronization
- Check for data races in shared data structures

### Deadlocks & Livelocks
- Verify consistent lock ordering across code paths
- Check for nested lock acquisition patterns
- Look for blocking calls while holding locks
- Verify timeout mechanisms on lock acquisition

### Coroutines & Async
- Verify proper dispatcher/context usage (IO vs Main vs Default)
- Check for unstructured concurrency (leaked coroutines/tasks)
- Ensure cancellation is properly handled and propagated
- Verify suspending functions don't block the thread

### Thread Confinement
- Check UI updates happen on the main/UI thread
- Verify database operations use appropriate threads
- Look for thread-confined objects accessed from wrong threads
- Check callback/listener thread expectations

## Output Format

| Severity | Description |
|----------|-------------|
| Critical | Data race or deadlock that will cause corruption or hang |
| High | Race condition that is likely to manifest under load |
| Medium | Thread safety issue in low-contention path |
| Low | Defensive improvement for potential future issues |
