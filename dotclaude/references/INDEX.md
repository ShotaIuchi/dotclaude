# References Index

Index of shared references referenced from skills/.

---

## Directory Structure

```
references/
├── INDEX.md                    # This index + design principles links
├── common/                     # Common to all categories (kept at root)
│   ├── clean-architecture.md
│   └── testing-strategy.md
├── platforms/                  # Platforms
│   ├── android/
│   │   ├── decisions.md
│   │   ├── conventions.md
│   │   └── architecture-patterns.md
│   └── ios/
│       ├── decisions.md
│       ├── conventions.md
│       └── architecture-patterns.md
├── languages/                  # Languages
│   └── kotlin/
│       ├── decisions.md
│       ├── conventions.md
│       ├── library-patterns.md
│       ├── feature-patterns.md
│       └── kmp-architecture-patterns.md
├── services/                   # Cloud services
│   └── aws/
│       ├── decisions.md
│       ├── conventions.md
│       └── sam-architecture-patterns.md
└── tools/                      # Development tools
    └── claude-code/
        ├── decisions.md
        └── best-practices.md
```

---

## Design Principles (External Links)

Authoritative sources for design principles that all skills should reference.

| Principle | Description | Link | Priority |
|-----------|-------------|------|----------|
| Clean Architecture | Separation of concerns through concentric layers with dependency rules pointing inward | [The Clean Architecture (Robert C. Martin)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html) | ★★★ Original |
| SOLID Principles | Five object-oriented design principles (Single Responsibility, Open-Closed, Liskov Substitution, Interface Segregation, Dependency Inversion) | [SOLID (Wikipedia)](https://en.wikipedia.org/wiki/SOLID) | ★★ Foundation |
| Dependency Injection | Design pattern where objects receive dependencies from external sources rather than creating them | [Dependency Injection (Wikipedia)](https://en.wikipedia.org/wiki/Dependency_injection) | ★★ Foundation |

---

## Category Index

### common/ - Common References

| File | Description | Related Skills |
|------|-------------|----------------|
| [clean-architecture.md](common/clean-architecture.md) | Clean architecture principles and patterns | android, ios, kmp |
| [testing-strategy.md](common/testing-strategy.md) | Testing strategy and best practices | android, ios, kmp |

### platforms/android/ - Android Specific

| File | Description | Related Skills |
|------|-------------|----------------|
| [decisions.md](platforms/android/decisions.md) | Android technology adoption/rejection decisions | android |
| [conventions.md](platforms/android/conventions.md) | Project-specific Android conventions | android |
| [architecture-patterns.md](platforms/android/architecture-patterns.md) | MVVM/UDF/Repository architecture patterns | android |

### platforms/ios/ - iOS Specific

| File | Description | Related Skills |
|------|-------------|----------------|
| [decisions.md](platforms/ios/decisions.md) | iOS technology adoption/rejection decisions | ios |
| [conventions.md](platforms/ios/conventions.md) | Project-specific iOS conventions | ios |
| [architecture-patterns.md](platforms/ios/architecture-patterns.md) | SwiftUI+MVVM architecture patterns | ios |

### languages/kotlin/ - Kotlin Related

| File | Description | Related Skills |
|------|-------------|----------------|
| [decisions.md](languages/kotlin/decisions.md) | KMP technology adoption/rejection decisions | android, kmp |
| [conventions.md](languages/kotlin/conventions.md) | Project-specific Kotlin/KMP conventions | kmp |
| [library-patterns.md](languages/kotlin/library-patterns.md) | Library implementation patterns | kmp |
| [feature-patterns.md](languages/kotlin/feature-patterns.md) | Feature implementation patterns | kmp |
| [kmp-architecture-patterns.md](languages/kotlin/kmp-architecture-patterns.md) | KMP architecture patterns | kmp |

### services/aws/ - AWS Related

| File | Description | Related Skills |
|------|-------------|----------------|
| [decisions.md](services/aws/decisions.md) | AWS technology adoption/rejection decisions | aws-sam |
| [conventions.md](services/aws/conventions.md) | Project-specific AWS SAM conventions | aws-sam |
| [sam-architecture-patterns.md](services/aws/sam-architecture-patterns.md) | SAM architecture patterns | aws-sam |

### tools/claude-code/ - Claude Code

| File | Description | Related Skills |
|------|-------------|----------------|
| [decisions.md](tools/claude-code/decisions.md) | Claude Code usage adoption/rejection decisions | - |
| [best-practices.md](tools/claude-code/best-practices.md) | Project-specific best practices | - |

> For official Skills / Sub-agents / CLAUDE.md specs, see: https://docs.anthropic.com/en/docs/claude-code/skills

---

## Reference Map by Skill

> **Note**: All paths below are relative to `skills/` directory. For example, `../references/` resolves to the `references/` directory at the project root.

### android-architecture

```yaml
references:
  - path: ../references/common/clean-architecture.md
  - path: ../references/common/testing-strategy.md
  - path: ../references/platforms/android/conventions.md
  - path: ../references/platforms/android/architecture-patterns.md
```

### ios-architecture

```yaml
references:
  - path: ../references/common/clean-architecture.md
  - path: ../references/common/testing-strategy.md
  - path: ../references/platforms/ios/conventions.md
  - path: ../references/platforms/ios/architecture-patterns.md
```

### kmp-architecture

```yaml
references:
  - path: ../references/common/clean-architecture.md
  - path: ../references/common/testing-strategy.md
  - path: ../references/languages/kotlin/conventions.md
  - path: ../references/languages/kotlin/library-patterns.md
  - path: ../references/languages/kotlin/feature-patterns.md
  - path: ../references/languages/kotlin/kmp-architecture-patterns.md
```

### aws-sam

```yaml
references:
  - path: ../references/services/aws/conventions.md
  - path: ../references/services/aws/sam-architecture-patterns.md
```

---

## Usage

### Reference Specification in SKILL.md

```yaml
---
name: Skill Name
description: ...
references:
  - path: ../references/{group}/{category}/decisions.md  # Check decisions.md first
  - path: ../references/{group}/{category}/{file}.md # Detailed files
---
```

### Relative Path Rules

- Relative path from SKILL.md: `../references/{group}/{category}/{file}.md`
- All paths are relative to SKILL.md
- Technology decisions and rationale can be checked in each category's decisions.md

### Group Classification

| Group | Description | Example |
|-------|-------------|---------|
| common/ | Common to all categories | clean-architecture, testing-strategy |
| platforms/ | Platform-specific | android, ios |
| languages/ | Programming language-specific | kotlin |
| services/ | Cloud service-specific | aws |
| tools/ | Development tools | claude-code |
