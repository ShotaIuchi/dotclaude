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
│   │   └── architecture.md
│   └── ios/
│       ├── index.md
│       └── architecture.md
├── languages/                  # Languages
│   └── kotlin/
│       ├── index.md
│       ├── coroutines.md
│       ├── kmp-architecture.md
│       ├── kmp-auth.md
│       ├── kmp-camera.md
│       ├── kmp-compose-ui.md
│       ├── kmp-data-sqldelight.md
│       ├── kmp-di-koin.md
│       ├── kmp-error-handling.md
│       ├── kmp-expect-actual.md
│       ├── kmp-network-ktor.md
│       ├── kmp-state-udf.md
│       └── kmp-testing.md
├── services/                   # Cloud services
│   └── aws/
│       ├── index.md
│       └── sam-template.md
└── tools/                      # Development tools
    └── claude-code/
        ├── index.md
        └── command-frontmatter.md
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
| [index.md](platforms/android/index.md) | Structure, priority, external links | android |
| [architecture.md](platforms/android/architecture.md) | Android MVVM/UDF architecture details | android |

### platforms/ios/ - iOS Specific

| File | Description | Related Skills |
|------|-------------|----------------|
| [index.md](platforms/ios/index.md) | Structure, priority, external links | ios |
| [architecture.md](platforms/ios/architecture.md) | iOS SwiftUI/MVVM architecture details | ios |

### languages/kotlin/ - Kotlin Related

| File | Description | Related Skills |
|------|-------------|----------------|
| [index.md](languages/kotlin/index.md) | Structure, priority, external links | android, kmp |
| [coroutines.md](languages/kotlin/coroutines.md) | Kotlin Coroutines best practices | android, kmp |
| [kmp-architecture.md](languages/kotlin/kmp-architecture.md) | Kotlin Multiplatform architecture | kmp |
| [kmp-auth.md](languages/kotlin/kmp-auth.md) | KMP authentication patterns | kmp |
| [kmp-camera.md](languages/kotlin/kmp-camera.md) | KMP camera integration | kmp |
| [kmp-compose-ui.md](languages/kotlin/kmp-compose-ui.md) | Compose Multiplatform UI patterns | kmp |
| [kmp-data-sqldelight.md](languages/kotlin/kmp-data-sqldelight.md) | SQLDelight data persistence | kmp |
| [kmp-di-koin.md](languages/kotlin/kmp-di-koin.md) | Koin dependency injection | kmp |
| [kmp-error-handling.md](languages/kotlin/kmp-error-handling.md) | KMP error handling patterns | kmp |
| [kmp-expect-actual.md](languages/kotlin/kmp-expect-actual.md) | Expect/actual declarations | kmp |
| [kmp-network-ktor.md](languages/kotlin/kmp-network-ktor.md) | Ktor networking | kmp |
| [kmp-state-udf.md](languages/kotlin/kmp-state-udf.md) | Unidirectional data flow state management | kmp |
| [kmp-testing.md](languages/kotlin/kmp-testing.md) | KMP testing strategies | kmp |

### services/aws/ - AWS Related

| File | Description | Related Skills |
|------|-------------|----------------|
| [index.md](services/aws/index.md) | Structure, priority, external links | aws-sam |
| [sam-template.md](services/aws/sam-template.md) | AWS SAM template and implementation patterns | aws-sam |

### tools/claude-code/ - Claude Code

| File | Description | Related Skills |
|------|-------------|----------------|
| [index.md](tools/claude-code/index.md) | Claude Code リファレンス索引 | - |
| [command-frontmatter.md](tools/claude-code/command-frontmatter.md) | コマンド/スキルのフロントマター仕様 | - |

---

## Reference Map by Skill

> **Note**: All paths below are relative to `skills/` directory. For example, `../references/` resolves to the `references/` directory at the project root.

### android-architecture

```yaml
references:
  - path: ../references/platforms/android/index.md   # Check index.md first
  - path: ../references/common/clean-architecture.md
  - path: ../references/common/testing-strategy.md
  - path: ../references/languages/kotlin/coroutines.md
  - path: ../references/platforms/android/architecture.md
```

### ios-architecture

```yaml
references:
  - path: ../references/platforms/ios/index.md       # Check index.md first
  - path: ../references/common/clean-architecture.md
  - path: ../references/common/testing-strategy.md
  - path: ../references/platforms/ios/architecture.md
```

### kmp-architecture

```yaml
references:
  - path: ../references/languages/kotlin/index.md    # Check index.md first
  - path: ../references/common/clean-architecture.md
  - path: ../references/common/testing-strategy.md
  - path: ../references/languages/kotlin/coroutines.md
  - path: ../references/languages/kotlin/kmp-architecture.md
  - path: ../references/languages/kotlin/kmp-auth.md
  - path: ../references/languages/kotlin/kmp-camera.md
  - path: ../references/languages/kotlin/kmp-compose-ui.md
  - path: ../references/languages/kotlin/kmp-data-sqldelight.md
  - path: ../references/languages/kotlin/kmp-di-koin.md
  - path: ../references/languages/kotlin/kmp-error-handling.md
  - path: ../references/languages/kotlin/kmp-expect-actual.md
  - path: ../references/languages/kotlin/kmp-network-ktor.md
  - path: ../references/languages/kotlin/kmp-state-udf.md
  - path: ../references/languages/kotlin/kmp-testing.md
```

### aws-sam

```yaml
references:
  - path: ../references/services/aws/index.md        # Check index.md first
  - path: ../references/services/aws/sam-template.md
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
