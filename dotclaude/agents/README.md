# Sub-Agent System

Definitions and usage of sub-agents used in the WF Management System.

## Overview

Sub-agents are specialized agents that utilize Claude Code's Task tool.
Each agent is optimized for specific tasks and can be called from workflow commands
or executed directly via the `/agent` command.

## Agent Classification

### Workflow Support Type (workflow/)

Agents that work in conjunction with workflow commands.

| Agent | Purpose | Caller |
|-------|---------|--------|
| `research` | Issue background research, related code identification | wf1-kickoff |
| `spec-writer` | Specification draft creation | wf2-spec |
| `planner` | Implementation planning | wf3-plan |
| `implementer` | Single step implementation support | wf5-implement |

### Task-Specific Type (task/)

General-purpose task agents that can be executed standalone.

| Agent | Purpose |
|-------|---------|
| `reviewer` | Code review |
| `doc-reviewer` | Document review (single file) |
| `test-writer` | Test creation |
| `refactor` | Refactoring suggestions |
| `doc-writer` | Documentation creation |

### Project Analysis Type (analysis/)

Agents for investigating and analyzing the codebase.

| Agent | Purpose |
|-------|---------|
| `codebase` | Codebase investigation |
| `dependency` | Dependency analysis |
| `impact` | Impact scope identification |

## Usage

### Via Workflow Commands

Workflow commands automatically call the appropriate agent.

```
/wf1-kickoff
→ research agent investigates Issue background

/wf2-spec
→ spec-writer agent creates specification draft
```

### Direct Invocation

Any agent can be executed directly via the `/agent` command.

```
/agent research issue=123
/agent codebase query="authentication flow implementation location"
/agent reviewer files="src/auth/*.ts"
```

## Agent Definition Format

Each agent is defined in the following format.

```markdown
# Agent: {name}

## Metadata
- **ID**: {identifier}
- **Base Type**: {explore | plan | bash | general}
- **Category**: {workflow | task | analysis}

## Purpose
{purpose}

## Context
{required state.json / documents}

## Capabilities
{what it can do}

## Constraints
{constraints}

## Instructions
{execution procedure}

## Output Format
{output format}
```

## Integration with state.json

Agent execution status is recorded in state.json.

```json
{
  "works": {
    "<work-id>": {
      "agents": {
        "last_used": "research",
        "sessions": {
          "research": {
            "status": "completed",
            "last_run": "2026-01-17T10:30:00+09:00"
          }
        }
      }
    }
  }
}
```

## Directory Structure

```
agents/
├── README.md           # This file
├── _base/
│   ├── context.md      # Common context
│   └── constraints.md  # Common constraints
├── workflow/
│   ├── research.md
│   ├── spec-writer.md
│   ├── planner.md
│   └── implementer.md
├── task/
│   ├── reviewer.md
│   ├── doc-reviewer.md
│   ├── test-writer.md
│   ├── refactor.md
│   └── doc-writer.md
└── analysis/
    ├── codebase.md
    ├── dependency.md
    └── impact.md
```
