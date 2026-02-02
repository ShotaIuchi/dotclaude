# GHWF Automation Rule

Rules for automated execution of ghwf workflow commands.

## Scope

This rule applies when executing any `ghwf*` skill command:
- ghwf1-kickoff, ghwf2-spec, ghwf3-plan, ghwf4-review
- ghwf5-implement, ghwf6-verify, ghwf7-pr

## Automatic Commit and Push

When executing ghwf workflow steps, **commit and push are explicitly authorized**.

Do not ask for confirmation before:
- Creating commits with workflow documents
- Pushing changes to the remote branch

This authorization is granted because:
1. ghwf workflows are designed for automated execution via daemon
2. All changes are tracked in `.wf/` documents and state.json
3. Users have explicitly started the workflow with `/ghwf0-remote start`

## Commit Message Format

Follow the commit schema in `rules/commit.schema.md`:
- Type: `docs` for workflow documents, `feat`/`fix` for implementation
- Include issue number from state.json
- Write subject in Japanese

## Push Behavior

- Push to the current feature branch only
- Never force push
- If push fails due to conflict, stop and report in Issue comment
