---
description: Schedule management for batch workflow execution
argument-hint: "<create|show|edit|validate|clear> [sources... | work-id]"
---

# /wf0-schedule

Command for creating and managing workflow schedules with dependency analysis.
Reads Issues/Jiras/Local works, analyzes dependencies, and builds execution schedule.

## Usage

```
/wf0-schedule <subcommand> [arguments...]
```

## Subcommands

| Subcommand | Description |
|------------|-------------|
| `create [sources...]` | Create schedule from specified sources |
| `show` | Display current schedule |
| `edit [work-id]` | Edit priority or dependencies |
| `validate` | Validate schedule (circular dependency check) |
| `clear` | Delete current schedule |

## Source Specification

### GitHub Issues

```bash
# By label
/wf0-schedule create github="label:scheduled"
/wf0-schedule create github="label:batch,label:priority"

# By milestone
/wf0-schedule create github="milestone:v1.0"

# Multiple labels (AND condition)
/wf0-schedule create github="label:feature,label:approved"
```

### Jira Issues

```bash
# By JQL query
/wf0-schedule create jira="project=PROJ AND sprint=current"
/wf0-schedule create jira="project=PROJ AND status='To Do'"
```

### Local Works

```bash
# By work-id (comma-separated)
/wf0-schedule create local=FEAT-001,FIX-002,REFACTOR-003
```

### Combined Sources

```bash
# Multiple sources
/wf0-schedule create github="label:scheduled" jira="sprint=current"

# All sources from config.json
/wf0-schedule create --all
```

## Processing

Parse $ARGUMENTS and execute the following processing.

### 1. Parse Subcommand and Arguments

```bash
subcommand=$(echo "$ARGUMENTS" | awk '{print $1}')
remaining_args=$(echo "$ARGUMENTS" | awk '{$1=""; print $0}' | xargs)

if [ -z "$subcommand" ]; then
  echo "ERROR: Subcommand required (create|show|edit|validate|clear)"
  exit 1
fi
```

### 2. Load Configuration

```bash
# Check for .wf directory
if [ ! -d .wf ]; then
  echo "WF system is not initialized"
  echo "Please run /wf1-kickoff first"
  exit 1
fi

# Load config.json
CONFIG_FILE=".wf/config.json"
if [ ! -f "$CONFIG_FILE" ]; then
  CONFIG_FILE="$HOME/.claude/examples/config.json"
fi

# Load schedule.json if exists
SCHEDULE_FILE=".wf/schedule.json"
```

### 3. Execute Subcommand

#### 3.1 create

Create a new schedule from specified sources.

```bash
echo "📅 Creating Schedule"
echo "═══════════════════════════════════════"
echo ""

# Initialize schedule structure
schedule_data=$(cat << 'EOF'
{
  "version": "1.0",
  "created_at": "",
  "status": "pending",
  "sources": [],
  "works": {},
  "execution": {
    "max_parallel": 2,
    "sessions": {}
  },
  "progress": {
    "total": 0,
    "completed": 0,
    "in_progress": 0,
    "pending": 0
  }
}
EOF
)

# Set creation timestamp
schedule_data=$(echo "$schedule_data" | jq --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '.created_at = $ts')

# Parse sources from arguments
sources=()
use_all=false

for arg in $remaining_args; do
  case "$arg" in
    --all)
      use_all=true
      ;;
    github=*)
      query="${arg#github=}"
      sources+=("{\"type\": \"github\", \"query\": \"$query\"}")
      ;;
    jira=*)
      query="${arg#jira=}"
      sources+=("{\"type\": \"jira\", \"query\": \"$query\"}")
      ;;
    local=*)
      ids="${arg#local=}"
      sources+=("{\"type\": \"local\", \"ids\": \"$ids\"}")
      ;;
  esac
done

# If --all, load sources from config.json batch section
if [ "$use_all" = true ]; then
  if jq -e '.batch.sources' "$CONFIG_FILE" > /dev/null 2>&1; then
    config_sources=$(jq -c '.batch.sources[]' "$CONFIG_FILE")
    for src in $config_sources; do
      sources+=("$src")
    done
  else
    echo "ERROR: No batch.sources defined in config.json"
    exit 1
  fi
fi

if [ ${#sources[@]} -eq 0 ]; then
  echo "ERROR: No sources specified"
  echo ""
  echo "Examples:"
  echo "  /wf0-schedule create github=\"label:scheduled\""
  echo "  /wf0-schedule create jira=\"sprint=current\""
  echo "  /wf0-schedule create local=FEAT-001,FIX-002"
  echo "  /wf0-schedule create --all"
  exit 1
fi

# Add sources to schedule
for src in "${sources[@]}"; do
  schedule_data=$(echo "$schedule_data" | jq --argjson s "$src" '.sources += [$s]')
done

echo "Sources:"
for src in "${sources[@]}"; do
  src_type=$(echo "$src" | jq -r '.type')
  src_query=$(echo "$src" | jq -r '.query // .ids // "N/A"')
  echo "  - $src_type: $src_query"
done
echo ""

# Fetch works from each source
works_collected=()

for src in "${sources[@]}"; do
  src_type=$(echo "$src" | jq -r '.type')

  case "$src_type" in
    github)
      query=$(echo "$src" | jq -r '.query')
      echo "Fetching from GitHub ($query)..."

      # Parse query parameters
      label_filter=""
      milestone_filter=""

      # Extract label: patterns
      labels=$(echo "$query" | grep -oE 'label:[^,]+' | sed 's/label://g' | tr '\n' ',' | sed 's/,$//')
      if [ -n "$labels" ]; then
        label_filter="--label \"$labels\""
      fi

      # Fetch issues (using array to avoid eval security risk)
      gh_args=(gh issue list --state open --json number,title,body,labels --limit 50)
      if [ -n "$labels" ]; then
        gh_args+=(--label "$labels")
      fi
      issues=$("${gh_args[@]}" 2>/dev/null || echo "[]")

      # Process each issue (using process substitution to avoid subshell variable scope issue)
      while read -r issue; do
        issue_num=$(echo "$issue" | jq -r '.number')
        issue_title=$(echo "$issue" | jq -r '.title')
        issue_body=$(echo "$issue" | jq -r '.body // ""')

        # Generate work-id from issue
        work_id=$(wf_schedule_generate_work_id "$issue_num" "$issue_title")

        # Detect dependencies from issue body
        deps=$(wf_schedule_detect_dependencies "$issue_body")

        echo "  - #$issue_num: $issue_title"
        works_collected+=("{
          \"work_id\": \"$work_id\",
          \"source\": {\"type\": \"github\", \"id\": \"$issue_num\", \"title\": \"$issue_title\"},
          \"priority\": 5,
          \"dependencies\": $deps,
          \"status\": \"pending\",
          \"worktree_path\": null
        }")
      done < <(echo "$issues" | jq -c '.[]')
      ;;

    jira)
      query=$(echo "$src" | jq -r '.query')
      echo "Fetching from Jira ($query)..."

      # Load Jira config
      jira_domain=$(jq -r '.jira.domain // empty' "$CONFIG_FILE")
      jira_project=$(jq -r '.jira.project // empty' "$CONFIG_FILE")

      if [ -z "$jira_domain" ]; then
        echo "  WARNING: Jira domain not configured in config.json"
        echo "  NOTE: Jira integration is planned but not yet implemented."
        echo "        Configure in config.json when available:"
        echo "        {"
        echo "          \"jira\": {"
        echo "            \"domain\": \"your-domain.atlassian.net\","
        echo "            \"project\": \"PROJ\","
        echo "            \"auth\": \"api_token_reference\""
        echo "          }"
        echo "        }"
        continue
      fi

      # Jira API call would go here
      # TODO: Implement Jira REST API integration with OAuth 2.0 or API token
      echo "  (Jira integration is planned - requires API token configuration)"
      ;;

    local)
      ids=$(echo "$src" | jq -r '.ids')
      echo "Adding local works ($ids)..."

      IFS=',' read -ra id_array <<< "$ids"
      for wid in "${id_array[@]}"; do
        wid=$(echo "$wid" | xargs)  # trim whitespace

        # Check if work exists in state.json
        if [ -f ".wf/state.json" ]; then
          work_exists=$(jq -r ".works[\"$wid\"] // empty" .wf/state.json)
          if [ -n "$work_exists" ]; then
            echo "  - $wid (existing)"
            works_collected+=("{
              \"work_id\": \"$wid\",
              \"source\": {\"type\": \"local\", \"id\": \"$wid\"},
              \"priority\": 5,
              \"dependencies\": [],
              \"status\": \"pending\",
              \"worktree_path\": null
            }")
          else
            echo "  - $wid (not found, will create)"
            works_collected+=("{
              \"work_id\": \"$wid\",
              \"source\": {\"type\": \"local\", \"id\": \"$wid\"},
              \"priority\": 5,
              \"dependencies\": [],
              \"status\": \"pending\",
              \"worktree_path\": null
            }")
          fi
        fi
      done
      ;;
  esac
done

echo ""

# Add works to schedule
for work in "${works_collected[@]}"; do
  work_id=$(echo "$work" | jq -r '.work_id')
  schedule_data=$(echo "$schedule_data" | jq --argjson w "$work" --arg id "$work_id" '.works[$id] = $w')
done

# Update progress counts
total_works=$(echo "$schedule_data" | jq '.works | length')
schedule_data=$(echo "$schedule_data" | jq --argjson t "$total_works" '.progress.total = $t | .progress.pending = $t')

# Build dependency graph and detect cycles
echo "Analyzing dependencies..."
if ! wf_schedule_validate_dag "$schedule_data"; then
  echo "ERROR: Circular dependency detected!"
  echo "Please fix dependencies before creating schedule"
  exit 1
fi

# Calculate priority order based on dependencies
schedule_data=$(wf_schedule_calculate_priority "$schedule_data")

# Save schedule
echo "$schedule_data" | jq '.' > "$SCHEDULE_FILE"

echo ""
echo "═══════════════════════════════════════"
echo "✅ Schedule created: $total_works works"
echo ""
echo "Use '/wf0-schedule show' to view the schedule"
echo "Use '/wf0-batch start' to begin execution"
```

#### 3.2 show

Display current schedule.

```bash
if [ ! -f "$SCHEDULE_FILE" ]; then
  echo "No schedule found"
  echo "Use '/wf0-schedule create' to create one"
  exit 0
fi

echo "📅 Current Schedule"
echo "═══════════════════════════════════════"
echo ""

# Load schedule
schedule=$(cat "$SCHEDULE_FILE")

# Display metadata
created_at=$(echo "$schedule" | jq -r '.created_at')
status=$(echo "$schedule" | jq -r '.status')
total=$(echo "$schedule" | jq -r '.progress.total')
completed=$(echo "$schedule" | jq -r '.progress.completed')
in_progress=$(echo "$schedule" | jq -r '.progress.in_progress')
pending=$(echo "$schedule" | jq -r '.progress.pending')

echo "Status:     $status"
echo "Created:    $created_at"
echo ""
echo "Progress:   $completed/$total completed"
echo "            $in_progress in progress"
echo "            $pending pending"
echo ""

echo "═══════════════════════════════════════"
echo "Works (by priority):"
echo ""

# List works sorted by priority
echo "$schedule" | jq -r '.works | to_entries | sort_by(.value.priority) | .[] |
  "[\(.value.priority)] \(.key)\n    Status: \(.value.status)\n    Source: \(.value.source.type) #\(.value.source.id)\n    Deps: \(if (.value.dependencies | length) > 0 then (.value.dependencies | join(", ")) else "(none)" end)\n"'

echo "═══════════════════════════════════════"
echo ""
echo "Commands:"
echo "  /wf0-schedule edit <work-id>  - Edit priority/dependencies"
echo "  /wf0-schedule validate        - Check for issues"
echo "  /wf0-batch start              - Start execution"
```

#### 3.3 edit

Edit priority or dependencies for a work.

```bash
if [ ! -f "$SCHEDULE_FILE" ]; then
  echo "No schedule found"
  exit 1
fi

work_id="$remaining_args"

if [ -z "$work_id" ]; then
  echo "ERROR: work-id required"
  echo "Usage: /wf0-schedule edit <work-id>"
  exit 1
fi

# Check if work exists in schedule
if ! jq -e ".works[\"$work_id\"]" "$SCHEDULE_FILE" > /dev/null 2>&1; then
  echo "ERROR: Work '$work_id' not found in schedule"
  exit 1
fi

# Get current values
current_priority=$(jq -r ".works[\"$work_id\"].priority" "$SCHEDULE_FILE")
current_deps=$(jq -r ".works[\"$work_id\"].dependencies | join(\", \")" "$SCHEDULE_FILE")

echo "📝 Edit: $work_id"
echo "═══════════════════════════════════════"
echo ""
echo "Current priority: $current_priority"
echo "Current dependencies: ${current_deps:-"(none)"}"
echo ""

# Prompt for changes via Claude interaction
# Claude will parse user input and update accordingly
echo "To update, specify:"
echo "  priority=<1-10>       (1=highest)"
echo "  depends=<work-id,...> (comma-separated)"
echo "  remove-dep=<work-id>  (remove dependency)"
echo ""
echo "Example: priority=1 depends=FEAT-100,FEAT-101"
```

When editing is confirmed by user input, Claude parses the user's response and extracts edit parameters. The interaction flow is:

1. Claude displays the current values (shown above)
2. User provides input like: `priority=1 depends=FEAT-100,FEAT-101`
3. Claude parses user input into `edit_params` variable
4. The following script processes each parameter:

```bash
# Parse edit parameters (from user input parsed by Claude)
# edit_params is populated from Claude's parsing of user response
for param in $edit_params; do
  case "$param" in
    priority=*)
      new_priority="${param#priority=}"
      jq ".works[\"$work_id\"].priority = $new_priority" "$SCHEDULE_FILE" > "$SCHEDULE_FILE.tmp" && \
        mv "$SCHEDULE_FILE.tmp" "$SCHEDULE_FILE"
      echo "Priority updated to $new_priority"
      ;;
    depends=*)
      new_deps="${param#depends=}"
      IFS=',' read -ra dep_array <<< "$new_deps"
      deps_json=$(printf '%s\n' "${dep_array[@]}" | jq -R . | jq -s .)
      jq ".works[\"$work_id\"].dependencies = $deps_json" "$SCHEDULE_FILE" > "$SCHEDULE_FILE.tmp" && \
        mv "$SCHEDULE_FILE.tmp" "$SCHEDULE_FILE"
      echo "Dependencies updated"
      ;;
    remove-dep=*)
      dep_to_remove="${param#remove-dep=}"
      jq ".works[\"$work_id\"].dependencies -= [\"$dep_to_remove\"]" "$SCHEDULE_FILE" > "$SCHEDULE_FILE.tmp" && \
        mv "$SCHEDULE_FILE.tmp" "$SCHEDULE_FILE"
      echo "Removed dependency: $dep_to_remove"
      ;;
  esac
done

# Re-validate after changes
wf_schedule_validate_dag "$(cat "$SCHEDULE_FILE")"
```

#### 3.4 validate

Validate the schedule for issues.

```bash
if [ ! -f "$SCHEDULE_FILE" ]; then
  echo "No schedule found"
  exit 1
fi

echo "🔍 Validating Schedule"
echo "═══════════════════════════════════════"
echo ""

schedule=$(cat "$SCHEDULE_FILE")
has_errors=false
has_warnings=false

# Check 1: Circular dependencies
echo "Checking circular dependencies..."
if ! wf_schedule_validate_dag "$schedule"; then
  echo "  ❌ Circular dependency detected"
  has_errors=true
else
  echo "  ✅ No circular dependencies"
fi

# Check 2: Missing dependencies
echo ""
echo "Checking dependency references..."
all_work_ids=$(echo "$schedule" | jq -r '.works | keys[]')
missing_deps=()

for work_id in $all_work_ids; do
  deps=$(echo "$schedule" | jq -r ".works[\"$work_id\"].dependencies[]?" 2>/dev/null)
  for dep in $deps; do
    if ! echo "$all_work_ids" | grep -q "^$dep$"; then
      missing_deps+=("$work_id -> $dep")
      has_warnings=true
    fi
  done
done

if [ ${#missing_deps[@]} -gt 0 ]; then
  echo "  ⚠️  Missing dependencies:"
  for md in "${missing_deps[@]}"; do
    echo "    - $md"
  done
else
  echo "  ✅ All dependencies resolved"
fi

# Check 3: Priority conflicts
echo ""
echo "Checking priority conflicts..."
# Works with dependencies should not have higher priority than their dependencies
priority_issues=()
for work_id in $all_work_ids; do
  work_priority=$(echo "$schedule" | jq -r ".works[\"$work_id\"].priority")
  deps=$(echo "$schedule" | jq -r ".works[\"$work_id\"].dependencies[]?" 2>/dev/null)
  for dep in $deps; do
    dep_priority=$(echo "$schedule" | jq -r ".works[\"$dep\"].priority // 999")
    if [ "$work_priority" -lt "$dep_priority" ]; then
      priority_issues+=("$work_id (p$work_priority) depends on $dep (p$dep_priority)")
      has_warnings=true
    fi
  done
done

if [ ${#priority_issues[@]} -gt 0 ]; then
  echo "  ⚠️  Priority conflicts (dependency has lower priority):"
  for pi in "${priority_issues[@]}"; do
    echo "    - $pi"
  done
else
  echo "  ✅ No priority conflicts"
fi

echo ""
echo "═══════════════════════════════════════"

if [ "$has_errors" = true ]; then
  echo "❌ Validation failed with errors"
  exit 1
elif [ "$has_warnings" = true ]; then
  echo "⚠️  Validation passed with warnings"
  exit 0
else
  echo "✅ Validation passed"
  exit 0
fi
```

#### 3.5 clear

Delete current schedule.

```bash
if [ ! -f "$SCHEDULE_FILE" ]; then
  echo "No schedule to clear"
  exit 0
fi

# Check if batch is running
if [ -f "$SCHEDULE_FILE" ]; then
  status=$(jq -r '.status' "$SCHEDULE_FILE")
  if [ "$status" = "running" ]; then
    echo "ERROR: Cannot clear schedule while batch is running"
    echo "Use '/wf0-batch stop' first"
    exit 1
  fi
fi

rm -f "$SCHEDULE_FILE"
echo "✅ Schedule cleared"
```

## Helper Functions

These functions are used by the schedule processing:

```bash
# Generate work-id from issue number and title
wf_schedule_generate_work_id() {
  local issue_num="$1"
  local title="$2"

  # Extract type prefix from title or labels
  local prefix="FEAT"
  if echo "$title" | grep -qi "fix\|bug"; then
    prefix="FIX"
  elif echo "$title" | grep -qi "refactor"; then
    prefix="REFACTOR"
  fi

  # Create slug from title
  local slug
  slug=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | cut -c1-30)

  echo "$prefix-$issue_num-$slug"
}

# Detect dependencies from issue body
wf_schedule_detect_dependencies() {
  local body="$1"
  local deps=()

  # Load patterns from config or use defaults
  local patterns=(
    'depends on #([0-9]+)'
    'blocked by #([0-9]+)'
    'requires ([A-Z]+-[0-9]+)'
    'after: ([A-Z]+-[0-9]+-[a-z0-9-]+)'
  )

  for pattern in "${patterns[@]}"; do
    matches=$(echo "$body" | grep -oiE "$pattern" | sed -E "s/$pattern/\\1/i")
    for match in $matches; do
      deps+=("$match")
    done
  done

  # Return as JSON array
  printf '%s\n' "${deps[@]}" | jq -R . | jq -s '.'
}

# DFS helper for cycle detection (separated from main function for bash compatibility)
# Usage: _wf_schedule_dfs_impl <node> <schedule_json>
# Uses global arrays: _visited, _rec_stack
_wf_schedule_dfs_impl() {
  local node="$1"
  local schedule="$2"

  # Mark as visiting (in recursion stack)
  _rec_stack+=("$node")

  # Get dependencies
  local deps
  deps=$(echo "$schedule" | jq -r ".works[\"$node\"].dependencies[]?" 2>/dev/null)

  for dep in $deps; do
    # Check if dep is in recursion stack (cycle)
    if printf '%s\n' "${_rec_stack[@]}" | grep -q "^$dep$"; then
      echo "Cycle detected: $node -> $dep"
      return 1
    fi

    # If not visited, recurse
    if ! printf '%s\n' "${_visited[@]}" | grep -q "^$dep$"; then
      if ! _wf_schedule_dfs_impl "$dep" "$schedule"; then
        return 1
      fi
    fi
  done

  # Mark as visited, remove from rec_stack
  _visited+=("$node")
  _rec_stack=("${_rec_stack[@]/$node}")
  return 0
}

# Validate DAG (no circular dependencies)
wf_schedule_validate_dag() {
  local schedule="$1"

  # Build adjacency list and detect cycles using DFS
  # Returns 0 if valid, 1 if cycle detected

  local works
  works=$(echo "$schedule" | jq -r '.works | keys[]')

  # Use topological sort to detect cycles
  # Initialize global arrays for DFS (bash function scope workaround)
  _visited=()
  _rec_stack=()

  for work in $works; do
    if ! printf '%s\n' "${_visited[@]}" | grep -q "^$work$"; then
      if ! _wf_schedule_dfs_impl "$work" "$schedule"; then
        return 1
      fi
    fi
  done

  return 0
}

# Calculate priority based on dependency graph
wf_schedule_calculate_priority() {
  local schedule="$1"

  # Topological sort to determine execution order
  # Works with no dependencies get highest priority
  # Works depending on others get lower priority

  local works
  works=$(echo "$schedule" | jq -r '.works | keys[]')

  for work in $works; do
    local depth
    depth=$(wf_schedule_get_dependency_depth "$schedule" "$work" 0)

    # Priority = depth + 1 (lower number = higher priority)
    schedule=$(echo "$schedule" | jq --arg w "$work" --argjson p "$((depth + 1))" \
      '.works[$w].priority = $p')
  done

  echo "$schedule"
}

# Get dependency depth (recursive)
wf_schedule_get_dependency_depth() {
  local schedule="$1"
  local work="$2"
  local current_depth="$3"

  local deps
  deps=$(echo "$schedule" | jq -r ".works[\"$work\"].dependencies[]?" 2>/dev/null)

  if [ -z "$deps" ]; then
    echo "$current_depth"
    return
  fi

  local max_depth=$current_depth
  for dep in $deps; do
    local dep_depth
    dep_depth=$(wf_schedule_get_dependency_depth "$schedule" "$dep" $((current_depth + 1)))
    if [ "$dep_depth" -gt "$max_depth" ]; then
      max_depth=$dep_depth
    fi
  done

  echo "$max_depth"
}
```

## Dependency Detection Patterns

The following patterns are detected from Issue/Jira body text:

| Pattern | Example | Detected Dependency |
|---------|---------|---------------------|
| `depends on #N` | depends on #123 | Issue #123 |
| `blocked by #N` | blocked by #456 | Issue #456 |
| `requires PROJ-N` | requires PROJ-789 | Jira PROJ-789 |
| `after: WORK-ID` | after: FEAT-001-auth | Work FEAT-001-auth |

Custom patterns can be configured in `config.json`. Note the different regex notations:

**Bash grep notation** (used in script):
```bash
# Uses POSIX ERE with grep -oiE
'depends on #([0-9]+)'
'blocked by #([0-9]+)'
'requires ([A-Z]+-[0-9]+)'
'after: ([A-Z]+-[0-9]+-[a-z0-9-]+)'
```

**JSON config notation** (used in config.json):
```json
{
  "batch": {
    "dependency_patterns": [
      "depends on #(\\d+)",
      "blocked by #(\\d+)",
      "requires ([A-Z]+-\\d+)",
      "after: ([A-Z]+-\\d+-\\w+)"
    ]
  }
}
```

Key differences:
- JSON requires double-escaped backslashes (`\\d` vs `[0-9]`)
- JSON uses PCRE-style shortcuts (`\\d`, `\\w`) while bash uses POSIX ERE (`[0-9]`, `[a-z0-9-]`)

## Schedule JSON Schema

The `status` field uses these values consistently throughout:
- Schedule status: `pending`, `running`, `paused`, `completed`
- Work status: `pending`, `running`, `completed`, `failed`

```json
{
  "version": "1.0",
  "created_at": "2026-01-26T10:00:00Z",
  "status": "pending",  // One of: pending, running, paused, completed
  "sources": [
    {"type": "github", "query": "label:scheduled"},
    {"type": "jira", "query": "sprint=current"},
    {"type": "local", "ids": "FEAT-001,FIX-002"}
  ],
  "works": {
    "FEAT-123-auth": {
      "work_id": "FEAT-123-auth",
      "source": {"type": "github", "id": "123", "title": "Add authentication"},
      "priority": 1,
      "dependencies": ["FEAT-100-database"],
      "status": "pending",  // One of: pending, running, completed, failed
      "worktree_path": ".worktrees/feat-123-auth"
    }
  },
  "execution": {
    "max_parallel": 3,
    "sessions": {
      "worker-1": {"work_id": "FEAT-100", "status": "running", "started_at": "..."}
    }
  },
  "progress": {
    "total": 5,
    "completed": 1,
    "in_progress": 2,
    "pending": 2
  }
}
```

## Output Examples

### Create Success

```
📅 Creating Schedule
═══════════════════════════════════════

Sources:
  - github: label:scheduled

Fetching from GitHub (label:scheduled)...
  - #123: Add user authentication
  - #124: Implement export feature
  - #125: Fix login bug

Analyzing dependencies...
  ✅ No circular dependencies

═══════════════════════════════════════
✅ Schedule created: 3 works

Use '/wf0-schedule show' to view the schedule
Use '/wf0-batch start' to begin execution
```

### Show Display

```
📅 Current Schedule
═══════════════════════════════════════

Status:     pending
Created:    2026-01-26T10:00:00Z

Progress:   0/3 completed
            0 in progress
            3 pending

═══════════════════════════════════════
Works (by priority):

[1] FEAT-100-database
    Status: pending
    Source: github #100
    Deps: (none)

[2] FEAT-123-auth
    Status: pending
    Source: github #123
    Deps: FEAT-100-database

[3] FEAT-124-export
    Status: pending
    Source: github #124
    Deps: FEAT-123-auth

═══════════════════════════════════════

Commands:
  /wf0-schedule edit <work-id>  - Edit priority/dependencies
  /wf0-schedule validate        - Check for issues
  /wf0-batch start              - Start execution
```

## Notes

- Requires `gh` CLI for GitHub integration
- Requires `jq` for JSON processing
- Jira integration requires API token configuration
- Schedule is stored in `.wf/schedule.json`
- Works are processed in priority order respecting dependencies
