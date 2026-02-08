---
name: team-refactor
description: Agent Teamsで大規模リファクタリングチームを自動構成・起動
argument-hint: "[--pr N | --commit REF | --diff | --staged | path | goal]"
user-invocable: true
disable-model-invocation: true
---

# Refactor Team

Create an Agent Team with automatically selected specialists based on the refactoring target and goal.

## Instructions

1. **Analyze the target** (file, directory, or refactoring goal) to determine the refactoring type
2. **Select appropriate specialists** based on the selection matrix below
3. **Create the agent team** with only the selected specialists
4. Have them share findings and produce a comprehensive refactoring plan

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

## Step 1: Codebase Analysis

Before spawning any teammates, analyze the target to determine the refactoring type:

| Signal | Type |
|--------|------|
| Extracting classes/functions, splitting modules, decomposing monoliths | Extract/Split |
| Renaming symbols, moving files, reorganizing directory structure | Rename/Restructure |
| Replacing patterns (e.g., callbacks to async/await, inheritance to composition) | Pattern Change |
| Updating libraries, frameworks, or language versions | Dependency Update |
| Optimizing hot paths, reducing memory usage, improving throughput | Performance |
| Mixed signals | Analyze dominant patterns and apply multiple types |

## Step 2: Specialist Selection Matrix

| Specialist | Extract/Split | Rename/Restructure | Pattern Change | Dependency Update | Performance |
|:-----------|:------------:|:------------------:|:--------------:|:-----------------:|:-----------:|
| Dependency Mapper | Always | Always | Always | Always | Always |
| Code Archeologist | Always | Always | Always | If legacy | If legacy |
| Pattern Analyst | Always | If pattern-related | Always | Skip | If algorithmic |
| Migration Planner | If breaking changes | Always | Always | Always | Skip |
| Test Guardian | Always | Always | Always | Always | Always |
| Impact Assessor | Always | Always | Always | Always | Always |
| Compatibility Checker | If public API | If public API | If public API | Always | Skip |

### Selection Rules

- **Always**: Spawn this specialist unconditionally
- **Skip**: Do not spawn this specialist
- **Conditional**: Spawn only if the condition is met based on code analysis

When uncertain, **include the specialist** (prefer thoroughness over efficiency).

## Step 3: Team Creation

Spawn only the selected specialists using the **Task tool** (`subagent_type: "general-purpose"`).

**Execution Rules:**
- Send ALL Task tool calls in a **single message** for parallel execution
- Each subagent runs in its own context and returns findings to the lead (main context)
- Provide each subagent with the full target context (refactoring scope, file contents, etc.) in the prompt
- The lead (main context) is responsible for synthesis — do NOT spawn a subagent for synthesis

1. **Dependency Mapper**: Map all dependencies, import chains, call graphs, and coupling relationships for the target code. Identify tightly coupled modules, circular dependencies, and hidden connections that could break during refactoring.

2. **Code Archeologist**: Research the history of the code, understand why decisions were made, and identify hidden constraints. Use git blame, commit messages, and code comments to uncover rationale that must be preserved.

3. **Pattern Analyst**: Identify current design patterns, anti-patterns, and recommend target patterns for the refactoring. Evaluate whether proposed patterns fit the codebase's conventions and team's familiarity.

4. **Migration Planner**: Create a step-by-step migration plan that ensures each step leaves the codebase in a working state. Define rollback points, feature flags, and incremental delivery milestones.

5. **Test Guardian**: Verify existing test coverage, identify gaps, and ensure tests will catch regressions during refactoring. Recommend additional tests needed before starting and verification checkpoints throughout.

6. **Impact Assessor**: Analyze the blast radius of changes, identify affected consumers, and assess risk levels. Categorize impacts by severity and likelihood, and flag areas requiring extra caution.

7. **Compatibility Checker**: Verify backward compatibility for public APIs, exported interfaces, and external contracts. Identify breaking changes and propose compatibility shims or migration guides for consumers.

## Workflow

1. Lead analyzes the codebase and defines the refactoring scope, announcing selected specialists with reasoning
2. Each selected specialist analyzes the target from their specialized perspective
3. Specialists share findings with each other to build a comprehensive understanding
4. The lead synthesizes all findings into a safe, incremental refactoring plan:
   - Dependency map showing affected modules and their relationships
   - Risk assessment with severity and likelihood ratings
   - Step-by-step execution order with rollback points
   - Test verification checkpoints between each major step

## Output

The lead produces a final refactoring plan including:
- Refactoring type detected and specialists selected (with reasoning)
- Dependency map of affected code
- Risk assessment matrix
- Ordered execution steps with rollback strategy
- Test verification checkpoints
