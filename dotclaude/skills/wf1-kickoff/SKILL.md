---
name: wf1-kickoff
description: >
  キックオフドキュメントを作成してワークフローを開始する。作業ディレクトリの作成、
  state.jsonの初期化、テンプレートからのキックオフドキュメント生成を行う。
  ユーザーが新しいタスクを始めたい、ワークフローを開始したい、作業に着手したい場合や、
  「新しいタスク」「始めよう」「キックオフ」「Xの作業開始」などと言った場合に使用する。
  wf1〜wf5ワークフローシリーズの最初のステップ。
argument-hint: "<work-id> [goal]"
---

# /wf1-kickoff

Initialize a new workflow workspace. This is the entry point for all wf1-wf5 workflows.

## What This Skill Does

1. Create the work directory at `docs/wf/<work-id>/`
2. Initialize `state.json` to track workflow progress
3. Generate `01_KICKOFF.md` from the template
4. Interview the user to fill in the kickoff document

## Workflow

### Step 1: Determine Work ID

If the user provides a work-id as an argument, use it. Otherwise, ask the user for a
short, descriptive identifier (e.g., `add-csv-export`, `fix-login-bug`). The work-id
should be kebab-case.

### Step 2: Check for Existing Work

Check if `docs/wf/<work-id>/` already exists. If so, warn the user and ask whether
to resume or create a new work-id.

### Step 3: Create Directory and Files

1. Create `docs/wf/<work-id>/`
2. Copy this skill's bundled `templates/01_KICKOFF.md` to `docs/wf/<work-id>/01_KICKOFF.md`
3. Create `state.json` with initial state:

All timestamps must use UTC in the format `YYYY-MM-DDTHH:MM:SSZ` (e.g., `2026-03-01T12:00:00Z`).

```json
{
  "work_id": "<work-id>",
  "phase": "kickoff",
  "created_at": "YYYY-MM-DDTHH:MM:SSZ",
  "updated_at": "YYYY-MM-DDTHH:MM:SSZ",
  "phases": {
    "kickoff": { "status": "in_progress", "completed_at": null },
    "spec": { "status": "pending", "completed_at": null },
    "plan": { "status": "pending", "completed_at": null },
    "impl": { "status": "pending", "completed_at": null, "current_step": null, "total_steps": null },
    "review": { "status": "pending", "completed_at": null, "target": null, "verdict": null }
  }
}
```

### Step 4: Fill the Kickoff Document

Interview the user to fill in the kickoff document. Ask about:
- **Goal**: What do they want to achieve? (1-2 sentences)
- **Completion criteria**: How do we know it's done?
- **Constraints**: Any limitations or requirements?
- **Out of scope**: What should NOT be done?
- **Dependencies**: Anything this work depends on?
- **Open questions**: Items that need human decisions

Replace the template placeholders with the user's answers. Remove unused placeholder
sections rather than leaving them empty.

### Step 5: Finalize

1. Update `state.json`: set `phases.kickoff.status` to `"completed"` and
   `phases.kickoff.completed_at` to the current timestamp
2. Update `phase` to `"spec"` (next phase)
3. Tell the user: the kickoff is complete, and they can proceed with `/wf2-spec <work-id>`

## Important Notes

- The template is bundled with this skill at `skills/wf1-kickoff/templates/01_KICKOFF.md`.
- The work directory structure is: `docs/wf/<work-id>/` (relative to project root)
- Always show the user the completed kickoff document before finalizing
- The kickoff document is written in Japanese (following the template language)
