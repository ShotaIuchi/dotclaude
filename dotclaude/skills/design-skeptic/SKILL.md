---
name: design-skeptic
description: >-
  Critical design analysis. Apply when stress-testing design proposals for
  hidden assumptions, failure scenarios, edge cases, single points of failure,
  and overengineering risks.
user-invocable: false
---

# Skeptic Perspective

Stress-test design proposals by questioning assumptions and exposing risks.

## Analysis Checklist

### Assumption Validation
- Identify implicit assumptions about user behavior or data patterns
- Challenge stated performance expectations with worst-case scenarios
- Verify that availability and reliability claims are backed by evidence
- Question whether the problem statement itself is correctly framed
- Check for optimistic bias in effort estimates and timelines

### Failure Scenarios
- Map single points of failure and their blast radius
- Verify graceful degradation paths for each critical component
- Check that cascading failure modes are identified and mitigated
- Assess disaster recovery and data loss scenarios

### Edge Cases & Limits
- Identify boundary conditions in data size, concurrency, and throughput
- Check behavior under empty, null, or malformed input conditions
- Verify handling of clock skew, network partitions, and race conditions
- Assess what happens at resource exhaustion (memory, disk, connections)

### Complexity Assessment
- Evaluate whether the design is overengineered for the actual requirements
- Check for unnecessary abstraction layers that add cognitive overhead
- Look for simpler alternatives that achieve the same goals
- Assess whether the complexity budget is justified by the problem scope

## Output Format

Report findings with strength ratings:

| Strength | Description |
|----------|-------------|
| Strong | Robust against failures, assumptions well-validated |
| Moderate | Some risks identified but manageable with mitigations |
| Weak | Critical assumptions unvalidated or major failure gaps |
| Neutral | Insufficient information to assess resilience |
