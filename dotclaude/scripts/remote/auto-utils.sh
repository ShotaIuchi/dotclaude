#!/usr/bin/env bash
# shellcheck shell=bash
#
# WF Auto Mode Utilities
# Helper functions for automatic workflow discovery and execution
#
# NOTE: Run `shellcheck scripts/remote/auto-utils.sh` for static analysis
#

# Source common remote utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
if [ -f "$SCRIPT_DIR/remote-utils.sh" ]; then
    source "$SCRIPT_DIR/remote-utils.sh"
fi

# Get project root
_wf_auto_get_project_root() {
    git rev-parse --show-toplevel 2>/dev/null || pwd
}

# Get config file path
_wf_auto_get_config_file() {
    local project_root
    project_root=$(_wf_auto_get_project_root)

    # Check project-level config first
    if [ -f "$project_root/.wf/config.json" ]; then
        echo "$project_root/.wf/config.json"
    elif [ -f "$HOME/.claude/config.json" ]; then
        echo "$HOME/.claude/config.json"
    else
        echo ""
    fi
}

# Get auto.json state file path
_wf_auto_get_state_file() {
    local project_root
    project_root=$(_wf_auto_get_project_root)
    echo "$project_root/.wf/auto.json"
}

#
# Get configuration value with default
# @param $1 Key path (e.g., "auto.query")
# @param $2 Default value
# @return Configuration value
#
wf_auto_get_config() {
    local key="$1"
    local default="$2"
    local config_file
    config_file=$(_wf_auto_get_config_file)

    if [ -z "$config_file" ] || [ ! -f "$config_file" ]; then
        echo "$default"
        return
    fi

    local value
    value=$(jq -r ".$key // empty" "$config_file" 2>/dev/null)

    if [ -z "$value" ] || [ "$value" = "null" ]; then
        echo "$default"
    else
        echo "$value"
    fi
}

#
# Query GitHub Issues for auto-workflow processing
# @param $1 Query label (default: auto-workflow)
# @param $2 Exclude labels (comma-separated, default: completed)
# @return JSON array of issue objects
#
wf_auto_query_issues() {
    local query_label="${1:-auto-workflow}"
    local exclude_labels="${2:-completed}"

    # Build exclude filter
    local exclude_filter=""
    IFS=',' read -ra EXCLUDE_ARRAY <<< "$exclude_labels"
    for label in "${EXCLUDE_ARRAY[@]}"; do
        exclude_filter+=" -label:${label}"
    done

    # Query issues
    gh issue list \
        --label "$query_label" \
        --state open \
        --json number,title,labels,createdAt \
        --jq "[.[] | select(.labels | map(.name) | index(\"$exclude_labels\") | not)]" \
        2>/dev/null || echo "[]"
}

#
# Pick next issue to process (oldest first)
# @param $1 JSON array of issues
# @return Issue number or empty
#
wf_auto_pick_next() {
    local issues="$1"

    # Sort by createdAt and return oldest
    echo "$issues" | jq -r 'sort_by(.createdAt) | .[0].number // empty'
}

#
# Create branch for issue
# @param $1 Issue number
# @return Branch name
#
wf_auto_create_branch() {
    local issue_num="$1"
    local project_root
    project_root=$(_wf_auto_get_project_root)

    # Get issue info
    local issue_info
    issue_info=$(gh issue view "$issue_num" --json title,labels 2>/dev/null)

    if [ -z "$issue_info" ]; then
        echo "[ERROR] Failed to get issue #$issue_num info" >&2
        return 1
    fi

    local title
    title=$(echo "$issue_info" | jq -r '.title')

    # Determine prefix from labels
    local prefix="feat"
    local labels
    labels=$(echo "$issue_info" | jq -r '.labels[].name' 2>/dev/null)

    if echo "$labels" | grep -qi "bug\|fix"; then
        prefix="fix"
    elif echo "$labels" | grep -qi "refactor"; then
        prefix="refactor"
    elif echo "$labels" | grep -qi "chore"; then
        prefix="chore"
    fi

    # Create work ID from issue number
    local work_id
    work_id=$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//;s/-$//' | cut -c1-30)
    work_id="GH-${issue_num}-${work_id}"

    # Create branch name
    local branch_name="${prefix}/${work_id}"

    # Ensure we're on main/develop
    local base_branch
    base_branch=$(wf_auto_get_config "default_base_branch" "main")

    cd "$project_root" || return 1

    # Fetch and checkout base
    git fetch origin "$base_branch" 2>/dev/null || true
    git checkout "$base_branch" 2>/dev/null || git checkout -b "$base_branch" origin/"$base_branch" 2>/dev/null || true
    git pull origin "$base_branch" 2>/dev/null || true

    # Create feature branch
    if git checkout -b "$branch_name" 2>/dev/null; then
        echo "$branch_name"
        return 0
    else
        # Branch might already exist
        if git checkout "$branch_name" 2>/dev/null; then
            echo "$branch_name"
            return 0
        fi
        echo "[ERROR] Failed to create branch: $branch_name" >&2
        return 1
    fi
}

#
# Execute full workflow for an issue
# @param $1 Issue number
# @param $2 Work ID
# @return 0 on success, 1 on failure
#
wf_auto_execute_workflow() {
    local issue_num="$1"
    local work_id="$2"
    local project_root
    project_root=$(_wf_auto_get_project_root)

    cd "$project_root" || return 1

    # Execute wf1-kickoff first
    echo "[INFO] Starting kickoff for issue #$issue_num..."
    local output_file
    output_file=$(mktemp)

    if ! claude --print "/wf1-kickoff #$issue_num" > "$output_file" 2>&1; then
        echo "[ERROR] Kickoff failed. Output:" >&2
        cat "$output_file" >&2
        rm -f "$output_file"
        return 1
    fi
    rm -f "$output_file"

    # Then run nextstep loop
    local max_steps=10
    local step=0

    while [ $step -lt $max_steps ]; do
        step=$((step + 1))
        echo "[INFO] Executing step $step/$max_steps..."

        output_file=$(mktemp)
        if ! claude --print "/wf0-nextstep" > "$output_file" 2>&1; then
            echo "[ERROR] Step $step failed. Output:" >&2
            cat "$output_file" >&2
            rm -f "$output_file"
            return 1
        fi

        # Check if workflow is complete
        if grep -q "Workflow complete\|No next step\|completed" "$output_file" 2>/dev/null; then
            echo "[INFO] Workflow completed at step $step"
            rm -f "$output_file"
            return 0
        fi

        rm -f "$output_file"

        # Brief pause between steps
        sleep 5
    done

    echo "[WARN] Reached maximum steps ($max_steps)"
    return 0
}

#
# Mark issue as completed
# @param $1 Issue number
# @param $2 Label to add (default: completed)
#
wf_auto_mark_complete() {
    local issue_num="$1"
    local complete_label="${2:-completed}"

    # Add completed label
    if gh issue edit "$issue_num" --add-label "$complete_label" 2>/dev/null; then
        echo "[INFO] Added '$complete_label' label to issue #$issue_num"
    else
        echo "[WARN] Failed to add label to issue #$issue_num" >&2
    fi

    # Post completion comment
    local body="## Workflow Completed

This issue has been processed by WF Auto Mode.

---
*Automated message from WF Auto Daemon*"

    gh issue comment "$issue_num" --body "$body" 2>/dev/null || true
}

#
# Mark issue as failed (skip and continue)
# @param $1 Issue number
# @param $2 Error message
#
wf_auto_mark_failed() {
    local issue_num="$1"
    local error_msg="${2:-Unknown error}"

    # Post failure comment
    local body="## Workflow Failed

An error occurred during automatic processing:

\`\`\`
$error_msg
\`\`\`

This issue has been skipped. Manual intervention may be required.

---
*Automated message from WF Auto Daemon*"

    gh issue comment "$issue_num" --body "$body" 2>/dev/null || true

    echo "[WARN] Posted failure notice to issue #$issue_num"
}

#
# Update auto.json state file
# @param $1 Field name
# @param $2 Value
#
wf_auto_update_state() {
    local field="$1"
    local value="$2"
    local state_file
    state_file=$(_wf_auto_get_state_file)
    local project_root
    project_root=$(_wf_auto_get_project_root)

    # Ensure .wf directory exists
    mkdir -p "$project_root/.wf"

    # Create state file if it doesn't exist
    if [ ! -f "$state_file" ]; then
        echo '{}' > "$state_file"
    fi

    # Handle boolean, null, and numeric values
    if [ "$value" = "true" ] || [ "$value" = "false" ] || [ "$value" = "null" ] || [[ "$value" =~ ^[0-9]+$ ]]; then
        jq ".$field = $value" "$state_file" > "$state_file.tmp" && \
            mv "$state_file.tmp" "$state_file"
    else
        jq ".$field = \"$value\"" "$state_file" > "$state_file.tmp" && \
            mv "$state_file.tmp" "$state_file"
    fi
}

#
# Get value from auto.json state file
# @param $1 Field name
# @param $2 Default value
# @return Field value
#
wf_auto_get_state() {
    local field="$1"
    local default="${2:-}"
    local state_file
    state_file=$(_wf_auto_get_state_file)

    if [ ! -f "$state_file" ]; then
        echo "$default"
        return
    fi

    local value
    value=$(jq -r ".$field // empty" "$state_file" 2>/dev/null)

    if [ -z "$value" ] || [ "$value" = "null" ]; then
        echo "$default"
    else
        echo "$value"
    fi
}

#
# Push changes after workflow execution
# @return 0 on success, 1 on failure
#
wf_auto_push_changes() {
    local project_root
    project_root=$(_wf_auto_get_project_root)

    cd "$project_root" || return 1

    # Get current branch
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD)

    # Check for uncommitted changes
    if [ -n "$(git status --porcelain)" ]; then
        echo "[WARN] Uncommitted changes exist, skipping push"
        return 0
    fi

    # Push to remote
    if git push -u origin "$branch" 2>&1; then
        echo "[INFO] Pushed to origin/$branch"
        return 0
    else
        echo "[ERROR] Failed to push to origin/$branch"
        return 1
    fi
}

#
# Clean up branch after failed execution
# @param $1 Branch name
#
wf_auto_cleanup_branch() {
    local branch="$1"
    local project_root
    project_root=$(_wf_auto_get_project_root)

    cd "$project_root" || return

    # Get base branch
    local base_branch
    base_branch=$(wf_auto_get_config "default_base_branch" "main")

    # Checkout base and delete feature branch
    git checkout "$base_branch" 2>/dev/null || true
    git branch -D "$branch" 2>/dev/null || true

    echo "[INFO] Cleaned up branch: $branch"
}
