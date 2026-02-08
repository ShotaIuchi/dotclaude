---
name: test-team
description: Agent Teamsでテスト一括作成チームを自動構成・起動
argument-hint: "[file/directory path or module name]"
user-invocable: true
disable-model-invocation: true
---

# Test Team

Create an Agent Team with automatically selected test writers based on the target code type.

## Instructions

1. **Analyze the target** (file, directory, or module) to determine the code type
2. **Select appropriate test writers** based on the selection matrix below
3. **Create the agent team** with only the selected test writers
4. Have them coordinate to produce a comprehensive test suite with coverage report

## Step 1: Code Analysis

Before spawning any teammates, analyze the target code to understand testable components:

| Signal | Type |
|--------|------|
| Pure functions, classes with methods, state machines | Business Logic |
| HTTP handlers, REST controllers, GraphQL resolvers, gRPC services | API/Service |
| React/Vue/Svelte components, Compose UI, SwiftUI views, XML layouts | UI Component |
| Repository classes, DAO, ORM models, database queries, cache layers | Data Layer |
| Helper functions, string manipulation, date parsing, math operations | Utility/Library |
| Service-to-service calls, event handlers, message queues, middleware | Integration Point |
| Mixed signals | Analyze dominant patterns and apply multiple types |

## Step 2: Test Writer Selection Matrix

| Test Writer | Business Logic | API/Service | UI Component | Data Layer | Utility/Library | Integration Point |
|:------------|:-------------:|:-----------:|:------------:|:----------:|:---------------:|:-----------------:|
| Unit Test Writer | Always | Always | Always | Always | Always | Always |
| Integration Test Writer | If multi-component | Always | If stateful | Always | If has dependencies | Always |
| Edge Case Specialist | Always | Always | Always | Always | Always | Always |
| Mock/Fixture Designer | If has dependencies | Always | Always | If external DB | If has dependencies | Always |
| Performance Test Writer | If critical path | If high-traffic | If render-heavy | If query-heavy | If performance-critical | If latency-sensitive |
| Security Test Writer | If auth-related | Always | If input-handling | If user data | If crypto/auth | Always |
| Snapshot/Golden Test Writer | Skip | If response format | Always | Skip | Skip | If contract |

### Selection Rules

- **Always**: Spawn this test writer unconditionally
- **Skip**: Do not spawn this test writer
- **Conditional**: Spawn only if the condition is met based on code analysis

When uncertain, **include the test writer** (prefer thoroughness over efficiency).

## Step 3: Team Creation

Spawn only the selected test writers with their specialized prompts:

1. **Unit Test Writer**: Create comprehensive unit tests for individual functions, methods, and classes with proper isolation. Cover happy paths, expected error conditions, and return value validation. Use appropriate assertions and test naming conventions for the project's language and framework.

2. **Integration Test Writer**: Create tests that verify interactions between components, services, and external systems. Test data flow across boundaries, API contract compliance, database transactions, and end-to-end workflows with real or containerized dependencies.

3. **Edge Case Specialist**: Identify and test boundary conditions, null inputs, empty collections, overflow, unicode, and error paths. Systematically explore off-by-one errors, maximum/minimum values, concurrent access, timeout scenarios, and malformed input handling.

4. **Mock/Fixture Designer**: Design test doubles, fixtures, factories, and test data that enable reliable and fast test execution. Create reusable mock objects, stub responses, fake implementations, and seed data that accurately represent production scenarios.

5. **Performance Test Writer**: Create benchmarks, load tests, and performance regression tests for critical paths. Measure execution time, memory allocation, throughput, and latency under various load conditions. Establish baseline metrics and thresholds.

6. **Security Test Writer**: Create tests for authentication, authorization, input validation, injection, and data protection. Verify access control boundaries, token handling, CSRF protection, SQL/NoSQL injection prevention, and sensitive data encryption.

7. **Snapshot/Golden Test Writer**: Create snapshot tests for UI components, API response formats, and serialization contracts. Capture expected output baselines and detect unintended changes in rendered output, JSON schemas, or binary formats.

## Workflow

1. Lead analyzes the target code and identifies all testable surfaces
2. Each test writer creates tests for their specialty area
3. Test writers coordinate to avoid duplication and ensure coverage
4. Lead verifies all tests pass and produces a coverage report with:
   - Total coverage percentage by line, branch, and function
   - Tested scenarios grouped by test writer
   - Identified untestable code with refactoring suggestions
   - Test maintenance notes and known limitations

## Output

The lead produces a final test suite report including:
- Code type detected and test writers selected (with reasoning)
- Test suite with all generated test files
- Coverage report with line, branch, and function metrics
- List of all tested scenarios organized by category
- Identified untestable code with suggestions for making it testable
- Test maintenance notes and guidelines for keeping tests up to date
