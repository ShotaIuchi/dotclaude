---
name: review-security
description: >-
  Security-focused code review. Apply when reviewing code for vulnerabilities,
  authentication, authorization, input validation, injection attacks,
  CSRF, XSS, secrets exposure, and OWASP Top 10 issues.
user-invocable: false
---

# Security Review

Review code from a security perspective.

## Review Checklist

### Authentication & Authorization
- Verify proper authentication on all endpoints
- Check authorization logic for privilege escalation
- Validate token handling (JWT expiry, refresh, storage)
- Ensure session management is secure

### Input Validation
- Check all user inputs are validated and sanitized
- Verify parameterized queries (no SQL injection)
- Check for command injection vulnerabilities
- Validate file upload handling

### Data Protection
- Ensure secrets are not hardcoded or logged
- Check sensitive data is encrypted at rest and in transit
- Verify PII handling follows best practices
- Check for information leakage in error messages

### OWASP Top 10
- Injection (SQLi, XSS, command injection)
- Broken authentication
- Sensitive data exposure
- XML external entities (XXE)
- Broken access control
- Security misconfiguration
- Cross-site scripting (XSS)
- Insecure deserialization
- Using components with known vulnerabilities
- Insufficient logging and monitoring

## Output Format

Report findings with severity ratings:

| Severity | Description |
|----------|-------------|
| Critical | Exploitable vulnerability, immediate fix required |
| High | Significant risk, fix before merge |
| Medium | Potential risk, should fix soon |
| Low | Minor concern, consider fixing |
| Info | Best practice suggestion |
