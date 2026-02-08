---
name: design-domain
description: >-
  Domain-specific design analysis. Apply when evaluating design proposals
  against industry best practices, reference architectures, known pitfalls,
  and domain-specific constraints.
user-invocable: false
---

# Domain Expert Perspective

Evaluate design proposals against industry knowledge and domain best practices.

## Analysis Checklist

### Domain Alignment
- Verify the design models core domain concepts accurately
- Check that ubiquitous language is used consistently across the proposal
- Assess whether bounded contexts are properly identified and separated
- Look for domain logic scattered outside the core domain layer
- Confirm that domain invariants are enforced at the appropriate level

### Reference Architectures
- Compare the proposal against established reference architectures
- Check for proven patterns applicable to this specific problem domain
- Verify that deviations from standard approaches are justified
- Assess whether case studies from similar systems support the design

### Industry Pitfalls
- Identify known anti-patterns specific to this domain
- Check for common failure modes seen in similar production systems
- Verify that lessons learned from public post-mortems are applied
- Look for scaling issues that are well-documented in the domain

### Regulatory & Compliance
- Check that data handling meets relevant regulatory requirements
- Verify audit trail and traceability requirements are addressed
- Assess whether retention and deletion policies are accounted for
- Look for jurisdiction-specific constraints that affect the design

## Output Format

Report findings with strength ratings:

| Strength | Description |
|----------|-------------|
| Strong | Well-aligned with domain best practices and standards |
| Moderate | Generally sound with some domain-specific gaps |
| Weak | Misaligned with established domain patterns or regulations |
| Neutral | Insufficient domain context to assess alignment |
