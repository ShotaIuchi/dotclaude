---
name: wf2-spec
description: >
  キックオフに基づいて仕様書を作成する。キックオフドキュメントを読み、コードベースを
  調査し、要件と受け入れ基準を含む詳細な仕様をドラフトする。
  ユーザーが要件を書きたい、仕様書を作成したい、受け入れ基準を定義したい場合や、
  「仕様を書いて」「要件」「何を作るべきか」と言った場合に使用する。
  キックオフの完了が前提（先に /wf1-kickoff を実行すること）。
argument-hint: "<work-id>"
---

# /wf2-spec

Create a specification document for an existing workflow.

## Prerequisites

- A completed kickoff exists at `docs/wf/<work-id>/01_KICKOFF.md`
- `state.json` shows kickoff phase is completed

## Workflow

### Step 1: Load Context

1. Read `docs/wf/<work-id>/state.json` to verify the workflow exists and kickoff is done
2. Read `docs/wf/<work-id>/01_KICKOFF.md` to understand the goal and constraints
3. If the kickoff phase is not completed, tell the user to run `/wf1-kickoff` first

### Step 2: Research

Based on the kickoff goal, explore the codebase to understand:
- Which files and components are affected
- Existing patterns and conventions
- Potential edge cases and risks

Use the Explore agent for broad codebase exploration, or Glob/Grep for targeted searches.

### Step 3: Draft the Specification

1. Copy this skill's bundled `templates/02_SPEC.md` to `docs/wf/<work-id>/02_SPEC.md`
2. Fill in the spec based on kickoff goals and codebase research:
   - **Overview**: Summarize what the change does
   - **Scope**: What's in and out
   - **User / Use Cases**: Who benefits and how
   - **Functional Requirements**: Concrete FR-N items
   - **Non-Functional Requirements**: Performance, security, etc.
   - **Acceptance Criteria**: Given/When/Then format
   - **Affected Components**: Based on codebase research
   - **Change Details**: Before/After where applicable
   - **Test Strategy**: How to verify

Remove sections that don't apply (e.g., API changes if there's no API).

### Step 4: Review with User

Present the draft spec to the user. Ask if anything is missing, incorrect, or
needs adjustment. Iterate until the user approves.

### Step 5: Finalize

1. Update `state.json`:
   - Set `phases.spec.status` to `"completed"`
   - Set `phases.spec.completed_at` to current timestamp
   - Set `phase` to `"plan"`
2. Tell the user: the spec is complete, proceed with `/wf3-plan <work-id>`

## Important Notes

- The spec should be concrete enough to implement from. Avoid vague requirements.
- Include "Open Questions" for anything that needs human decisions during implementation.
- The spec document is written in Japanese (following the template language).
- Cross-reference the kickoff document for traceability.
- All timestamps in `state.json` must use UTC: `YYYY-MM-DDTHH:MM:SSZ`.
