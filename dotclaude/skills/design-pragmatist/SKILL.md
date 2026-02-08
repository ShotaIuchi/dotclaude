---
name: design-pragmatist
description: >-
  Practical design analysis. Apply when evaluating design proposals for
  real-world feasibility, team capabilities, implementation timeline,
  maintenance cost, and proven solution patterns.
user-invocable: false
---

# Pragmatist Perspective

Evaluate design proposals from a practical, real-world feasibility standpoint.

## Analysis Checklist

### Feasibility Assessment
- Verify the proposal can be implemented with available tools and frameworks
- Check that assumptions about infrastructure and services are realistic
- Identify any dependencies on unproven or immature technologies
- Assess whether the proposed timeline accounts for integration complexity
- Confirm that prototyping or proof-of-concept has validated risky areas

### Team & Timeline Fit
- Check that required skills exist within the current team
- Assess whether the learning curve is acceptable for the project timeline
- Verify that staffing and resource allocation supports the proposal
- Look for opportunities to parallelize work across team members

### Maintenance Burden
- Evaluate long-term operational complexity of the proposed design
- Check that debugging and troubleshooting paths are straightforward
- Verify that monitoring, logging, and alerting are accounted for
- Assess documentation requirements for knowledge transfer

### Proven Patterns
- Verify the design leverages well-established patterns over novel approaches
- Check for existing internal solutions that could be reused or extended
- Look for unnecessary reinvention where off-the-shelf solutions exist
- Assess whether deviations from standard patterns are justified

## Output Format

Report findings with strength ratings:

| Strength | Description |
|----------|-------------|
| Strong | Highly practical, proven approach with low risk |
| Moderate | Feasible with some concerns or trade-offs to manage |
| Weak | Significant feasibility risks or unrealistic assumptions |
| Neutral | Insufficient information to assess practicality |
