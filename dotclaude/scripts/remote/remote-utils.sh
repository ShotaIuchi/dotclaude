#!/usr/bin/env bash
# shellcheck shell=bash
#
# WF Remote Utilities
# Helper functions for remote workflow operations
#
# State architecture:
#   docs/wf/<work-id>/state.json - per-work state (committed)
#   .wf/state.json               - legacy fallback (minimal)
#
# NOTE: Run `shellcheck scripts/remote/remote-utils.sh` for static analysis
#

# Get project root
_wf_remote_get_project_root() {
    git rev-parse --show-toplevel 2>/dev/null || pwd
}

# Get per-work state file path
# @param $1 work-id
_wf_remote_get_work_state_file() {
    local work_id="$1"
    echo "$(_wf_remote_get_project_root)/docs/wf/${work_id}/state.json"
}

# Get legacy state file path (fallback)
_wf_remote_get_state_file() {
    echo "$(_wf_remote_get_project_root)/.wf/state.json"
}

#
# Check for new commands in Issue comments
# @param $1 Issue number
# @param $2 Last processed comment ID (optional)
# @return JSON with command info or empty
#
wf_remote_check_commands() {
    local issue_num="$1"
    local last_comment_id="${2:-}"

    # Get recent comments (last 10)
    local comments
    comments=$(gh api "repos/{owner}/{repo}/issues/$issue_num/comments" \
        --jq 'reverse | .[:10]' 2>/dev/null || echo "[]")

    # Look for command comments
    # Handle empty last_id by using -1 as default (no valid comment ID is negative)
    echo "$comments" | jq -r --arg last_id "$last_comment_id" '
        .[] |
        select(.id != (if $last_id == "" then -1 else ($last_id | tonumber) end)) |
        select(.body | test("^/(approve|next|pause|stop)\\s*$"; "i")) |
        {
            comment_id: .id,
            command: (.body | capture("^/(?<cmd>approve|next|pause|stop)"; "i") | .cmd | ascii_downcase),
            author: .user.login,
            created_at: .created_at
        }
    ' | head -1
}

#
# Check if user is a collaborator
# @param $1 Username
# @return 0 if collaborator, 1 otherwise
#
wf_remote_is_collaborator() {
    local username="$1"

    # Check repository collaborator permission
    local permission
    permission=$(gh api "repos/{owner}/{repo}/collaborators/$username/permission" \
        --jq '.permission' 2>/dev/null || echo "none")

    case "$permission" in
        admin|write|maintain)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

#
# Update remote status in state.json
# @param $1 work-id
# @param $2 field name (status, last_check, enabled)
# @param $3 value
#
wf_remote_update_status() {
    local work_id="$1"
    local field="$2"
    local value="$3"

    # Write to per-work state under .remote key
    local work_state_file
    work_state_file=$(_wf_remote_get_work_state_file "$work_id")

    if [ -f "$work_state_file" ]; then
        if [ "$value" = "true" ] || [ "$value" = "false" ]; then
            jq ".remote.$field = $value" "$work_state_file" > "$work_state_file.tmp" && \
                mv "$work_state_file.tmp" "$work_state_file"
        else
            jq ".remote.$field = \"$value\"" "$work_state_file" > "$work_state_file.tmp" && \
                mv "$work_state_file.tmp" "$work_state_file"
        fi
        return 0
    fi

    # Fallback: write to legacy state file
    local state_file
    state_file=$(_wf_remote_get_state_file)

    if [ -f "$state_file" ]; then
        if [ "$value" = "true" ] || [ "$value" = "false" ]; then
            jq ".works[\"$work_id\"].remote.$field = $value" "$state_file" > "$state_file.tmp" && \
                mv "$state_file.tmp" "$state_file"
        else
            jq ".works[\"$work_id\"].remote.$field = \"$value\"" "$state_file" > "$state_file.tmp" && \
                mv "$state_file.tmp" "$state_file"
        fi
    fi
}

#
# Post status to GitHub Issue
# @param $1 Issue number
# @param $2 Status type (progress|success|error|warning|info)
# @param $3 Message
#
wf_remote_post_status() {
    local issue_num="$1"
    local status_type="$2"
    local message="$3"

    local emoji
    case "$status_type" in
        progress) emoji="⏳" ;;
        success) emoji="✅" ;;
        error) emoji="❌" ;;
        warning) emoji="⚠️" ;;
        info) emoji="ℹ️" ;;
        *) emoji="🤖" ;;
    esac

    local body="$emoji $message

---
*Automated message from WF Remote Daemon*"

    if ! gh issue comment "$issue_num" --body "$body" 2>/dev/null; then
        echo "[WARN] Failed to post status to issue #$issue_num" >&2
    fi
}

#
# Post step completion status to GitHub Issue
# @param $1 Issue number
# @param $2 work-id
#
wf_remote_post_step_complete() {
    local issue_num="$1"
    local work_id="$2"

    # Read from per-work state
    local work_state_file
    work_state_file=$(_wf_remote_get_work_state_file "$work_id")

    local current_phase="unknown"
    local next_phase="unknown"

    if [ -f "$work_state_file" ]; then
        current_phase=$(jq -r '.current // "unknown"' "$work_state_file")
        next_phase=$(jq -r '.next // "unknown"' "$work_state_file")
    else
        # Fallback: legacy state file
        local state_file
        state_file=$(_wf_remote_get_state_file)
        if [ -f "$state_file" ]; then
            current_phase=$(jq -r ".works[\"$work_id\"].current // \"unknown\"" "$state_file")
            next_phase=$(jq -r ".works[\"$work_id\"].next // \"unknown\"" "$state_file")
        fi
    fi

    # Get document list
    local doc_dir="docs/wf/$work_id"
    local docs_list=""
    if [ -d "$doc_dir" ]; then
        docs_list=$(ls -1 "$doc_dir" 2>/dev/null | sed 's/^/- /' || echo "- (none)")
    fi

    local body
    body=$(cat << EOF
## 🤖 $current_phase 完了

**ステータス**: 待機中（承認待ち）
**次のステップ**: $next_phase

### 成果物
$docs_list

---
💡 \`/approve\` で次のステップを実行

*Automated message from WF Remote Daemon*
EOF
)

    gh issue comment "$issue_num" --body "$body" 2>/dev/null || true
}

#
# Invoke Claude Code CLI to execute next step
# @param $1 work-id
# @return 0 on success, 1 on failure
#
wf_remote_invoke_claude() {
    local work_id="$1"
    local project_root
    project_root=$(_wf_remote_get_project_root)

    # Change to project directory
    cd "$project_root" || return 1

    # Execute Claude Code with wf0-nextstep
    # Use --print to run non-interactively
    # Capture output to temporary file for success/failure analysis
    local output_file
    output_file=$(mktemp)
    local exit_code=0

    if claude --print "/wf0-nextstep $work_id" > "$output_file" 2>&1; then
        exit_code=0
    else
        exit_code=1
        echo "[ERROR] Claude execution failed. Output:" >&2
        cat "$output_file" >&2
    fi

    rm -f "$output_file"
    return $exit_code
}

#
# Push changes after step execution
# @param $1 work-id
# @return 0 on success, 1 on failure
#
wf_remote_push_changes() {
    local work_id="$1"

    # Read branch from per-work state
    local work_state_file
    work_state_file=$(_wf_remote_get_work_state_file "$work_id")

    local branch=""

    if [ -f "$work_state_file" ]; then
        branch=$(jq -r '.git.branch // empty' "$work_state_file")
    fi

    # Fallback: legacy state file
    if [ -z "$branch" ]; then
        local state_file
        state_file=$(_wf_remote_get_state_file)
        if [ -f "$state_file" ]; then
            branch=$(jq -r ".works[\"$work_id\"].git.branch // empty" "$state_file")
        fi
    fi

    if [ -z "$branch" ]; then
        echo "[ERROR] No branch found for $work_id"
        return 1
    fi

    # Check if on correct branch
    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD)

    if [ "$current_branch" != "$branch" ]; then
        echo "[WARN] Not on expected branch ($branch), currently on $current_branch"
    fi

    # Check for uncommitted changes
    if [ -n "$(git status --porcelain)" ]; then
        echo "[WARN] Uncommitted changes exist, skipping push"
        return 0
    fi

    # Push to remote
    if git push origin "$branch" 2>&1; then
        echo "[INFO] Pushed to origin/$branch"
        return 0
    else
        echo "[ERROR] Failed to push to origin/$branch"
        return 1
    fi
}

#
# Get repository info
# @return Repository in owner/repo format
#
wf_remote_get_repo() {
    gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null
}
