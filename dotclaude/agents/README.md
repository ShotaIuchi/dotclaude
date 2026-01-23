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
| [`research`](workflow/research.md) | Issue background research, related code identification | wf1-kickoff |
| [`spec-writer`](workflow/spec-writer.md) | Specification draft creation | wf2-spec |
| [`planner`](workflow/planner.md) | Implementation planning | wf3-plan |
| [`implementer`](workflow/implementer.md) | Single step implementation support | wf5-implement |

### Task-Specific Type (task/)

General-purpose task agents that can be executed standalone.

| Agent | Purpose |
|-------|---------|
| [`reviewer`](task/reviewer.md) | Code review |
| [`doc-reviewer`](task/doc-reviewer.md) | Document review (single file) |
| [`doc-fixer`](task/doc-fixer.md) | Apply fixes from review file |
| [`test-writer`](task/test-writer.md) | Test creation |
| [`refactor`](task/refactor.md) | Refactoring suggestions |
| [`doc-writer`](task/doc-writer.md) | Documentation creation |

### Project Analysis Type (analysis/)

Agents for investigating and analyzing the codebase.

| Agent | Purpose |
|-------|---------|
| [`codebase`](analysis/codebase.md) | Codebase investigation |
| [`dependency`](analysis/dependency.md) | Dependency analysis |
| [`impact`](analysis/impact.md) | Impact scope identification |

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

#### Command Arguments

| Argument | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `agent_name` | string | Yes | - | Name of the agent to execute (e.g., `research`, `codebase`) |
| `<param>=<value>` | varies | No | - | Agent-specific parameters passed as key=value pairs |

Common parameters by agent type:
- **workflow agents**: `issue`, `work_id`, `phase`
- **task agents**: `files`, `target`, `scope`
- **analysis agents**: `query`, `path`, `depth`

See individual agent documentation for complete parameter specifications.

## Parallel Execution

**独立したagentは並列実行する。** 詳細は [`rules/parallel-execution.md`](../rules/parallel-execution.md) を参照。

### 並列実行可否

| カテゴリ | 並列実行 | 理由 |
|----------|----------|------|
| analysis/* | ✅ 可能 | 読み取り専用、副作用なし |
| task/reviewer | ✅ 可能 | 読み取り専用 |
| task/doc-reviewer | ✅ 可能 | 読み取り専用 |
| workflow/* | ⚠️ 注意 | state.json更新の競合に注意 |
| task/doc-fixer | ❌ 順次 | ファイル編集の競合回避 |

### 例: 並列レビュー

```
# 3つのagentを同時起動
/agent reviewer files="src/auth/*.kt"
/agent impact path="src/auth"
/agent codebase query="認証の既存実装"
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

Agent execution status is recorded in state.json. For the complete schema definition, see [state.json schema](../rules/state.schema.md).

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

> **Note**: This structure is maintained manually. For verification, run `ls -R agents/` from the project root.

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
│   ├── doc-fixer.md
│   ├── test-writer.md
│   ├── refactor.md
│   └── doc-writer.md
└── analysis/
    ├── codebase.md
    ├── dependency.md
    └── impact.md
```
