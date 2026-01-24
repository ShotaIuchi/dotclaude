# WF Management System

A workflow management system for AI (Claude Code) and humans to work while viewing the same state and artifacts.

## Overview

This system solves the following challenges:

- **State Sharing**: AI and humans grasp the same work state
- **Unified Artifact Management**: Manage documents and code in a linked manner
- **Work Reproducibility**: Continue work on different PCs or sessions
- **Prevention of Off-Plan Changes**: Implement only planned work

## Setup

### Prerequisites

The following tools are required:

- `bash` - Shell script execution
- `jq` - JSON processing
- `gh` - GitHub CLI
- `git` - Version control

### Installation

#### Method 1: Using amu (Recommended)

Using [amu](https://github.com/ShotaIuchi/amu) makes it easy to manage multiple dotclaude configurations.

```bash
# 1. Clone this repository
git clone https://github.com/your-org/dotclaude.git

# 2. Run amu add in the ~/.claude directory
cd ~/.claude
amu add /path/to/dotclaude/dotclaude
```

#### Method 2: Symbolic Link

```bash
# 1. Clone this repository
git clone https://github.com/your-org/dotclaude.git

# 2. Symlink dotclaude to ~/.claude (global configuration)
ln -s /path/to/dotclaude/dotclaude ~/.claude

# Or, for per-project use
cd your-project
ln -s /path/to/dotclaude/dotclaude .claude
```

### Initialization

```bash
# Initialize WF system in the project
./path/to/dotclaude/scripts/wf-init.sh
```

This creates the following:

- `.wf/config.json` - Shared configuration
- `.wf/state.json` - Shared state
- `docs/wf/` - Workflow documents
- Adds `.wf/local.json` to `.gitignore`

## Command List

### Environment Commands (wf0-*)

| Command | Description |
|---------|-------------|
| `/wf0-restore [work-id]` | Restore existing workspace |
| `/wf0-status [work-id\|all]` | Display status |

### Workspace & Documentation Commands (wf1-5)

| Command | Description |
|---------|-------------|
| `/wf1-workspace issue=<n>` | Create new workspace |
| `/wf2-kickoff` | Create Kickoff (define goals and success criteria) |
| `/wf2-kickoff update` | Update Kickoff |
| `/wf2-kickoff revise "<instruction>"` | Revise Kickoff |
| `/wf2-kickoff chat` | Brainstorming dialogue |
| `/wf3-spec` | Create specification |
| `/wf4-plan` | Create implementation plan |
| `/wf5-review` | Record review |

### Implementation Commands (wf6-7)

| Command | Description |
|---------|-------------|
| `/wf6-implement [step]` | Implement one step of the Plan |
| `/wf7-verify` | Test and build verification |
| `/wf7-verify pr` | Create PR after verification |

### Agents

| Command | Description |
|---------|-------------|
| `/agent <name> [params]` | Directly invoke a sub-agent |

## Workflow

### Basic Flow

```
/wf1-workspace issue=123
    ↓
/wf2-kickoff (define goals and success criteria)
    ↓
/wf3-spec (develop change specification)
    ↓
/wf4-plan (plan implementation steps)
    ↓
/wf5-review (optional: plan review)
    ↓
/wf6-implement (implement one step at a time)
    ↓ ↑ repeat
/wf7-verify pr (verify and create PR)
```

### Work Restoration

```bash
# Continue work on a different PC
/wf0-restore FEAT-123-export-csv
```

### Kickoff Revision

```bash
# Revise with instructions
/wf2-kickoff revise "Narrow the scope to CSV export only"
```

## Repository Structure

```
dotclaude/                 # Repository root
├── dotclaude/             # Target to link to ~/.claude
│   ├── agents/            # Sub-agent definitions
│   ├── commands/          # Slash command definitions
│   ├── guides/            # Architecture guides
│   ├── examples/          # Configuration file examples
│   ├── scripts/           # Shell scripts
│   └── templates/         # Document templates
├── .gitignore
└── README.md
```

## Directory Structure

```
your-project/
├── .wf/
│   ├── config.json      # Shared configuration (committed)
│   ├── state.json       # Shared state (committed)
│   └── local.json       # Local configuration (gitignored)
├── docs/wf/
│   └── FEAT-123-slug/
│       ├── 00_KICKOFF.md
│       ├── 01_SPEC.md
│       ├── 02_PLAN.md
│       ├── 03_REVIEW.md
│       ├── 04_IMPLEMENT_LOG.md
│       └── 05_REVISIONS.md
└── .claude/             # Symbolic link from dotclaude
    └── commands/        # Slash commands
        ├── wf1-workspace.md
        ├── wf0-restore.md
        └── ...
```

## Configuration Files

### config.json

```json
{
  "default_base_branch": "develop",
  "base_branch_candidates": ["develop", "main", "master"],
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
  }
}
```

### state.json

```json
{
  "active_work": "FEAT-123-export-csv",
  "works": {
    "FEAT-123-export-csv": {
      "current": "wf6-implement",
      "next": "wf7-verify",
      "git": {
        "base": "develop",
        "branch": "feat/123-export-csv"
      }
    }
  }
}
```

## Sub-Agents

A collection of specialized agents utilizing Claude Code's Task tool.
They work in conjunction with workflow commands and can also be invoked directly via the `/agent` command.

### Workflow Support Type

| Agent | Purpose | Caller |
|-------|---------|--------|
| `research` | Issue background research, related code identification | wf2-kickoff |
| `spec-writer` | Specification draft creation | wf3-spec |
| `planner` | Implementation planning | wf4-plan |
| `implementer` | Single step implementation support | wf6-implement |

### Task-Specific Type

| Agent | Purpose |
|-------|---------|
| `reviewer` | Code review |
| `test-writer` | Test creation |
| `refactor` | Refactoring suggestions |
| `doc-writer` | Documentation creation |

### Project Analysis Type

| Agent | Purpose |
|-------|---------|
| `codebase` | Codebase investigation |
| `dependency` | Dependency analysis |
| `impact` | Impact scope identification |

### Agent Usage Examples

```bash
# Issue background research
/agent research issue=123

# Codebase investigation
/agent codebase query="authentication flow implementation location"

# Code review
/agent reviewer files="src/auth/*.ts"

# Impact scope analysis
/agent impact target="src/utils/format.ts"
```

See `dotclaude/agents/README.md` for details.

## Important Constraints

### 1. No Off-Plan Changes

`/wf6-implement` implements only the steps documented in the Plan.
If changes outside the Plan are needed, update the Plan first.

### 2. One Execution = One Step

`/wf6-implement` implements only one step per execution.
This makes work progress clear.

### 3. Preserve Original Content

When updating Kickoff, record history in `05_REVISIONS.md`.

### 4. Dependencies Required

For second and subsequent workflows, clearly document dependencies.

## Templates

Document templates are available in the `dotclaude/templates/` directory.
Customize them according to your project.

### Template Design Philosophy

Templates are designed as "interfaces to align AI and human thinking."

| Principle | Description |
|-----------|-------------|
| **Create frames for required items even if empty** | Visualize gaps and prevent omissions |
| **Explicitly mark where AI should not decide alone** | List items requiring human judgment in Open Questions section |
| **Fix review locations** | Unify structure and clarify check points |

### Template Structure

| File | Role | Key Sections |
|------|------|--------------|
| `00_KICKOFF.md` | Goal and success criteria definition | Goal, Success Criteria, Dependencies (structured), Open Questions |
| `01_SPEC.md` | Change specification | Scope (In/Out), Users/Use-cases, Requirements (FR/NFR separated), Acceptance Criteria (Given/When/Then) |
| `02_PLAN.md` | Implementation plan | Overview, Steps (simple structure), Risks, Rollback |
| `03_REVIEW.md` | Review record | Review Result (Status), Findings, Required Changes, Nice-to-have |
| `04_IMPLEMENT_LOG.md` | Implementation log | Date-based log format (Step, Summary, Files, Test Result) |
| `05_REVISIONS.md` | Change history | Revision number-based (Reason, Changed Sections) |

## Troubleshooting

### If state.json is corrupted

```bash
# Manually fix using examples/state.json as reference
# Or initialize
echo '{"active_work": null, "works": {}}' > .wf/state.json
```

### If branch is not found

```bash
# Fetch latest from remote
git fetch --all --prune
# Restore again
/wf0-restore
```

### If worktree remains

```bash
# List worktrees
git worktree list
# Remove
git worktree remove .worktrees/feat-123-slug
```

## License

MIT
