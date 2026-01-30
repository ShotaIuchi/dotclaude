---
name: wf2-spec
description: 仕様書（Spec）ドキュメントを作成
argument-hint: "[update | validate]"
context: fork
agent: general-purpose
---

**Always respond in Japanese.**

# /wf2-spec

Create or update the Specification (Spec) document.

## Usage

```
/wf2-spec [subcommand]
```

## Subcommands

- `(none)`: Create new Spec
- `update`: Update existing Spec
- `validate`: Check consistency with Kickoff

## Processing

### 1. Check Prerequisites

Get active work. Require `01_KICKOFF.md` exists.

### 2. Load and Analyze Kickoff

Extract: Goal, Success Criteria, Constraints, Dependencies.

### 3. Investigate Codebase

Use Glob/Grep for file discovery. Use Task tool with Explore agent for complex analysis.

Checklist: identify affected files, check existing patterns, check related tests, check existing specs in `docs/spec/`.

### 4. Create Spec

Load template `~/.claude/templates/02_SPEC.md`. Fill with investigation results and Kickoff content.

### 5. Consistency Check

1. **With Kickoff**: Goal reflected, Success Criteria achievable, Constraints considered
2. **With existing specs**: No contradictions with `docs/spec/`, API compatibility
3. **Test strategy**: Tests exist to verify Success Criteria

If issues found: list warnings, ask user to address or document reasoning in Notes.

### 6. Update state.json

Set `current: "wf2-spec"`, `next: "wf3-plan"`.

### 7. Commit

`docs(wf): create spec <work-id>` (or `update spec`).

### 8. Completion Message

Show file path, affected components with severity, next step (`/wf3-plan`).

## validate Subcommand

Check Kickoff↔Spec consistency. Display OK/warning/missing for each criterion.

## Notes

- Do not change Kickoff content arbitrarily
- Warn on contradictions with existing specs
- Suggest Kickoff revision if technically infeasible

## Agent Reference

This skill delegates to the [spec-writer agent](../../agents/workflow/spec-writer.md).
