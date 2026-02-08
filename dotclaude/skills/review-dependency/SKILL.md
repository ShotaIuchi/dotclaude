---
name: review-dependency
description: >-
  Dependency and supply chain-focused code review. Apply when reviewing
  library additions, version upgrades, license compliance, known vulnerabilities,
  dependency size, transitive dependencies, and lock files.
user-invocable: false
---

# Dependency Review

Review code from a dependency and supply chain security perspective.

## Review Checklist

### Vulnerability Assessment
- Check new dependencies for known CVEs
- Verify dependency versions are not end-of-life
- Look for dependencies with poor maintenance (no recent updates)
- Check for typosquatting risks on package names

### License Compliance
- Verify license compatibility with project license
- Check for copyleft licenses (GPL) in proprietary projects
- Look for license changes in version upgrades
- Ensure license attribution requirements are met

### Dependency Size & Impact
- Check if new dependency is justified (vs implementing directly)
- Verify dependency size impact on build/bundle
- Look for lighter alternatives for simple functionality
- Check transitive dependency tree for bloat

### Version Management
- Verify version pinning strategy is consistent
- Check lock files are updated and committed
- Look for wildcard version ranges that allow breaking changes
- Verify compatibility between related dependency versions

### Supply Chain Security
- Check dependency source is official (not fork or mirror)
- Verify package integrity (checksums, signatures)
- Look for post-install scripts that execute arbitrary code
- Check for dependencies that request excessive permissions

### Update Strategy
- Verify automated vulnerability scanning is configured
- Check major version upgrades include migration review
- Ensure deprecated APIs are not used in new code
- Verify upgrade path exists for critical dependencies

## Output Format

| Risk | Description |
|------|-------------|
| Critical | Known vulnerability or license violation |
| High | Unmaintained dependency or major risk |
| Medium | Version management issue or unnecessary dependency |
| Low | Minor improvement to dependency hygiene |
