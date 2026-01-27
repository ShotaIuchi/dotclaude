---
name: commit
description: Commit changes via sub-agent
argument-hint: "[--files <path>] [--dry-run] [--amend] [message | scope instruction]"
context: fork
agent: general-purpose
---

# /commit

Commit changes via sub-agent with auto-generated commit messages.

## Purpose

- Auto-generate commit messages
- Create commits following commit.schema.md

## Usage

```
/commit [--files <path>] [message | scope instruction]
```

## Examples

```bash
# Auto-generate commit message (staged files only, or all if nothing staged)
/commit

# Specify commit message
/commit feat: Add user authentication

# Scope by instruction (natural language)
/commit 認証機能の変更だけ

# Scope by file path
/commit --files src/auth/

# Combine message and scope
/commit --files src/auth/ feat: Add login feature
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

### 2. Parse Arguments

```
Parse $ARGUMENTS:
1. Extract --files <path> if present (glob pattern or directory)
2. Extract --dry-run, --amend flags
3. Remaining text = commit message or scope instruction
```

Determine scope instruction vs commit message:
- If text looks like a commit message (starts with type prefix like `feat:`, `fix:`, etc.): treat as message
- Otherwise: treat as **scope instruction** (natural language filter for which files to include)

### 3. Build Prompt

Check commit schema location:

```
Schema locations (check in order):
1. docs/rules/commit.schema.md (project)
2. .claude/rules/commit.schema.md (project)
3. ~/.claude/rules/commit.schema.md (global)
```

### 4. Launch Subagent

Use the Task tool with the following parameters:

| Parameter | Value |
|-----------|-------|
| `subagent_type` | `general-purpose` |
| `description` | `Commit changes` |
| `prompt` | See below |

#### Prompt Template

```
You are a git commit agent.
Always respond in Japanese.

Current directory: $CWD

## Staging Strategy

Determine which files to stage based on the following priority:

### Priority 1: --files option
If --files was specified, stage ONLY files matching the given path/glob pattern.

### Priority 2: Scope instruction (natural language)
If a scope instruction was given (e.g., "認証機能の変更だけ"):
1. Run `git status` and `git diff` to see all changes
2. Select ONLY files that match the scope instruction
3. Stage only those files

### Priority 3: Already staged files
If files are already staged (`git diff --cached` is non-empty) and no scope/files specified:
- Commit ONLY the already staged files
- Do NOT stage additional files

### Priority 4: Default (nothing staged, no scope)
If nothing is staged and no scope specified:
- Review all changed files
- Stage appropriate files (exclude .env, credentials, secrets, etc.)

## Task

1. Check changes with `git status` and `git diff --cached`
2. Apply the staging strategy above
3. Determine commit message:
   - If user specified message: Use "$MESSAGE"
   - Otherwise: Generate appropriate message from staged changes
4. Execute `git commit`

## Commit Message Rules

- Format: `<type>: <subject>`
- Types: feat, fix, docs, style, refactor, test, chore
- Subject: 50 characters or less, imperative mood, no period at end
- Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>

## Execution

Complete the commit following the steps above.
```

### 5. Display Result

```
Display commit summary:
- Files committed
- Commit message
- Commit hash
```

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--files <path>` | Stage only files matching path/glob pattern | - |
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
