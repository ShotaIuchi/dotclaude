---
name: wf-review
description: >
  ワークフローの成果物をレビューし改訂する。キックオフ、仕様、計画、実装の
  いずれのフェーズの出力でもレビュー可能で、品質、完全性、一貫性をチェックする。
  ユーザーが作業をレビューしたい、品質をチェックしたい、フィードバックを得たい、
  ドキュメントを改訂したい場合や、「レビュー」「確認して」「これで合ってる？」
  「仕様を修正」と言った場合に使用する。ワークフローのどの時点でも使用可能。
argument-hint: "<work-id> [phase]"
---

# /wf-review

Review workflow deliverables and suggest or apply revisions.

## Arguments

- `<work-id>`: The workflow to review (required)
- `[phase]`: Which phase to review: `kickoff`, `spec`, `plan`, `impl`, or `all`
  (optional, defaults to the most recently completed phase)

## Workflow

### Step 1: Load Context

1. Read `docs/wf/<work-id>/state.json` to understand workflow state
2. Determine which phase to review:
   - If the user specified a phase, use that
   - Otherwise, review the most recently completed phase
3. Read all relevant documents up to and including the review target

### Step 2: Perform the Review

Review criteria depend on the target phase:

#### Reviewing Kickoff (`01_KICKOFF.md`)
- Is the goal clear and specific enough?
- Are completion criteria measurable and testable?
- Are constraints realistic?
- Are there unresolved questions that should be answered before proceeding?

#### Reviewing Spec (`02_SPEC.md`)
- Do requirements trace back to the kickoff goal?
- Are acceptance criteria testable (Given/When/Then)?
- Is anything missing from scope that should be included?
- Are there contradictions between requirements?
- Is the spec implementable as written?

#### Reviewing Plan (`03_PLAN.md`)
- Do steps cover all spec requirements?
- Is the order logical (dependencies respected)?
- Are steps small enough to verify independently?
- Are risks identified with realistic mitigations?
- Are file paths concrete and correct?

#### Reviewing Implementation (`05_IMPLEMENT_LOG.md` + actual code)
- Does the implementation match the spec?
- Are there deviations from the plan that weren't logged?
- Code quality: style, error handling, security
- Test coverage: are the acceptance criteria verified?
- Are there issues that need to be fixed?

### Step 3: Generate Review Document

1. If `04_REVIEW.md` doesn't exist, create it from this skill's bundled `templates/04_REVIEW.md`
2. If it already exists, append a new review section (with date and target phase)
3. Fill in:
   - **Summary**: Overall assessment
   - **Checklist**: Applicable items checked/unchecked
   - **Blocking issues**: Must-fix before proceeding
   - **Recommended fixes**: Should-fix, not blocking
   - **Improvement suggestions**: Nice-to-have
   - **Verdict**: `approved` / `request-changes` / `needs-discussion`

### Step 4: Apply Revisions

If the user approves the review findings:

1. Apply the suggested changes to the target document
2. Create or update `06_REVISIONS.md` with the revision record
   (copy from this skill's bundled `templates/06_REVISIONS.md` if it doesn't exist)
3. Update `state.json`:
   - Set `phases.review.target` to the reviewed phase
   - Set `phases.review.verdict` to the review outcome

### Step 5: Recommend Next Action

Based on the review:
- If **approved**: suggest proceeding to the next phase
- If **request-changes**: the changes have been applied, suggest re-reviewing
  or proceeding
- If **needs-discussion**: highlight the open questions for the user to resolve

## Important Notes

- The review document is written in Japanese (following the template language).
- Reviews can happen at any point — not just after implementation.
- Multiple reviews of the same phase are expected and normal.
- The review should be constructive, not just critical. Highlight what's working
  well alongside issues.
- When reviewing implementation, actually read the changed code — don't just
  check the log.
- All timestamps in `state.json` must use UTC: `YYYY-MM-DDTHH:MM:SSZ`.
