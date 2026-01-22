#!/usr/bin/env bash
#
# Common setup for bats tests
# Source this file from each test file
#

# Test scripts directory
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# scripts/ directory
SCRIPTS_DIR="$(cd "${TESTS_DIR}/../scripts" && pwd)"

# Temporary directory (used during tests)
TEST_TMPDIR=""

#
# Bash version check
# Functions using associative arrays require bash 4+
#
check_bash_version() {
    if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
        skip "bash 4+ required (current: ${BASH_VERSION})"
    fi
}

#
# Setup for all tests
# Called from bats setup_file()
#
common_setup_file() {
    # Requires bash 4+ (for associative arrays)
    if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
        echo "bash 4+ required (current: ${BASH_VERSION})" >&2
        return 1
    fi
}

#
# Setup for each test
# Called from bats setup()
#
common_setup() {
    # Create temporary directory
    TEST_TMPDIR="$(mktemp -d)"

    # Source wf-utils.sh
    # Temporarily disable set -u (for associative array initialization)
    # shellcheck source=../scripts/wf-utils.sh
    set +u
    source "${SCRIPTS_DIR}/wf-utils.sh"
    set -u
}

#
# Helper to run functions that use associative arrays in a subshell
# Associative arrays are not inherited in command substitution,
# so this helper sources the script before execution
# @param $1 Function name
# @param $@ Arguments
#
run_with_arrays() {
    local func="$1"
    shift
    (
        set +u
        source "${SCRIPTS_DIR}/wf-utils.sh"
        set -u
        "$func" "$@"
    )
}

#
# Cleanup for each test
# Called from bats teardown()
#
common_teardown() {
    # Delete temporary directory
    if [[ -n "${TEST_TMPDIR}" && -d "${TEST_TMPDIR}" ]]; then
        rm -rf "${TEST_TMPDIR}"
    fi
}

#
# Create config.json in temporary directory
# @param $1 branch_prefix settings (JSON object format, without braces)
#           Example: '"FEAT": "feature", "FIX": "bugfix"'
# @return Path to created config.json
#
create_test_config() {
    local branch_prefix="${1:-}"
    local config_path="${TEST_TMPDIR}/config.json"

    cat > "${config_path}" << EOF
{
    "branch_prefix": {${branch_prefix}}
}
EOF
    echo "${config_path}"
}
