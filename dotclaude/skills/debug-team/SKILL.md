---
name: debug-team
description: Agent Teamsでバグ原因の並列仮説検証チームを自動構成・起動
argument-hint: "[--issue N | --pr N | --commit REF | --diff | path | text]"
user-invocable: true
disable-model-invocation: true
---

# Debug Team

Create an Agent Team with automatically selected investigators to analyze and identify root causes of bugs through parallel hypothesis verification.

## Instructions

1. **Analyze the bug** (error message, stack trace, file, or issue) to understand the symptom
2. **Generate hypotheses** for multiple independent root causes
3. **Select appropriate investigators** based on the selection matrix below
4. **Create the agent team** with only the selected investigators
5. Have them share evidence and produce a consolidated root cause analysis

## Step 0: Scope Detection

Parse `$ARGUMENTS` to determine the analysis target.
See `references/agent-team/scope-detection.md` for full detection rules.

| Flag | Scope | Action |
|------|-------|--------|
| `--pr <N>` | PR | `gh pr diff <N>` + `gh pr view <N> --json title,body,files` |
| `--issue <N>` | Issue | `gh issue view <N> --json title,body,comments` |
| `--commit <ref>` | Commit | `git show <ref>` or `git diff <range>` |
| `--diff` | Unstaged changes | `git diff` |
| `--staged` | Staged changes | `git diff --staged` |
| `--branch <name>` | Branch diff | `git diff main...<name>` |
| Path pattern | File/Directory | `Glob` + `Read` |
| Free text | Description | Use as context for analysis |
| (empty or ambiguous) | Unknown | Ask user to specify target |

## Step 1: Bug Analysis

Before spawning any teammates, analyze the target to determine the bug type:

| Signal | Type |
|--------|------|
| `NullPointerException`, `TypeError`, wrong return values, incorrect conditions | Logic Bug |
| Inconsistent data, stale cache, corrupted state, unexpected side effects | State Bug |
| Intermittent failures, timing-dependent, thread/coroutine issues, deadlocks | Race Condition |
| `OutOfMemoryError`, leaks, high CPU, resource exhaustion, handle leaks | Memory/Resource |
| API failures, serialization errors, version mismatches, protocol errors | Integration |
| Works locally but fails in CI/prod, missing env vars, permission errors | Config/Env |
| Mixed signals | Analyze dominant patterns and apply multiple types |

## Step 2: Hypothesis Generation

Based on the bug analysis, generate 3-7 independent hypotheses for the root cause. Each hypothesis should be:

- Specific and testable
- Independent from other hypotheses (can be verified in parallel)
- Assigned to the most appropriate investigator

## Step 3: Investigator Selection Matrix

| Investigator | Logic Bug | State Bug | Race Condition | Memory/Resource | Integration | Config/Env |
|:-------------|:---------:|:---------:|:--------------:|:---------------:|:-----------:|:----------:|
| Stack Trace Analyzer | Always | Always | Always | Always | Always | Always |
| State Inspector | If stateful | Always | Always | If state-related | If stateful | Skip |
| Concurrency Investigator | Skip | If async | Always | If thread-related | If async | Skip |
| Data Flow Tracer | Always | Always | If data-dependent | Skip | Always | Skip |
| Environment Checker | Skip | Skip | Skip | Skip | If env-dependent | Always |
| Dependency Auditor | If version-related | Skip | Skip | If library-related | Always | Always |
| Reproduction Specialist | Always | Always | Always | Always | Always | Always |

### Selection Rules

- **Always**: Spawn this investigator unconditionally
- **Skip**: Do not spawn this investigator
- **Conditional**: Spawn only if the condition is met based on bug analysis

When uncertain, **include the investigator** (prefer thoroughness over efficiency).

## Step 4: Team Creation

Spawn only the selected investigators with their specialized prompts:

1. **Stack Trace Analyzer**: Analyze error messages, stack traces, exception chains, and error propagation paths to pinpoint failure locations.

2. **State Inspector**: Examine application state, variable values, data structures, and state transitions to find unexpected state corruption.

3. **Concurrency Investigator**: Check for race conditions, deadlocks, thread safety issues, shared mutable state, and timing-dependent bugs.

4. **Data Flow Tracer**: Trace data from input to failure point, checking transformations, boundary conditions, type conversions, and null propagation.

5. **Environment Checker**: Verify configuration, environment variables, file permissions, network connectivity, and platform-specific behaviors.

6. **Dependency Auditor**: Check dependency versions, breaking changes, incompatibilities, known bugs in libraries, and transitive dependency conflicts.

7. **Reproduction Specialist**: Attempt to identify minimal reproduction steps, isolate the trigger conditions, and verify the bug is consistent.

## Workflow

1. Lead analyzes the bug symptoms and generates hypotheses
2. Each selected investigator pursues their hypothesis independently
3. Investigators share evidence and cross-validate findings
4. Lead synthesizes a root cause analysis with confidence levels:
   - High confidence: Strong evidence chain, reproducible
   - Medium confidence: Partial evidence, likely but not proven
   - Low confidence: Hypothesis consistent with symptoms but unverified

## Output

The lead produces a final root cause analysis report including:
- Bug type detected and investigators selected (with reasoning)
- Root cause with confidence level and evidence chain
- Alternative hypotheses considered and their status
- Recommended fix approach with implementation guidance
