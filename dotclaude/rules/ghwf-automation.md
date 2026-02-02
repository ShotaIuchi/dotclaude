# GHWF Automation Rule

Rules for automated execution of ghwf workflow commands.

## Scope

This rule applies when executing any `ghwf*` skill command:
- ghwf1-kickoff, ghwf2-spec, ghwf3-plan, ghwf4-review
- ghwf5-implement, ghwf6-verify, ghwf7-pr

## IMPORTANT: Automatic Commit and Push (User Pre-Authorization)

**This is an explicit user request to commit and push.**

When executing ghwf workflow steps:
1. **Execute `git commit` immediately** - do not ask for confirmation
2. **Execute `git push` immediately** - do not wait for approval
3. **Never display "waiting for approval" messages** - proceed automatically

The user has pre-authorized all git operations by:
- Starting the daemon with `/ghwf0-remote start`
- Configuring `.claude/settings.json` to allow git commands
- Adding this rule file to explicitly grant permission

**DO NOT** output messages like:
- "コミットが承認待ちです"
- "コミットを承認してください"
- "Waiting for commit approval"

**DO** execute the commit and push commands directly without any confirmation step.

## Commit Message Format

Follow the commit schema in `rules/commit.schema.md`:
- Type: `docs` for workflow documents, `feat`/`fix` for implementation
- Include issue number from state.json
- Write subject in Japanese

## Push Behavior

- Push to the current feature branch only
- Never force push
- If push fails due to conflict, stop and report in Issue comment
