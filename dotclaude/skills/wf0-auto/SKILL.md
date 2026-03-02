---
name: wf0-auto
description: >
  wf1-kickoff から wf5-review までを一気にノンストップで自動実行する。
  ユーザーが「全部自動で」「ノンストップ」「一括実行」「自動ワークフロー」
  「wf1からwf5まで通しで」「全フェーズ実行」「自動で最後まで」と言った場合に使用する。
  goalとwork-idを受け取ったら、途中の承認ポイントを全てスキップして最後まで走り切る。
argument-hint: "<work-id> <goal>"
---

# /wf0-auto

Run the entire wf1-wf5 workflow pipeline in one shot, without stopping for user approval at intermediate checkpoints.

This skill is an **orchestrator** — it delegates to the existing wf1-wf5 skills, not reimplements them. Each phase reads and follows its respective `/wfN-*` skill, with the auto-mode overrides described below.

## What This Skill Does

Invokes the following skills sequentially:

1. `/wf1-kickoff <work-id> <goal>` - Create workspace and kickoff document
2. `/wf2-spec <work-id>` - Research and draft specification
3. `/wf3-plan <work-id>` - Create implementation plan
4. `/wf4-impl <work-id>` - Execute all implementation steps
5. `/wf5-review <work-id>` - Review and apply fixes

The key difference from running each skill individually: this skill applies **auto-mode overrides** at each phase so that no user-approval gate blocks the pipeline.

## Arguments

- `<work-id>`: Kebab-case identifier for the work (required)
- `<goal>`: What to achieve - a clear description of the task (required, everything after work-id)

## Workflow

### Phase 0: Validate Input

If work-id or goal is missing, ask the user for both. Do not proceed without them.

Check if `docs/wf/<work-id>/` already exists. If so, check `state.json` for resume (see Resume Behavior below). If no `state.json` exists, warn the user and ask whether to overwrite or pick a new work-id.

### Phase 1: Kickoff

Read and follow `/wf1-kickoff` skill (`skills/wf1-kickoff/SKILL.md`).

**Auto-mode overrides:**
- Skip the user interview (Step 4). Instead, derive the kickoff document content from the provided `<goal>`:
  - **Goal**: Use the user's goal directly
  - **Completion criteria**: Infer from the goal
  - **Constraints**: Infer from the codebase context, or leave minimal
  - **Out of scope**: Set reasonable boundaries based on the goal
  - **Dependencies**: Check the codebase for relevant dependencies
  - **Open questions**: Leave empty (auto mode assumes no blockers)
- Do not ask the user to confirm the completed kickoff document — proceed immediately.

**Progress output**: `[1/5] Kickoff complete.`

### Phase 2: Spec

Read and follow `/wf2-spec` skill (`skills/wf2-spec/SKILL.md`).

**Auto-mode overrides:**
- Skip Step 4 (Review with User). Do not present the spec for approval or iterate — accept the first draft and proceed.

**Progress output**: `[2/5] Spec complete.`

### Phase 3: Plan

Read and follow `/wf3-plan` skill (`skills/wf3-plan/SKILL.md`).

**Auto-mode overrides:**
- Skip Step 4 (Review with User). Do not present the plan for feedback — accept the first draft and proceed.

**Progress output**: `[3/5] Plan complete. N steps defined.`

### Phase 4: Implementation

Read and follow `/wf4-impl` skill (`skills/wf4-impl/SKILL.md`).

**Auto-mode overrides:**
- Execute ALL steps without pausing between them. Do not ask the user whether to continue after each step — run them all consecutively.
- If a step fails and cannot be completed as planned:
  - Log the issue in `05_IMPLEMENT_LOG.md`
  - Attempt a reasonable fix
  - If the fix works, continue to the next step
  - If the fix doesn't work, log it and move on (note the incomplete step)
  - Do NOT ask the user how to proceed — make a best-effort decision and continue.

**Progress output**: `[4/5] Implementation complete. N/M steps succeeded.`

### Phase 5: Review

Read and follow `/wf5-review` skill (`skills/wf5-review/SKILL.md`).

**Auto-mode overrides:**
- If verdict is `request-changes`: automatically apply non-breaking fixes without asking the user for approval.
- If verdict is `needs-discussion`: log the open questions but do not block — report them in the final summary.

**Progress output**: `[5/5] Review complete. Verdict: <verdict>.`

### Final Report

After all phases, present a summary:

```
## Workflow Complete: <work-id>

- Kickoff: Done
- Spec: Done (N requirements)
- Plan: Done (N steps)
- Implementation: Done (N/M steps succeeded)
- Review: <verdict>

Documents: docs/wf/<work-id>/
```

List any issues that need manual attention (failed impl steps, review findings with needs-discussion).

## Error Handling

- If any phase encounters an unrecoverable error, log it in the relevant document, update `state.json` to reflect the failure point, and report to the user. Do not silently swallow errors.
- The workflow is resumable: if it stops partway through, the user can fix the issue and run `/wf0-auto <work-id>` again. The skill should detect the current state from `state.json` and resume from where it left off.

## Resume Behavior

When `docs/wf/<work-id>/` already exists and has a `state.json`:

1. Read `state.json` to determine current phase
2. Skip already-completed phases
3. Resume from the current phase (or the next pending phase), applying auto-mode overrides as above
4. For impl phase: resume from `current_step + 1`

## Important Notes

- This skill **delegates to** the wf1-wf5 skills. Read each skill's SKILL.md and follow its instructions, applying only the auto-mode overrides listed above.
- If wf1-wf5 skills are updated, this skill automatically benefits because it reads them at execution time.
- All documents are written in Japanese (following template language).
- All timestamps in `state.json` use UTC: `YYYY-MM-DDTHH:MM:SSZ`.
