---
name: migration-team
description: Agent Teamsで技術移行の並列実行チームを自動構成・起動
argument-hint: "[--pr N | --diff | migration target]"
user-invocable: true
disable-model-invocation: true
---

# Migration Team

Create an Agent Team with automatically selected migration specialists based on the migration type.

## Instructions

1. **Analyze the migration scope** to determine the technology transition type
2. **Select appropriate specialists** based on the selection matrix below
3. **Create the agent team** with only the selected specialists
4. Have them coordinate to produce a phased migration plan and execute transformations

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

## Step 1: Migration Analysis

Before spawning any teammates, analyze the migration scope to determine its type:

| Signal | Type |
|--------|------|
| Version upgrade of runtime, compiler, or language (e.g., Java 11 to 17, Python 2 to 3) | Language/Runtime |
| Framework or library upgrade/replacement (e.g., React 17 to 18, Angular to React, Koin to Hilt) | Framework/Library |
| Protocol change (e.g., REST to GraphQL, SOAP to REST, HTTP to gRPC) | API Protocol |
| Database engine or ORM change (e.g., MySQL to PostgreSQL, Room to SQLDelight) | Database |
| Build system or tooling change (e.g., Gradle to Bazel, Webpack to Vite, npm to pnpm) | Build/Tooling |
| Cloud or infrastructure change (e.g., EC2 to ECS, Heroku to AWS, monolith to microservices) | Infrastructure |
| Mixed signals | Analyze dominant patterns and apply multiple types |

## Step 2: Specialist Selection Matrix

| Specialist | Language/Runtime | Framework/Library | API Protocol | Database | Build/Tooling | Infrastructure |
|:-----------|:----------------:|:-----------------:|:------------:|:--------:|:-------------:|:--------------:|
| Breaking Change Analyst | Always | Always | Always | Always | Always | Always |
| Compatibility Bridge Builder | Always | Always | Always | Always | If config change | If config change |
| Code Transformer | Always | Always | If client code | If query code | If config format | Skip |
| Data Migrator | If serialization | If data format | If schema change | Always | Skip | If state migration |
| Test Migrator | Always | Always | Always | Always | Always | If test infra |
| Rollback Planner | Always | Always | Always | Always | Always | Always |
| Dependency Resolver | Always | Always | If protocol deps | If driver change | Always | Always |

### Selection Rules

- **Always**: Spawn this specialist unconditionally
- **Skip**: Do not spawn this specialist
- **Conditional**: Spawn only if the condition is met based on migration analysis

When uncertain, **include the specialist** (prefer safety over speed).

## Step 3: Team Creation

Spawn only the selected specialists with their specialized prompts:

1. **Breaking Change Analyst**: Catalog all breaking changes between source and target versions, APIs, and behaviors. Produce a comprehensive inventory of incompatible changes, deprecated features, removed APIs, and behavioral differences with impact assessment for each item.

2. **Compatibility Bridge Builder**: Create compatibility layers, adapters, and shims to enable incremental migration. Design abstractions that allow old and new code to coexist, enabling a gradual rollout rather than a big-bang switch.

3. **Code Transformer**: Perform automated code transformations using codemods, search-replace, and AST-based rewrites. Handle syntax changes, API renames, import path updates, and pattern replacements systematically across the codebase.

4. **Data Migrator**: Handle data format changes, schema migrations, serialization updates, and data validation. Create migration scripts for database schemas, configuration files, stored data formats, and ensure data integrity throughout the transition.

5. **Test Migrator**: Update test code, test utilities, mocks, and assertions to match the new technology. Adapt test frameworks, update test helpers, fix broken assertions, and ensure test coverage is maintained or improved after migration.

6. **Rollback Planner**: Design rollback procedures, feature flags, and safe fallback paths for each migration phase. Create step-by-step rollback instructions, define rollback triggers and criteria, and ensure every change can be safely reverted.

7. **Dependency Resolver**: Resolve dependency conflicts, version incompatibilities, and transitive dependency issues. Analyze the dependency tree, identify conflicting versions, find compatible version ranges, and handle peer dependency requirements.

## Workflow

1. Lead analyzes the migration scope and creates a phased plan
2. Each specialist works on their migration stream in parallel
3. Specialists coordinate on integration points and conflict resolution
4. Lead orchestrates verification and produces a migration status report with:
   - Completed transformations and their verification status
   - Remaining manual changes requiring human intervention
   - Rollback instructions for each completed phase
   - Verification checklist for post-migration validation

## Output

The lead produces a final migration status report including:
- Migration type detected and specialists selected (with reasoning)
- Phased migration plan with dependency ordering
- Completed transformations with verification results
- Remaining manual changes with detailed instructions
- Rollback procedures for each migration phase
- Verification checklist for post-migration validation
- Known risks and mitigation strategies
