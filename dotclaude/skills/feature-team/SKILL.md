---
name: feature-team
description: Agent Teamsで新機能の並列実装チームを自動構成・起動
argument-hint: "[feature description, issue number, or spec file path]"
user-invocable: true
disable-model-invocation: true
---

# Feature Team

Create an Agent Team with automatically selected specialists to implement new features through parallel workstreams.

## Instructions

1. **Analyze the feature** (description, issue, or spec) to determine scope and components
2. **Select appropriate specialists** based on the selection matrix below
3. **Create the agent team** with only the selected specialists
4. Have them coordinate on integration points and produce a completion report

## Step 1: Feature Analysis

Before spawning any teammates, analyze the target to determine the feature type:

| Signal | Type |
|--------|------|
| UI components, screens, layouts, user interactions, styling | UI Feature |
| Endpoints, handlers, request/response schemas, middleware | API Feature |
| Schemas, migrations, queries, storage, ETL, indexing | Data Feature |
| Third-party APIs, webhooks, OAuth, external services | Integration |
| CI/CD, deployment, monitoring, scaling, configuration | Infrastructure |
| Mixed signals | Analyze dominant patterns and apply multiple types |

## Step 2: Specialist Selection Matrix

| Specialist | UI Feature | API Feature | Data Feature | Integration | Infrastructure |
|:-----------|:----------:|:-----------:|:------------:|:-----------:|:--------------:|
| API Designer | If needs API | Always | Always | Always | Skip |
| UI Implementer | Always | Skip | If has UI | If has UI | Skip |
| Data Modeler | If data-driven | Always | Always | Always | If storage-related |
| Business Logic | Always | Always | Always | Always | Skip |
| Test Writer | Always | Always | Always | Always | Always |
| Doc Writer | Always | Always | Always | Always | Always |
| Security Analyst | If auth-related | Always | If PII | Always | Always |

### Selection Rules

- **Always**: Spawn this specialist unconditionally
- **Skip**: Do not spawn this specialist
- **Conditional**: Spawn only if the condition is met based on feature analysis

When uncertain, **include the specialist** (prefer thoroughness over efficiency).

## Step 3: Team Creation

Spawn only the selected specialists with their specialized prompts:

1. **API Designer**: Design API endpoints, request/response schemas, error handling, versioning, and integration contracts.

2. **UI Implementer**: Implement user interface components, layouts, interactions, accessibility, and responsive design.

3. **Data Modeler**: Design data schemas, migrations, relationships, indexes, and data access patterns.

4. **Business Logic Implementer**: Implement core business rules, validation logic, workflows, and domain-specific algorithms.

5. **Test Writer**: Create unit tests, integration tests, and edge case tests for all new functionality.

6. **Doc Writer**: Create or update API documentation, user guides, and inline code documentation.

7. **Security Analyst**: Review for authentication, authorization, input validation, data protection, and security best practices.

## Workflow

1. Lead analyzes the feature and decomposes it into parallel workstreams
2. Each selected specialist works on their designated component
3. Specialists coordinate on integration points and shared interfaces
4. Lead orchestrates integration and produces a completion report with:
   - Completed components and their status
   - Integration verification results
   - Remaining tasks or follow-up items

## Output

The lead produces a final implementation summary including:
- Feature type detected and specialists selected (with reasoning)
- Completed components with integration status
- Test coverage summary
- Remaining tasks or known limitations
