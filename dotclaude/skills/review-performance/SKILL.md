---
name: review-performance
description: >-
  Performance-focused code review. Apply when reviewing code for
  N+1 queries, unnecessary re-renders, memory leaks, inefficient algorithms,
  database access patterns, caching, and resource optimization.
user-invocable: false
---

# Performance Review

Review code from a performance perspective.

## Review Checklist

### Database & Queries
- Check for N+1 query problems
- Verify proper use of indexes
- Look for unnecessary data fetching (SELECT *)
- Check batch operations vs individual queries
- Verify connection pool configuration

### Memory & Resources
- Check for memory leaks (unclosed resources, retained references)
- Verify proper cleanup in lifecycle methods
- Look for unnecessary object creation in hot paths
- Check for unbounded collections or caches

### Algorithm & Data Structures
- Verify appropriate time/space complexity
- Check for unnecessary nested loops
- Look for redundant computation that could be cached
- Verify efficient use of data structures

### UI & Rendering
- Check for unnecessary re-renders or recompositions
- Verify lazy loading for large lists
- Look for blocking operations on main/UI thread
- Check image loading and caching strategy

### Network & I/O
- Verify proper use of async/concurrent operations
- Check for unnecessary API calls
- Look for missing pagination
- Verify timeout and retry configurations

## Output Format

Report findings with impact ratings:

| Impact | Description |
|--------|-------------|
| Critical | Causes visible degradation or crashes under load |
| High | Noticeable impact on user experience |
| Medium | Measurable but not immediately visible |
| Low | Micro-optimization, minor improvement |
