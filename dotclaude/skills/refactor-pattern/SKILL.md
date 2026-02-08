---
name: refactor-pattern
description: >-
  Design pattern analysis for refactoring. Apply when identifying current
  patterns, anti-patterns, recommending target patterns, and evaluating
  pattern fit with codebase conventions.
user-invocable: false
---

# Pattern Analyst Analysis

Identify current design patterns and anti-patterns, and recommend target patterns for the refactoring.

## Analysis Checklist

### Current Pattern Identification
- Classify design patterns in use (creational, structural, behavioral)
- Map how patterns interact across module boundaries
- Identify implicit patterns not formally documented
- Check pattern consistency across similar components

### Anti-Pattern Detection
- Detect god classes or functions with too many responsibilities
- Find feature envy (methods using other class data excessively)
- Identify shotgun surgery (changes requiring edits in many places)
- Look for primitive obsession and data clumps

### Target Pattern Selection
- Recommend patterns that match the refactoring goal
- Evaluate pattern fit with existing codebase conventions
- Consider team familiarity and learning curve
- Assess pattern complexity vs benefit tradeoff

### Pattern Migration Path
- Define steps to transform current pattern to target pattern
- Identify intermediate states that remain functional
- Check for pattern conflicts during transition
- Verify the target pattern supports future extensibility

### Codebase Convention Alignment
- Check consistency with patterns used elsewhere in the project
- Verify naming conventions match the target pattern idioms
- Ensure error handling style aligns with project standards
- Validate that the target pattern fits the project's testing approach

## Output Format

Report findings with impact ratings:

| Impact | Description |
|--------|-------------|
| Breaking | Anti-pattern causing active defects or blocking changes |
| High | Pattern mismatch creating significant maintenance burden |
| Medium | Suboptimal pattern that should improve with migration |
| Low | Minor pattern inconsistency, cosmetic improvement |
