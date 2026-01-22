# Skills System

Skill definitions that provide project-specific knowledge and best practices to Claude.

## Overview

Skills define specialized knowledge about specific domains or technology stacks.
They reference knowledge from references/ and provide guidance optimized for the project.

## Skill List

| Skill | Purpose |
|-------|---------|
| `android-architecture` | Android app architecture design |
| `ios-architecture` | iOS app architecture design |
| `kmp-architecture` | Kotlin Multiplatform architecture design |
| `aws-sam` | AWS SAM template and Lambda implementation |

## Usage

Claude understands the context when skills are included in prompts.

```
Please implement according to the android-architecture skill in this project.
```

## Skill Definition Format

Each skill is defined in the following format.

```markdown
---
name: Skill name
description: Description (in English)
references:
  - path: ../references/...
---

# Skill Name

## Purpose
{Guidance this skill provides}

## Use Cases
{Situations where this skill should be used}

## Key Principles
{Principles to follow}

## Implementation Patterns
{Recommended implementation patterns}
```

## Directory Structure

```
skills/
├── README.md                 # This file
├── android-architecture/
│   └── SKILL.md
├── ios-architecture/
│   └── SKILL.md
├── kmp-architecture/
│   └── SKILL.md
└── aws-sam/
    └── SKILL.md
```

## Relationship with references/

Skills reference knowledge from references/.

```
skills/android-architecture/SKILL.md
  → references: ../references/platforms/android/...

skills/aws-sam/SKILL.md
  → references: ../references/services/aws/...
```

## Steps for Adding New Skills

1. Create `skills/{skill-name}/` directory
2. Create `SKILL.md` (following the format above)
3. Set paths to necessary references/
4. Update the skill list in this README.md
