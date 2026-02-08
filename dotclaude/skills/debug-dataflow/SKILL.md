---
name: debug-dataflow
description: >-
  Data flow tracing investigation. Apply when debugging data transformation
  errors, boundary conditions, type conversions, null propagation, and
  unexpected data mutations.
user-invocable: false
---

# Data Flow Tracer Investigation

Trace data through transformation pipelines to identify where values become incorrect or unexpected.

## Investigation Checklist

### Input Validation Trail
- Verify inputs are validated at the entry point before processing
- Check for missing validation on optional or nullable fields
- Identify inputs that bypass validation through alternative paths
- Verify boundary values are handled correctly at each stage
- Look for implicit assumptions about input format or encoding

### Transformation Chain
- Trace data through each transformation step end to end
- Identify steps where data shape or structure changes unexpectedly
- Check for lossy transformations that discard significant information
- Verify mapping functions handle all possible input variants
- Look for order-dependent transformations applied inconsistently

### Type Coercion
- Identify implicit type conversions that alter data semantics
- Check for precision loss in numeric type widening or narrowing
- Verify string-to-number and number-to-string conversions are safe
- Look for truthy/falsy coercion that changes boolean logic
- Detect encoding mismatches in string or byte conversions

### Null/Undefined Propagation
- Trace null values from origin through all downstream consumers
- Check for missing null guards at function boundaries
- Identify optional chaining gaps that allow null to propagate
- Verify default value assignments handle all falsy cases correctly
- Look for null coalescing that masks legitimate null signals

## Output Format

Report findings with confidence ratings:

| Confidence | Description |
|------------|-------------|
| High | Root cause clearly identified with supporting evidence |
| Medium | Probable cause identified but needs verification |
| Low | Hypothesis formed but insufficient evidence |
| Inconclusive | Unable to determine from available information |
