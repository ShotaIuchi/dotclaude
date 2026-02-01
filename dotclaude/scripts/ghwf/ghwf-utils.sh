#!/usr/bin/env bash
#
# GHWF Utility Functions
#
# Shared functions for GitHub Workflow daemon
#

# =============================================================================
# Retry Configuration
# =============================================================================

GHWF_RETRY_MAX="${GHWF_RETRY_MAX:-3}"
GHWF_RETRY_DELAY="${GHWF_RETRY_DELAY:-5}"
GHWF_RETRY_BACKOFF="${GHWF_RETRY_BACKOFF:-2}"

# Generic retry wrapper with exponential backoff
# Usage: ghwf_retry <max_attempts> <initial_delay> <backoff_multiplier> <command...>
ghwf_retry() {
    local max_attempts="$1"
    local delay="$2"
    local backoff="$3"
    shift 3

    local attempt=1
    local exit_code=0

    while [ "$attempt" -le "$max_attempts" ]; do
        if "$@"; then
            return 0
        fi
        exit_code=$?

        if [ "$attempt" -lt "$max_attempts" ]; then
            echo "[RETRY] Attempt $attempt/$max_attempts failed. Retrying in ${delay}s..." >&2
            sleep "$delay"
            delay=$((delay * backoff))
        fi

        ((attempt++))
    done

    echo "[RETRY] All $max_attempts attempts failed" >&2
    return "$exit_code"
}

# Retry with default settings
# Usage: ghwf_retry_default <command...>
ghwf_retry_default() {
    ghwf_retry "$GHWF_RETRY_MAX" "$GHWF_RETRY_DELAY" "$GHWF_RETRY_BACKOFF" "$@"
}

# =============================================================================
# Core Functions
# =============================================================================

# Get project root
ghwf_get_project_root() {
    git rev-parse --show-toplevel 2>/dev/null || pwd
}

# Get state file path
ghwf_get_state_file() {
    echo "$(ghwf_get_project_root)/.wf/ghwf-state.json"
}

# Initialize state file if not exists
ghwf_init_state() {
    local state_file
    state_file=$(ghwf_get_state_file)

    if [ ! -f "$state_file" ]; then
        mkdir -p "$(dirname "$state_file")"
        cat > "$state_file" << 'EOF'
{
  "daemon": {
    "enabled": false
  },
  "works": {}
}
EOF
    fi
}

# Update daemon state
ghwf_update_daemon_state() {
    local key="$1"
    local value="$2"
    local state_file
    state_file=$(ghwf_get_state_file)

    ghwf_init_state

    local tmp_file="${state_file}.tmp"
    jq --arg key "$key" --arg value "$value" \
        '.daemon[$key] = $value' "$state_file" > "$tmp_file" && \
        mv "$tmp_file" "$state_file"
}

# Query issues with ghwf command labels (with retry)
# Only returns issues that have BOTH:
#   1. The base "ghwf" label (opt-in for monitoring)
#   2. A command label (ghwf:start, ghwf:approve, etc.)
ghwf_query_command_issues() {
    ghwf_retry_default gh issue list --label "ghwf" --json number,title,labels --limit 100 | jq -r '
        .[] | select(.labels[]?.name |
            test("^ghwf:(exec|redo|redo-[1-7]|revision|stop)$"))
    '
}

# Get command label from issue (with retry)
ghwf_get_command_label() {
    local issue_number="$1"

    ghwf_retry_default gh issue view "$issue_number" --json labels --jq '
        .labels[].name | select(test("^ghwf:(exec|redo|redo-[1-7]|revision|stop)$"))
    ' | head -1
}

# Get state labels from issue
ghwf_get_state_labels() {
    local issue_number="$1"

    gh issue view "$issue_number" --json labels --jq '
        [.labels[].name | select(test("^ghwf:(executing|waiting|completed|step-[1-7])$"))]
    '
}

# Remove label from issue
ghwf_remove_label() {
    local issue_number="$1"
    local label="$2"

    gh issue edit "$issue_number" --remove-label "$label" 2>/dev/null || true
}

# Add label to issue (with retry)
ghwf_add_label() {
    local issue_number="$1"
    local label="$2"

    ghwf_retry_default gh issue edit "$issue_number" --add-label "$label"
}

# Check for updates since last execution
ghwf_check_updates() {
    local issue_number="$1"
    local last_execution="$2"
    local pr_number="$3"

    # Get issue updated time
    local issue_updated
    issue_updated=$(gh issue view "$issue_number" --json updatedAt --jq '.updatedAt')

    # Compare timestamps
    if [[ "$issue_updated" > "$last_execution" ]]; then
        echo "issue_updated"
        return 0
    fi

    # Check for new comments (excluding bot)
    local new_comments
    new_comments=$(gh issue view "$issue_number" --json comments --jq "
        [.comments[] |
         select(.createdAt > \"$last_execution\") |
         select(.author.login != \"github-actions[bot]\") |
         select(.body | startswith(\"🤖\") | not)
        ] | length
    ")

    if [ "$new_comments" -gt 0 ]; then
        echo "new_comments"
        return 0
    fi

    # Check PR reviews if PR exists
    if [ -n "$pr_number" ] && [ "$pr_number" != "null" ]; then
        local new_reviews
        new_reviews=$(gh pr view "$pr_number" --json reviews --jq "
            [.reviews[] | select(.submittedAt > \"$last_execution\")] | length
        ")

        if [ "$new_reviews" -gt 0 ]; then
            echo "pr_reviews"
            return 0
        fi
    fi

    # No updates
    echo "none"
    return 1
}

# Get latest instruction from comments
ghwf_get_instruction() {
    local issue_number="$1"
    local last_execution="$2"

    gh issue view "$issue_number" --json comments --jq "
        [.comments[] |
         select(.createdAt > \"$last_execution\") |
         select(.author.login != \"github-actions[bot]\") |
         select(.body | startswith(\"🤖\") | not)
        ] | last | .body // \"\"
    "
}

# Post status comment (with retry)
ghwf_post_comment() {
    local issue_number="$1"
    local message="$2"

    ghwf_retry_default gh issue comment "$issue_number" --body "🤖 $message"
}

# Get work-id from issue number
ghwf_get_work_id() {
    local issue_number="$1"
    local state_file
    state_file=$(ghwf_get_state_file)

    if [ ! -f "$state_file" ]; then
        return 1
    fi

    jq -r --arg issue "$issue_number" '
        .works | to_entries[] |
        select(.value.source.issue == ($issue | tonumber)) |
        .key
    ' "$state_file"
}

# Get step number from label
ghwf_get_step_from_label() {
    local label="$1"

    case "$label" in
        ghwf:redo-1) echo 1 ;;
        ghwf:redo-2) echo 2 ;;
        ghwf:redo-3) echo 3 ;;
        ghwf:redo-4) echo 4 ;;
        ghwf:redo-5) echo 5 ;;
        ghwf:redo-6) echo 6 ;;
        ghwf:redo-7) echo 7 ;;
        ghwf:revision) echo 1 ;;
        *) echo 0 ;;
    esac
}

# Get auto-to step limit from issue labels
# Returns the minimum step from auto-to labels, or 0 if none
ghwf_get_auto_to_step() {
    local issue_number="$1"

    gh issue view "$issue_number" --json labels --jq '
        [.labels[].name |
         select(test("^ghwf:auto-to-[2-6]$")) |
         sub("ghwf:auto-to-"; "") | tonumber
        ] + [
         .labels[].name |
         select(. == "ghwf:auto-all") |
         7
        ] |
        if length > 0 then min else 0 end
    '
}

# Check if current step should auto-continue (no approval needed)
# Returns: "yes" if should continue, "no" if should wait
ghwf_should_auto_continue() {
    local issue_number="$1"
    local current_step="$2"

    local auto_limit
    auto_limit=$(ghwf_get_auto_to_step "$issue_number")

    if [ "$auto_limit" -eq 0 ]; then
        echo "no"
        return 1
    fi

    if [ "$current_step" -lt "$auto_limit" ]; then
        echo "yes"
        return 0
    else
        echo "no"
        return 1
    fi
}

# Get current step from labels
ghwf_get_current_step() {
    local issue_number="$1"

    gh issue view "$issue_number" --json labels --jq '
        [.labels[].name | select(test("^ghwf:step-[1-7]$"))] |
        map(sub("ghwf:step-"; "") | tonumber) |
        max // 0
    '
}

# Get step command name
ghwf_get_step_command() {
    local step="$1"
    case "$step" in
        1) echo "ghwf1-kickoff" ;;
        2) echo "ghwf2-spec" ;;
        3) echo "ghwf3-plan" ;;
        4) echo "ghwf4-review" ;;
        5) echo "ghwf5-implement" ;;
        6) echo "ghwf6-verify" ;;
        7) echo "ghwf7-pr" ;;
        *) echo "" ;;
    esac
}

# Invoke Claude Code for workflow step (with retry)
# Note: Uses fewer retries for Claude as it's a heavier operation
# Args: step, issue_number, work_id, instruction
ghwf_invoke_claude() {
    local step="$1"
    local issue_number="$2"
    local work_id="$3"
    local instruction="$4"

    local cmd
    cmd=$(ghwf_get_step_command "$step")

    if [ -z "$cmd" ]; then
        echo "[ERROR] Invalid step: $step" >&2
        return 1
    fi

    # Use 2 retries with longer delay for Claude invocations
    local max_retries="${GHWF_CLAUDE_RETRY_MAX:-2}"
    local retry_delay="${GHWF_CLAUDE_RETRY_DELAY:-30}"

    if [ -n "$instruction" ]; then
        # Revise mode: all steps use state.json, no extra args needed
        ghwf_retry "$max_retries" "$retry_delay" 2 bash -c "echo '$instruction' | claude --print '/$cmd revise'"
    else
        # New execution: ghwf1-kickoff requires issue number
        if [ "$step" -eq 1 ]; then
            ghwf_retry "$max_retries" "$retry_delay" 2 claude --print "/$cmd $issue_number"
        else
            ghwf_retry "$max_retries" "$retry_delay" 2 claude --print "/$cmd"
        fi
    fi
}

# Push changes (with retry)
ghwf_push_changes() {
    local branch
    branch=$(git branch --show-current)

    ghwf_retry_default git push origin "$branch"
}

# Check collaborator permission for a user
# Returns: "allowed" or "denied"
ghwf_check_permission() {
    local username="$1"

    if [ -z "$username" ]; then
        echo "denied"
        return 1
    fi

    local permission
    permission=$(gh api "repos/{owner}/{repo}/collaborators/$username/permission" \
        --jq '.permission' 2>/dev/null || echo "none")

    case "$permission" in
        admin|write|maintain)
            echo "allowed"
            return 0
            ;;
        *)
            echo "denied"
            return 1
            ;;
    esac
}

# Get comment author from issue
ghwf_get_label_author() {
    local issue_number="$1"
    local label="$2"

    # GitHub API doesn't directly tell who added a label
    # Check timeline events for label additions
    gh api "repos/{owner}/{repo}/issues/$issue_number/timeline" \
        --jq "[.[] | select(.event == \"labeled\" and .label.name == \"$label\")] | last | .actor.login // \"\"" \
        2>/dev/null || echo ""
}

# Ensure required labels exist in the repository
# Format: name|color|description (using | as delimiter to avoid conflict with : in label names)
# Auto-detects repository from current directory
ghwf_ensure_labels() {
    # Get repository name (owner/repo format)
    local repo
    repo=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null) || {
        echo "[WARN] Could not detect repository. Skipping label creation." >&2
        return 1
    }

    echo "[INFO] Creating labels for $repo..."

    local labels=(
        "ghwf|#6F42C1|Enable ghwf daemon monitoring"
        "ghwf:executing|#0E8A16|Currently executing a step"
        "ghwf:waiting|#FBCA04|Waiting for user approval"
        "ghwf:completed|#1D76DB|All steps completed"
        "ghwf:exec|#5319E7|Execute next step"
        "ghwf:redo|#D93F0B|Redo current step"
        "ghwf:redo-1|#D93F0B|Redo from step 1"
        "ghwf:redo-2|#D93F0B|Redo from step 2"
        "ghwf:redo-3|#D93F0B|Redo from step 3"
        "ghwf:redo-4|#D93F0B|Redo from step 4"
        "ghwf:redo-5|#D93F0B|Redo from step 5"
        "ghwf:redo-6|#D93F0B|Redo from step 6"
        "ghwf:redo-7|#D93F0B|Redo from step 7"
        "ghwf:revision|#D93F0B|Full revision from step 1"
        "ghwf:stop|#B60205|Stop monitoring"
        "ghwf:auto-to-2|#5319E7|Auto-run until step 2 (spec)"
        "ghwf:auto-to-3|#5319E7|Auto-run until step 3 (plan)"
        "ghwf:auto-to-4|#5319E7|Auto-run until step 4 (review)"
        "ghwf:auto-to-5|#5319E7|Auto-run until step 5 (implement)"
        "ghwf:auto-to-6|#5319E7|Auto-run until step 6 (verify)"
        "ghwf:auto-all|#5319E7|Auto-run all steps without approval"
        "ghwf:waiting-deps|#FEF2C0|Waiting for dependency issues to close"
        "ghwf:waiting-subs|#FEF2C0|Waiting for sub-issues to complete"
        "ghwf:step-1|#C5DEF5|Step 1 completed"
        "ghwf:step-2|#C5DEF5|Step 2 completed"
        "ghwf:step-3|#C5DEF5|Step 3 completed"
        "ghwf:step-4|#C5DEF5|Step 4 completed"
        "ghwf:step-5|#C5DEF5|Step 5 completed"
        "ghwf:step-6|#C5DEF5|Step 6 completed"
        "ghwf:step-7|#C5DEF5|Step 7 completed"
    )

    local created=0
    local skipped=0
    for label_def in "${labels[@]}"; do
        IFS='|' read -r name color description <<< "$label_def"
        # Try to create with explicit --repo, ignore if exists
        if gh label create "$name" --repo "$repo" --color "${color#\#}" --description "$description" 2>/dev/null; then
            ((created++))
        else
            ((skipped++))
        fi
    done

    echo "[INFO] Labels: $created created, $skipped already exist"
}

# Update work state in state file
ghwf_update_work_state() {
    local work_id="$1"
    local key="$2"
    local value="$3"
    local state_file
    state_file=$(ghwf_get_state_file)

    ghwf_init_state

    local tmp_file="${state_file}.tmp"
    jq --arg work_id "$work_id" --arg key "$key" --arg value "$value" \
        '.works[$work_id][$key] = $value' "$state_file" > "$tmp_file" && \
        mv "$tmp_file" "$state_file"
}

# Check if issue is blocked by dependencies
# Returns: "blocked" if has open blocking issues, "ok" otherwise
ghwf_check_dependencies() {
    local issue_number="$1"

    # Get blocked_by dependencies via REST API
    local blocked_by
    blocked_by=$(gh api "repos/{owner}/{repo}/issues/$issue_number/dependencies/blocked_by" \
        --jq '[.[] | select(.state == "open")] | length' 2>/dev/null || echo "0")

    if [ "$blocked_by" -gt 0 ]; then
        echo "blocked"
    else
        echo "ok"
    fi
}

# Get list of blocking issue numbers (open only)
ghwf_get_blocking_issues() {
    local issue_number="$1"

    gh api "repos/{owner}/{repo}/issues/$issue_number/dependencies/blocked_by" \
        --jq '[.[] | select(.state == "open") | .number] | join(", ")' 2>/dev/null || echo ""
}

# Check if issue has open sub-issues
# Returns: "blocked" if has open sub-issues, "ok" otherwise
ghwf_check_sub_issues() {
    local issue_number="$1"

    # Get sub-issues via REST API
    local open_subs
    open_subs=$(gh api "repos/{owner}/{repo}/issues/$issue_number/sub_issues" \
        --jq '[.[] | select(.state == "open")] | length' 2>/dev/null || echo "0")

    if [ "$open_subs" -gt 0 ]; then
        echo "blocked"
    else
        echo "ok"
    fi
}

# Get list of open sub-issue numbers
ghwf_get_open_sub_issues() {
    local issue_number="$1"

    gh api "repos/{owner}/{repo}/issues/$issue_number/sub_issues" \
        --jq '[.[] | select(.state == "open") | .number] | join(", ")' 2>/dev/null || echo ""
}

# Get PR number from issue
ghwf_get_pr_from_issue() {
    local issue_number="$1"
    local state_file
    state_file=$(ghwf_get_state_file)

    if [ ! -f "$state_file" ]; then
        return 1
    fi

    jq -r --arg issue "$issue_number" '
        .works | to_entries[] |
        select(.value.source.issue == ($issue | tonumber)) |
        .value.source.pr // ""
    ' "$state_file"
}
