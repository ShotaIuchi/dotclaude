# /wf6-verify

Command to verify implementation and create PR.

## Usage

```
/wf6-verify [subcommand]
```

## Subcommands

- `(none)`: Run verification only
- `pr`: Create PR after verification
- `update`: Update existing PR

## Processing

Parse $ARGUMENTS and execute the following processing.

### 1. Check Prerequisites

```bash
work_id=$(jq -r '.active_work // empty' .wf/state.json)
docs_dir="docs/wf/$work_id"
kickoff_path="$docs_dir/00_KICKOFF.md"
spec_path="$docs_dir/01_SPEC.md"
plan_path="$docs_dir/02_PLAN.md"
log_path="$docs_dir/04_IMPLEMENT_LOG.md"

# Check if all steps are completed
current_step=$(jq -r ".works[\"$work_id\"].plan.current_step // 0" .wf/state.json)
total_steps=$(jq -r ".works[\"$work_id\"].plan.total_steps // 0" .wf/state.json)

if [ "$current_step" -lt "$total_steps" ]; then
  echo "⚠️ There are incomplete steps: $current_step/$total_steps"
  echo "Please run /wf5-implement"
fi
```

### 2. Run Tests

Run project tests:

```bash
# Use test command from config.json if defined
if [ -f ".wf/config.json" ]; then
  test_cmd=$(jq -r '.verify.test // empty' .wf/config.json)
  if [ -n "$test_cmd" ]; then
    eval "$test_cmd"
  fi
fi

# Fallback if no command in config.json or command is empty
if [ -z "$test_cmd" ] || [ "$test_cmd" = "null" ]; then
  # Check for package.json
  if [ -f "package.json" ]; then
    npm test
  fi

  # Check for pytest
  if [ -f "pytest.ini" ] || [ -f "pyproject.toml" ]; then
    pytest
  fi

  # Check for go.mod
  if [ -f "go.mod" ]; then
    go test ./...
  fi
fi
```

Record test results:

```
📋 Test Results
═══════════════════════════════════════

Total: 150 tests
Passed: 148
Failed: 2
Skipped: 0

Failed Tests:
- test_user_login: AssertionError
- test_export_csv: TimeoutError
```

### 3. Check Build

Run project build:

```bash
# Use build command from config.json if defined
if [ -f ".wf/config.json" ]; then
  build_cmd=$(jq -r '.verify.build // empty' .wf/config.json)
  if [ -n "$build_cmd" ]; then
    eval "$build_cmd"
  fi
fi

# Fallback if no command in config.json or command is empty
if [ -z "$build_cmd" ] || [ "$build_cmd" = "null" ]; then
  # Node.js
  if [ -f "package.json" ]; then
    npm run build
  fi

  # Go
  if [ -f "go.mod" ]; then
    go build ./...
  fi

  # Rust
  if [ -f "Cargo.toml" ]; then
    cargo build
  fi
fi
```

### 4. Lint/Format Check

```bash
# Use lint command from config.json if defined
if [ -f ".wf/config.json" ]; then
  lint_cmd=$(jq -r '.verify.lint // empty' .wf/config.json)
  if [ -n "$lint_cmd" ]; then
    eval "$lint_cmd"
  fi
fi

# Fallback if no command in config.json or command is empty
if [ -z "$lint_cmd" ] || [ "$lint_cmd" = "null" ]; then
  # ESLint
  if [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ]; then
    npm run lint
  fi

  # Prettier
  if [ -f ".prettierrc" ]; then
    npm run format:check
  fi

  # Black (Python)
  if [ -f "pyproject.toml" ]; then
    black --check .
  fi

  # golangci-lint
  if [ -f ".golangci.yml" ]; then
    golangci-lint run
  fi
fi
```

### 5. Check Success Criteria

Compare with Success Criteria from Kickoff:

```
📋 Success Criteria Check
═══════════════════════════════════════

Success Criteria from Kickoff:
- [✓] CSV export functionality works
- [✓] Completes within 3 seconds for 100,000 records
- [✓] Appropriate error messages are displayed on error
- [ ] User manual is updated

Result: 3/4 completed
There are incomplete items.
```

### 6. Verification Summary

```
📋 Verification Summary: <work-id>
═══════════════════════════════════════

Implementation:
- Steps: <current>/<total> completed
- Files changed: <n>
- Lines: +<added>, -<removed>

Tests:
- Total: <n>
- Passed: <n>
- Failed: <n>

Build: ✓ Success

Lint: ✓ No issues

Success Criteria: <n>/<m> completed

Overall: <PASS / FAIL>
```

### 7. Create PR (pr subcommand)

If verification passes, create PR:

```bash
branch=$(jq -r ".works[\"$work_id\"].git.branch" .wf/state.json)
base=$(jq -r ".works[\"$work_id\"].git.base" .wf/state.json)

# Push
git push -u origin "$branch"

# Generate PR title from work-id and Kickoff Goal
# Extract goal from Kickoff document
kickoff_goal=$(grep -A2 "## Goal" "$docs_dir/00_KICKOFF.md" | tail -1 | sed 's/^[[:space:]]*//')
# Extract source type and ID for reference
source_type=$(jq -r ".works[\"$work_id\"].source.type" .wf/state.json)
source_id=$(jq -r ".works[\"$work_id\"].source.id" .wf/state.json)

# Generate PR title: "<goal summary> (#<issue_number>)" for GitHub, or just "<goal summary>" for others
if [ "$source_type" = "github" ]; then
  pr_title="${kickoff_goal} (#${source_id})"
else
  pr_title="$kickoff_goal"
fi

# Create PR
gh pr create \
  --base "$base" \
  --title "$pr_title" \
  --body "$(cat << EOF
## Summary

<Summary of Goal from Kickoff>

## Changes

<Main changes as bullet points>

## Test Plan

<Testing method>

## Related Issues

Closes #<issue_number>

## Documents

- [Kickoff](docs/wf/<work-id>/00_KICKOFF.md)
- [Spec](docs/wf/<work-id>/01_SPEC.md)
- [Plan](docs/wf/<work-id>/02_PLAN.md)
- [Implementation Log](docs/wf/<work-id>/04_IMPLEMENT_LOG.md)
EOF
)"
```

### 8. Update PR (update subcommand)

Update existing PR:

```bash
# Push changes
git push

# Update PR description (if needed)
gh pr edit --body "$(cat << EOF
...
EOF
)"
```

### 9. Update state.json

```bash
jq ".works[\"$work_id\"].current = \"wf6-verify\"" .wf/state.json > tmp && mv tmp .wf/state.json
jq ".works[\"$work_id\"].next = \"complete\"" .wf/state.json > tmp && mv tmp .wf/state.json

# Record PR information
jq ".works[\"$work_id\"].pr = {\"number\": <pr_number>, \"url\": \"<pr_url>\"}" .wf/state.json > tmp && mv tmp .wf/state.json
```

### 10. Completion Message

#### For verification only

```
✅ Verification complete

Result: PASS

Tests: 150/150 passed
Build: Success
Lint: No issues
Success Criteria: 4/4 completed

To create PR: /wf6-verify pr
```

#### For PR creation

```
✅ PR created

PR: #<number>
URL: <pr_url>

Title: <title>
Base: <base> ← <branch>

Next steps:
- Request review
- Confirm CI/CD completion
```

## Handling Verification Failure

```
❌ Verification failed

Failed Items:
- [ ] Tests: 2 failed
  - test_user_login
  - test_export_csv
- [ ] Success Criteria: 1 incomplete
  - User manual update

Response:
1. Fix failed tests
2. Address incomplete Success Criteria
3. Run /wf6-verify again
```

## Notes

- Cannot create PR if tests fail
- Cannot create PR if build fails
- Warning displayed for incomplete Success Criteria items
- Verification can be re-run after PR creation
