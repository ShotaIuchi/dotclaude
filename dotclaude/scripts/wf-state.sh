#!/usr/bin/env bash
#
# WF Operation System - State Management
# Read/write operations for state.json, local.json, config.json
#

set -euo pipefail

# Directory of this script (bash/zsh compatible)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# Load wf-utils.sh
source "${SCRIPT_DIR}/wf-utils.sh"

#
# Read config.json
# @param $1 Project root (optional)
# @return Contents of config.json
#
wf_read_config() {
    local project_root="${1:-$(wf_get_project_root)}"
    local config_path="${project_root}/${WF_DIR}/config.json"

    if wf_file_exists "$config_path"; then
        cat "$config_path"
    else
        # Return default settings
        cat << 'EOF'
{
  "default_base_branch": "main",
  "base_branch_candidates": ["main", "master", "develop"],
  "allow_pattern_candidates": ["release/.*", "hotfix/.*"],
  "branch_prefix": {
    "FEAT": "feat",
    "FIX": "fix",
    "REFACTOR": "refactor",
    "CHORE": "chore",
    "RFC": "rfc"
  },
  "worktree": {
    "enabled": false,
    "root_dir": ".worktrees"
  }
}
EOF
    fi
}

#
# Get value from config.json
# @param $1 jq query (e.g., .default_base_branch)
# @param $2 Project root (optional)
# @return Retrieved value
#
wf_config_get() {
    local query="$1"
    local project_root="${2:-$(wf_get_project_root)}"

    wf_read_config "$project_root" | jq -r "$query // empty"
}

#
# Read state.json
# @param $1 Project root (optional)
# @return Contents of state.json
#
wf_read_state() {
    local project_root="${1:-$(wf_get_project_root)}"
    local state_path="${project_root}/${WF_DIR}/state.json"

    if wf_file_exists "$state_path"; then
        cat "$state_path"
    else
        # Return empty state
        echo '{"active_work": null, "works": {}}'
    fi
}

#
# Write to state.json
# @param $1 JSON data
# @param $2 Project root (optional)
#
wf_write_state() {
    local data="$1"
    local project_root="${2:-$(wf_get_project_root)}"
    local state_path="${project_root}/${WF_DIR}/state.json"

    # Create directory
    mkdir -p "$(dirname "$state_path")"

    # Format and write JSON
    echo "$data" | jq '.' > "$state_path"
}

#
# Get value from state.json
# @param $1 jq query
# @param $2 Project root (optional)
# @return Retrieved value
#
wf_state_get() {
    local query="$1"
    local project_root="${2:-$(wf_get_project_root)}"

    wf_read_state "$project_root" | jq -r "$query // empty"
}

#
# Update value in state.json
# @param $1 jq update expression (e.g., .active_work = "FEAT-123")
# @param $2 Project root (optional)
#
wf_state_set() {
    local update_expr="$1"
    local project_root="${2:-$(wf_get_project_root)}"

    local current_state
    current_state=$(wf_read_state "$project_root")

    local new_state
    new_state=$(echo "$current_state" | jq "$update_expr")

    wf_write_state "$new_state" "$project_root"
}

#
# Get active_work
# @param $1 Project root (optional)
# @return Value of active_work
#
wf_get_active_work() {
    local project_root="${1:-$(wf_get_project_root)}"
    wf_state_get '.active_work' "$project_root"
}

#
# Set active_work
# @param $1 work-id
# @param $2 Project root (optional)
#
wf_set_active_work() {
    local work_id="$1"
    local project_root="${2:-$(wf_get_project_root)}"

    wf_state_set ".active_work = \"${work_id}\"" "$project_root"
}

#
# Get work state
# @param $1 work-id
# @param $2 Project root (optional)
# @return Work state (JSON)
#
wf_get_work() {
    local work_id="$1"
    local project_root="${2:-$(wf_get_project_root)}"

    wf_state_get ".works[\"${work_id}\"]" "$project_root"
}

#
# Set work state
# @param $1 work-id
# @param $2 Work state (JSON)
# @param $3 Project root (optional)
#
wf_set_work() {
    local work_id="$1"
    local work_data="$2"
    local project_root="${3:-$(wf_get_project_root)}"

    wf_state_set ".works[\"${work_id}\"] = ${work_data}" "$project_root"
}

#
# Update specific field of work
# @param $1 work-id
# @param $2 Field path (e.g., .current)
# @param $3 Value
# @param $4 Project root (optional)
#
wf_update_work_field() {
    local work_id="$1"
    local field="$2"
    local value="$3"
    local project_root="${4:-$(wf_get_project_root)}"

    # Wrap value in quotes if it's a string
    if [[ "$value" =~ ^[0-9]+$ ]] || [[ "$value" == "true" ]] || [[ "$value" == "false" ]] || [[ "$value" == "null" ]] || [[ "$value" =~ ^\{.*\}$ ]] || [[ "$value" =~ ^\[.*\]$ ]]; then
        wf_state_set ".works[\"${work_id}\"]${field} = ${value}" "$project_root"
    else
        wf_state_set ".works[\"${work_id}\"]${field} = \"${value}\"" "$project_root"
    fi
}

#
# Get current phase of work
# @param $1 work-id
# @param $2 Project root (optional)
# @return Current phase
#
wf_get_work_current() {
    local work_id="$1"
    local project_root="${2:-$(wf_get_project_root)}"

    wf_state_get ".works[\"${work_id}\"].current" "$project_root"
}

#
# Get next phase of work
# @param $1 work-id
# @param $2 Project root (optional)
# @return Next phase
#
wf_get_work_next() {
    local work_id="$1"
    local project_root="${2:-$(wf_get_project_root)}"

    wf_state_get ".works[\"${work_id}\"].next" "$project_root"
}

#
# Read local.json
# @param $1 Project root (optional)
# @return Contents of local.json
#
wf_read_local() {
    local project_root="${1:-$(wf_get_project_root)}"
    local local_path="${project_root}/${WF_DIR}/local.json"

    if wf_file_exists "$local_path"; then
        cat "$local_path"
    else
        # Return empty state
        echo '{"works": {}}'
    fi
}

#
# Write to local.json
# @param $1 JSON data
# @param $2 Project root (optional)
#
wf_write_local() {
    local data="$1"
    local project_root="${2:-$(wf_get_project_root)}"
    local local_path="${project_root}/${WF_DIR}/local.json"

    # Create directory
    mkdir -p "$(dirname "$local_path")"

    # Format and write JSON
    echo "$data" | jq '.' > "$local_path"
}

#
# Get value from local.json
# @param $1 jq query
# @param $2 Project root (optional)
# @return Retrieved value
#
wf_local_get() {
    local query="$1"
    local project_root="${2:-$(wf_get_project_root)}"

    wf_read_local "$project_root" | jq -r "$query // empty"
}

#
# Update value in local.json
# @param $1 jq update expression
# @param $2 Project root (optional)
#
wf_local_set() {
    local update_expr="$1"
    local project_root="${2:-$(wf_get_project_root)}"

    local current_local
    current_local=$(wf_read_local "$project_root")

    local new_local
    new_local=$(echo "$current_local" | jq "$update_expr")

    wf_write_local "$new_local" "$project_root"
}

#
# Get worktree path
# @param $1 work-id
# @param $2 Project root (optional)
# @return Worktree path
#
wf_get_worktree_path() {
    local work_id="$1"
    local project_root="${2:-$(wf_get_project_root)}"

    wf_local_get ".works[\"${work_id}\"].worktree_path" "$project_root"
}

#
# Set worktree path
# @param $1 work-id
# @param $2 Worktree path
# @param $3 Project root (optional)
#
wf_set_worktree_path() {
    local work_id="$1"
    local worktree_path="$2"
    local project_root="${3:-$(wf_get_project_root)}"

    wf_local_set ".works[\"${work_id}\"].worktree_path = \"${worktree_path}\"" "$project_root"
}

#
# Get all work-ids
# @param $1 Project root (optional)
# @return List of work-ids (newline-separated)
#
wf_list_works() {
    local project_root="${1:-$(wf_get_project_root)}"

    wf_read_state "$project_root" | jq -r '.works | keys[]' 2>/dev/null
}

#
# Create new work
# @param $1 work-id
# @param $2 Base branch
# @param $3 Feature branch
# @param $4 Project root (optional)
#
wf_create_work() {
    local work_id="$1"
    local base_branch="$2"
    local feature_branch="$3"
    local project_root="${4:-$(wf_get_project_root)}"

    local timestamp
    timestamp=$(wf_get_timestamp)

    local work_data
    work_data=$(cat << EOF
{
  "current": "wf1-kickoff",
  "next": "wf2-spec",
  "git": {
    "base": "${base_branch}",
    "branch": "${feature_branch}"
  },
  "kickoff": {
    "revision": 0,
    "last_updated": null
  },
  "created_at": "${timestamp}"
}
EOF
)

    wf_set_work "$work_id" "$work_data" "$project_root"
    wf_set_active_work "$work_id" "$project_root"
}

#
# Advance work phase
# @param $1 work-id
# @param $2 New current phase
# @param $3 New next phase
# @param $4 Project root (optional)
#
wf_advance_phase() {
    local work_id="$1"
    local new_current="$2"
    local new_next="$3"
    local project_root="${4:-$(wf_get_project_root)}"

    wf_update_work_field "$work_id" ".current" "$new_current" "$project_root"
    wf_update_work_field "$work_id" ".next" "$new_next" "$project_root"
}

# ==============================================================================
# Agent Management Functions
# ==============================================================================

#
# Record agent session
# @param $1 work-id
# @param $2 Agent name
# @param $3 Status (running | completed | failed)
# @param $4 Project root (optional)
#
wf_record_agent_session() {
    local work_id="$1"
    local agent_name="$2"
    local status="$3"
    local project_root="${4:-$(wf_get_project_root)}"

    local timestamp
    timestamp=$(wf_get_timestamp)

    # Initialize agents object if it doesn't exist
    local current_state
    current_state=$(wf_read_state "$project_root")

    local has_agents
    has_agents=$(echo "$current_state" | jq -r ".works[\"${work_id}\"].agents // empty")

    if [ -z "$has_agents" ]; then
        wf_state_set ".works[\"${work_id}\"].agents = {\"last_used\": null, \"sessions\": {}}" "$project_root"
    fi

    # Update last_used
    wf_state_set ".works[\"${work_id}\"].agents.last_used = \"${agent_name}\"" "$project_root"

    # Update session info
    local session_data
    session_data=$(cat << EOF
{"status": "${status}", "last_run": "${timestamp}"}
EOF
)
    wf_state_set ".works[\"${work_id}\"].agents.sessions[\"${agent_name}\"] = ${session_data}" "$project_root"
}

#
# Get agent session status
# @param $1 work-id
# @param $2 Agent name
# @param $3 Project root (optional)
# @return Status
#
wf_get_agent_status() {
    local work_id="$1"
    local agent_name="$2"
    local project_root="${3:-$(wf_get_project_root)}"

    wf_state_get ".works[\"${work_id}\"].agents.sessions[\"${agent_name}\"].status" "$project_root"
}

#
# Get last used agent
# @param $1 work-id
# @param $2 Project root (optional)
# @return Agent name
#
wf_get_last_agent() {
    local work_id="$1"
    local project_root="${2:-$(wf_get_project_root)}"

    wf_state_get ".works[\"${work_id}\"].agents.last_used" "$project_root"
}

#
# List agent sessions
# @param $1 work-id
# @param $2 Project root (optional)
# @return Session list (JSON)
#
wf_list_agent_sessions() {
    local work_id="$1"
    local project_root="${2:-$(wf_get_project_root)}"

    wf_read_state "$project_root" | jq ".works[\"${work_id}\"].agents.sessions // {}"
}
