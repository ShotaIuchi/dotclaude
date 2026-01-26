#!/usr/bin/env bash
# shellcheck shell=bash
#
# WF Batch Utilities
# Helper functions for batch workflow operations
#
# NOTE: Run `shellcheck scripts/batch/batch-utils.sh` for static analysis
#

# Get project root
_wf_batch_get_project_root() {
    git rev-parse --show-toplevel 2>/dev/null || pwd
}

# Get schedule file path
_wf_batch_get_schedule_file() {
    echo "$(_wf_batch_get_project_root)/.wf/schedule.json"
}

# Get config file path
_wf_batch_get_config_file() {
    local project_root
    project_root=$(_wf_batch_get_project_root)

    if [ -f "$project_root/.wf/config.json" ]; then
        echo "$project_root/.wf/config.json"
    elif [ -f "$HOME/.claude/examples/config.json" ]; then
        echo "$HOME/.claude/examples/config.json"
    else
        echo ""
    fi
}

#
# Lock management for schedule.json
# Uses flock for atomic operations
#

LOCK_FILE="/tmp/wf-batch-schedule.lock"

wf_batch_lock() {
    exec 200>"$LOCK_FILE"
    flock -x 200
}

wf_batch_unlock() {
    flock -u 200 2>/dev/null || true
}

#
# Update schedule.json atomically
# @param $1 jq expression
#
wf_batch_update_schedule() {
    local jq_expr="$1"
    local schedule_file
    schedule_file=$(_wf_batch_get_schedule_file)

    wf_batch_lock
    jq "$jq_expr" "$schedule_file" > "$schedule_file.tmp" && \
        mv "$schedule_file.tmp" "$schedule_file"
    wf_batch_unlock
}

#
# Get next available work for execution
# Returns work_id that has no unresolved dependencies
# @return work_id or empty string
#
wf_batch_get_next_work() {
    local schedule_file
    schedule_file=$(_wf_batch_get_schedule_file)

    if [ ! -f "$schedule_file" ]; then
        return
    fi

    wf_batch_lock

    # Get all pending works sorted by priority
    local pending_works
    pending_works=$(jq -r '
        .works | to_entries
        | map(select(.value.status == "pending"))
        | sort_by(.value.priority)
        | .[].key
    ' "$schedule_file")

    # Find first work with all dependencies resolved
    for work_id in $pending_works; do
        local deps_resolved=true

        # Get dependencies
        local deps
        deps=$(jq -r ".works[\"$work_id\"].dependencies[]?" "$schedule_file" 2>/dev/null)

        for dep in $deps; do
            # Check if dependency is completed
            local dep_status
            dep_status=$(jq -r ".works[\"$dep\"].status // \"pending\"" "$schedule_file")

            if [ "$dep_status" != "completed" ]; then
                deps_resolved=false
                break
            fi
        done

        if [ "$deps_resolved" = true ]; then
            wf_batch_unlock
            echo "$work_id"
            return
        fi
    done

    wf_batch_unlock
}

#
# Claim a work for a specific worker
# @param $1 work_id
# @param $2 worker_id (e.g., "worker-1")
# @return 0 on success, 1 if already claimed
#
wf_batch_claim_work() {
    local work_id="$1"
    local worker_id="$2"
    local schedule_file
    schedule_file=$(_wf_batch_get_schedule_file)

    wf_batch_lock

    # Check current status
    local current_status
    current_status=$(jq -r ".works[\"$work_id\"].status" "$schedule_file")

    if [ "$current_status" != "pending" ]; then
        wf_batch_unlock
        return 1
    fi

    # Claim the work
    jq --arg w "$work_id" --arg wkr "$worker_id" '
        .works[$w].status = "running" |
        .execution.sessions[$wkr] = {
            "work_id": $w,
            "status": "running",
            "started_at": (now | todate)
        } |
        .progress.pending = ([.works[] | select(.status == "pending")] | length) |
        .progress.in_progress = ([.works[] | select(.status == "running")] | length)
    ' "$schedule_file" > "$schedule_file.tmp" && mv "$schedule_file.tmp" "$schedule_file"

    wf_batch_unlock
    return 0
}

#
# Mark work as completed
# @param $1 work_id
# @param $2 worker_id
#
wf_batch_complete_work() {
    local work_id="$1"
    local worker_id="$2"
    local schedule_file
    schedule_file=$(_wf_batch_get_schedule_file)

    wf_batch_lock

    jq --arg w "$work_id" --arg wkr "$worker_id" '
        .works[$w].status = "completed" |
        .works[$w].completed_at = (now | todate) |
        .execution.sessions[$wkr] = {
            "work_id": null,
            "status": "idle"
        } |
        .progress.completed = ([.works[] | select(.status == "completed")] | length) |
        .progress.in_progress = ([.works[] | select(.status == "running")] | length)
    ' "$schedule_file" > "$schedule_file.tmp" && mv "$schedule_file.tmp" "$schedule_file"

    wf_batch_unlock

    # Check if all works completed
    local pending
    pending=$(jq '[.works[] | select(.status == "pending" or .status == "running")] | length' "$schedule_file")

    if [ "$pending" -eq 0 ]; then
        wf_batch_update_schedule '.status = "completed"'
    fi
}

#
# Mark work as failed
# @param $1 work_id
# @param $2 worker_id
# @param $3 error message
#
wf_batch_fail_work() {
    local work_id="$1"
    local worker_id="$2"
    local error_msg="$3"
    local schedule_file
    schedule_file=$(_wf_batch_get_schedule_file)

    wf_batch_lock

    jq --arg w "$work_id" --arg wkr "$worker_id" --arg err "$error_msg" '
        .works[$w].status = "failed" |
        .works[$w].error = $err |
        .works[$w].failed_at = (now | todate) |
        .execution.sessions[$wkr] = {
            "work_id": null,
            "status": "idle"
        } |
        .progress.in_progress = ([.works[] | select(.status == "running")] | length)
    ' "$schedule_file" > "$schedule_file.tmp" && mv "$schedule_file.tmp" "$schedule_file"

    wf_batch_unlock
}

#
# Release worker (set to idle without completing work)
# @param $1 worker_id
#
wf_batch_release_worker() {
    local worker_id="$1"
    local schedule_file
    schedule_file=$(_wf_batch_get_schedule_file)

    wf_batch_lock

    jq --arg wkr "$worker_id" '
        .execution.sessions[$wkr] = {
            "work_id": null,
            "status": "idle"
        }
    ' "$schedule_file" > "$schedule_file.tmp" && mv "$schedule_file.tmp" "$schedule_file"

    wf_batch_unlock
}

#
# Create worktree for a work
# @param $1 work_id
# @param $2 branch name
# @return worktree path
#
wf_batch_create_worktree() {
    local work_id="$1"
    local branch="$2"
    local project_root
    project_root=$(_wf_batch_get_project_root)

    local config_file
    config_file=$(_wf_batch_get_config_file)

    local worktree_root
    if [ -n "$config_file" ]; then
        worktree_root=$(jq -r '.worktree.root_dir // ".worktrees"' "$config_file")
    else
        worktree_root=".worktrees"
    fi

    local worktree_path="$project_root/$worktree_root/$(echo "$work_id" | tr '[:upper:]' '[:lower:]')"

    # Check if worktree already exists
    if [ -d "$worktree_path" ]; then
        echo "$worktree_path"
        return 0
    fi

    # Create branch if it doesn't exist
    if ! git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null; then
        # Get base branch from config
        local base_branch
        if [ -n "$config_file" ]; then
            base_branch=$(jq -r '.default_base_branch // "main"' "$config_file")
        else
            base_branch="main"
        fi

        git branch "$branch" "$base_branch" 2>/dev/null || true
    fi

    # Create worktree
    mkdir -p "$(dirname "$worktree_path")"
    git worktree add "$worktree_path" "$branch" 2>/dev/null

    # Symlink .wf directory for shared state
    if [ -d "$project_root/.wf" ]; then
        ln -sf "$project_root/.wf" "$worktree_path/.wf" 2>/dev/null || true
    fi

    # Update schedule with worktree path
    wf_batch_update_schedule ".works[\"$work_id\"].worktree_path = \"$worktree_root/$(echo "$work_id" | tr '[:upper:]' '[:lower:]')\""

    echo "$worktree_path"
}

#
# Cleanup worktree after work completion
# @param $1 work_id
#
wf_batch_cleanup_worktree() {
    local work_id="$1"
    local project_root
    project_root=$(_wf_batch_get_project_root)

    local config_file
    config_file=$(_wf_batch_get_config_file)

    local worktree_root
    if [ -n "$config_file" ]; then
        worktree_root=$(jq -r '.worktree.root_dir // ".worktrees"' "$config_file")
    else
        worktree_root=".worktrees"
    fi

    local worktree_path="$project_root/$worktree_root/$(echo "$work_id" | tr '[:upper:]' '[:lower:]')"

    if [ -d "$worktree_path" ]; then
        # Remove symlink first
        rm -f "$worktree_path/.wf" 2>/dev/null || true

        # Remove worktree
        git worktree remove "$worktree_path" --force 2>/dev/null || rm -rf "$worktree_path"
    fi

    # Update schedule
    wf_batch_update_schedule ".works[\"$work_id\"].worktree_path = null"
}

#
# Get branch name for a work
# @param $1 work_id
# @return branch name
#
wf_batch_get_branch_name() {
    local work_id="$1"
    local config_file
    config_file=$(_wf_batch_get_config_file)

    # Determine prefix from work_id
    local prefix
    prefix=$(echo "$work_id" | cut -d'-' -f1)

    local branch_prefix
    if [ -n "$config_file" ]; then
        branch_prefix=$(jq -r ".branch_prefix.$prefix // \"feat\"" "$config_file")
    else
        branch_prefix="feat"
    fi

    # Extract issue number and slug
    local issue_slug
    issue_slug=$(echo "$work_id" | sed "s/^$prefix-//")

    echo "$branch_prefix/$issue_slug"
}

#
# Check if schedule is in running state
# @return 0 if running, 1 otherwise
#
wf_batch_is_running() {
    local schedule_file
    schedule_file=$(_wf_batch_get_schedule_file)

    if [ ! -f "$schedule_file" ]; then
        return 1
    fi

    local status
    status=$(jq -r '.status' "$schedule_file")

    [ "$status" = "running" ]
}

#
# Get schedule status summary
# @return JSON with progress info
#
wf_batch_get_progress() {
    local schedule_file
    schedule_file=$(_wf_batch_get_schedule_file)

    if [ ! -f "$schedule_file" ]; then
        echo '{"total":0,"completed":0,"in_progress":0,"pending":0}'
        return
    fi

    jq '.progress' "$schedule_file"
}

#
# Log message with timestamp
# @param $1 level (INFO|WARN|ERROR)
# @param $2 message
#
wf_batch_log() {
    local level="$1"
    local message="$2"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message"
}

#
# Execute Claude Code for a work
# @param $1 work_id
# @param $2 worktree_path
# @param $3 workflow command (e.g., "wf0-nextstep")
# @return 0 on success, 1 on failure
#
wf_batch_invoke_claude() {
    local work_id="$1"
    local worktree_path="$2"
    local wf_command="${3:-wf0-nextstep}"

    # Change to worktree directory
    cd "$worktree_path" || return 1

    # Execute Claude Code
    local output_file
    output_file=$(mktemp)
    local exit_code=0

    if claude --print "/$wf_command $work_id" > "$output_file" 2>&1; then
        exit_code=0
    else
        exit_code=1
        wf_batch_log "ERROR" "Claude execution failed for $work_id"
        cat "$output_file" >&2
    fi

    rm -f "$output_file"
    return $exit_code
}

#
# Push changes from worktree
# @param $1 work_id
# @param $2 worktree_path
# @return 0 on success, 1 on failure
#
wf_batch_push_changes() {
    local work_id="$1"
    local worktree_path="$2"

    cd "$worktree_path" || return 1

    local branch
    branch=$(git rev-parse --abbrev-ref HEAD)

    # Check for uncommitted changes
    if [ -n "$(git status --porcelain)" ]; then
        wf_batch_log "WARN" "Uncommitted changes in $work_id, skipping push"
        return 0
    fi

    # Push to remote
    if git push origin "$branch" 2>&1; then
        wf_batch_log "INFO" "Pushed $branch to origin"
        return 0
    else
        wf_batch_log "ERROR" "Failed to push $branch"
        return 1
    fi
}

#
# Check if all dependencies of a work are completed
# @param $1 work_id
# @return 0 if all deps completed, 1 otherwise
#
wf_batch_deps_resolved() {
    local work_id="$1"
    local schedule_file
    schedule_file=$(_wf_batch_get_schedule_file)

    local deps
    deps=$(jq -r ".works[\"$work_id\"].dependencies[]?" "$schedule_file" 2>/dev/null)

    if [ -z "$deps" ]; then
        return 0
    fi

    for dep in $deps; do
        local dep_status
        dep_status=$(jq -r ".works[\"$dep\"].status // \"pending\"" "$schedule_file")

        if [ "$dep_status" != "completed" ]; then
            return 1
        fi
    done

    return 0
}

#
# Generate work-id from issue number and title
# @param $1 issue_num
# @param $2 title
# @param $3 prefix (optional, defaults to FEAT)
# @return work_id
#
wf_batch_generate_work_id() {
    local issue_num="$1"
    local title="$2"
    local prefix="${3:-FEAT}"

    # Detect type from title
    if echo "$title" | grep -qi "fix\|bug"; then
        prefix="FIX"
    elif echo "$title" | grep -qi "refactor"; then
        prefix="REFACTOR"
    elif echo "$title" | grep -qi "chore"; then
        prefix="CHORE"
    fi

    # Create slug from title
    local slug
    slug=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | cut -c1-30 | sed 's/-$//')

    echo "$prefix-$issue_num-$slug"
}

#
# Detect dependencies from issue/PR body text
# @param $1 body text
# @return JSON array of dependencies
#
wf_batch_detect_dependencies() {
    local body="$1"
    local deps=()

    # Default patterns
    local patterns=(
        'depends on #([0-9]+)'
        'blocked by #([0-9]+)'
        'requires ([A-Z]+-[0-9]+)'
        'after: ([A-Z]+-[0-9]+-[a-z0-9-]+)'
    )

    # Load custom patterns from config if available
    local config_file
    config_file=$(_wf_batch_get_config_file)

    if [ -n "$config_file" ]; then
        local custom_patterns
        custom_patterns=$(jq -r '.batch.dependency_patterns[]?' "$config_file" 2>/dev/null)
        if [ -n "$custom_patterns" ]; then
            patterns=()
            while IFS= read -r p; do
                patterns+=("$p")
            done <<< "$custom_patterns"
        fi
    fi

    for pattern in "${patterns[@]}"; do
        local matches
        matches=$(echo "$body" | grep -oiE "$pattern" 2>/dev/null | sed -E "s/$pattern/\1/i")
        for match in $matches; do
            deps+=("$match")
        done
    done

    # Return as JSON array
    if [ ${#deps[@]} -eq 0 ]; then
        echo "[]"
    else
        printf '%s\n' "${deps[@]}" | jq -R . | jq -s 'unique'
    fi
}
