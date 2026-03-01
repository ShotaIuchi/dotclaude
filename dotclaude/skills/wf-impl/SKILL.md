---
name: wf-impl
description: >
  計画に従ってステップバイステップで実装を実行する。実装計画を読み、各ステップを
  実行し、変更内容とテスト結果を記録し、進捗を更新する。
  ユーザーがコーディングを開始したい、計画を実装したい、ステップを実行したい場合や、
  「実装して」「作って」「コーディング開始」「ステップNをやって」と言った場合に使用する。
  計画の完了が前提（先に /wf-plan を実行すること）。
argument-hint: "<work-id> [step-number]"
---

# /wf-impl

Execute implementation according to the plan, step by step.

## Prerequisites

- A completed plan exists at `docs/wf/<work-id>/03_PLAN.md`
- `state.json` shows plan phase is completed

## Workflow

### Step 1: Load Context

1. Read `docs/wf/<work-id>/state.json` to verify plan is done and check progress
2. Read `docs/wf/<work-id>/01_KICKOFF.md` for goal and constraints
3. Read `docs/wf/<work-id>/02_SPEC.md` for requirements
4. Read `docs/wf/<work-id>/03_PLAN.md` for the implementation steps
5. If `05_IMPLEMENT_LOG.md` exists, read it to see what's already been done

### Step 2: Determine Current Step

- If the user specifies a step number, use that
- Otherwise, check `state.json` for `phases.impl.current_step`
- If no step has started, begin with step 1

### Step 3: Execute the Step

For each step in the plan:

1. **Announce**: Tell the user which step you're about to execute
2. **Implement**: Make the code changes described in the plan
3. **Test**: Run relevant tests to verify the changes work
4. **Log**: Record what was done in `05_IMPLEMENT_LOG.md`
   - Actual changes made (with file paths)
   - Any issues encountered and how they were resolved
   - Test results
   - Handover items for the next step

If `05_IMPLEMENT_LOG.md` doesn't exist yet, create it from this skill's bundled `templates/05_IMPLEMENT_LOG.md`.

### Step 4: Update Progress

After each step:

1. Update `state.json`:
   - Set `phases.impl.current_step` to the completed step number
   - If all steps are done, set `phases.impl.status` to `"completed"` and
     `phases.impl.completed_at` to current timestamp
2. Update the progress table in `03_PLAN.md` (mark step as "completed")

### Step 5: Continue or Pause

- If there are more steps, ask the user if they want to continue to the next step
  or pause here
- If all steps are complete, tell the user implementation is done and suggest
  running `/wf-review <work-id>` for a final review

## Handling Issues During Implementation

- If a step can't be completed as planned, log the issue and ask the user how to
  proceed. Options include: modify the plan, skip the step, or try an alternative.
- If you discover something that affects the spec, note it in the implementation log
  and suggest running `/wf-review <work-id> spec` to update the spec.
- Never silently deviate from the plan. Always log deviations.

## Important Notes

- The implementation log is written in Japanese (following the template language).
- Execute one step at a time unless the user explicitly asks to do multiple.
- Always run tests after each step when possible.
- Keep the implementation log detailed enough for someone else to understand what
  happened and why.
- All timestamps in `state.json` must use UTC: `YYYY-MM-DDTHH:MM:SSZ`.
