---
name: migration-data
description: >-
  Data migration and schema changes. Apply when handling database schema
  migrations, data format conversions, serialization updates, configuration
  migration, and data integrity verification.
user-invocable: false
---

# Data Migration

Handle data and schema migrations safely.

## Migration Checklist

### Schema Migration
- Define forward and reverse schema migration scripts
- Verify schema changes are backward compatible where needed
- Check for data type changes that may cause truncation or loss
- Ensure index and constraint updates are included

### Data Format Conversion
- Identify all serialization format changes
- Implement data transformation for existing records
- Verify date, time, and locale format compatibility
- Check for encoding changes affecting stored data

### Configuration Migration
- Map old configuration keys to new equivalents
- Provide default values for newly required settings
- Validate migrated configuration against new schema
- Ensure environment-specific overrides are preserved

### Data Integrity
- Verify referential integrity after migration
- Run checksums or row counts to confirm completeness
- Check for orphaned records or dangling references
- Validate business logic constraints on migrated data

## Output Format

Report findings with risk ratings:

| Risk | Description |
|------|-------------|
| Critical | Data loss or corruption possible, blocks migration |
| High | Data integrity at risk, requires careful validation |
| Medium | Format change may affect downstream consumers |
| Low | Minor configuration update, low risk of issues |
