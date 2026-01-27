---
name: wf0-config
description: Interactive configuration editor for .wf/config.json
---

# /wf0-config

Command to interactively edit `.wf/config.json` settings.

## Usage

```
/wf0-config                  # Interactive mode (start with category selection)
/wf0-config show             # Display current settings
/wf0-config init             # Initialize config.json
/wf0-config <category>       # Edit specific category only
```

## Arguments

- `show`: Display current settings in formatted output
- `init`: Initialize `.wf/config.json` with required settings
- `<category>`: Edit specific category only
  - `branch`: Branch settings
  - `worktree`: Git worktree settings
  - `commit`: Commit message settings
  - `verify`: Verification command settings
  - `jira`: Jira integration settings

## Configuration Categories

| Category | Settings | Description |
|----------|----------|-------------|
| branch | `default_base_branch`, `base_branch_candidates`, `allow_pattern_candidates`, `branch_prefix` | Branch naming rules |
| worktree | `worktree.enabled`, `worktree.root_dir` | git worktree settings |
| commit | `commit.type_detection`, `commit.default_type` | Commit message settings |
| verify | `verify.test`, `verify.build`, `verify.lint` | Verification commands |
| jira | `jira.project`, `jira.domain` | Jira integration |

## Processing

Parse $ARGUMENTS and execute the following processing.

> **Note**: `$ARGUMENTS` is a placeholder representing the command-line arguments passed to the command.
> Claude Code parses this internally to determine the subcommand and options.

### 1. Check for .wf directory

```bash
if [ ! -d ".wf" ]; then
  echo "WF directory not found. Creating .wf/"
  mkdir -p .wf
fi
```

### 2. Handle Subcommands

#### `show` subcommand

Display current configuration in formatted output:

```
WF Configuration
===

File: .wf/config.json

Branch Settings:
   Default base branch:    develop
   Base branch candidates: develop, main, master
   Allow patterns:         release/.*, hotfix/.*
   Branch prefix:
     FEAT     -> feat
     FIX      -> fix
     REFACTOR -> refactor
     CHORE    -> chore
     RFC      -> rfc

Worktree Settings:
   Enabled:  true
   Root dir: .worktrees

Commit Settings:
   Type detection: auto
   Default type:   feat

Verify Commands:
   Test:  npm test
   Build: npm run build
   Lint:  npm run lint

Jira Settings:
   Project: PROJ
   Domain:  your-company.atlassian.net
```

If a setting is not configured, show "(not set)" with default value hint.

#### `init` subcommand

1. Check if `.wf/config.json` exists
2. If exists, ask for confirmation to overwrite using AskUserQuestion:
   ```
   Question: ".wf/config.json already exists. Overwrite?"
   Options:
   - "Overwrite" - Delete and recreate
   - "Cancel" - Keep existing
   ```
3. Ask required settings interactively:
   - Default base branch (required)
   - Enable worktree (optional)
4. Create config.json with provided values

#### No arguments (Interactive mode)

Use 2-step interactive flow:

**Step 1: Category Selection**

Use AskUserQuestion with multiSelect=true:

```
Question: "Which categories do you want to edit?"
Header: "Categories"
Options:
- label: "Branch settings"
  description: "Default base branch, candidates, prefix rules"
- label: "Worktree settings"
  description: "Enable/disable git worktree, root directory"
- label: "Commit settings"
  description: "Commit type detection, default type"
- label: "Verify settings"
  description: "Test, build, lint commands"
- label: "Jira settings"
  description: "Jira project and domain configuration"
```

**Step 2: Edit Selected Categories**

For each selected category, ask about individual settings.

#### `<category>` argument

Skip Step 1 and directly edit the specified category.

### 3. Category-specific Dialogs

#### Branch Settings

```
Question: "Default base branch?"
Header: "Base"
Current: develop (if set)
Options:
- "develop" (if current)
- "main"
- "master"
- "Other" (free input)
```

```
Question: "Additional base branch candidates?"
Header: "Candidates"
Description: "Branches that can be used as base (comma-separated)"
Options:
- "Keep current: develop, main, master"
- "Reset to defaults"
- "Other" (free input)
```

```
Question: "Branch prefix configuration?"
Header: "Prefix"
Options:
- "Keep current"
- "Use defaults (feat/fix/refactor/chore/rfc)"
- "Customize" -> additional dialog for each type
```

```
Question: "Allow pattern candidates?"
Header: "Patterns"
Description: "Regex patterns for branches that can be used as base (e.g., release/.*, hotfix/.*)"
Current: release/.*, hotfix/.*
Options:
- "Keep current"
- "Reset to defaults (release/.*, hotfix/.*)"
- "Other" (free input, comma-separated)
```

#### Worktree Settings

```
Question: "Enable git worktree?"
Header: "Worktree"
Description: "When enabled, each workflow works in isolated directories"
Current: disabled
Options:
- "Enable (Recommended)"
  description: "Work in isolated directories per workflow"
- "Disable"
  description: "Work in single repository"
```

If enabled:
```
Question: "Worktree root directory?"
Header: "Root Dir"
Options:
- ".worktrees (default)"
- "../worktrees"
- "Other" (free input)
```

#### Commit Settings

```
Question: "Commit type detection method?"
Header: "Detection"
Options:
- "auto (Recommended)"
  description: "Detect from branch prefix automatically"
- "manual"
  description: "Always ask for commit type"
- "fixed"
  description: "Use default type always"
```

```
Question: "Default commit type?"
Header: "Default"
Options:
- "feat"
- "fix"
- "chore"
- "refactor"
```

#### Verify Settings

```
Question: "Test command?"
Header: "Test"
Current: npm test
Options:
- "npm test"
- "yarn test"
- "pnpm test"
- "Other" (free input)
```

```
Question: "Build command?"
Header: "Build"
Current: npm run build
Options:
- "npm run build"
- "yarn build"
- "pnpm build"
- "Other" (free input)
```

```
Question: "Lint command?"
Header: "Lint"
Current: npm run lint
Options:
- "npm run lint"
- "yarn lint"
- "pnpm lint"
- "Other" (free input)
```

#### Jira Settings

```
Question: "Jira project key?"
Header: "Project"
Description: "e.g., PROJ, MYAPP"
Options:
- "Skip (disable Jira integration)"
- "Other" (free input)
```

```
Question: "Jira domain?"
Header: "Domain"
Description: "e.g., your-company.atlassian.net"
Options:
- "Other" (free input)
```

### 4. Save Configuration

After all dialogs complete:

1. Show summary of changes:
   ```
   Configuration Changes:

   Branch:
     default_base_branch: develop -> main

   Worktree:
     enabled: false -> true
     root_dir: (new) .worktrees

   Save changes?
   ```

2. Ask for confirmation using AskUserQuestion:
   ```
   Question: "Save these changes?"
   Options:
   - "Save"
   - "Cancel"
   ```

3. Write to `.wf/config.json`

4. Display completion message:
   ```
   Configuration saved to .wf/config.json

   Run /wf0-config show to verify settings
   ```

## Config Schema

Full config.json schema:

```json
{
  "default_base_branch": "develop",
  "base_branch_candidates": ["develop", "main", "master"],
  "allow_pattern_candidates": ["release/.*", "hotfix/.*"],
  "branch_prefix": {
    "FEAT": "feat",
    "FIX": "fix",
    "REFACTOR": "refactor",
    "CHORE": "chore",
    "RFC": "rfc"
  },
  "worktree": {
    "enabled": false,
    "root_dir": ".worktrees"
  },
  "commit": {
    "type_detection": "auto",
    "default_type": "feat"
  },
  "verify": {
    "test": "npm test",
    "build": "npm run build",
    "lint": "npm run lint"
  },
  "jira": {
    "project": null,
    "domain": null
  }
}
```

## Notes

- If `.wf/config.json` does not exist:
  - `show`: Display message "No config found. Run `/wf0-config init` to create one."
  - `init`: Proceed with initialization
  - No arguments: Automatically enter `init` flow with message "No config found. Starting initialization..."
  - `<category>`: Display error "Config not found. Run `/wf0-config init` first."
- Preserve existing settings that are not being edited
- Validate branch names and commands before saving
- Show defaults for unset values in `show` output
