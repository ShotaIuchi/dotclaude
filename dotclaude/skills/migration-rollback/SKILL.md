---
name: migration-rollback
description: >-
  Rollback planning for migrations. Apply when designing rollback procedures,
  feature flags, safe fallback paths, rollback triggers, and step-by-step
  revert instructions.
user-invocable: false
---

# Rollback Planning

Design safe rollback procedures for migration.

## Migration Checklist

### Rollback Procedures
- Define step-by-step revert instructions for each migration phase
- Verify rollback scripts restore previous state completely
- Ensure rollback can be performed without data loss
- Document estimated rollback time and required resources

### Feature Flags & Toggles
- Implement feature flags to enable gradual rollout
- Verify flags can disable new behavior without redeployment
- Check that flag state is consistent across all services
- Ensure flag cleanup plan exists after migration completes

### Rollback Triggers
- Define measurable criteria that trigger automatic rollback
- Set up monitoring alerts for error rate and latency spikes
- Establish clear escalation path when triggers are hit
- Verify rollback can be initiated both manually and automatically

### Recovery Verification
- Validate system health after rollback execution
- Confirm data consistency between rolled-back components
- Run smoke tests to verify core functionality is restored
- Check that dependent systems are notified of rollback

## Output Format

Report findings with risk ratings:

| Risk | Description |
|------|-------------|
| Critical | No rollback path exists, migration is irreversible |
| High | Rollback possible but may cause data inconsistency |
| Medium | Rollback requires manual steps but is achievable |
| Low | Clean rollback with automated procedures available |
