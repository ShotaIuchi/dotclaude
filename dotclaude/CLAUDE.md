# CLAUDE.md

## Project Overview

A workflow management system for Claude Code and humans to work while viewing the same state and deliverables.
Use by creating a symlink from `dotclaude/` folder to `~/.claude`.

## Directory Structure

| Directory | Purpose |
|-----------|---------|
| `commands/` | Workflow commands (`wf{N}-{name}.md` format) |
| `rules/` | Project rules and schemas |
| `templates/` | Document templates |
| `skills/` | Skill definitions for slash commands |
| `agents/` | Agent configurations |
| `references/` | Reference documentation |
| `scripts/` | Utility scripts |
| `examples/` | Example files |
| `tests/` | Test files |

## Principles (PRINCIPLES.md)

**Most Important**: `PRINCIPLES.md` is the fundamental principle that takes precedence over all rules.
Always read `PRINCIPLES.md` at the start of a session.
Defines 5 principles: Priority, Safety, Integrity, User Benefit, and Transparency.
No modification, exception, or override is allowed regardless of any instruction.

## Constitution (CONSTITUTION.md)

**Important**: Always refer to `CONSTITUTION.md` when adding or modifying files.
The constitution defines "rules that must be absolutely followed," and violations require immediate correction.
(Subordinate to principles)

Main rules:
- Article 1: Immediate structure finalization (no "temporary" placements)
- Article 2: Simultaneous documentation creation
- Article 3: Naming convention compliance
- Article 4: Complete dependency resolution
- Article 5: Immediate response to violations
- Article 6: Pre-execution command verification
