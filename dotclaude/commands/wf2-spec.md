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

Investigate related code based on Kickoff content:

- Identify affected files
- Check existing implementation patterns
- Check related tests
- Check consistency with existing specifications (`docs/spec/`)

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
