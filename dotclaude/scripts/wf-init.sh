#!/usr/bin/env bash
#
# WF Operation System - Project Initialization
# Creates .wf/ and docs/wf/ directory structure
#

set -euo pipefail

# Directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load wf-utils.sh and wf-state.sh
source "${SCRIPT_DIR}/wf-utils.sh"
source "${SCRIPT_DIR}/wf-state.sh"

#
# Initialize WF system in a project
# @param $1 Project root (optional)
#
wf_init_project() {
    local project_root="${1:-$(wf_get_project_root)}"

    wf_require_jq
    wf_require_git_repo

    wf_info "Initializing WF system: ${project_root}"

    # Create .wf/ directory
    local wf_path="${project_root}/${WF_DIR}"
    if wf_dir_exists "$wf_path"; then
        wf_warn ".wf/ directory already exists"
    else
        mkdir -p "$wf_path"
        wf_info "Created .wf/ directory"
    fi

    # Create docs/wf/ directory
    local docs_path="${project_root}/${WF_DOCS_DIR}"
    if wf_dir_exists "$docs_path"; then
        wf_warn "docs/wf/ directory already exists"
    else
        mkdir -p "$docs_path"
        wf_info "Created docs/wf/ directory"
    fi

    # Create config.json (if not exists)
    local config_path="${wf_path}/config.json"
    if wf_file_exists "$config_path"; then
        wf_warn "config.json already exists"
    else
        wf_create_default_config "$project_root"
        wf_info "Created config.json"
    fi

    # Create state.json (if not exists)
    local state_path="${wf_path}/state.json"
    if wf_file_exists "$state_path"; then
        wf_warn "state.json already exists"
    else
        wf_write_state '{"active_work": null, "works": {}}' "$project_root"
        wf_info "Created state.json"
    fi

    # Add local.json to .gitignore
    wf_update_gitignore "$project_root"

    wf_success "WF system initialization complete"
}

#
# Create default config.json
# @param $1 Project root
#
wf_create_default_config() {
    local project_root="$1"
    local config_path="${project_root}/${WF_DIR}/config.json"

    # Detect default branch
    local default_branch
    default_branch=$(wf_detect_default_branch "$project_root")

    cat << EOF > "$config_path"
{
  "default_base_branch": "${default_branch}",
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
}

#
# Detect default branch
# @param $1 Project root
# @return Default branch name
#
wf_detect_default_branch() {
    local project_root="$1"

    cd "$project_root" || return 1

    # Check remote HEAD
    local remote_head
    remote_head=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|^refs/remotes/origin/||' || true)

    if [[ -n "$remote_head" ]]; then
        echo "$remote_head"
        return 0
    fi

    # Check candidate branches
    for branch in main master develop; do
        if git show-ref --verify --quiet "refs/heads/${branch}" 2>/dev/null || \
           git show-ref --verify --quiet "refs/remotes/origin/${branch}" 2>/dev/null; then
            echo "$branch"
            return 0
        fi
    done

    # Default to main if not found
    echo "main"
}

#
# Update .gitignore to exclude local.json
# @param $1 Project root
#
wf_update_gitignore() {
    local project_root="$1"
    local gitignore_path="${project_root}/.gitignore"
    local entry=".wf/local.json"

    # Create .gitignore if it doesn't exist
    if ! wf_file_exists "$gitignore_path"; then
        echo "$entry" > "$gitignore_path"
        wf_info "Created .gitignore and added ${entry}"
        return 0
    fi

    # Check if already included
    if grep -qF "$entry" "$gitignore_path" 2>/dev/null; then
        wf_info ".gitignore already contains ${entry}"
        return 0
    fi

    # Add entry
    echo "" >> "$gitignore_path"
    echo "# WF local settings" >> "$gitignore_path"
    echo "$entry" >> "$gitignore_path"
    wf_info "Added ${entry} to .gitignore"
}

#
# Create document directory for work
# @param $1 work-id
# @param $2 Project root (optional)
# @return Created directory path
#
wf_create_work_docs_dir() {
    local work_id="$1"
    local project_root="${2:-$(wf_get_project_root)}"

    local docs_dir="${project_root}/${WF_DOCS_DIR}/${work_id}"

    if wf_dir_exists "$docs_dir"; then
        wf_warn "Document directory already exists: ${docs_dir}"
    else
        mkdir -p "$docs_dir"
        wf_info "Created document directory: ${docs_dir}"
    fi

    echo "$docs_dir"
}

#
# Create worktree
# @param $1 work-id
# @param $2 Branch name
# @param $3 Project root (optional)
# @return Worktree path
#
wf_create_worktree() {
    local work_id="$1"
    local branch="$2"
    local project_root="${3:-$(wf_get_project_root)}"

    # Check if worktree is enabled
    local worktree_enabled
    worktree_enabled=$(wf_config_get '.worktree.enabled' "$project_root")

    if [[ "$worktree_enabled" != "true" ]]; then
        wf_info "worktree is disabled"
        return 0
    fi

    local worktree_root
    worktree_root=$(wf_config_get '.worktree.root_dir' "$project_root")
    worktree_root="${worktree_root:-.worktrees}"

    # Generate directory name from branch name (replace / with -)
    local dir_name
    dir_name=$(echo "$branch" | tr '/' '-')

    local worktree_path="${project_root}/${worktree_root}/${dir_name}"

    # Skip if already exists
    if wf_dir_exists "$worktree_path"; then
        wf_warn "worktree already exists: ${worktree_path}"
        echo "$worktree_path"
        return 0
    fi

    # Create worktree root directory
    mkdir -p "${project_root}/${worktree_root}"

    # Create worktree
    cd "$project_root" || return 1
    git worktree add "$worktree_path" "$branch" 2>/dev/null || {
        # Create new branch if it doesn't exist
        git worktree add -b "$branch" "$worktree_path" 2>/dev/null || {
            wf_error "Failed to create worktree: ${worktree_path}"
        }
    }

    wf_info "Created worktree: ${worktree_path}"
    echo "$worktree_path"
}

#
# Remove worktree
# @param $1 Worktree path
# @param $2 Project root (optional)
#
wf_remove_worktree() {
    local worktree_path="$1"
    local project_root="${2:-$(wf_get_project_root)}"

    if ! wf_dir_exists "$worktree_path"; then
        wf_warn "worktree does not exist: ${worktree_path}"
        return 0
    fi

    cd "$project_root" || return 1
    git worktree remove "$worktree_path" --force 2>/dev/null || {
        wf_warn "Failed to remove worktree: ${worktree_path}"
    }

    wf_info "Removed worktree: ${worktree_path}"
}

# Main processing (when executed directly)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-init}" in
        init)
            wf_init_project "${2:-}"
            ;;
        *)
            echo "Usage: $0 [init] [project_root]"
            exit 1
            ;;
    esac
fi
