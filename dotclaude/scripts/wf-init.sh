#!/usr/bin/env bash
#
# WF運用システム - プロジェクト初期化
# .wf/ と docs/wf/ 構造を作成
#

set -euo pipefail

# このスクリプトのディレクトリ
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# wf-utils.sh と wf-state.sh を読み込み
source "${SCRIPT_DIR}/wf-utils.sh"
source "${SCRIPT_DIR}/wf-state.sh"

#
# WF システムをプロジェクトに初期化
# @param $1 プロジェクトルート（オプション）
#
wf_init_project() {
    local project_root="${1:-$(wf_get_project_root)}"

    wf_require_jq
    wf_require_git_repo

    wf_info "WF システムを初期化しています: ${project_root}"

    # .wf/ ディレクトリ作成
    local wf_path="${project_root}/${WF_DIR}"
    if wf_dir_exists "$wf_path"; then
        wf_warn ".wf/ ディレクトリは既に存在します"
    else
        mkdir -p "$wf_path"
        wf_info ".wf/ ディレクトリを作成しました"
    fi

    # docs/wf/ ディレクトリ作成
    local docs_path="${project_root}/${WF_DOCS_DIR}"
    if wf_dir_exists "$docs_path"; then
        wf_warn "docs/wf/ ディレクトリは既に存在します"
    else
        mkdir -p "$docs_path"
        wf_info "docs/wf/ ディレクトリを作成しました"
    fi

    # config.json 作成（存在しない場合）
    local config_path="${wf_path}/config.json"
    if wf_file_exists "$config_path"; then
        wf_warn "config.json は既に存在します"
    else
        wf_create_default_config "$project_root"
        wf_info "config.json を作成しました"
    fi

    # state.json 作成（存在しない場合）
    local state_path="${wf_path}/state.json"
    if wf_file_exists "$state_path"; then
        wf_warn "state.json は既に存在します"
    else
        wf_write_state '{"active_work": null, "works": {}}' "$project_root"
        wf_info "state.json を作成しました"
    fi

    # .gitignore に local.json を追加
    wf_update_gitignore "$project_root"

    wf_success "WF システムの初期化が完了しました"
}

#
# デフォルトの config.json を作成
# @param $1 プロジェクトルート
#
wf_create_default_config() {
    local project_root="$1"
    local config_path="${project_root}/${WF_DIR}/config.json"

    # デフォルトブランチを検出
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
# デフォルトブランチを検出
# @param $1 プロジェクトルート
# @return デフォルトブランチ名
#
wf_detect_default_branch() {
    local project_root="$1"

    cd "$project_root" || return 1

    # remote の HEAD を確認
    local remote_head
    remote_head=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|^refs/remotes/origin/||' || true)

    if [[ -n "$remote_head" ]]; then
        echo "$remote_head"
        return 0
    fi

    # 候補ブランチを確認
    for branch in main master develop; do
        if git show-ref --verify --quiet "refs/heads/${branch}" 2>/dev/null || \
           git show-ref --verify --quiet "refs/remotes/origin/${branch}" 2>/dev/null; then
            echo "$branch"
            return 0
        fi
    done

    # 見つからない場合は main
    echo "main"
}

#
# .gitignore を更新して local.json を除外
# @param $1 プロジェクトルート
#
wf_update_gitignore() {
    local project_root="$1"
    local gitignore_path="${project_root}/.gitignore"
    local entry=".wf/local.json"

    # .gitignore が存在しない場合は作成
    if ! wf_file_exists "$gitignore_path"; then
        echo "$entry" > "$gitignore_path"
        wf_info ".gitignore を作成し、${entry} を追加しました"
        return 0
    fi

    # 既に含まれているか確認
    if grep -qF "$entry" "$gitignore_path" 2>/dev/null; then
        wf_info ".gitignore に ${entry} は既に含まれています"
        return 0
    fi

    # 追加
    echo "" >> "$gitignore_path"
    echo "# WF local settings" >> "$gitignore_path"
    echo "$entry" >> "$gitignore_path"
    wf_info ".gitignore に ${entry} を追加しました"
}

#
# work 用のドキュメントディレクトリを作成
# @param $1 work-id
# @param $2 プロジェクトルート（オプション）
# @return 作成したディレクトリパス
#
wf_create_work_docs_dir() {
    local work_id="$1"
    local project_root="${2:-$(wf_get_project_root)}"

    local docs_dir="${project_root}/${WF_DOCS_DIR}/${work_id}"

    if wf_dir_exists "$docs_dir"; then
        wf_warn "ドキュメントディレクトリは既に存在します: ${docs_dir}"
    else
        mkdir -p "$docs_dir"
        wf_info "ドキュメントディレクトリを作成しました: ${docs_dir}"
    fi

    echo "$docs_dir"
}

#
# worktree を作成
# @param $1 work-id
# @param $2 ブランチ名
# @param $3 プロジェクトルート（オプション）
# @return worktree パス
#
wf_create_worktree() {
    local work_id="$1"
    local branch="$2"
    local project_root="${3:-$(wf_get_project_root)}"

    # worktree が有効か確認
    local worktree_enabled
    worktree_enabled=$(wf_config_get '.worktree.enabled' "$project_root")

    if [[ "$worktree_enabled" != "true" ]]; then
        wf_info "worktree は無効です"
        return 0
    fi

    local worktree_root
    worktree_root=$(wf_config_get '.worktree.root_dir' "$project_root")
    worktree_root="${worktree_root:-.worktrees}"

    # ブランチ名からディレクトリ名を生成（/ を - に置換）
    local dir_name
    dir_name=$(echo "$branch" | tr '/' '-')

    local worktree_path="${project_root}/${worktree_root}/${dir_name}"

    # 既に存在する場合はスキップ
    if wf_dir_exists "$worktree_path"; then
        wf_warn "worktree は既に存在します: ${worktree_path}"
        echo "$worktree_path"
        return 0
    fi

    # worktree ルートディレクトリ作成
    mkdir -p "${project_root}/${worktree_root}"

    # worktree 作成
    cd "$project_root" || return 1
    git worktree add "$worktree_path" "$branch" 2>/dev/null || {
        # ブランチが存在しない場合は新規作成
        git worktree add -b "$branch" "$worktree_path" 2>/dev/null || {
            wf_error "worktree の作成に失敗しました: ${worktree_path}"
        }
    }

    wf_info "worktree を作成しました: ${worktree_path}"
    echo "$worktree_path"
}

#
# worktree を削除
# @param $1 worktree パス
# @param $2 プロジェクトルート（オプション）
#
wf_remove_worktree() {
    local worktree_path="$1"
    local project_root="${2:-$(wf_get_project_root)}"

    if ! wf_dir_exists "$worktree_path"; then
        wf_warn "worktree が存在しません: ${worktree_path}"
        return 0
    fi

    cd "$project_root" || return 1
    git worktree remove "$worktree_path" --force 2>/dev/null || {
        wf_warn "worktree の削除に失敗しました: ${worktree_path}"
    }

    wf_info "worktree を削除しました: ${worktree_path}"
}

# メイン処理（直接実行された場合）
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
