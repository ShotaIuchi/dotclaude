---
name: refactor-dependency
description: >-
  Dependency mapping and analysis for refactoring. Apply when mapping
  import chains, call graphs, coupling relationships, circular dependencies,
  and hidden connections in target code.
user-invocable: false
---

# Dependency Mapper Analysis

Map all dependencies, import chains, call graphs, and coupling relationships for the refactoring target.

## Analysis Checklist

### Import Chain Analysis
- Trace all direct and transitive imports from the target code
- Identify shared dependencies across multiple modules
- Check for re-exports that create indirect coupling
- Map import depth to detect deeply nested dependency chains

### Call Graph Mapping
- Build function/method call graphs for the target scope
- Identify entry points and terminal nodes
- Detect callback chains and event-driven connections
- Map data flow through function parameters and return values

### Coupling Assessment
- Measure afferent coupling (who depends on this code)
- Measure efferent coupling (what this code depends on)
- Identify connascence types (name, type, meaning, position, algorithm)
- Check for hidden coupling through shared mutable state or globals

### Circular Dependency Detection
- Detect direct circular imports between modules
- Find indirect cycles through transitive dependencies
- Identify bidirectional data flow between layers
- Check for initialization-order dependencies that mask cycles

### Dependency Health Metrics
- Calculate instability ratio for each module in scope
- Identify modules that violate the stable dependencies principle
- Check for unnecessary dependencies that could be removed
- Assess dependency freshness and maintenance status

## Output Format

Report findings with impact ratings:

| Impact | Description |
|--------|-------------|
| Breaking | Dependency that will break if changed without coordination |
| High | Tightly coupled dependency requiring careful migration |
| Medium | Moderate coupling that should be addressed during refactoring |
| Low | Loose coupling, safe to change independently |
