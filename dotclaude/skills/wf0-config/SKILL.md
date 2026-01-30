---
name: wf0-config
description: .wf/config.json の対話式設定エディタ
argument-hint: "[show | init | <category>]"
---

**Always respond in Japanese.**

# /wf0-config

Interactively edit `.wf/config.json` settings.

## Usage

```
/wf0-config                  # Interactive mode (category selection)
/wf0-config show             # Display current settings
/wf0-config init             # Initialize config.json
/wf0-config <category>       # Edit specific category
```

## Categories

| Category | Key Settings |
|----------|-------------|
| `branch` | `default_base_branch`, `base_branch_candidates`, `allow_pattern_candidates`, `branch_prefix` |
| `worktree` | `worktree.enabled`, `worktree.root_dir` |
| `commit` | `commit.type_detection`, `commit.default_type` |
| `verify` | `verify.test`, `verify.build`, `verify.lint` |
| `jira` | `jira.project`, `jira.domain` |

## Processing

### `show`

Display all settings formatted. Show "(not set)" with default hints for unconfigured values.

### `init`

1. If config exists, ask to overwrite (AskUserQuestion)
2. Ask required settings: default base branch, enable worktree
3. Create config.json

### Interactive mode (no arguments)

1. **Category selection**: AskUserQuestion with multiSelect=true listing all 5 categories
2. **Edit each selected category**: Ask about individual settings using AskUserQuestion for each

### `<category>`

Skip category selection, directly edit the specified category.

### Category Dialogs

Each category presents AskUserQuestion prompts for its settings. Current values shown when available.

- **Branch**: base branch (develop/main/master/Other), candidates, prefix config, allow patterns
- **Worktree**: enable/disable, root directory (.worktrees/Other)
- **Commit**: type detection (auto/manual/fixed), default type (feat/fix/chore/refactor)
- **Verify**: test/build/lint commands (npm/yarn/pnpm/Other for each)
- **Jira**: project key, domain

### Save

1. Show summary of changes (old→new)
2. Ask confirmation (AskUserQuestion: Save/Cancel)
3. Write to `.wf/config.json`

## Config Schema

```json
{
  "default_base_branch": "develop",
  "base_branch_candidates": ["develop", "main", "master"],
  "allow_pattern_candidates": ["release/.*", "hotfix/.*"],
  "branch_prefix": { "FEAT": "feat", "FIX": "fix", "REFACTOR": "refactor", "CHORE": "chore", "RFC": "rfc" },
  "worktree": { "enabled": false, "root_dir": ".worktrees" },
  "commit": { "type_detection": "auto", "default_type": "feat" },
  "verify": { "test": "npm test", "build": "npm run build", "lint": "npm run lint" },
  "jira": { "project": null, "domain": null }
}
```

## Notes

- `show` without config: suggest `/wf0-config init`
- `<category>` without config: error, suggest `init` first
- No arguments without config: auto-enter `init` flow
- Preserve unedited settings
