---
name: review-fix
description: >
  レビュー結果を元に複数エージェントで多角的に調査し、ユーザーが選択した指摘を修正するスキル。
  「レビュー結果を修正」「指摘を直して」「レビュー対応」「review fix」「指摘修正」
  「レビューフィードバック対応」「コードレビュー対応」「修正対応」等で起動する。
  multi-reviewの出力はもちろん、PRコメント、手書きの指摘リスト、他ツールのレビュー出力など
  あらゆるレビュー結果を受け付ける。指摘ごとに調査してから修正対象をユーザーに選ばせるため、
  安全かつ納得感のある修正が可能。
argument-hint: <review source: "last review", file paths, PR number, or paste review text>
---

# review-fix: Multi-Agent Investigation & Fix

Takes review findings — from multi-review, PR comments, or any other source — and investigates each one from three angles before letting you choose which to fix. This ensures you understand the full picture before any code changes happen.

## How It Works (Overview)

```
Review Input → Parse Findings → Investigate Each (3 agents parallel)
  → Present Investigation Results → User Selects → Fix Selected → Summary
```

## Step 1 — Parse Review Input

Determine what review findings to work with based on `$ARGUMENTS`:

| Input | Action |
|-------|--------|
| `last review` or empty | Look for the most recent multi-review output in the conversation history |
| File paths | Read files as review reports and extract findings |
| PR number (`#123`) | Run `gh pr view <number> --comments` to get review comments |
| Pasted text | Parse the text directly as review findings |
| Natural language | Identify what the user is referring to and extract findings |

### Parsing multi-review output

When the input comes from multi-review (the most common case), the report follows a structured markdown format with severity headers (Critical, Important, Suggestions, Positive). Parse each finding into this internal structure:

```json
{
  "id": 1,
  "severity": "critical",
  "title": "SQL injection via string interpolation",
  "location": "auth.ts:42",
  "expert": "Security",
  "detail": "Original detail from the review",
  "recommendation": "Original recommendation"
}
```

### Parsing other review formats

For PR comments, free-text, or other tools' output, do your best to extract structured findings. Each finding needs at minimum a title and enough context to investigate. If the input is ambiguous, ask the user to clarify rather than guessing.

**Exclude "Positive" findings** — those are things to keep, not things to fix.

After parsing, display a numbered summary:

```
Found N findings from the review:
  1. [Critical] SQL injection via string interpolation — auth.ts:42
  2. [Important] N+1 query pattern in user list — api.ts:55
  3. [Suggestion] Missing input validation — handler.ts:12
```

## Step 2 — Investigate All Findings

This is the core value of this skill: investigating each finding from multiple angles **before** touching any code. Do not skip this step. Do not investigate inline yourself — use the Agent tool to spawn dedicated subagents.

The reason for using separate agents is that each one operates independently with its own context, which means:
- The Code Explorer can deeply trace call chains without polluting the main context
- The Test Analyst can search broadly for test files without cluttering the conversation
- The Best Practices Researcher can run multiple web searches without blocking other work
- All three run in parallel, so the total time is ~1x instead of ~3x

### How to spawn agents

Use the **Agent tool** (subagent_type: `general-purpose`) to spawn all investigation agents **in a single message**. For N findings, that means up to 3×N Agent tool calls in one response.

If there are many findings (>4), batch them: investigate 3-4 findings per round to avoid overwhelming the system.

For each finding, spawn these three agents:

### Agent 1: Code Explorer

Traces the root cause through the codebase and maps the full impact. Use this prompt template:

```
You are a Code Explorer investigating a review finding. Your job is to trace
the root cause and map the full impact — do NOT fix anything, only investigate.

Working directory: {working_directory}

Finding:
  Title: {title}
  Location: {location}
  Detail: {detail}
  Recommendation: {recommendation}

Instructions:
1. Read the code at the reported location and its surrounding context
2. Trace the data flow — where does the problematic input come from? Where does the output go?
3. Find all related code: callers, callees, similar patterns elsewhere in the codebase
4. Identify the root cause (not just the symptom)
5. Map the blast radius — what other code would be affected by a fix?

Return your findings as a JSON code block:
{
  "root_cause": "Clear explanation of the underlying issue",
  "affected_files": ["file:line", ...],
  "related_patterns": ["Description of similar patterns found elsewhere"],
  "blast_radius": "What would be affected by a change",
  "confidence": "high | medium | low"
}
```

### Agent 2: Test Analyst

Checks the testing landscape around the finding. Use this prompt template:

```
You are a Test Analyst investigating test coverage around a review finding.
Your job is to assess the testing situation — do NOT fix anything, only investigate.

Working directory: {working_directory}

Finding:
  Title: {title}
  Location: {location}
  Detail: {detail}

Instructions:
1. Search the codebase for test files related to the reported location
2. Check if the specific issue is tested (e.g., is there a test for SQL injection on this endpoint?)
3. Identify test gaps — what tests are missing that should exist?
4. If fixing this issue, what new tests would be needed?
5. Check if existing tests would break from a fix

Return your findings as a JSON code block:
{
  "existing_tests": ["test_file:test_name — what it covers"],
  "covers_issue": true/false,
  "test_gaps": ["Description of missing test coverage"],
  "tests_needed_for_fix": ["Description of tests to add"],
  "tests_at_risk": ["Tests that might break if this is fixed"]
}
```

### Agent 3: Best Practices Researcher

Searches the web for current recommendations and known issues. Use this prompt template:

```
You are a Best Practices Researcher investigating current recommendations
for a review finding. Your job is to research — do NOT fix anything.

Finding:
  Title: {title}
  Detail: {detail}
  Recommendation: {recommendation}
  Language/Framework: {detected from codebase}

Instructions:
1. Use WebSearch to find current best practices for addressing this type of issue
2. Search for known CVEs or security advisories if the finding is security-related
3. Look for official documentation or migration guides if the finding involves deprecated APIs
4. Find community consensus on the recommended fix approach
5. Check if the recommended fix has any known pitfalls

Return your findings as a JSON code block:
{
  "best_practice": "The currently recommended approach",
  "sources": ["URL — brief description"],
  "caveats": ["Known pitfalls or edge cases with the recommended fix"],
  "alternative_approaches": ["Other valid approaches if the primary one doesn't fit"]
}
```

### Example: spawning agents for 2 findings

For 2 findings, spawn 6 Agent tool calls in a single message:

1. Agent(description="Finding 1: Code Explorer", prompt="You are a Code Explorer...", subagent_type="general-purpose")
2. Agent(description="Finding 1: Test Analyst", prompt="You are a Test Analyst...", subagent_type="general-purpose")
3. Agent(description="Finding 1: Best Practices", prompt="You are a Best Practices Researcher...", subagent_type="general-purpose")
4. Agent(description="Finding 2: Code Explorer", prompt="You are a Code Explorer...", subagent_type="general-purpose")
5. Agent(description="Finding 2: Test Analyst", prompt="You are a Test Analyst...", subagent_type="general-purpose")
6. Agent(description="Finding 2: Best Practices", prompt="You are a Best Practices Researcher...", subagent_type="general-purpose")

All 6 calls go in a single message so they execute in parallel.

## Step 3 — Present Investigation Results

Once all agents complete, synthesize the results into a clear report for each finding. Present them in a format that helps the user make informed decisions:

```markdown
# Investigation Results

## Finding 1: [Critical] SQL injection via string interpolation — auth.ts:42

### Root Cause
The `buildQuery()` function concatenates user input directly into SQL strings.
This pattern also exists in `search.ts:78` and `report.ts:33`.

### Test Status
- Existing tests: `auth.test.ts:testLogin` — covers happy path only
- No tests for malicious input
- Fix would need: parameterized query tests, injection attempt tests

### Best Practice
Use parameterized queries (prepared statements). Official docs: [link]
- Caveat: Switching to parameterized queries requires updating the query builder interface.

### Impact: 3 files affected | Confidence: High

---

## Finding 2: [Important] N+1 query pattern — api.ts:55
...
```

After the report, ask the user to select which findings to fix:

```
Which findings would you like me to fix? (Enter numbers, e.g., "1,3" or "all")
```

Use the AskUserQuestion tool with multiSelect enabled if there are 4 or fewer findings. For more than 4, present the numbered list and ask for comma-separated numbers in freeform input.

## Step 4 — Fix Selected Findings

For each selected finding, apply the fix informed by the investigation:

1. **Plan the fix** based on root cause analysis (not just the surface symptom)
2. **Apply code changes** to all affected files identified by the Code Explorer
3. **Add or update tests** based on the Test Analyst's gap analysis
4. **Follow best practices** identified by the Researcher, including handling any caveats

Fix findings in dependency order — if finding A's fix affects code related to finding B, fix A first. When the order doesn't matter, process by severity (critical first).

After each fix:
- Verify the fix compiles / passes linting (run the project's build command if one exists)
- Run existing tests to check for regressions

If a fix turns out to be more complex than expected (e.g., requires architectural changes), pause and explain the situation to the user rather than making sweeping changes silently.

## Step 5 — Summary

After all fixes are applied, produce a summary:

```markdown
# Fix Summary

## Applied Fixes
| # | Finding | Files Changed | Tests Added |
|---|---------|--------------|-------------|
| 1 | SQL injection — auth.ts:42 | 3 | 2 |
| 3 | Missing validation — handler.ts:12 | 1 | 1 |

## Skipped Findings
| # | Finding | Reason |
|---|---------|--------|
| 2 | N+1 query pattern | Not selected by user |

## Verification
- Build: PASS
- Tests: 24 passed, 0 failed (3 new)

## Notes
- The SQL injection fix also addressed the same pattern in search.ts and report.ts
  (found during investigation).
- Consider running the full test suite before merging.
```

## Tips

- When investigating many findings (>6), the parallel agent spawns can be heavy. Consider batching in groups of 3-4 findings at a time to avoid overwhelming the context.
- If the review input is vague or lacks location info, the Code Explorer agent becomes especially important for pinpointing where the issue actually lives.
- For security-related findings, always check best practices via web search — security recommendations evolve quickly.
- Cross-reference investigation results: if the Code Explorer finds the same pattern in 5 files but the review only mentioned 1, inform the user about the broader scope before fixing.
