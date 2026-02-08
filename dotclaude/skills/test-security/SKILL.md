---
name: test-security
description: >-
  Security test creation. Apply when writing tests for authentication,
  authorization, input validation, injection prevention, CSRF protection,
  and data encryption verification.
user-invocable: false
---

# Security Tests

Write security tests that verify authentication, authorization, and data protection.

## Test Creation Checklist

### Authentication Testing
- Verify login succeeds with valid credentials and fails with invalid ones
- Test token expiration, refresh, and revocation flows
- Check multi-factor authentication enforcement and bypass prevention
- Validate session management (creation, timeout, invalidation)
- Test brute-force protection and account lockout mechanisms

### Authorization Boundary Testing
- Verify role-based access control for all protected resources
- Test horizontal privilege escalation (accessing other users' data)
- Test vertical privilege escalation (performing admin-only actions)
- Check authorization enforcement at API layer, not just UI
- Validate that denied requests return no sensitive information in errors

### Injection Prevention
- Test SQL injection with parameterized and raw query inputs
- Verify XSS prevention in all user-generated content rendering
- Check command injection in system call parameters
- Test path traversal in file upload and download operations
- Validate LDAP, XML, and template injection resistance

### Data Protection Verification
- Verify sensitive data encryption at rest and in transit
- Check that secrets are not logged, cached, or exposed in errors
- Test PII masking in logs, exports, and API responses
- Validate secure deletion of sensitive data on user request
- Confirm CORS, CSP, and security header configuration

## Output Format

Report test plan with priority ratings:

| Priority | Description |
|----------|-------------|
| Must | Tests preventing authentication bypass and data exposure |
| Should | Authorization boundary tests for privilege escalation |
| Could | Defense-in-depth tests for secondary attack vectors |
| Won't | Theoretical attacks requiring physical access or insider threat |
