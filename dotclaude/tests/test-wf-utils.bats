#!/usr/bin/env bats
#
# wf-utils.sh のユニットテスト
# bash 4+ が必要（連想配列を使用するため）
#

# setup.bash を読み込み
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
# wf_generate_slug() のテスト
# =============================================================================

@test "wf_generate_slug: 基本的な英語タイトル" {
    result=$(wf_generate_slug "Add Export CSV Feature")
    [[ "$result" == "add-export-csv-feature" ]]
}

@test "wf_generate_slug: 大文字を小文字に変換" {
    result=$(wf_generate_slug "UPPERCASE TITLE")
    [[ "$result" == "uppercase-title" ]]
}

@test "wf_generate_slug: 特殊文字を除去" {
    result=$(wf_generate_slug "Fix: user's login (bug #123)")
    [[ "$result" == "fix-user-s-login-bug-123" ]]
}

@test "wf_generate_slug: 連続ハイフンを単一に" {
    result=$(wf_generate_slug "hello---world")
    [[ "$result" == "hello-world" ]]
}

@test "wf_generate_slug: 先頭・末尾のハイフンを除去" {
    result=$(wf_generate_slug "---hello world---")
    [[ "$result" == "hello-world" ]]
}

@test "wf_generate_slug: 40文字を超える場合は切り詰め" {
    # 50文字のタイトル
    result=$(wf_generate_slug "this is a very long title that exceeds forty chars")
    [[ ${#result} -le 40 ]]
    [[ "$result" == "this-is-a-very-long-title-that-exceeds-f" ]]
}

# =============================================================================
# wf_detect_type_from_labels() のテスト
# bash 4+ の連想配列が必要
# =============================================================================

@test "wf_detect_type_from_labels: feature ラベル" {
    check_bash_version
    result=$(run_with_arrays wf_detect_type_from_labels "feature")
    [[ "$result" == "FEAT" ]]
}

@test "wf_detect_type_from_labels: bug ラベル" {
    check_bash_version
    result=$(run_with_arrays wf_detect_type_from_labels "bug")
    [[ "$result" == "FIX" ]]
}

@test "wf_detect_type_from_labels: 複数ラベル（最初にマッチ）" {
    check_bash_version
    result=$(run_with_arrays wf_detect_type_from_labels "documentation, bug, enhancement")
    [[ "$result" == "FIX" ]]
}

@test "wf_detect_type_from_labels: 大文字小文字を無視" {
    check_bash_version
    result=$(run_with_arrays wf_detect_type_from_labels "BUG")
    [[ "$result" == "FIX" ]]
}

@test "wf_detect_type_from_labels: 未知のラベルはFEAT" {
    check_bash_version
    result=$(run_with_arrays wf_detect_type_from_labels "unknown-label")
    [[ "$result" == "FEAT" ]]
}

# =============================================================================
# wf_generate_work_id() のテスト
# =============================================================================

@test "wf_generate_work_id: 基本的な生成" {
    result=$(wf_generate_work_id "FEAT" "123" "add-feature")
    [[ "$result" == "FEAT-123-add-feature" ]]
}

@test "wf_generate_work_id: FIX タイプ" {
    result=$(wf_generate_work_id "FIX" "456" "fix-bug")
    [[ "$result" == "FIX-456-fix-bug" ]]
}

# =============================================================================
# wf_work_id_to_branch() のテスト
# bash 4+ の連想配列が必要
# =============================================================================

@test "wf_work_id_to_branch: FEAT タイプ" {
    check_bash_version
    result=$(run_with_arrays wf_work_id_to_branch "FEAT-123-add-export")
    [[ "$result" == "feat/123-add-export" ]]
}

@test "wf_work_id_to_branch: FIX タイプ" {
    check_bash_version
    result=$(run_with_arrays wf_work_id_to_branch "FIX-456-fix-login")
    [[ "$result" == "fix/456-fix-login" ]]
}

@test "wf_work_id_to_branch: カスタム config 使用" {
    check_bash_version
    local config_path
    config_path=$(create_test_config '"FEAT": "feature"')
    result=$(run_with_arrays wf_work_id_to_branch "FEAT-123-add-export" "$config_path")
    [[ "$result" == "feature/123-add-export" ]]
}

# =============================================================================
# wf_branch_to_work_id() のテスト
# =============================================================================

@test "wf_branch_to_work_id: feat ブランチ" {
    result=$(wf_branch_to_work_id "feat/123-add-export")
    [[ "$result" == "FEAT-123-add-export" ]]
}

@test "wf_branch_to_work_id: fix ブランチ" {
    result=$(wf_branch_to_work_id "fix/456-fix-login")
    [[ "$result" == "FIX-456-fix-login" ]]
}

@test "wf_branch_to_work_id: refactor ブランチ" {
    result=$(wf_branch_to_work_id "refactor/789-cleanup")
    [[ "$result" == "REFACTOR-789-cleanup" ]]
}

@test "wf_branch_to_work_id: 未知のプレフィックスはFEAT" {
    result=$(wf_branch_to_work_id "unknown/999-something")
    [[ "$result" == "FEAT-999-something" ]]
}

# =============================================================================
# wf_get_branch_prefix() のテスト
# bash 4+ の連想配列が必要
# =============================================================================

@test "wf_get_branch_prefix: デフォルト値 FEAT" {
    check_bash_version
    result=$(run_with_arrays wf_get_branch_prefix "FEAT")
    [[ "$result" == "feat" ]]
}

@test "wf_get_branch_prefix: デフォルト値 FIX" {
    check_bash_version
    result=$(run_with_arrays wf_get_branch_prefix "FIX")
    [[ "$result" == "fix" ]]
}

@test "wf_get_branch_prefix: config.json からカスタム値" {
    check_bash_version
    local config_path
    config_path=$(create_test_config '"FEAT": "feature", "FIX": "bugfix"')
    result=$(run_with_arrays wf_get_branch_prefix "FEAT" "$config_path")
    [[ "$result" == "feature" ]]
}
