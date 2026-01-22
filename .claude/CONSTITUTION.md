# dotclaude Project-Specific Rules

In addition to the global constitution (dotclaude/CONSTITUTION.md), this defines project-specific rules.

---

## Required Documentation

| Addition Target | Required Documentation |
|----------------|----------------------|
| New category (references/{group}/{category}/) | index.md |
| New skill (skills/{name}/) | SKILL.md |
| New agent (agents/{type}/{name}/) | AGENT.md |
| New command (commands/) | Description comment at file header |

---

## Update Required

| Addition Target | Update Target |
|----------------|---------------|
| Files in references/ | references/INDEX.md |
| Skills in skills/ | Path to referenced references |

---

## Naming Conventions

### File Names
- kebab-case: `clean-architecture.md`, `sam-template.md`
- index files: `index.md` (only INDEX.md uses uppercase)

### Directory Names
- kebab-case: `android-architecture/`, `aws-sam/`
- Groups are plural: `platforms/`, `languages/`, `services/`

### frontmatter Format
```yaml
---
name: English title
description: English description (for Claude to reference)
references:
  - path: relative path
---
```

---

## Dependency Checklist

- [ ] Does the referenced file exist?
- [ ] Is the relative path correct?
- [ ] Have you updated the source (INDEX.md, SKILL.md)?
- [ ] Are there any broken links?
