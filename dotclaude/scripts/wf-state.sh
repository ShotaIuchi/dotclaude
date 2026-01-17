#!/usr/bin/env bash
#
# WF運用システム - 状態管理
# state.json, local.json, config.json の読み書き
#

set -euo pipefail

# このスクリプトのディレクトリ
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# wf-utils.sh を読み込み
source "${SCRIPT_DIR}/wf-utils.sh"

/**
 * config.json を読み込む
 * @param $1 プロジェクトルート（オプション）
 * @return config.json の内容
 */
wf_read_config() {
    local project_root="${1:-$(wf_get_project_root)}"
    local config_path="${project_root}/${WF_DIR}/config.json"

    if wf_file_exists "$config_path"; then
        cat "$config_path"
    else
        # デフォルト設定を返す
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

/**
 * config.json から値を取得
 * @param $1 jq クエリ（例: .default_base_branch）
 * @param $2 プロジェクトルート（オプション）
 * @return 取得した値
 */
wf_config_get() {
    local query="$1"
    local project_root="${2:-$(wf_get_project_root)}"

    wf_read_config "$project_root" | jq -r "$query // empty"
}

/**
 * state.json を読み込む
 * @param $1 プロジェクトルート（オプション）
 * @return state.json の内容
 */
wf_read_state() {
    local project_root="${1:-$(wf_get_project_root)}"
    local state_path="${project_root}/${WF_DIR}/state.json"

    if wf_file_exists "$state_path"; then
        cat "$state_path"
    else
        # 空の状態を返す
        echo '{"active_work": null, "works": {}}'
    fi
}

/**
 * state.json に書き込む
 * @param $1 JSON データ
 * @param $2 プロジェクトルート（オプション）
 */
wf_write_state() {
    local data="$1"
    local project_root="${2:-$(wf_get_project_root)}"
    local state_path="${project_root}/${WF_DIR}/state.json"

    # ディレクトリ作成
    mkdir -p "$(dirname "$state_path")"

    # JSON を整形して書き込み
    echo "$data" | jq '.' > "$state_path"
}

/**
 * state.json から値を取得
 * @param $1 jq クエリ
 * @param $2 プロジェクトルート（オプション）
 * @return 取得した値
 */
wf_state_get() {
    local query="$1"
    local project_root="${2:-$(wf_get_project_root)}"

    wf_read_state "$project_root" | jq -r "$query // empty"
}

/**
 * state.json の値を更新
 * @param $1 jq 更新式（例: .active_work = "FEAT-123"）
 * @param $2 プロジェクトルート（オプション）
 */
wf_state_set() {
    local update_expr="$1"
    local project_root="${2:-$(wf_get_project_root)}"

    local current_state
    current_state=$(wf_read_state "$project_root")

    local new_state
    new_state=$(echo "$current_state" | jq "$update_expr")

    wf_write_state "$new_state" "$project_root"
}

/**
 * active_work を取得
 * @param $1 プロジェクトルート（オプション）
 * @return active_work の値
 */
wf_get_active_work() {
    local project_root="${1:-$(wf_get_project_root)}"
    wf_state_get '.active_work' "$project_root"
}

/**
 * active_work を設定
 * @param $1 work-id
 * @param $2 プロジェクトルート（オプション）
 */
wf_set_active_work() {
    local work_id="$1"
    local project_root="${2:-$(wf_get_project_root)}"

    wf_state_set ".active_work = \"${work_id}\"" "$project_root"
}

/**
 * work の状態を取得
 * @param $1 work-id
 * @param $2 プロジェクトルート（オプション）
 * @return work の状態（JSON）
 */
wf_get_work() {
    local work_id="$1"
    local project_root="${2:-$(wf_get_project_root)}"

    wf_state_get ".works[\"${work_id}\"]" "$project_root"
}

/**
 * work の状態を設定
 * @param $1 work-id
 * @param $2 work の状態（JSON）
 * @param $3 プロジェクトルート（オプション）
 */
wf_set_work() {
    local work_id="$1"
    local work_data="$2"
    local project_root="${3:-$(wf_get_project_root)}"

    wf_state_set ".works[\"${work_id}\"] = ${work_data}" "$project_root"
}

/**
 * work の特定フィールドを更新
 * @param $1 work-id
 * @param $2 フィールドパス（例: .current）
 * @param $3 値
 * @param $4 プロジェクトルート（オプション）
 */
wf_update_work_field() {
    local work_id="$1"
    local field="$2"
    local value="$3"
    local project_root="${4:-$(wf_get_project_root)}"

    # 値が文字列の場合は引用符で囲む
    if [[ "$value" =~ ^[0-9]+$ ]] || [[ "$value" == "true" ]] || [[ "$value" == "false" ]] || [[ "$value" == "null" ]] || [[ "$value" =~ ^\{.*\}$ ]] || [[ "$value" =~ ^\[.*\]$ ]]; then
        wf_state_set ".works[\"${work_id}\"]${field} = ${value}" "$project_root"
    else
        wf_state_set ".works[\"${work_id}\"]${field} = \"${value}\"" "$project_root"
    fi
}

/**
 * work の current フェーズを取得
 * @param $1 work-id
 * @param $2 プロジェクトルート（オプション）
 * @return current フェーズ
 */
wf_get_work_current() {
    local work_id="$1"
    local project_root="${2:-$(wf_get_project_root)}"

    wf_state_get ".works[\"${work_id}\"].current" "$project_root"
}

/**
 * work の next フェーズを取得
 * @param $1 work-id
 * @param $2 プロジェクトルート（オプション）
 * @return next フェーズ
 */
wf_get_work_next() {
    local work_id="$1"
    local project_root="${2:-$(wf_get_project_root)}"

    wf_state_get ".works[\"${work_id}\"].next" "$project_root"
}

/**
 * local.json を読み込む
 * @param $1 プロジェクトルート（オプション）
 * @return local.json の内容
 */
wf_read_local() {
    local project_root="${1:-$(wf_get_project_root)}"
    local local_path="${project_root}/${WF_DIR}/local.json"

    if wf_file_exists "$local_path"; then
        cat "$local_path"
    else
        # 空の状態を返す
        echo '{"works": {}}'
    fi
}

/**
 * local.json に書き込む
 * @param $1 JSON データ
 * @param $2 プロジェクトルート（オプション）
 */
wf_write_local() {
    local data="$1"
    local project_root="${2:-$(wf_get_project_root)}"
    local local_path="${project_root}/${WF_DIR}/local.json"

    # ディレクトリ作成
    mkdir -p "$(dirname "$local_path")"

    # JSON を整形して書き込み
    echo "$data" | jq '.' > "$local_path"
}

/**
 * local.json から値を取得
 * @param $1 jq クエリ
 * @param $2 プロジェクトルート（オプション）
 * @return 取得した値
 */
wf_local_get() {
    local query="$1"
    local project_root="${2:-$(wf_get_project_root)}"

    wf_read_local "$project_root" | jq -r "$query // empty"
}

/**
 * local.json の値を更新
 * @param $1 jq 更新式
 * @param $2 プロジェクトルート（オプション）
 */
wf_local_set() {
    local update_expr="$1"
    local project_root="${2:-$(wf_get_project_root)}"

    local current_local
    current_local=$(wf_read_local "$project_root")

    local new_local
    new_local=$(echo "$current_local" | jq "$update_expr")

    wf_write_local "$new_local" "$project_root"
}

/**
 * worktree パスを取得
 * @param $1 work-id
 * @param $2 プロジェクトルート（オプション）
 * @return worktree パス
 */
wf_get_worktree_path() {
    local work_id="$1"
    local project_root="${2:-$(wf_get_project_root)}"

    wf_local_get ".works[\"${work_id}\"].worktree_path" "$project_root"
}

/**
 * worktree パスを設定
 * @param $1 work-id
 * @param $2 worktree パス
 * @param $3 プロジェクトルート（オプション）
 */
wf_set_worktree_path() {
    local work_id="$1"
    local worktree_path="$2"
    local project_root="${3:-$(wf_get_project_root)}"

    wf_local_set ".works[\"${work_id}\"].worktree_path = \"${worktree_path}\"" "$project_root"
}

/**
 * すべての work-id を取得
 * @param $1 プロジェクトルート（オプション）
 * @return work-id のリスト（改行区切り）
 */
wf_list_works() {
    local project_root="${1:-$(wf_get_project_root)}"

    wf_read_state "$project_root" | jq -r '.works | keys[]' 2>/dev/null
}

/**
 * 新しい work を作成
 * @param $1 work-id
 * @param $2 base branch
 * @param $3 feature branch
 * @param $4 プロジェクトルート（オプション）
 */
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
  "current": "wf0-workspace",
  "next": "wf1-kickoff",
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

/**
 * work のフェーズを進める
 * @param $1 work-id
 * @param $2 新しい current フェーズ
 * @param $3 新しい next フェーズ
 * @param $4 プロジェクトルート（オプション）
 */
wf_advance_phase() {
    local work_id="$1"
    local new_current="$2"
    local new_next="$3"
    local project_root="${4:-$(wf_get_project_root)}"

    wf_update_work_field "$work_id" ".current" "$new_current" "$project_root"
    wf_update_work_field "$work_id" ".next" "$new_next" "$project_root"
}
