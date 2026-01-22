#!/usr/bin/env bash
#
# WF Operation System - Utility Functions
# Provides common utilities like slug generation, TYPE detection, etc.
#

set -euo pipefail

# Root directory of dotclaude repository
DOTCLAUDE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# WF configuration directory (in project)
WF_DIR=".wf"

# WF documents directory (in project)
WF_DOCS_DIR="docs/wf"

# Default branch prefix values
declare -A DEFAULT_BRANCH_PREFIX=(
    ["FEAT"]="feat"
    ["FIX"]="fix"
    ["REFACTOR"]="refactor"
    ["CHORE"]="chore"
    ["RFC"]="rfc"
)

# Label to TYPE mapping
declare -A LABEL_TO_TYPE=(
    ["feature"]="FEAT"
    ["enhancement"]="FEAT"
    ["bug"]="FIX"
    ["bugfix"]="FIX"
    ["refactor"]="REFACTOR"
    ["refactoring"]="REFACTOR"
    ["chore"]="CHORE"
    ["maintenance"]="CHORE"
    ["rfc"]="RFC"
    ["discussion"]="RFC"
)

#
# Output error message and exit
# @param $1 Error message
# @param $2 Exit code (default: 1)
#
wf_error() {
    local message="$1"
    local code="${2:-1}"
    echo "[ERROR] $message" >&2
    exit "$code"
}

#
# Output warning message
# @param $1 Warning message
#
wf_warn() {
    local message="$1"
    echo "[WARN] $message" >&2
}

#
# Output info message
# @param $1 Message
#
wf_info() {
    local message="$1"
    echo "[INFO] $message"
}

#
# Output success message
# @param $1 Message
#
wf_success() {
    local message="$1"
    echo "[OK] $message"
}

#
# Generate slug from title string
# - Convert to lowercase
# - Remove characters other than alphanumeric and hyphen
# - Collapse consecutive hyphens to single
# - Remove leading/trailing hyphens
# - Limit to maximum 40 characters
# @param $1 Title string
# @return Slug string
#
wf_generate_slug() {
    local title="$1"

    # Use -E option for both macOS (BSD sed) and Linux (GNU sed) compatibility
    echo "$title" \
        | tr '[:upper:]' '[:lower:]' \
        | sed 's/[^a-z0-9-]/-/g' \
        | sed -E 's/-+/-/g' \
        | sed 's/^-//;s/-$//' \
        | cut -c1-40
}

#
# Detect TYPE from GitHub Issue labels
# @param $1 Labels (comma-separated)
# @return TYPE (FEAT, FIX, REFACTOR, CHORE, RFC)
#
wf_detect_type_from_labels() {
    local labels="$1"

    # Split labels by comma and check
    IFS=',' read -ra label_array <<< "$labels"
    for label in "${label_array[@]}"; do
        # Trim leading/trailing whitespace
        label=$(echo "$label" | xargs)
        label_lower=$(echo "$label" | tr '[:upper:]' '[:lower:]')

        # Temporarily disable set -u for associative array access
        set +u
        local type_value="${LABEL_TO_TYPE[$label_lower]:-}"
        set -u

        if [[ -n "$type_value" ]]; then
            echo "$type_value"
            return 0
        fi
    done

    # Default is FEAT
    echo "FEAT"
}

#
# Get branch prefix from TYPE
# @param $1 TYPE
# @param $2 config.json path (optional)
# @return Branch prefix
#
wf_get_branch_prefix() {
    local type="$1"
    local config_path="${2:-}"

    # Try to get from config.json
    if [[ -n "$config_path" && -f "$config_path" ]]; then
        local prefix
        prefix=$(jq -r ".branch_prefix.${type} // empty" "$config_path" 2>/dev/null)
        if [[ -n "$prefix" ]]; then
            echo "$prefix"
            return 0
        fi
    fi

    # Return default value (temporarily disable set -u for associative array access)
    set +u
    local default_prefix="${DEFAULT_BRANCH_PREFIX[$type]:-feat}"
    set -u
    echo "$default_prefix"
}

#
# Generate work-id
# @param $1 TYPE
# @param $2 Issue number
# @param $3 slug
# @return work-id (e.g., FEAT-123-export-csv)
#
wf_generate_work_id() {
    local type="$1"
    local issue="$2"
    local slug="$3"

    echo "${type}-${issue}-${slug}"
}

#
# Generate branch name from work-id
# @param $1 work-id
# @param $2 config.json path (optional)
# @return Branch name (e.g., feat/123-export-csv)
#
wf_work_id_to_branch() {
    local work_id="$1"
    local config_path="${2:-}"

    # Decompose work-id (TYPE-ISSUE-SLUG)
    local type issue slug
    type=$(echo "$work_id" | cut -d'-' -f1)
    issue=$(echo "$work_id" | cut -d'-' -f2)
    slug=$(echo "$work_id" | cut -d'-' -f3-)

    local prefix
    prefix=$(wf_get_branch_prefix "$type" "$config_path")

    echo "${prefix}/${issue}-${slug}"
}

#
# Generate work-id from branch name
# @param $1 Branch name
# @return work-id
#
wf_branch_to_work_id() {
    local branch="$1"

    # Remove prefix (feat/123-slug → 123-slug)
    local suffix
    suffix=$(echo "$branch" | sed 's|^[^/]*/||')

    # Infer TYPE from prefix
    local prefix type
    prefix=$(echo "$branch" | cut -d'/' -f1)

    case "$prefix" in
        feat) type="FEAT" ;;
        fix) type="FIX" ;;
        refactor) type="REFACTOR" ;;
        chore) type="CHORE" ;;
        rfc) type="RFC" ;;
        *) type="FEAT" ;;
    esac

    echo "${type}-${suffix}"
}

#
# Check if jq is installed
#
wf_require_jq() {
    if ! command -v jq &> /dev/null; then
        wf_error "jq is not installed. Please install with: brew install jq"
    fi
}

#
# Check if gh is installed
#
wf_require_gh() {
    if ! command -v gh &> /dev/null; then
        wf_error "gh (GitHub CLI) is not installed. Please install with: brew install gh"
    fi
}

#
# Check if gh is authenticated
#
wf_require_gh_auth() {
    wf_require_gh
    if ! gh auth status &> /dev/null; then
        wf_error "gh is not authenticated. Please authenticate with: gh auth login"
    fi
}

#
# Check if current directory is a git repository
#
wf_require_git_repo() {
    if ! git rev-parse --git-dir &> /dev/null; then
        wf_error "Current directory is not a git repository."
    fi
}

#
# Get project root
# @return Git repository root path
#
wf_get_project_root() {
    git rev-parse --show-toplevel 2>/dev/null || pwd
}

#
# Get current branch name
# @return Branch name
#
wf_get_current_branch() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null
}

#
# Get current time in ISO8601 format
# @return ISO8601 formatted datetime (e.g., 2026-01-17T10:00:00+09:00)
#
wf_get_timestamp() {
    date +"%Y-%m-%dT%H:%M:%S%z" | sed 's/\([0-9][0-9]\)$/:\1/'
}

#
# Show confirmation prompt
# @param $1 Confirmation message
# @return 0: yes, 1: no
#
wf_confirm() {
    local message="$1"
    local response

    read -r -p "$message [y/N]: " response
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

#
# Check if file exists
# @param $1 File path
# @return 0: exists, 1: does not exist
#
wf_file_exists() {
    [[ -f "$1" ]]
}

#
# Check if directory exists
# @param $1 Directory path
# @return 0: exists, 1: does not exist
#
wf_dir_exists() {
    [[ -d "$1" ]]
}
