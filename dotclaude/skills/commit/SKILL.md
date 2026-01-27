---
name: commit
description: Commit changes via sub-agent
argument-hint: "[message]"
---

# /commit

Commit changes via sub-agent with auto-generated commit messages.

## Purpose

- Auto-generate commit messages
- Create commits following commit.schema.md

## Usage

```
/commit [message]
```

## Examples

```bash
# Auto-generate commit message
/commit

# Specify message
/commit feat: Add user authentication

# With quoted message
/commit "Add login feature"
```

## Processing

Parse $ARGUMENTS and execute the following:

### 1. Pre-flight Check

```
# Check for staged or unstaged changes
if no changes to commit:
  Display: "Nothing to commit"
  Exit
```

### 2. Build Prompt

Check commit schema location:

```
Schema locations (check in order):
1. docs/rules/commit.schema.md (project)
2. .claude/rules/commit.schema.md (project)
3. ~/.claude/rules/commit.schema.md (global)
```

### 3. Launch Subagent

Use the Task tool with the following parameters:

| Parameter | Value |
|-----------|-------|
| `subagent_type` | `general-purpose` |
| `description` | `Commit changes` |
| `prompt` | See below |

#### Prompt Template

```
You are a git commit agent.

Current directory: $CWD

## Task

1. Check changes with `git status`
2. Check staged changes with `git diff --cached`
3. Stage unstaged changes appropriately
   - Exclude sensitive files (.env, credentials, secrets, etc.)
   - Review changed files and stage only necessary ones
4. Determine commit message:
   - If user specified message: Use "$ARGUMENTS"
   - Otherwise: Generate appropriate message from changes
5. Execute `git commit`

## Commit Message Rules

- Format: `<type>: <subject>`
- Types: feat, fix, docs, style, refactor, test, chore
- Subject: 50 characters or less, imperative mood, no period at end
- Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>

## Execution

Complete the commit following the steps above.
```

### 4. Display Result

```
Display commit summary:
- Files committed
- Commit message
- Commit hash
```

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--dry-run` | Show what would be committed without committing | off |
| `--amend` | Amend the previous commit | off |

### Option Handling

```
if --dry-run in $ARGUMENTS:
  Add to prompt:
  "## Dry-run Mode
   Do not actually commit, only show what would be committed.
   Report `git diff --cached` and `git status` results and exit."

if --amend in $ARGUMENTS:
  Add to prompt:
  "## Amend Mode
   1. First show previous commit with `git log -1 --oneline`
   2. Confirm with user: 'Do you want to amend this commit?'
   3. After confirmation, use `git commit --amend`
   Warning: --amend rewrites the previous commit.
   Do not use on already pushed commits."
```

## Notes

- If pre-commit hooks exist, they will be executed
- Exit with error if conflicts exist
- Use `--amend` only after confirming the previous commit is yours
