#!/usr/bin/env bash
#
# GHWF Daemon
# Polls GitHub Issues/PRs for ghwf:* labels and executes workflow steps
#
# Usage: ghwf-daemon.sh
#
# Configuration (Environment Variables):
#   POLL_INTERVAL - Polling interval in seconds (default: 60)
#   VERBOSE       - Enable detailed logging (default: false)
#

set -euo pipefail

# Directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# Load utilities
source "${SCRIPT_DIR}/ghwf-utils.sh"

# Configuration
POLL_INTERVAL="${POLL_INTERVAL:-60}"
VERBOSE="${VERBOSE:-false}"
MAX_STEPS_PER_SESSION="${MAX_STEPS_PER_SESSION:-0}"  # 0 = unlimited

# Track executed steps in this session
EXECUTED_STEPS=0

echo "==================================="
echo "GHWF Daemon"
echo "==================================="
echo "Poll interval: ${POLL_INTERVAL}s"
echo "Max steps:     ${MAX_STEPS_PER_SESSION:-unlimited}"
[ "$MAX_STEPS_PER_SESSION" -eq 0 ] && echo "               (unlimited)"
echo "Verbose:       $VERBOSE"
echo "==================================="
echo ""

# Ensure labels exist
echo "[INFO] Ensuring ghwf labels exist..."
ghwf_ensure_labels

# Initialize state
ghwf_init_state
ghwf_update_daemon_state "enabled" "true"
ghwf_update_daemon_state "started_at" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
ghwf_update_daemon_state "tmux_session" "ghwf-daemon"

# Signal handling
cleanup() {
    echo ""
    echo "[INFO] Shutting down..."
    ghwf_update_daemon_state "enabled" "false"
    exit 0
}
trap cleanup SIGTERM SIGINT

# Alias for step name (uses utility function)
get_step_name() {
    ghwf_get_step_command "$1"
}

# Process a single issue
process_issue() {
    local issue_number="$1"
    local command_label="$2"

    echo "[INFO] Processing issue #$issue_number with label: $command_label"

    # Check max steps limit (0 = unlimited)
    if [ "$MAX_STEPS_PER_SESSION" -gt 0 ] && [ "$EXECUTED_STEPS" -ge "$MAX_STEPS_PER_SESSION" ]; then
        echo "[WARN] Max steps ($MAX_STEPS_PER_SESSION) reached for this session"
        ghwf_post_comment "$issue_number" "セッションの最大ステップ数 ($MAX_STEPS_PER_SESSION) に達しました。デーモンを再起動してください。"
        return 1
    fi

    # Check permission of label author
    local label_author
    label_author=$(ghwf_get_label_author "$issue_number" "$command_label")

    if [ -n "$label_author" ]; then
        local permission
        permission=$(ghwf_check_permission "$label_author")

        if [ "$permission" = "denied" ]; then
            echo "[WARN] User $label_author does not have permission"
            ghwf_remove_label "$issue_number" "$command_label"
            return 1
        fi
        echo "[INFO] Permission check passed for user: $label_author"
    fi

    # Check dependencies (after permission check, before command processing)
    local dep_status
    dep_status=$(ghwf_check_dependencies "$issue_number")

    if [ "$dep_status" = "blocked" ]; then
        local blocking_issues
        blocking_issues=$(ghwf_get_blocking_issues "$issue_number")
        echo "[INFO] Issue #$issue_number is blocked by: #$blocking_issues"
        ghwf_add_label "$issue_number" "ghwf:waiting-deps"
        ghwf_remove_label "$issue_number" "$command_label"
        return 0  # Skip without error
    fi

    # Remove waiting-deps label if exists (no longer blocked)
    ghwf_remove_label "$issue_number" "ghwf:waiting-deps" 2>/dev/null || true

    # Get work-id
    local work_id
    work_id=$(ghwf_get_work_id "$issue_number")

    # Get state file info
    local state_file
    state_file=$(ghwf_get_state_file)

    local last_execution=""
    local pr_number=""

    if [ -n "$work_id" ] && [ -f "$state_file" ]; then
        last_execution=$(jq -r ".works[\"$work_id\"].last_execution // \"\"" "$state_file")
        pr_number=$(jq -r ".works[\"$work_id\"].source.pr // \"\"" "$state_file")
    fi

    case "$command_label" in
        ghwf:exec)
            # Get next step
            local current_step
            current_step=$(ghwf_get_current_step "$issue_number")
            local next_step=$((current_step + 1))

            if [ "$next_step" -gt 7 ]; then
                echo "[INFO] Workflow already completed"
                ghwf_remove_label "$issue_number" "ghwf:exec"
                return
            fi

            # Update labels
            ghwf_remove_label "$issue_number" "ghwf:exec"
            ghwf_remove_label "$issue_number" "ghwf:waiting"
            ghwf_add_label "$issue_number" "ghwf:executing"

            # Execute steps (loop for auto-to support)
            while [ "$next_step" -le 7 ]; do
                echo "[INFO] Executing step $next_step: $(get_step_name "$next_step")"

                # Check for stop label (highest priority)
                if gh issue view "$issue_number" --json labels --jq '.labels[].name' | grep -q "^ghwf:stop$"; then
                    echo "[INFO] Stop label detected, halting execution"
                    ghwf_remove_label "$issue_number" "ghwf:executing"
                    ghwf_remove_label "$issue_number" "ghwf:stop"
                    ghwf_post_comment "$issue_number" "停止ラベルを検出しました。Step $((next_step - 1)) で停止。"
                    return
                fi

                # Execute step
                if ghwf_invoke_claude "$next_step" "$work_id" ""; then
                    ((EXECUTED_STEPS++)) || true
                    ghwf_push_changes
                    ghwf_add_label "$issue_number" "ghwf:step-$next_step"

                    # Check if completed all steps
                    if [ "$next_step" -eq 7 ]; then
                        ghwf_remove_label "$issue_number" "ghwf:executing"
                        ghwf_add_label "$issue_number" "ghwf:completed"
                        return
                    fi

                    # Check max steps limit (0 = unlimited)
                    if [ "$MAX_STEPS_PER_SESSION" -gt 0 ] && [ "$EXECUTED_STEPS" -ge "$MAX_STEPS_PER_SESSION" ]; then
                        ghwf_remove_label "$issue_number" "ghwf:executing"
                        ghwf_add_label "$issue_number" "ghwf:waiting"
                        ghwf_post_comment "$issue_number" "最大ステップ数に達しました。\`ghwf:exec\` で続行できます。"
                        return
                    fi

                    # Check if should auto-continue
                    if [ "$(ghwf_should_auto_continue "$issue_number" "$next_step")" = "yes" ]; then
                        echo "[INFO] Auto-continuing to next step..."
                        next_step=$((next_step + 1))
                        continue
                    else
                        # Reached auto-to limit or no auto-to label, wait for approval
                        ghwf_remove_label "$issue_number" "ghwf:executing"
                        ghwf_add_label "$issue_number" "ghwf:waiting"
                        return
                    fi
                else
                    ghwf_remove_label "$issue_number" "ghwf:executing"
                    ghwf_add_label "$issue_number" "ghwf:waiting"
                    ghwf_post_comment "$issue_number" "Step $(get_step_name "$next_step") failed. Please check and retry."
                    return
                fi
            done
            ;;

        ghwf:redo|ghwf:redo-[1-7])
            # Check for updates
            local update_type
            update_type=$(ghwf_check_updates "$issue_number" "$last_execution" "$pr_number")

            if [ "$update_type" = "none" ]; then
                echo "[INFO] No updates found, waiting for instruction"
                ghwf_post_comment "$issue_number" "変更内容をコメントで指示してください。"
                return
            fi

            # Get target step
            local target_step
            if [ "$command_label" = "ghwf:redo" ]; then
                target_step=$(ghwf_get_current_step "$issue_number")
            else
                target_step=$(ghwf_get_step_from_label "$command_label")
            fi

            echo "[INFO] Redo from step $target_step: $(get_step_name "$target_step")"

            # Get instruction
            local instruction
            instruction=$(ghwf_get_instruction "$issue_number" "$last_execution")

            # Update labels
            ghwf_remove_label "$issue_number" "$command_label"
            ghwf_remove_label "$issue_number" "ghwf:waiting"
            ghwf_remove_label "$issue_number" "ghwf:completed"
            ghwf_add_label "$issue_number" "ghwf:executing"

            # Remove step labels >= target
            for i in $(seq "$target_step" 7); do
                ghwf_remove_label "$issue_number" "ghwf:step-$i"
            done

            # Execute from target step
            for step in $(seq "$target_step" 7); do
                echo "[INFO] Executing step $step: $(get_step_name "$step")"

                local step_instruction=""
                if [ "$step" -eq "$target_step" ]; then
                    step_instruction="$instruction"
                fi

                if ! ghwf_invoke_claude "$step" "$work_id" "$step_instruction"; then
                    ghwf_remove_label "$issue_number" "ghwf:executing"
                    ghwf_add_label "$issue_number" "ghwf:waiting"
                    ghwf_post_comment "$issue_number" "Step $(get_step_name "$step") failed."
                    return
                fi

                ((EXECUTED_STEPS++)) || true
                ghwf_push_changes
                ghwf_add_label "$issue_number" "ghwf:step-$step"

                # Check max steps (0 = unlimited)
                if [ "$MAX_STEPS_PER_SESSION" -gt 0 ] && [ "$EXECUTED_STEPS" -ge "$MAX_STEPS_PER_SESSION" ]; then
                    ghwf_remove_label "$issue_number" "ghwf:executing"
                    ghwf_add_label "$issue_number" "ghwf:waiting"
                    ghwf_post_comment "$issue_number" "最大ステップ数に達しました。\`ghwf:approve\` で続行できます。"
                    return
                fi
            done

            ghwf_remove_label "$issue_number" "ghwf:executing"
            ghwf_add_label "$issue_number" "ghwf:completed"
            ;;

        ghwf:revision)
            # Check for updates
            local update_type
            update_type=$(ghwf_check_updates "$issue_number" "$last_execution" "$pr_number")

            if [ "$update_type" = "none" ]; then
                echo "[INFO] No updates found, waiting for instruction"
                ghwf_post_comment "$issue_number" "変更内容をコメントで指示してください。"
                return
            fi

            echo "[INFO] Full revision from step 1"

            # Update labels
            ghwf_remove_label "$issue_number" "ghwf:revision"
            ghwf_remove_label "$issue_number" "ghwf:waiting"
            ghwf_remove_label "$issue_number" "ghwf:completed"
            ghwf_add_label "$issue_number" "ghwf:executing"

            # Remove all step labels
            for i in $(seq 1 7); do
                ghwf_remove_label "$issue_number" "ghwf:step-$i"
            done

            # Get instruction
            local instruction
            instruction=$(ghwf_get_instruction "$issue_number" "$last_execution")

            # Execute all steps
            for step in $(seq 1 7); do
                echo "[INFO] Executing step $step: $(get_step_name "$step")"

                local step_instruction=""
                if [ "$step" -eq 1 ]; then
                    step_instruction="$instruction"
                fi

                if ! ghwf_invoke_claude "$step" "$work_id" "$step_instruction"; then
                    ghwf_remove_label "$issue_number" "ghwf:executing"
                    ghwf_add_label "$issue_number" "ghwf:waiting"
                    ghwf_post_comment "$issue_number" "Step $(get_step_name "$step") failed."
                    return
                fi

                ((EXECUTED_STEPS++)) || true
                ghwf_push_changes
                ghwf_add_label "$issue_number" "ghwf:step-$step"

                # Check max steps (0 = unlimited)
                if [ "$MAX_STEPS_PER_SESSION" -gt 0 ] && [ "$EXECUTED_STEPS" -ge "$MAX_STEPS_PER_SESSION" ]; then
                    ghwf_remove_label "$issue_number" "ghwf:executing"
                    ghwf_add_label "$issue_number" "ghwf:waiting"
                    ghwf_post_comment "$issue_number" "最大ステップ数に達しました。\`ghwf:approve\` で続行できます。"
                    return
                fi
            done

            ghwf_remove_label "$issue_number" "ghwf:executing"
            ghwf_add_label "$issue_number" "ghwf:completed"
            ;;

        ghwf:stop)
            echo "[INFO] Stopping monitoring for issue #$issue_number"
            ghwf_remove_label "$issue_number" "ghwf:stop"
            ghwf_remove_label "$issue_number" "ghwf:waiting"
            ghwf_remove_label "$issue_number" "ghwf:executing"
            ghwf_post_comment "$issue_number" "監視を停止しました。"
            ;;

        *)
            echo "[WARN] Unknown command: $command_label"
            ;;
    esac
}

# Main polling loop
while true; do
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Polling for ghwf:* labels... (steps: $EXECUTED_STEPS/$MAX_STEPS_PER_SESSION)"

    ghwf_update_daemon_state "last_poll" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    ghwf_update_daemon_state "executed_steps" "$EXECUTED_STEPS"

    # Check max steps before polling (0 = unlimited)
    if [ "$MAX_STEPS_PER_SESSION" -gt 0 ] && [ "$EXECUTED_STEPS" -ge "$MAX_STEPS_PER_SESSION" ]; then
        echo "[WARN] Max steps reached. Daemon will stop processing new commands."
        echo "[INFO] Restart daemon to reset step count."
        sleep "$POLL_INTERVAL"
        continue
    fi

    # Query issues with command labels
    issues=$(ghwf_query_command_issues 2>/dev/null || echo "[]")

    if [ "$issues" != "[]" ] && [ -n "$issues" ]; then
        # Process each issue (using process substitution to avoid subshell)
        while read -r issue_number; do
            if [ -n "$issue_number" ]; then
                command_label=$(ghwf_get_command_label "$issue_number")
                if [ -n "$command_label" ]; then
                    process_issue "$issue_number" "$command_label" || true
                fi
            fi
        done < <(echo "$issues" | jq -r '.number')
    else
        [ "$VERBOSE" = "true" ] && echo "[INFO] No pending commands found"
    fi

    sleep "$POLL_INTERVAL"
done
