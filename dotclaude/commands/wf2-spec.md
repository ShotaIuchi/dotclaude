# /wf2-spec

Command to create the Specification (Spec) document.

## Usage

```
/wf2-spec [subcommand]
```

## Subcommands

- `(none)`: Create new
- `update`: Update existing Spec
- `validate`: Check consistency with Kickoff

## Processing

Parse $ARGUMENTS and execute the following processing.

### 1. Check Prerequisites

```bash
work_id=$(jq -r '.active_work // empty' .wf/state.json)
docs_dir="docs/wf/$work_id"
kickoff_path="$docs_dir/00_KICKOFF.md"
spec_path="$docs_dir/01_SPEC.md"

# Check if Kickoff exists
if [ ! -f "$kickoff_path" ]; then
  echo "Kickoff document not found"
  echo "Please run /wf1-kickoff first"
  exit 1
fi
```

### 2. Load and Analyze Kickoff

```bash
cat "$kickoff_path"
```

Extract from Kickoff:
- Goal
- Success Criteria
- Constraints
- Dependencies

### 3. Investigate Codebase

Investigate related code based on Kickoff content using the following tools:

**File Discovery:**
```
# Use Glob to find relevant files
Glob(pattern: "src/**/*.ts")  # or appropriate pattern for the codebase

# Use Grep to search for related code
Grep(pattern: "<keyword_from_kickoff>", type: "ts")
```

**Deep Investigation (for complex analysis):**
```
# Use Task tool with Explore agent for comprehensive codebase investigation
Task(
  subagent_type: "Explore",
  prompt: "Investigate <specific_area> related to <goal_from_kickoff>",
  description: "Codebase investigation"
)
```

Investigation checklist:
- Identify affected files
- Check existing implementation patterns
- Check related tests
- Check consistency with existing specifications (`docs/spec/` if exists)

### 4. Create Spec

**Template reference:** Load and use `~/.claude/templates/01_SPEC.md`.

Replace template placeholders with investigation results and Kickoff content.

### 5. Consistency Check

Check the following points:

1. **Consistency with Kickoff**
   - Is Goal reflected in Spec
   - Are changes achievable for Success Criteria
   - Are Constraints considered

2. **Consistency with Existing Specifications**
   - No contradictions with specifications in `docs/spec/`
   - Compatible with existing API specifications

3. **Test Strategy Validity**
   - Are there tests to verify Success Criteria

**When warnings are detected:**
```
⚠️ Consistency check found issues

Issues:
- [!] Constraint "performance requirements" not considered in Spec
- [ ] Dependency "authentication API" impact not documented

Action required:
1. Review the issues above
2. Update Spec to address each issue, OR
3. If issues are intentional, document the reasoning in Notes section

Continue with current Spec? (Use AskUserQuestion)
```

### 6. Update state.json

```bash
jq ".works[\"$work_id\"].current = \"wf2-spec\"" .wf/state.json > tmp && mv tmp .wf/state.json
jq ".works[\"$work_id\"].next = \"wf3-plan\"" .wf/state.json > tmp && mv tmp .wf/state.json
```

### 7. Commit

Commit Spec document changes:

```bash
# For new creation
git add "$spec_path" .wf/state.json
git commit -m "docs(wf): create spec <work-id>

Work: <work-id>
"

# For update
git add "$spec_path" .wf/state.json
git commit -m "docs(wf): update spec <work-id>

Work: <work-id>
"
```

### 8. Completion Message

```
✅ Spec document created

File: docs/wf/<work-id>/01_SPEC.md

Affected Components:
- <component1> (high)
- <component2> (medium)

Next step: Run /wf3-plan to create the implementation plan
```

## validate Subcommand

Check consistency between existing Spec and Kickoff:

```
📋 Spec Validation: <work-id>
═══════════════════════════════════════

Kickoff → Spec Consistency Check:

[✓] Goal is reflected in Overview
[✓] Success Criteria are covered in Test Strategy
[!] Constraint "performance requirements" not considered
[ ] Dependency "authentication API" impact not documented

Result: 2 warnings, 1 missing
```

## Notes

- Do not arbitrarily change Kickoff content
- Warn if there are contradictions with existing specifications
- Suggest Kickoff revision if technically not feasible
