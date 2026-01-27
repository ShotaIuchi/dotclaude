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
│   │   ├── index.md
│   │   └── conventions.md
│   └── ios/
│       ├── index.md
│       └── conventions.md
├── languages/                  # Languages
│   └── kotlin/
│       ├── index.md
│       ├── conventions.md
│       ├── library-patterns.md
│       └── feature-patterns.md
├── services/                   # Cloud services
│   └── aws/
│       ├── index.md
│       └── conventions.md
└── tools/                      # Development tools
    └── claude-code/
        ├── index.md
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
| [index.md](platforms/android/index.md) | 公式ドキュメントへのポインタ | android |
| [conventions.md](platforms/android/conventions.md) | プロジェクト固有のAndroid規約 | android |

### platforms/ios/ - iOS Specific

| File | Description | Related Skills |
|------|-------------|----------------|
| [index.md](platforms/ios/index.md) | 公式ドキュメントへのポインタ | ios |
| [conventions.md](platforms/ios/conventions.md) | プロジェクト固有のiOS規約 | ios |

### languages/kotlin/ - Kotlin Related

| File | Description | Related Skills |
|------|-------------|----------------|
| [index.md](languages/kotlin/index.md) | 公式ドキュメントへのポインタ | android, kmp |
| [conventions.md](languages/kotlin/conventions.md) | プロジェクト固有のKotlin/KMP規約 | kmp |
| [library-patterns.md](languages/kotlin/library-patterns.md) | ライブラリ実装パターン集 | kmp |
| [feature-patterns.md](languages/kotlin/feature-patterns.md) | 機能実装パターン集 | kmp |

### services/aws/ - AWS Related

| File | Description | Related Skills |
|------|-------------|----------------|
| [index.md](services/aws/index.md) | 公式ドキュメントへのポインタ | aws-sam |
| [conventions.md](services/aws/conventions.md) | プロジェクト固有のAWS SAM規約 | aws-sam |

### tools/claude-code/ - Claude Code

| File | Description | Related Skills |
|------|-------------|----------------|
| [index.md](tools/claude-code/index.md) | 公式ドキュメントへのポインタ | - |
| [best-practices.md](tools/claude-code/best-practices.md) | プロジェクト固有のベストプラクティス | - |

> Skills / Sub-agents / CLAUDE.md の仕様は公式ドキュメントを参照: https://docs.anthropic.com/en/docs/claude-code/skills

---

## Reference Map by Skill

> **Note**: All paths below are relative to `skills/` directory. For example, `../references/` resolves to the `references/` directory at the project root.

### android-architecture

```yaml
references:
  - path: ../references/platforms/android/index.md   # Check index.md first
  - path: ../references/common/clean-architecture.md
  - path: ../references/common/testing-strategy.md
  - path: ../references/platforms/android/conventions.md
```

### ios-architecture

```yaml
references:
  - path: ../references/platforms/ios/index.md       # Check index.md first
  - path: ../references/common/clean-architecture.md
  - path: ../references/common/testing-strategy.md
  - path: ../references/platforms/ios/conventions.md
```

### kmp-architecture

```yaml
references:
  - path: ../references/languages/kotlin/index.md    # Check index.md first
  - path: ../references/common/clean-architecture.md
  - path: ../references/common/testing-strategy.md
  - path: ../references/languages/kotlin/conventions.md
  - path: ../references/languages/kotlin/library-patterns.md
  - path: ../references/languages/kotlin/feature-patterns.md
```

### aws-sam

```yaml
references:
  - path: ../references/services/aws/index.md        # Check index.md first
  - path: ../references/services/aws/conventions.md
```

---

## Usage

### Reference Specification in SKILL.md

```yaml
---
name: Skill Name
description: ...
references:
  - path: ../references/{group}/{category}/index.md  # Check index.md first
  - path: ../references/{group}/{category}/{file}.md # Detailed files
---
```

### Relative Path Rules

- Relative path from SKILL.md: `../references/{group}/{category}/{file}.md`
- All paths are relative to SKILL.md
- External links and priority can be checked in each category's index.md

### Group Classification

| Group | Description | Example |
|-------|-------------|---------|
| common/ | Common to all categories | clean-architecture, testing-strategy |
| platforms/ | Platform-specific | android, ios |
| languages/ | Programming language-specific | kotlin |
| services/ | Cloud service-specific | aws |
| tools/ | Development tools | claude-code |
