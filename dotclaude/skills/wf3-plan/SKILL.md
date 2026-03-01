---
name: wf3-plan
description: >
  仕様から実装計画を作成する。作業をファイルリスト、タスク、完了基準を含む
  順序付きステップに分解する。
  ユーザーが実装を計画したい、作業をステップに分解したい、タスクリストを作成したい場合や、
  「計画して」「どう実装すべきか」「分解して」と言った場合に使用する。
  仕様の完了が前提（先に /wf2-spec を実行すること）。
argument-hint: "<work-id>"
---

# /wf3-plan

Create a step-by-step implementation plan for an existing workflow.

## Prerequisites

- A completed spec exists at `docs/wf/<work-id>/02_SPEC.md`
- `state.json` shows spec phase is completed

## Workflow

### Step 1: Load Context

1. Read `docs/wf/<work-id>/state.json` to verify spec is done
2. Read `docs/wf/<work-id>/01_KICKOFF.md` for goal and constraints
3. Read `docs/wf/<work-id>/02_SPEC.md` for requirements
4. If spec phase is not completed, tell the user to run `/wf2-spec` first

### Step 2: Analyze and Design

Research the codebase to determine:
- Exact files that need to be created or modified
- The right order of changes (dependency-aware)
- Risks and potential rollback strategies
- Estimated scope of each step

### Step 3: Draft the Plan

1. Copy this skill's bundled `templates/03_PLAN.md` to `docs/wf/<work-id>/03_PLAN.md`
2. Fill in the plan:
   - **Overview**: High-level approach in 1-2 sentences
   - **Steps**: Each step should be:
     - Small enough to complete and verify independently
     - Ordered by dependency (foundational changes first)
     - Clear about which files are touched
     - Have concrete completion criteria
   - **Progress table**: One row per step, all starting as "pending"
   - **Risks**: Identified risks with impact, probability, and mitigation
   - **Rollback plan**: How to undo if things go wrong

### Step Guidelines

- Aim for 3-10 steps. If you need more than 10, consider grouping related changes.
- Each step should be testable on its own.
- Include both the "what" (task list) and "why" (purpose) for each step.
- Specify file paths concretely (e.g., `src/utils/csv.ts`, not "the CSV module").

### Step 4: Review with User

Present the plan and ask for feedback. Common adjustments:
- Reordering steps
- Splitting or merging steps
- Adjusting scope per step
- Adding/removing risks

### Step 5: Finalize

1. Update `state.json`:
   - Set `phases.plan.status` to `"completed"`
   - Set `phases.plan.completed_at` to current timestamp
   - Set `phases.impl.total_steps` to the number of steps
   - Set `phase` to `"impl"`
2. Tell the user: the plan is complete, proceed with `/wf4-impl <work-id>`

## Important Notes

- The plan document is written in Japanese (following the template language).
- Steps should map clearly to spec requirements for traceability.
- The plan is a living document — it may be updated during implementation if
  the user discovers issues via `/wf5-review`.
- All timestamps in `state.json` must use UTC: `YYYY-MM-DDTHH:MM:SSZ`.
