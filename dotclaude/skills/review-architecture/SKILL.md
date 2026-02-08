---
name: review-architecture
description: >-
  Architecture-focused code review. Apply when reviewing code for
  design patterns, SOLID principles, layer separation, dependency direction,
  modularity, coupling, cohesion, and maintainability.
user-invocable: false
---

# Architecture Review

Review code from an architecture and design perspective.

## Review Checklist

### SOLID Principles
- Single Responsibility: Each class/module has one reason to change
- Open/Closed: Extended via abstraction, not modification
- Liskov Substitution: Subtypes are substitutable for base types
- Interface Segregation: No forced dependency on unused interfaces
- Dependency Inversion: Depend on abstractions, not concretions

### Layer Separation
- Verify proper separation of concerns (UI / Domain / Data)
- Check dependency direction (inner layers don't depend on outer)
- Look for business logic leaking into UI or data layers
- Verify data mapping between layers (Entity / Model / DTO)

### Modularity & Coupling
- Check for tight coupling between unrelated modules
- Verify proper use of dependency injection
- Look for god classes or modules with too many responsibilities
- Check for circular dependencies

### Consistency & Patterns
- Verify consistency with existing codebase patterns
- Check naming conventions are followed
- Look for reinvented patterns where existing utilities exist
- Verify error handling follows project conventions

### Extensibility & Maintainability
- Check if changes are easy to extend without modification
- Verify testability (dependencies are injectable)
- Look for hardcoded values that should be configurable
- Check documentation for complex logic

## Output Format

Report findings with categories:

| Category | Description |
|----------|-------------|
| Violation | Breaks established architecture rules |
| Concern | May cause problems as codebase grows |
| Suggestion | Improvement for better maintainability |
| Positive | Good pattern worth highlighting |
