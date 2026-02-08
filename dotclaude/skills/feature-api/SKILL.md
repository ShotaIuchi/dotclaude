---
name: feature-api
description: >-
  API design and implementation. Apply when designing endpoints,
  request/response schemas, error handling, versioning, rate limiting,
  and integration contracts for new features.
user-invocable: false
---

# API Designer Implementation

Design and implement API endpoints for new features.

## Implementation Checklist

### Endpoint Design
- Define RESTful resource paths and HTTP methods
- Verify consistent naming conventions across endpoints
- Check for proper use of query parameters vs path parameters
- Ensure idempotency for PUT/DELETE operations
- Validate rate limiting and throttling configuration

### Request/Response Schema
- Define clear request body schemas with required/optional fields
- Ensure response envelopes follow project conventions
- Verify pagination structure for collection endpoints
- Check for consistent date/time formats and data types
- Validate content negotiation headers

### Error Handling
- Define standard error response format with error codes
- Ensure proper HTTP status code usage (4xx vs 5xx)
- Verify descriptive error messages without leaking internals
- Check for consistent error handling across all endpoints
- Validate retry-safe error classifications

### Versioning & Compatibility
- Verify API versioning strategy is applied
- Check backward compatibility with existing clients
- Ensure deprecation notices for changed endpoints
- Validate migration path for breaking changes
- Check integration contract tests with consumers

## Output Format

Report implementation status:

| Status | Description |
|--------|-------------|
| Complete | Fully implemented and verified |
| Partial | Implementation started, needs remaining work |
| Blocked | Cannot proceed due to dependency or decision needed |
| Skipped | Not applicable to this feature |
