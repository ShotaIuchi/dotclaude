---
name: feature-data
description: >-
  Data modeling and schema design. Apply when designing database
  schemas, migrations, relationships, indexes, data access patterns,
  and storage strategies for new features.
user-invocable: false
---

# Data Modeler Implementation

Design data models and schemas for new features.

## Implementation Checklist

### Schema Design
- Define tables/collections with appropriate column types
- Verify naming conventions follow project standards
- Check for proper normalization or denormalization decisions
- Ensure default values and nullability are correct
- Validate enum types and domain constraints

### Relationships & Constraints
- Define foreign keys and referential integrity rules
- Verify cascade behavior for updates and deletes
- Check for proper unique constraints and composite keys
- Ensure many-to-many relationships use join tables
- Validate orphan record prevention

### Migration Strategy
- Create reversible migration scripts
- Verify zero-downtime migration compatibility
- Check data backfill requirements for new columns
- Ensure migration ordering and dependency resolution
- Validate rollback procedures and data safety

### Query Optimization
- Define indexes for common query patterns
- Verify query plans for critical access paths
- Check for efficient join strategies
- Ensure pagination uses cursor or keyset approach
- Validate bulk operation performance

## Output Format

Report implementation status:

| Status | Description |
|--------|-------------|
| Complete | Fully implemented and verified |
| Partial | Implementation started, needs remaining work |
| Blocked | Cannot proceed due to dependency or decision needed |
| Skipped | Not applicable to this feature |
