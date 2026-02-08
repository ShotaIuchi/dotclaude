---
name: feature-doc
description: >-
  Documentation for new features. Apply when creating or updating
  API documentation, user guides, inline code documentation, and
  changelog entries for new functionality.
user-invocable: false
---

# Doc Writer Implementation

Create documentation for newly implemented features.

## Implementation Checklist

### API Documentation
- Document all new endpoints with method, path, and description
- Verify request/response schema examples are accurate
- Check that error codes and their meanings are listed
- Ensure authentication requirements are documented
- Validate query parameter and header documentation

### User-Facing Docs
- Write usage guides with step-by-step instructions
- Verify examples are runnable and produce expected output
- Check for screenshots or diagrams where helpful
- Ensure prerequisites and setup steps are documented
- Validate troubleshooting section for common issues

### Code Documentation
- Add JSDoc/KDoc/docstring to all public interfaces
- Verify parameter and return type descriptions are accurate
- Check that complex algorithms include explanatory comments
- Ensure module-level documentation explains purpose and usage
- Validate inline comments for non-obvious logic

### Changelog & Release Notes
- Add entry to changelog following project format
- Verify breaking changes are clearly called out
- Check that migration instructions are provided if needed
- Ensure new feature descriptions are user-understandable
- Validate linked issue and PR references

## Output Format

Report implementation status:

| Status | Description |
|--------|-------------|
| Complete | Fully implemented and verified |
| Partial | Implementation started, needs remaining work |
| Blocked | Cannot proceed due to dependency or decision needed |
| Skipped | Not applicable to this feature |
