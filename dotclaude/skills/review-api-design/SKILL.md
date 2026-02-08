---
name: review-api-design
description: >-
  API design and contract-focused code review. Apply when reviewing
  REST APIs, GraphQL schemas, SDK interfaces, public function signatures,
  versioning, backward compatibility, and API documentation.
user-invocable: false
---

# API Design Review

Review code from an API design and contract perspective.

## Review Checklist

### Naming & Consistency
- Verify endpoint/method naming follows conventions
- Check parameter naming is clear and unambiguous
- Ensure consistent patterns across similar endpoints
- Verify HTTP methods match semantics (GET=read, POST=create, etc.)

### Request & Response Design
- Check request payloads are minimal and well-structured
- Verify response shapes are consistent across endpoints
- Ensure pagination is implemented for list endpoints
- Check filtering/sorting capabilities where needed

### Error Responses
- Verify error response format is consistent and documented
- Check HTTP status codes are semantically correct
- Ensure error messages are helpful without leaking internals
- Verify validation errors include field-level detail

### Versioning & Compatibility
- Check for breaking changes to existing contracts
- Verify backward compatibility is maintained
- Look for required fields that should be optional
- Check deprecation is properly signaled

### Documentation & Discoverability
- Verify API documentation is accurate and complete
- Check request/response examples are provided
- Ensure required vs optional parameters are clear
- Verify authentication/authorization requirements are documented

### Rate Limiting & Quotas
- Check rate limiting is applied to public endpoints
- Verify appropriate limits for different client tiers
- Ensure rate limit headers are included in responses
- Check bulk endpoints have payload size limits

## Output Format

| Category | Description |
|----------|-------------|
| Breaking | Change breaks existing clients |
| Design | API design issue affecting usability |
| Contract | Missing or ambiguous contract definition |
| Enhancement | Improvement for better developer experience |
