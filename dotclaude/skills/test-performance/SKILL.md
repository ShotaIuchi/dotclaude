---
name: test-performance
description: >-
  Performance test creation. Apply when writing benchmarks, load tests,
  performance regression tests, measuring execution time, memory allocation,
  and throughput under load.
user-invocable: false
---

# Performance Tests

Write performance tests that measure and guard against performance regressions.

## Test Creation Checklist

### Benchmark Design
- Establish clear metrics (latency, throughput, memory) for each benchmark
- Use warm-up iterations to eliminate JIT and cache cold-start effects
- Run sufficient iterations for statistically significant results
- Isolate benchmarked code from measurement overhead
- Document hardware and environment assumptions for reproducibility

### Load Testing
- Define realistic load profiles based on production traffic patterns
- Test with sustained load, spike patterns, and gradual ramp-up
- Measure response time percentiles (p50, p95, p99) under load
- Verify graceful degradation when load exceeds capacity
- Check resource utilization (CPU, memory, connections) during load

### Memory & Resource Profiling
- Measure allocation rates for hot code paths
- Detect memory leaks by monitoring heap growth over time
- Check for unclosed resources (file handles, connections, streams)
- Verify garbage collection pause times remain acceptable
- Profile object retention to identify unnecessary caching

### Regression Baselines
- Capture baseline metrics from stable release builds
- Define acceptable variance thresholds for each metric
- Automate comparison between current and baseline results
- Alert on regressions exceeding defined thresholds
- Store historical performance data for trend analysis

## Output Format

Report test plan with priority ratings:

| Priority | Description |
|----------|-------------|
| Must | Benchmarks for critical hot paths and SLA-bound operations |
| Should | Load tests covering primary user-facing workflows |
| Could | Profiling for optimization candidates and memory analysis |
| Won't | Micro-benchmarks with negligible real-world impact |
