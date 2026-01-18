#!/usr/bin/env bash
#
# WF運用システム - ユーティリティ関数
# slug生成、TYPE判定など共通処理を提供
#

set -euo pipefail

# dotclaude リポジトリのルートディレクトリ
DOTCLAUDE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# WF 設定ディレクトリ（プロジェクト内）
WF_DIR=".wf"

# WF ドキュメントディレクトリ（プロジェクト内）
WF_DOCS_DIR="docs/wf"

# ブランチプレフィックスのデフォルト値
declare -A DEFAULT_BRANCH_PREFIX=(
    ["FEAT"]="feat"
    ["FIX"]="fix"
    ["REFACTOR"]="refactor"
    ["CHORE"]="chore"
    ["RFC"]="rfc"
)

# TYPE を判定するラベル対応
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
# エラーメッセージを出力して終了
# @param $1 エラーメッセージ
# @param $2 終了コード（デフォルト: 1）
#
wf_error() {
    local message="$1"
    local code="${2:-1}"
    echo "[ERROR] $message" >&2
    exit "$code"
}

#
# 警告メッセージを出力
# @param $1 警告メッセージ
#
wf_warn() {
    local message="$1"
    echo "[WARN] $message" >&2
}

#
# 情報メッセージを出力
# @param $1 メッセージ
#
wf_info() {
    local message="$1"
    echo "[INFO] $message"
}

#
# 成功メッセージを出力
# @param $1 メッセージ
#
wf_success() {
    local message="$1"
    echo "[OK] $message"
}

#
# タイトル文字列からslugを生成
# - 小文字に変換
# - 英数字とハイフン以外を除去
# - 連続ハイフンを単一に
# - 先頭・末尾のハイフンを除去
# - 最大40文字に制限
# @param $1 タイトル文字列
# @return slug文字列
#
wf_generate_slug() {
    local title="$1"

    # macOS (BSD sed) と Linux (GNU sed) 両対応のため -E オプションを使用
    echo "$title" \
        | tr '[:upper:]' '[:lower:]' \
        | sed 's/[^a-z0-9-]/-/g' \
        | sed -E 's/-+/-/g' \
        | sed 's/^-//;s/-$//' \
        | cut -c1-40
}

#
# GitHub Issue のラベルから TYPE を判定
# @param $1 ラベル（カンマ区切り）
# @return TYPE（FEAT, FIX, REFACTOR, CHORE, RFC）
#
wf_detect_type_from_labels() {
    local labels="$1"

    # ラベルをカンマで分割して検査
    IFS=',' read -ra label_array <<< "$labels"
    for label in "${label_array[@]}"; do
        # 前後の空白を除去
        label=$(echo "$label" | xargs)
        label_lower=$(echo "$label" | tr '[:upper:]' '[:lower:]')

        # 連想配列アクセス時は set -u を一時的に無効化
        set +u
        local type_value="${LABEL_TO_TYPE[$label_lower]:-}"
        set -u

        if [[ -n "$type_value" ]]; then
            echo "$type_value"
            return 0
        fi
    done

    # デフォルトは FEAT
    echo "FEAT"
}

#
# TYPE からブランチプレフィックスを取得
# @param $1 TYPE
# @param $2 config.json のパス（オプション）
# @return ブランチプレフィックス
#
wf_get_branch_prefix() {
    local type="$1"
    local config_path="${2:-}"

    # config.json から取得を試みる
    if [[ -n "$config_path" && -f "$config_path" ]]; then
        local prefix
        prefix=$(jq -r ".branch_prefix.${type} // empty" "$config_path" 2>/dev/null)
        if [[ -n "$prefix" ]]; then
            echo "$prefix"
            return 0
        fi
    fi

    # デフォルト値を返す（連想配列アクセス時は set -u を一時的に無効化）
    set +u
    local default_prefix="${DEFAULT_BRANCH_PREFIX[$type]:-feat}"
    set -u
    echo "$default_prefix"
}

#
# work-id を生成
# @param $1 TYPE
# @param $2 Issue番号
# @param $3 slug
# @return work-id（例: FEAT-123-export-csv）
#
wf_generate_work_id() {
    local type="$1"
    local issue="$2"
    local slug="$3"

    echo "${type}-${issue}-${slug}"
}

#
# work-id からブランチ名を生成
# @param $1 work-id
# @param $2 config.json のパス（オプション）
# @return ブランチ名（例: feat/123-export-csv）
#
wf_work_id_to_branch() {
    local work_id="$1"
    local config_path="${2:-}"

    # work-id を分解（TYPE-ISSUE-SLUG）
    local type issue slug
    type=$(echo "$work_id" | cut -d'-' -f1)
    issue=$(echo "$work_id" | cut -d'-' -f2)
    slug=$(echo "$work_id" | cut -d'-' -f3-)

    local prefix
    prefix=$(wf_get_branch_prefix "$type" "$config_path")

    echo "${prefix}/${issue}-${slug}"
}

#
# ブランチ名から work-id を生成
# @param $1 ブランチ名
# @return work-id
#
wf_branch_to_work_id() {
    local branch="$1"

    # プレフィックスを除去（feat/123-slug → 123-slug）
    local suffix
    suffix=$(echo "$branch" | sed 's|^[^/]*/||')

    # プレフィックスから TYPE を推測
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
# jq がインストールされているか確認
#
wf_require_jq() {
    if ! command -v jq &> /dev/null; then
        wf_error "jq がインストールされていません。brew install jq でインストールしてください。"
    fi
}

#
# gh がインストールされているか確認
#
wf_require_gh() {
    if ! command -v gh &> /dev/null; then
        wf_error "gh (GitHub CLI) がインストールされていません。brew install gh でインストールしてください。"
    fi
}

#
# gh が認証済みか確認
#
wf_require_gh_auth() {
    wf_require_gh
    if ! gh auth status &> /dev/null; then
        wf_error "gh が認証されていません。gh auth login で認証してください。"
    fi
}

#
# 現在のディレクトリが git リポジトリか確認
#
wf_require_git_repo() {
    if ! git rev-parse --git-dir &> /dev/null; then
        wf_error "現在のディレクトリは git リポジトリではありません。"
    fi
}

#
# プロジェクトルートを取得
# @return git リポジトリのルートパス
#
wf_get_project_root() {
    git rev-parse --show-toplevel 2>/dev/null || pwd
}

#
# 現在のブランチ名を取得
# @return ブランチ名
#
wf_get_current_branch() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null
}

#
# ISO8601 形式の現在時刻を取得
# @return ISO8601 形式の日時（例: 2026-01-17T10:00:00+09:00）
#
wf_get_timestamp() {
    date +"%Y-%m-%dT%H:%M:%S%z" | sed 's/\([0-9][0-9]\)$/:\1/'
}

#
# 確認プロンプトを表示
# @param $1 確認メッセージ
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
# ファイルが存在するか確認
# @param $1 ファイルパス
# @return 0: 存在する, 1: 存在しない
#
wf_file_exists() {
    [[ -f "$1" ]]
}

#
# ディレクトリが存在するか確認
# @param $1 ディレクトリパス
# @return 0: 存在する, 1: 存在しない
#
wf_dir_exists() {
    [[ -d "$1" ]]
}
