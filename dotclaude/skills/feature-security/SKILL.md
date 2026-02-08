---
name: feature-security
description: >-
  Security analysis for new features. Apply when reviewing
  authentication, authorization, input validation, data protection,
  and security best practices in new feature implementations.
user-invocable: false
---

# Security Analyst Implementation

Analyze and verify security aspects of new feature implementations.

## Implementation Checklist

### Authentication & Authorization
- Verify authentication is required on all protected endpoints
- Check role-based access control enforcement
- Ensure token validation and expiration handling
- Validate session management and logout behavior
- Check for privilege escalation vulnerabilities

### Input Validation
- Verify all user inputs are validated and sanitized
- Check for SQL injection prevention (parameterized queries)
- Ensure XSS prevention in rendered user content
- Validate file upload restrictions (type, size, content)
- Check for command injection in system calls

### Data Protection
- Verify sensitive data is encrypted at rest and in transit
- Check that PII is properly masked in logs and responses
- Ensure secrets are not hardcoded or committed to source
- Validate proper use of hashing for passwords and tokens
- Check data retention and deletion compliance

### Security Configuration
- Verify CORS policy is properly configured
- Check security headers (CSP, HSTS, X-Frame-Options)
- Ensure dependency versions have no known vulnerabilities
- Validate error responses do not leak internal details
- Check rate limiting on authentication endpoints

## Output Format

Report implementation status:

| Status | Description |
|--------|-------------|
| Complete | Fully implemented and verified |
| Partial | Implementation started, needs remaining work |
| Blocked | Cannot proceed due to dependency or decision needed |
| Skipped | Not applicable to this feature |
