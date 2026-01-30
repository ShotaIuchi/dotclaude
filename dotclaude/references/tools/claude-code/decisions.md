# Claude Code Usage Decisions

## Adopted Patterns

| Pattern | Purpose | Adoption Reason | Alternatives |
|---------|---------|----------------|-------------|
| Self-contained skills/ | Command definition | Complete command logic in single file | Separate agents directory |
| references/ knowledge base | Knowledge sharing | Referenced from multiple skills | Duplicate content in each skill |
| context: fork | Sub-agents | Save main context tokens | Same-context execution |
| .wf/state.json | State management | Structured workflow state | Filename-based detection |
| .wf/memory.json | Session memory | Survives compaction | Context-dependent |
| hooks.json | Automated validation | Debug log detection, git safety | Manual checks |

## Rejected Options

| Pattern | Rejection Reason |
|---------|-----------------|
| MCP Server integration | File-based approach is sufficient; avoids server management complexity |
| Custom CLI wrapper | Claude Code standard commands are sufficient |
| DB-backed state management | Prefer simplicity of JSON files |
| Single monolithic CLAUDE.md | Split into skills/references for separation of concerns |
| Separate agents/ directory | Inline agent logic into skills for simpler structure |

## Related Documents

- [best-practices.md](best-practices.md) — Skill authoring best practices
