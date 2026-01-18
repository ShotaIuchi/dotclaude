#!/usr/bin/env bash
#
# bats テスト用の共通セットアップ
# 各テストファイルから source して使用する
#

# テストスクリプトのディレクトリ
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# scripts/ ディレクトリ
SCRIPTS_DIR="$(cd "${TESTS_DIR}/../scripts" && pwd)"

# 一時ディレクトリ（テスト中に使用）
TEST_TMPDIR=""

#
# bash バージョンチェック
# 連想配列を使う関数は bash 4+ が必要
#
check_bash_version() {
    if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
        skip "bash 4+ が必要です（現在: ${BASH_VERSION}）"
    fi
}

#
# テスト全体のセットアップ
# bats の setup_file() から呼び出す
#
common_setup_file() {
    # bash 4+ が必要（連想配列のため）
    if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
        echo "bash 4+ が必要です（現在: ${BASH_VERSION}）" >&2
        return 1
    fi
}

#
# 各テストのセットアップ
# bats の setup() から呼び出す
#
common_setup() {
    # 一時ディレクトリを作成
    TEST_TMPDIR="$(mktemp -d)"

    # wf-utils.sh を source
    # set -u を一時的に無効化（連想配列の初期化のため）
    # shellcheck source=../scripts/wf-utils.sh
    set +u
    source "${SCRIPTS_DIR}/wf-utils.sh"
    set -u
}

#
# 連想配列を使う関数をサブシェルで実行するヘルパー
# コマンド置換では連想配列が継承されないため、
# このヘルパーで source してから実行する
# @param $1 関数名
# @param $@ 引数
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
# 各テストのクリーンアップ
# bats の teardown() から呼び出す
#
common_teardown() {
    # 一時ディレクトリを削除
    if [[ -n "${TEST_TMPDIR}" && -d "${TEST_TMPDIR}" ]]; then
        rm -rf "${TEST_TMPDIR}"
    fi
}

#
# config.json を一時ディレクトリに作成
# @param $1 branch_prefix の設定（JSON オブジェクト形式、波括弧なし）
#           例: '"FEAT": "feature", "FIX": "bugfix"'
# @return 作成した config.json のパス
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
