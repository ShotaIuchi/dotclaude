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
│       └── kmp-architecture.md
└── services/                   # Cloud services
    └── aws/
        ├── index.md
        └── sam-template.md
```

---

## Design Principles (External Links)

Authoritative sources for design principles that all skills should reference.

| Principle | Link | Priority |
|-----------|------|----------|
| Clean Architecture | [The Clean Architecture (Robert C. Martin)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html) | ★★★ Original |
| SOLID Principles | [SOLID (Wikipedia)](https://en.wikipedia.org/wiki/SOLID) | ★★ Foundation |
| Dependency Injection | [Dependency Injection (Wikipedia)](https://en.wikipedia.org/wiki/Dependency_injection) | ★★ Foundation |

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

### services/aws/ - AWS Related

| File | Description | Related Skills |
|------|-------------|----------------|
| [index.md](services/aws/index.md) | Structure, priority, external links | aws-sam |
| [sam-template.md](services/aws/sam-template.md) | AWS SAM template and implementation patterns | aws-sam |

---

## Reference Map by Skill

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
