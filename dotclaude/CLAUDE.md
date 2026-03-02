# CLAUDE.md

## Project Overview

A workflow management system for Claude Code and humans to work while viewing the same state and deliverables.
Use by creating a symlink from `dotclaude/` folder to `~/.claude`.

## Principles (PRINCIPLES.md)

**Most Important**: `PRINCIPLES.md` is the fundamental principle that takes precedence over all rules.
Always read `PRINCIPLES.md` at the start of a session.

## Constitution (CONSTITUTION.md)

**Important**: Always refer to `CONSTITUTION.md` when adding or modifying files.

## Feature Development Workflow

### feature-dev Plugin (Required)

Install the **feature-dev** plugin from the marketplace for structured feature development:

```
/plugin install feature-dev@claude-plugins-official
```

This provides a 7-phase workflow (Discovery, Exploration, Clarifying Questions, Architecture, Implementation, Review, Summary) with three specialized agents: `code-explorer`, `code-architect`, and `code-reviewer`.

Use `/feature-dev <description>` to start the interactive workflow.

### feature-auto Skill

Use `/feature-auto <description>` to run the full feature-dev 7-phase workflow without human intervention. All human-in-the-loop checkpoints are overridden with autonomous decision-making.
