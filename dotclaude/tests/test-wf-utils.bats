#!/usr/bin/env bats
#
# Unit tests for wf-utils.sh
# Requires bash 4+ (for associative arrays)
#

# Load setup.bash
load 'setup.bash'

setup_file() {
    common_setup_file
}

setup() {
    common_setup
}

teardown() {
    common_teardown
}

# =============================================================================
# Tests for wf_generate_slug()
# =============================================================================

@test "wf_generate_slug: basic English title" {
    result=$(wf_generate_slug "Add Export CSV Feature")
    [[ "$result" == "add-export-csv-feature" ]]
}

@test "wf_generate_slug: converts uppercase to lowercase" {
    result=$(wf_generate_slug "UPPERCASE TITLE")
    [[ "$result" == "uppercase-title" ]]
}

@test "wf_generate_slug: removes special characters" {
    result=$(wf_generate_slug "Fix: user's login (bug #123)")
    [[ "$result" == "fix-user-s-login-bug-123" ]]
}

@test "wf_generate_slug: collapses consecutive hyphens to single" {
    result=$(wf_generate_slug "hello---world")
    [[ "$result" == "hello-world" ]]
}

@test "wf_generate_slug: removes leading and trailing hyphens" {
    result=$(wf_generate_slug "---hello world---")
    [[ "$result" == "hello-world" ]]
}

@test "wf_generate_slug: truncates if exceeds 40 characters" {
    # 50-character title
    result=$(wf_generate_slug "this is a very long title that exceeds forty chars")
    [[ ${#result} -le 40 ]]
    [[ "$result" == "this-is-a-very-long-title-that-exceeds-f" ]]
}

# =============================================================================
# Tests for wf_detect_type_from_labels()
# Requires bash 4+ associative arrays
# =============================================================================

@test "wf_detect_type_from_labels: feature label" {
    check_bash_version
    result=$(run_with_arrays wf_detect_type_from_labels "feature")
    [[ "$result" == "FEAT" ]]
}

@test "wf_detect_type_from_labels: bug label" {
    check_bash_version
    result=$(run_with_arrays wf_detect_type_from_labels "bug")
    [[ "$result" == "FIX" ]]
}

@test "wf_detect_type_from_labels: multiple labels (first match)" {
    check_bash_version
    result=$(run_with_arrays wf_detect_type_from_labels "documentation, bug, enhancement")
    [[ "$result" == "FIX" ]]
}

@test "wf_detect_type_from_labels: case insensitive" {
    check_bash_version
    result=$(run_with_arrays wf_detect_type_from_labels "BUG")
    [[ "$result" == "FIX" ]]
}

@test "wf_detect_type_from_labels: unknown label defaults to FEAT" {
    check_bash_version
    result=$(run_with_arrays wf_detect_type_from_labels "unknown-label")
    [[ "$result" == "FEAT" ]]
}

# =============================================================================
# Tests for wf_generate_work_id()
# =============================================================================

@test "wf_generate_work_id: basic generation" {
    result=$(wf_generate_work_id "FEAT" "123" "add-feature")
    [[ "$result" == "FEAT-123-add-feature" ]]
}

@test "wf_generate_work_id: FIX type" {
    result=$(wf_generate_work_id "FIX" "456" "fix-bug")
    [[ "$result" == "FIX-456-fix-bug" ]]
}

# =============================================================================
# Tests for wf_work_id_to_branch()
# Requires bash 4+ associative arrays
# =============================================================================

@test "wf_work_id_to_branch: FEAT type" {
    check_bash_version
    result=$(run_with_arrays wf_work_id_to_branch "FEAT-123-add-export")
    [[ "$result" == "feat/123-add-export" ]]
}

@test "wf_work_id_to_branch: FIX type" {
    check_bash_version
    result=$(run_with_arrays wf_work_id_to_branch "FIX-456-fix-login")
    [[ "$result" == "fix/456-fix-login" ]]
}

@test "wf_work_id_to_branch: uses custom config" {
    check_bash_version
    local config_path
    config_path=$(create_test_config '"FEAT": "feature"')
    result=$(run_with_arrays wf_work_id_to_branch "FEAT-123-add-export" "$config_path")
    [[ "$result" == "feature/123-add-export" ]]
}

# =============================================================================
# Tests for wf_branch_to_work_id()
# =============================================================================

@test "wf_branch_to_work_id: feat branch" {
    result=$(wf_branch_to_work_id "feat/123-add-export")
    [[ "$result" == "FEAT-123-add-export" ]]
}

@test "wf_branch_to_work_id: fix branch" {
    result=$(wf_branch_to_work_id "fix/456-fix-login")
    [[ "$result" == "FIX-456-fix-login" ]]
}

@test "wf_branch_to_work_id: refactor branch" {
    result=$(wf_branch_to_work_id "refactor/789-cleanup")
    [[ "$result" == "REFACTOR-789-cleanup" ]]
}

@test "wf_branch_to_work_id: unknown prefix defaults to FEAT" {
    result=$(wf_branch_to_work_id "unknown/999-something")
    [[ "$result" == "FEAT-999-something" ]]
}

# =============================================================================
# Tests for wf_get_branch_prefix()
# Requires bash 4+ associative arrays
# =============================================================================

@test "wf_get_branch_prefix: default value FEAT" {
    check_bash_version
    result=$(run_with_arrays wf_get_branch_prefix "FEAT")
    [[ "$result" == "feat" ]]
}

@test "wf_get_branch_prefix: default value FIX" {
    check_bash_version
    result=$(run_with_arrays wf_get_branch_prefix "FIX")
    [[ "$result" == "fix" ]]
}

@test "wf_get_branch_prefix: custom value from config.json" {
    check_bash_version
    local config_path
    config_path=$(create_test_config '"FEAT": "feature", "FIX": "bugfix"')
    result=$(run_with_arrays wf_get_branch_prefix "FEAT" "$config_path")
    [[ "$result" == "feature" ]]
}
