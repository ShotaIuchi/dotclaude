---
name: review-team
description: Agent Teamsでターゲットに最適なコードレビューチームを自動構成・起動
argument-hint: "[--pr N | --issue N | --commit REF | --diff | --staged | --branch NAME | path | text]"
user-invocable: true
disable-model-invocation: true
---

# Review Team

Create an Agent Team with automatically selected reviewers based on the target type.

## Instructions

1. **Analyze the target** (PR, file, or directory) to determine the project type
2. **Select appropriate reviewers** based on the selection matrix below
3. **Create the agent team** with only the selected reviewers
4. Have them share findings and produce a consolidated report

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

## Step 1: Target Analysis

Before spawning any teammates, analyze the target to determine its type:

| Signal | Type |
|--------|------|
| `.kt`, `.java`, `build.gradle.kts`, `AndroidManifest.xml`, `android/` | Mobile (Android) |
| `.swift`, `.xcodeproj`, `.xib`, `.storyboard`, `ios/`, `Podfile` | Mobile (iOS) |
| `shared/`, `commonMain/`, `expect/actual`, KMP module structure | Mobile (KMP) |
| `.ts`, `.tsx`, `.jsx`, `.vue`, `.svelte`, `next.config`, `vite.config` | Web Frontend |
| `template.yaml`, `samconfig.toml`, Lambda handlers, API Gateway | Server (AWS SAM) |
| `Dockerfile`, `docker-compose`, REST/GraphQL handlers, `src/api/` | Server (General) |
| `setup.py`, `Cargo.toml`, `go.mod`, `package.json` (no UI) | CLI / Library |
| Mixed signals | Analyze dominant patterns and apply multiple types |

## Step 2: Reviewer Selection Matrix

| Reviewer | Mobile | Server/API | Web Frontend | CLI/Library |
|:---------|:------:|:----------:|:------------:|:-----------:|
| Security | Always | Always | Always | Always |
| Performance | Always | Always | Always | Always |
| Architecture | Always | Always | Always | Always |
| Test Coverage | Always | Always | Always | Always |
| Error Handling | Always | Always | Always | Always |
| Concurrency | Always | Always | If async-heavy | If multi-threaded |
| API Design | If consuming APIs | Always | If building APIs | If public API |
| Accessibility | Always | Skip | Always | Skip |
| Dependency | Always | Always | Always | Always |
| Observability | If analytics/crash reporting | Always | If logging present | If logging present |

### Selection Rules

- **Always**: Spawn this reviewer unconditionally
- **Skip**: Do not spawn this reviewer
- **Conditional**: Spawn only if the condition is met based on code analysis

When uncertain, **include the reviewer** (prefer thoroughness over efficiency).

## Step 3: Team Creation

Spawn only the selected reviewers with their specialized prompts:

1. **Security Reviewer**: Review for vulnerabilities, authentication, authorization, input validation, injection attacks, CSRF, XSS, secrets exposure, and OWASP Top 10 issues.

2. **Performance Reviewer**: Review for N+1 queries, unnecessary re-renders, memory leaks, inefficient algorithms, database access patterns, caching, and resource optimization.

3. **Architecture Reviewer**: Review for design patterns, SOLID principles, layer separation, dependency direction, modularity, coupling, cohesion, and maintainability.

4. **Test Coverage Reviewer**: Review for missing unit tests, integration tests, edge cases, error handling paths, test quality, and test maintainability.

5. **Error Handling Reviewer**: Review for exception handling, error propagation, retry logic, fallback strategies, graceful degradation, and failure recovery paths.

6. **Concurrency Reviewer**: Review for thread safety, race conditions, deadlocks, shared mutable state, coroutine/async patterns, and synchronization issues.

7. **API Design Reviewer**: Review for REST/GraphQL API conventions, request/response design, versioning, backward compatibility, error responses, and documentation.

8. **Accessibility Reviewer**: Review for screen reader support, keyboard navigation, color contrast, WCAG compliance, semantic markup, ARIA labels, and inclusive design.

9. **Dependency Reviewer**: Review for known CVEs, license compliance, dependency size, transitive dependencies, supply chain security, and version management.

10. **Observability Reviewer**: Review for logging quality, monitoring coverage, metrics, distributed tracing, alerting, and production debugging capability.

## Workflow

1. Lead analyzes the target and announces selected reviewers with reasoning
2. Each selected reviewer reviews the target from their specialized perspective
3. Reviewers share critical findings with each other for cross-perspective validation
4. The lead synthesizes all findings into a consolidated report with priority ordering:
   - Critical / Blocker items first
   - High severity items
   - Medium severity items
   - Low severity / enhancements

## Output

The lead produces a final consolidated review report including:
- Target type detected and reviewers selected (with reasoning)
- Findings grouped by severity
- Actionable recommendations
