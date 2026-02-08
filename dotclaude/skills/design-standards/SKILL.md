---
name: design-standards
description: >-
  Standards compliance design analysis. Apply when evaluating design proposals
  for coding standards, architectural guidelines, organizational conventions,
  and consistency with existing patterns.
user-invocable: false
---

# Standards Keeper Perspective

Evaluate design proposals for compliance with established standards and conventions.

## Analysis Checklist

### Coding Standards
- Verify that the design follows project naming conventions and style guides
- Check that code organization matches established module structure
- Assess whether documentation standards are met for public interfaces
- Look for deviations from agreed error handling and logging patterns
- Confirm that test structure and coverage requirements are addressed

### Architectural Guidelines
- Check that the design respects established layer boundaries
- Verify that communication patterns match the agreed architecture style
- Assess whether new dependencies align with the approved technology stack
- Look for violations of dependency direction rules

### Organizational Conventions
- Verify that the design follows team-agreed review and approval processes
- Check that configuration management practices are maintained
- Assess whether deployment conventions and environment parity are preserved
- Look for deviations from established branching and release strategies

### Consistency Verification
- Compare the proposal against existing similar implementations in the codebase
- Check that shared utilities and libraries are reused rather than duplicated
- Verify that API response formats and error codes are consistent
- Assess whether the design introduces conflicting patterns

## Output Format

Report findings with strength ratings:

| Strength | Description |
|----------|-------------|
| Strong | Fully compliant with all applicable standards |
| Moderate | Mostly compliant with minor deviations justified |
| Weak | Significant standards violations or inconsistencies |
| Neutral | No applicable standards defined for this area |
