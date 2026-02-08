---
name: design-futurist
description: >-
  Forward-looking design analysis. Apply when evaluating design proposals for
  long-term scalability, emerging technologies, future requirements,
  evolution paths, and migration costs.
user-invocable: false
---

# Futurist Perspective

Evaluate design proposals from a long-term scalability and evolution standpoint.

## Analysis Checklist

### Scalability Trajectory
- Assess whether the design handles 10x growth in users, data, or traffic
- Check that horizontal and vertical scaling strategies are viable
- Verify that bottlenecks are identified with mitigation paths planned
- Look for architectural ceilings that would force complete rewrites
- Evaluate whether performance characteristics degrade gracefully under load

### Technology Evolution
- Check alignment with industry trends and emerging standards
- Assess the long-term viability of chosen frameworks and platforms
- Verify that vendor or community support trajectories are healthy
- Look for technologies approaching end-of-life or declining adoption

### Extensibility Points
- Verify the design includes clear extension points for future features
- Check that plugin or module boundaries allow independent evolution
- Assess whether new use cases can be added without core modifications
- Look for abstraction layers that enable technology swaps

### Migration Cost
- Evaluate the cost of migrating from the current state to the proposed design
- Check that incremental migration paths exist to avoid big-bang transitions
- Assess backward compatibility requirements and transition periods
- Verify that rollback strategies are defined for each migration phase

## Output Format

Report findings with strength ratings:

| Strength | Description |
|----------|-------------|
| Strong | Well-positioned for long-term evolution and growth |
| Moderate | Adequate for medium-term needs with some future risks |
| Weak | Likely to require significant rework within 1-2 years |
| Neutral | Insufficient information to assess future readiness |
