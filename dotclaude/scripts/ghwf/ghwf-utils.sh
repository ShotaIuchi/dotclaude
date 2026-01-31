#!/usr/bin/env bash
#
# GHWF Utility Functions
#
# Shared functions for GitHub Workflow daemon
#

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

# Query issues with ghwf command labels
ghwf_query_command_issues() {
    # Query for any ghwf: command label
    gh issue list --json number,title,labels --limit 100 | jq -r '
        .[] | select(.labels[]?.name |
            test("^ghwf:(approve|redo|redo-[1-7]|revision|stop)$"))
    '
}

# Get command label from issue
ghwf_get_command_label() {
    local issue_number="$1"

    gh issue view "$issue_number" --json labels --jq '
        .labels[].name | select(test("^ghwf:(approve|redo|redo-[1-7]|revision|stop)$"))
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

# Add label to issue
ghwf_add_label() {
    local issue_number="$1"
    local label="$2"

    gh issue edit "$issue_number" --add-label "$label"
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

# Post status comment
ghwf_post_comment() {
    local issue_number="$1"
    local message="$2"

    gh issue comment "$issue_number" --body "🤖 $message"
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

# Invoke Claude Code for workflow step
ghwf_invoke_claude() {
    local step="$1"
    local work_id="$2"
    local instruction="$3"

    local cmd
    cmd=$(ghwf_get_step_command "$step")

    if [ -z "$cmd" ]; then
        echo "[ERROR] Invalid step: $step" >&2
        return 1
    fi

    if [ -n "$instruction" ]; then
        echo "$instruction" | claude --print "/$cmd revise"
    else
        claude --print "/$cmd"
    fi
}

# Push changes
ghwf_push_changes() {
    local branch
    branch=$(git branch --show-current)

    git push origin "$branch"
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
ghwf_ensure_labels() {
    local labels=(
        "ghwf:executing:#0E8A16:Currently executing a step"
        "ghwf:waiting:#FBCA04:Waiting for user approval"
        "ghwf:completed:#1D76DB:All steps completed"
        "ghwf:approve:#5319E7:Proceed to next step"
        "ghwf:redo:#D93F0B:Redo current step"
        "ghwf:redo-1:#D93F0B:Redo from step 1"
        "ghwf:redo-2:#D93F0B:Redo from step 2"
        "ghwf:redo-3:#D93F0B:Redo from step 3"
        "ghwf:redo-4:#D93F0B:Redo from step 4"
        "ghwf:redo-5:#D93F0B:Redo from step 5"
        "ghwf:redo-6:#D93F0B:Redo from step 6"
        "ghwf:redo-7:#D93F0B:Redo from step 7"
        "ghwf:revision:#D93F0B:Full revision from step 1"
        "ghwf:stop:#B60205:Stop monitoring"
        "ghwf:step-1:#C5DEF5:Step 1 completed"
        "ghwf:step-2:#C5DEF5:Step 2 completed"
        "ghwf:step-3:#C5DEF5:Step 3 completed"
        "ghwf:step-4:#C5DEF5:Step 4 completed"
        "ghwf:step-5:#C5DEF5:Step 5 completed"
        "ghwf:step-6:#C5DEF5:Step 6 completed"
        "ghwf:step-7:#C5DEF5:Step 7 completed"
    )

    for label_def in "${labels[@]}"; do
        IFS=':' read -r name color description <<< "$label_def"
        # Try to create, ignore if exists
        gh label create "$name" --color "${color#\#}" --description "$description" 2>/dev/null || true
    done
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
