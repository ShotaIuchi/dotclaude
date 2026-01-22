# dotclaude Project CLAUDE.md

## Project Overview

A workflow management system for Claude Code and humans to work while viewing the same state and deliverables.
Use by creating a symlink from `dotclaude/` folder to `~/.claude`.

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

## Development Guidelines

### Commands (commands/*.md)

- File names follow `wf{N}-{name}.md` format
- Environment-related are `wf0-*`, document-related are `wf1-4`, implementation-related are `wf5-6`
- Command arguments are explicitly defined in Markdown
- State management is done through `.wf/state.json`
