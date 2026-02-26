#!/usr/bin/env bash
#
# WF Operation System - State Management
# Read/write operations for state.json, local.json, config.json
#
# State isolation: per-work state lives in docs/wf/<work-id>/state.json
# Global index: .wf/state.json is minimal {} (backward compat)
# Local state: .wf/local.json holds active_work + worktree paths (gitignored)
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

# ==============================================================================
# Global state.json (minimal index, kept for backward compat)
# ==============================================================================

#
# Read state.json (global index - minimal {})
# @param $1 Project root (optional)
# @return Contents of state.json
#
wf_read_state() {
    local project_root="${1:-$(wf_get_project_root)}"
    local state_path="${project_root}/${WF_DIR}/state.json"

    if wf_file_exists "$state_path"; then
        cat "$state_path"
    else
        echo '{}'
    fi
}

#
# Write to state.json (global index)
# @param $1 JSON data
# @param $2 Project root (optional)
#
wf_write_state() {
    local data="$1"
    local project_root="${2:-$(wf_get_project_root)}"
    local state_path="${project_root}/${WF_DIR}/state.json"

    mkdir -p "$(dirname "$state_path")"
    echo "$data" | jq '.' > "$state_path"
}

#
# Get value from state.json (global)
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
# Update value in state.json (global)
# @param $1 jq update expression
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

# ==============================================================================
# Per-work state (docs/wf/<work-id>/state.json)
# ==============================================================================

#
# Get per-work state file path
# @param $1 work-id
# @param $2 Project root (optional)
# @return Path to docs/wf/<work-id>/state.json
#
wf_get_work_state_path() {
    local work_id="$1"
    local project_root="${2:-$(wf_get_project_root)}"

    echo "${project_root}/${WF_DOCS_DIR}/${work_id}/state.json"
}

#
# Read per-work state
# @param $1 work-id
# @param $2 Project root (optional)
# @return Per-work state JSON
#
_wf_read_work_state() {
    local work_id="$1"
    local project_root="${2:-$(wf_get_project_root)}"

    local work_state_path
    work_state_path=$(wf_get_work_state_path "$work_id" "$project_root")

    if wf_file_exists "$work_state_path"; then
        cat "$work_state_path"
        return 0
    fi

    # Fallback: read from old .wf/state.json format
    local old_state_path="${project_root}/${WF_DIR}/state.json"
    if wf_file_exists "$old_state_path"; then
        local old_data
        old_data=$(jq -r ".works[\"${work_id}\"] // empty" "$old_state_path" 2>/dev/null)
        if [ -n "$old_data" ]; then
            echo "$old_data"
            return 0
        fi
    fi

    echo ""
}

#
# Write per-work state
# @param $1 work-id
# @param $2 Work state JSON
# @param $3 Project root (optional)
#
_wf_write_work_state() {
    local work_id="$1"
    local work_data="$2"
    local project_root="${3:-$(wf_get_project_root)}"

    local work_state_path
    work_state_path=$(wf_get_work_state_path "$work_id" "$project_root")

    mkdir -p "$(dirname "$work_state_path")"
    echo "$work_data" | jq '.' > "$work_state_path"
}

# ==============================================================================
# active_work (stored in local.json)
# ==============================================================================

#
# Get active_work
# @param $1 Project root (optional)
# @return Value of active_work
#
wf_get_active_work() {
    local project_root="${1:-$(wf_get_project_root)}"
    wf_local_get '.active_work' "$project_root"
}

#
# Set active_work
# @param $1 work-id
# @param $2 Project root (optional)
#
wf_set_active_work() {
    local work_id="$1"
    local project_root="${2:-$(wf_get_project_root)}"

    wf_local_set ".active_work = \"${work_id}\"" "$project_root"
}

# ==============================================================================
# Per-work accessors
# ==============================================================================

#
# Get work state
# @param $1 work-id
# @param $2 Project root (optional)
# @return Work state (JSON)
#
wf_get_work() {
    local work_id="$1"
    local project_root="${2:-$(wf_get_project_root)}"

    _wf_read_work_state "$work_id" "$project_root"
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

    _wf_write_work_state "$work_id" "$work_data" "$project_root"
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

    local current_data
    current_data=$(_wf_read_work_state "$work_id" "$project_root")

    if [ -z "$current_data" ]; then
        current_data='{}'
    fi

    local new_data
    # Wrap value in quotes if it's a string
    if [[ "$value" =~ ^[0-9]+$ ]] || [[ "$value" == "true" ]] || [[ "$value" == "false" ]] || [[ "$value" == "null" ]] || [[ "$value" =~ ^\{.*\}$ ]] || [[ "$value" =~ ^\[.*\]$ ]]; then
        new_data=$(echo "$current_data" | jq "${field} = ${value}")
    else
        new_data=$(echo "$current_data" | jq "${field} = \"${value}\"")
    fi

    _wf_write_work_state "$work_id" "$new_data" "$project_root"
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

    local work_data
    work_data=$(_wf_read_work_state "$work_id" "$project_root")

    if [ -n "$work_data" ]; then
        echo "$work_data" | jq -r '.current // empty'
    fi
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

    local work_data
    work_data=$(_wf_read_work_state "$work_id" "$project_root")

    if [ -n "$work_data" ]; then
        echo "$work_data" | jq -r '.next // empty'
    fi
}

# ==============================================================================
# local.json (gitignored, active_work + worktree paths)
# ==============================================================================

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
        # Return empty state with active_work
        echo '{"active_work": null, "works": {}}'
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

    mkdir -p "$(dirname "$local_path")"
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

# ==============================================================================
# Work listing and creation
# ==============================================================================

#
# Get all work-ids
# @param $1 Project root (optional)
# @return List of work-ids (newline-separated)
#
wf_list_works() {
    local project_root="${1:-$(wf_get_project_root)}"

    local docs_dir="${project_root}/${WF_DOCS_DIR}"
    local found_ids=""

    # Scan docs/wf/*/state.json
    if wf_dir_exists "$docs_dir"; then
        for state_file in "$docs_dir"/*/state.json; do
            if [ -f "$state_file" ]; then
                local dir_name
                dir_name=$(basename "$(dirname "$state_file")")
                if [ -n "$found_ids" ]; then
                    found_ids="${found_ids}"$'\n'"${dir_name}"
                else
                    found_ids="${dir_name}"
                fi
            fi
        done
    fi

    # Fallback: also check old .wf/state.json for works not yet migrated
    local old_state_path="${project_root}/${WF_DIR}/state.json"
    if wf_file_exists "$old_state_path"; then
        local old_works
        old_works=$(jq -r '.works // {} | keys[]' "$old_state_path" 2>/dev/null || true)
        if [ -n "$old_works" ]; then
            while IFS= read -r old_id; do
                # Only add if not already found in docs/wf/
                if ! echo "$found_ids" | grep -qF "$old_id" 2>/dev/null; then
                    if [ -n "$found_ids" ]; then
                        found_ids="${found_ids}"$'\n'"${old_id}"
                    else
                        found_ids="${old_id}"
                    fi
                fi
            done <<< "$old_works"
        fi
    fi

    echo "$found_ids"
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

    # Ensure docs/wf/<work-id>/ directory exists
    local work_docs_dir="${project_root}/${WF_DOCS_DIR}/${work_id}"
    mkdir -p "$work_docs_dir"

    # Write per-work state
    _wf_write_work_state "$work_id" "$work_data" "$project_root"

    # Set active work in local.json
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

    local current_data
    current_data=$(_wf_read_work_state "$work_id" "$project_root")

    if [ -z "$current_data" ]; then
        current_data='{}'
    fi

    # Initialize agents object if it doesn't exist
    local has_agents
    has_agents=$(echo "$current_data" | jq -r '.agents // empty')

    if [ -z "$has_agents" ]; then
        current_data=$(echo "$current_data" | jq '.agents = {"last_used": null, "sessions": {}}')
    fi

    # Update last_used and session info
    local session_data="{\"status\": \"${status}\", \"last_run\": \"${timestamp}\"}"
    current_data=$(echo "$current_data" | jq \
        --arg agent "$agent_name" \
        --argjson session "$session_data" \
        '.agents.last_used = $agent | .agents.sessions[$agent] = $session')

    _wf_write_work_state "$work_id" "$current_data" "$project_root"
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

    local work_data
    work_data=$(_wf_read_work_state "$work_id" "$project_root")

    if [ -n "$work_data" ]; then
        echo "$work_data" | jq -r ".agents.sessions[\"${agent_name}\"].status // empty"
    fi
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

    local work_data
    work_data=$(_wf_read_work_state "$work_id" "$project_root")

    if [ -n "$work_data" ]; then
        echo "$work_data" | jq -r '.agents.last_used // empty'
    fi
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

    local work_data
    work_data=$(_wf_read_work_state "$work_id" "$project_root")

    if [ -n "$work_data" ]; then
        echo "$work_data" | jq '.agents.sessions // {}'
    else
        echo '{}'
    fi
}

# ==============================================================================
# Migration
# ==============================================================================

#
# Migrate old .wf/state.json format to per-work state files
# @param $1 Project root (optional)
#
wf_migrate_state() {
    local project_root="${1:-$(wf_get_project_root)}"
    local old_state_path="${project_root}/${WF_DIR}/state.json"

    if ! wf_file_exists "$old_state_path"; then
        return 0
    fi

    local old_state
    old_state=$(cat "$old_state_path")

    # Check if old format (has .works and .active_work)
    local has_works
    has_works=$(echo "$old_state" | jq -r '.works // empty' 2>/dev/null)

    if [ -z "$has_works" ] || [ "$has_works" = "{}" ]; then
        return 0
    fi

    wf_info "Migrating old state.json to per-work state files..."

    # Migrate active_work to local.json
    local active_work
    active_work=$(echo "$old_state" | jq -r '.active_work // empty')

    if [ -n "$active_work" ]; then
        wf_set_active_work "$active_work" "$project_root"
        wf_info "Migrated active_work to local.json: ${active_work}"
    fi

    # Migrate each work to docs/wf/<work-id>/state.json
    local work_ids
    work_ids=$(echo "$old_state" | jq -r '.works | keys[]' 2>/dev/null || true)

    if [ -n "$work_ids" ]; then
        while IFS= read -r work_id; do
            local work_state_path
            work_state_path=$(wf_get_work_state_path "$work_id" "$project_root")

            # Only migrate if per-work file doesn't exist yet
            if ! wf_file_exists "$work_state_path"; then
                local work_data
                work_data=$(echo "$old_state" | jq ".works[\"${work_id}\"]")

                _wf_write_work_state "$work_id" "$work_data" "$project_root"
                wf_info "Migrated work: ${work_id}"
            fi
        done <<< "$work_ids"
    fi

    # Overwrite old state.json with minimal format
    wf_write_state '{}' "$project_root"
    wf_info "Cleaned old state.json to minimal format"
}
