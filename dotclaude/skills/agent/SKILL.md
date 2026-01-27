---
name: agent
description: Invoke sub-agents for specific tasks
argument-hint: "<agent_name> [param=value...]"
---

**Always respond in Japanese.**

# /agent

Command to directly invoke sub-agents.

## Usage

```
/agent <agent_name> [parameters...]
```

## Agent List

### Task-Specific Type

| Agent | Purpose | Base Type |
|-------|---------|-----------|
| `reviewer` | Code review | general |
| `test-writer` | Test creation | general |
| `refactor` | Refactoring suggestions | plan |
| `doc-writer` | Documentation creation | general |

### Project Analysis Type

| Agent | Purpose | Base Type |
|-------|---------|-----------|
| `codebase` | Codebase investigation | explore |
| `dependency` | Dependency analysis | explore |
| `impact` | Impact scope identification | explore |

## Usage Examples

```bash
# Codebase investigation
/agent codebase query="authentication flow implementation location"

# Code review
/agent reviewer files="src/auth/*.ts"

# Dependency analysis
/agent dependency package="lodash"

# Impact scope identification
/agent impact target="src/utils/format.ts"

# Test creation
/agent test-writer target="src/services/user.ts"

# Documentation creation
/agent doc-writer target="src/api/" type="api"
```

## Processing

Parse $ARGUMENTS and execute the following processing.

### 1. Parse Agent Name and Parameters

```bash
# Get first word from $ARGUMENTS as agent name
agent_name=$(echo "$ARGUMENTS" | awk '{print $1}')
params=$(echo "$ARGUMENTS" | cut -d' ' -f2-)
```

### 2. Load Agent Definition

Agent definition file locations (check in order):

```
# Project-specific (priority)
.claude/agents/task/<agent_name>.md
.claude/agents/analysis/<agent_name>.md

# Global (fallback)
~/.claude/agents/task/<agent_name>.md
~/.claude/agents/analysis/<agent_name>.md

# dotclaude project location (if using symlink)
dotclaude/agents/task/<agent_name>.md
dotclaude/agents/analysis/<agent_name>.md
```

Load the corresponding agent definition from the first matching location.

### 3. Prepare Context

Load the following files to build context:

1. `~/.claude/agents/_base/context.md` - Common context
2. `~/.claude/agents/_base/constraints.md` - Common constraints
3. Agent definition file

### 4. Check Current Work Status (Optional)

If there is active work, pass that information as well:

```bash
work_id=$(jq -r '.active_work // empty' .wf/state.json 2>/dev/null)
if [ -n "$work_id" ]; then
  docs_dir="docs/wf/$work_id"
  # Can also load related documents
fi
```

### 5. Execute Sub-Agent

Use Claude Code's Task tool to launch the sub-agent.

Select appropriate subagent_type according to agent's Base Type:

| Base Type | subagent_type |
|-----------|---------------|
| explore | Explore |
| plan | Plan |
| bash | Bash |
| general | general-purpose |

### 6. Record Execution Results

If there is active work, add execution record to state.json:

```bash
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
jq ".works[\"$work_id\"].agents.last_used = \"$agent_name\"" .wf/state.json > tmp && mv tmp .wf/state.json
jq ".works[\"$work_id\"].agents.sessions[\"$agent_name\"] = {\"status\": \"completed\", \"last_run\": \"$timestamp\"}" .wf/state.json > tmp && mv tmp .wf/state.json
```

### 7. Display Results

Format and display the agent's execution results.

## Parameter Format

Parameters are specified in `key=value` format.

```
/agent codebase query="search query"
/agent reviewer files="src/**/*.ts" focus="security"
```

## Error Handling

### When Agent Not Found

```
Error: Agent '<agent_name>' not found

Available agents:
- task: reviewer, test-writer, refactor, doc-writer
- analysis: codebase, dependency, impact
```

### When Required Parameters Missing

```
Error: Required parameters missing

Usage: /agent <agent_name> <param>=<value>

Example: /agent codebase query="search query"
```

## Notes

- Analysis type agents operate in read-only mode
- Execution results are recorded in state.json (if there is active work)
- **Agent definition files must exist** before using an agent. Use `/agent list` to verify available agents
- Workflow support agents (research, spec-writer, planner, implementer) have been integrated into skills (use `/wf1-kickoff`, `/wf2-spec`, `/wf3-plan`, `/wf5-implement` instead)
