---
name: multi-review
description: >
  複数の専門家エージェントが並列でレビューを行い、多角的な指摘を統合レポートとして出力する汎用レビュースキル。
  「レビューして」「コードレビュー」「PRレビュー」「設計レビュー」「品質チェック」
  「セキュリティチェック」「パフォーマンスレビュー」「並行性チェック」「非同期処理レビュー」
  「分散システムレビュー」「障害耐性チェック」「変更を確認して」等で起動する。
  コード変更、PR、設計ドキュメント、設定ファイルなど、あらゆるレビュー対象に使用できる。
argument-hint: <review target: file paths, "staged", "diff", PR number, or description>
---

# multi-review: Multi-Expert Parallel Review

Multiple domain experts review your target simultaneously, each bringing a distinct lens. Their findings are merged into a single prioritized report so nothing slips through the cracks.

## Expert Roles

The following roles are available. Choose the ones most relevant to the review target — not every review needs all roles.

| Role | Lens |
|------|------|
| Security | Threats, vulnerabilities, auth, data exposure |
| Performance | Efficiency, scalability, complexity, caching |
| Maintainability | Design, readability, SOLID, coupling |
| Quality | Correctness, edge cases, error handling, testing |
| Concurrency | Race conditions, deadlocks, async/await, locks |
| Distributed | Consistency, idempotency, retry, circuit breakers |
| State | State machines, cache coherence, lifecycle |
| Resilience | Fault tolerance, graceful degradation, recovery |
| BestPractices | Latest recommendations, deprecations, known CVEs |

**Role selection**: Look at the review target and pick the relevant roles. A simple utility function might only need Security, Quality, and Maintainability. A distributed async service needs most roles. Use judgment — spawning irrelevant experts wastes tokens without adding value.

### BestPractices Agent

The BestPractices agent is different from other roles. It uses **WebSearch** to look up current information that may be beyond the model's training data. This is the one role that provides genuinely unique value compared to what Claude can do without tools.

This agent should:

1. Identify the languages, frameworks, and libraries used in the review target
2. Search the web for each one:
   - `"{library} security advisory {current year}"` — known CVEs, security patches
   - `"{framework} best practices {current year}"` — current recommended patterns
   - `"{library} deprecated API"` — APIs that should be migrated away from
3. Cross-reference findings with the actual code under review
4. Only report findings that are **directly relevant** to the code — not generic best-practice lists

The BestPractices agent prompt should instruct it to use WebSearch and return findings in the same JSON format as other agents, with source URLs included in the `detail` field.

## Determining the Review Target

Parse `$ARGUMENTS` to figure out what to review:

| Input | Action |
|-------|--------|
| File paths (`src/auth.ts lib/db.rs`) | Read and review those files |
| `staged` or `--staged` | Run `git diff --staged` |
| `diff` | Run `git diff` (unstaged changes) |
| PR number (`#123` or `123`) | Run `gh pr diff <number>` |
| Empty | Try `git diff --staged` first; fall back to `git diff` |
| Natural language | Identify relevant files from the description, confirm with user if ambiguous |

For diff-based reviews, also read the full files being changed to provide context.

## Execution

### Step 1 — Gather the target

Capture the review material based on the rules above.

### Step 2 — Spawn experts in parallel

Use the Agent tool to spawn all selected experts **in a single message** (one tool call per expert). Each agent receives its role and the review target:

```
You are a {Role} expert reviewing code.

Review this target and return findings as JSON:
---
{review_target}
---

Return:
{
  "expert": "{role}",
  "findings": [
    {
      "severity": "critical | important | suggestion | positive",
      "title": "Brief one-line description",
      "location": "file_path:line_number (if applicable)",
      "detail": "Why this matters and what could go wrong",
      "recommendation": "Concrete fix or action"
    }
  ],
  "summary": "One-paragraph overall assessment from your perspective"
}
```

### Step 3 — Synthesize the report

Collect all agents' findings and produce the final report.

**Default: Integrated Report** — organized by severity, expert tagged in brackets:

```markdown
# Review Report

**Target**: <what was reviewed>
**Experts**: <list of experts used>

| Severity | Count |
|----------|-------|
| Critical | N |
| Important | N |
| Suggestion | N |
| Positive | N |

## Critical
- [Security] SQL injection via string interpolation — `auth.ts:42`
  Use parameterized queries instead of template literals.

## Important
- [Performance] N+1 query pattern in user list endpoint — `api.ts:55`
  Batch-load related records with a single JOIN.

## Suggestions
...

## Positive
...

## Cross-Expert Overlaps

| Finding | Flagged By | Severity |
|---------|-----------|----------|
| Missing input validation | Security, Quality | Critical |

## Expert Summaries
- **Security**: ...
- **Performance**: ...
```

**Alternative: Per-Expert Report** — when the user says `--by-expert`, group findings under each expert heading instead. Still include the Cross-Expert Overlaps table.

## Severity Guide

| Level | Meaning | Action |
|-------|---------|--------|
| Critical | Security holes, data loss, crashes, race conditions | Must fix before merge |
| Important | Performance issues, design debt, missing tests | Should fix soon |
| Suggestion | Style, minor optimizations, defensive improvements | Consider fixing |
| Positive | Good patterns worth preserving | Keep doing this |

## Tips

- If the review target is very large (>1000 lines), tell agents to focus on the top 5-8 findings each rather than cataloging every minor issue.
- For PR reviews, also read the PR description and linked issues for context.
- Cross-expert overlaps are one of the most valuable outputs. Two experts independently flagging the same issue is a strong signal. Always include the overlaps table.
