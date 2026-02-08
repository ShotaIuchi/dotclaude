---
name: design-user-advocate
description: >-
  User-centric design analysis. Apply when evaluating design proposals for
  end-user experience, developer experience, API usability, accessibility,
  and consumer satisfaction.
user-invocable: false
---

# User Advocate Perspective

Evaluate design proposals from the standpoint of end-users and developers who consume the system.

## Analysis Checklist

### End-User Impact
- Assess whether the design improves or degrades the user experience
- Check that latency and responsiveness targets meet user expectations
- Verify that error states provide clear, actionable feedback to users
- Look for user-facing regressions introduced by the design change
- Confirm that user workflows remain intuitive and efficient

### Developer Experience
- Evaluate the onboarding complexity for developers new to the codebase
- Check that APIs and interfaces are self-documenting and discoverable
- Verify that debugging and local development workflows are preserved
- Assess whether the design increases or reduces cognitive load for contributors

### API Ergonomics
- Check that API naming follows conventions and is predictable
- Verify that common operations are simple and advanced ones are possible
- Assess whether error responses are informative and consistent
- Look for unnecessary boilerplate or ceremony in typical usage patterns

### Accessibility & Inclusivity
- Verify that the design accommodates assistive technologies
- Check for assumptions about user connectivity, device, or locale
- Assess whether internationalization and localization are supported
- Look for design decisions that exclude users with disabilities

## Output Format

Report findings with strength ratings:

| Strength | Description |
|----------|-------------|
| Strong | Excellent user and developer experience throughout |
| Moderate | Acceptable experience with some usability friction |
| Weak | Poor experience or significant accessibility gaps |
| Neutral | Insufficient information to assess user impact |
