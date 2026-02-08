---
name: debug-reproduction
description: >-
  Bug reproduction and isolation investigation. Apply when attempting to
  reproduce intermittent bugs, isolate trigger conditions, create minimal
  reproduction cases, and verify consistency.
user-invocable: false
---

# Reproduction Specialist Investigation

Investigate bug reproduction to isolate triggers and create minimal, consistent reproduction cases.

## Investigation Checklist

### Trigger Isolation
- Identify the minimal set of inputs that trigger the bug
- Check for specific ordering or timing requirements to reproduce
- Verify which user actions or API calls are necessary preconditions
- Look for environmental triggers such as load, memory, or timing
- Determine if the bug requires specific data patterns or edge cases

### Minimal Reproduction
- Strip away unrelated code and configuration to isolate the bug
- Create a self-contained test case that demonstrates the failure
- Verify the reproduction case fails for the same reason as the original
- Remove dependencies one by one to find the minimal trigger set
- Document exact steps from clean state to observed failure

### Environment Reproduction
- Verify the bug reproduces across different machines and OS versions
- Check if specific runtime versions or configurations are required
- Test with clean versus populated state to isolate data dependency
- Identify whether the bug requires specific hardware or resource limits
- Verify network conditions or external service states needed to trigger

### Consistency Verification
- Run the reproduction case multiple times to measure failure rate
- Identify whether the bug is deterministic or intermittent
- Check for timing windows that make reproduction unreliable
- Verify that the reproduction case fails for the right reason
- Confirm the expected behavior by running against a known-good version

## Output Format

Report findings with confidence ratings:

| Confidence | Description |
|------------|-------------|
| High | Root cause clearly identified with supporting evidence |
| Medium | Probable cause identified but needs verification |
| Low | Hypothesis formed but insufficient evidence |
| Inconclusive | Unable to determine from available information |
