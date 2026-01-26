#!/usr/bin/env bash
#
# WF Batch Worker
# Executes workflow steps for assigned works
#
# Usage: batch-worker.sh <worker-number>
#
# Configuration (Environment Variables):
#   POLL_INTERVAL     - Assignment check interval in seconds (default: 5)
#   MAX_STEP_FAILURES - Max consecutive failures before giving up on a work (default: 3)
#   VERBOSE           - Enable detailed logging (default: false)
#   CLEANUP_WORKTREE  - Remove worktree after completion (default: true)
#
# Examples:
#   batch-worker.sh 1
#   VERBOSE=true batch-worker.sh 2
#

set -euo pipefail

# Directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# Load utilities
UTILS_FILE="${SCRIPT_DIR}/batch-utils.sh"
if [ ! -f "$UTILS_FILE" ]; then
    echo "ERROR: Required utility file not found: $UTILS_FILE"
    echo "Please ensure batch-utils.sh exists in the same directory as this script."
    exit 1
fi
source "$UTILS_FILE"

# Configuration
POLL_INTERVAL="${POLL_INTERVAL:-5}"
MAX_STEP_FAILURES="${MAX_STEP_FAILURES:-3}"
VERBOSE="${VERBOSE:-false}"
CLEANUP_WORKTREE="${CLEANUP_WORKTREE:-true}"

# Worker number from argument
WORKER_NUM="${1:-}"

if [ -z "$WORKER_NUM" ]; then
    echo "ERROR: worker number is required"
    echo "Usage: batch-worker.sh <worker-number>"
    exit 1
fi

# Validate worker number
if ! [[ "$WORKER_NUM" =~ ^[0-9]+$ ]]; then
    echo "ERROR: Invalid worker number: $WORKER_NUM"
    exit 1
fi

WORKER_ID="worker-$WORKER_NUM"

# Get project root
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SCHEDULE_FILE="$PROJECT_ROOT/.wf/schedule.json"

echo "==================================="
echo "WF Batch Worker $WORKER_NUM"
echo "==================================="
echo "Worker ID: $WORKER_ID"
echo "Project:   $PROJECT_ROOT"
echo "Interval:  ${POLL_INTERVAL}s"
echo "Max failures: $MAX_STEP_FAILURES"
echo "Verbose:   $VERBOSE"
echo "==================================="
echo ""

# Validate schedule exists
if [ ! -f "$SCHEDULE_FILE" ]; then
    echo "ERROR: schedule.json not found"
    exit 1
fi

# Signal handling for graceful shutdown
cleanup() {
    echo ""
    wf_batch_log "INFO" "Worker $WORKER_NUM received shutdown signal"

    # Release any claimed work
    current_work=$(jq -r ".execution.sessions[\"$WORKER_ID\"].work_id // empty" "$SCHEDULE_FILE")
    if [ -n "$current_work" ] && [ "$current_work" != "null" ]; then
        wf_batch_log "INFO" "Releasing work $current_work"
        # Reset work to pending (it was interrupted)
        wf_batch_update_schedule ".works[\"$current_work\"].status = \"pending\""
    fi

    wf_batch_release_worker "$WORKER_ID"

    wf_batch_log "INFO" "Worker $WORKER_NUM exiting gracefully."
    exit 0
}
trap cleanup SIGTERM SIGINT

# Initialize worker status
wf_batch_release_worker "$WORKER_ID"

wf_batch_log "INFO" "Worker $WORKER_NUM started, waiting for assignments..."

# Main worker loop
while true; do
    # Check if schedule is still running
    if ! wf_batch_is_running; then
        status=$(jq -r '.status' "$SCHEDULE_FILE")
        case "$status" in
            completed)
                wf_batch_log "INFO" "Schedule completed, worker exiting."
                exit 0
                ;;
            paused|failed)
                if [ "$VERBOSE" = "true" ]; then
                    wf_batch_log "INFO" "Schedule is $status, waiting..."
                fi
                sleep "$POLL_INTERVAL"
                continue
                ;;
        esac
    fi

    # Check for assigned work
    assignment=$(jq -r ".execution.sessions[\"$WORKER_ID\"] // empty" "$SCHEDULE_FILE")

    if [ -z "$assignment" ] || [ "$assignment" = "null" ]; then
        sleep "$POLL_INTERVAL"
        continue
    fi

    work_id=$(echo "$assignment" | jq -r '.work_id // empty')
    work_status=$(echo "$assignment" | jq -r '.status // "idle"')

    if [ -z "$work_id" ] || [ "$work_id" = "null" ] || [ "$work_status" = "idle" ]; then
        sleep "$POLL_INTERVAL"
        continue
    fi

    wf_batch_log "INFO" "Assigned work: $work_id"

    # Get work details
    work_data=$(jq ".works[\"$work_id\"]" "$SCHEDULE_FILE")
    source_type=$(echo "$work_data" | jq -r '.source.type')
    source_id=$(echo "$work_data" | jq -r '.source.id')

    wf_batch_log "INFO" "Source: $source_type #$source_id"

    # Determine branch name
    branch=$(wf_batch_get_branch_name "$work_id")
    wf_batch_log "INFO" "Branch: $branch"

    # Create or enter worktree
    worktree_path=$(wf_batch_create_worktree "$work_id" "$branch")

    if [ ! -d "$worktree_path" ]; then
        wf_batch_log "ERROR" "Failed to create worktree for $work_id"
        wf_batch_fail_work "$work_id" "$WORKER_ID" "Failed to create worktree"
        continue
    fi

    wf_batch_log "INFO" "Worktree: $worktree_path"

    # Execute workflow phases
    cd "$worktree_path"

    step_failures=0
    workflow_complete=false
    workflow_failed=false

    # Get current phase from state.json (if work already started)
    current_phase=$(jq -r ".works[\"$work_id\"].current // \"wf1-kickoff\"" "$PROJECT_ROOT/.wf/state.json" 2>/dev/null || echo "wf1-kickoff")

    wf_batch_log "INFO" "Starting from phase: $current_phase"

    while [ "$workflow_complete" = false ] && [ "$workflow_failed" = false ]; do
        wf_batch_log "INFO" "Executing: $current_phase"

        # Update execution status
        wf_batch_update_schedule ".execution.sessions[\"$WORKER_ID\"].status = \"executing $current_phase\""

        # Execute via Claude Code
        output_file=$(mktemp)
        exit_code=0

        if [ "$current_phase" = "wf1-kickoff" ]; then
            # Kickoff needs source info
            case "$source_type" in
                github)
                    if claude --print "/wf1-kickoff github=#$source_id" > "$output_file" 2>&1; then
                        exit_code=0
                    else
                        exit_code=1
                    fi
                    ;;
                jira)
                    if claude --print "/wf1-kickoff jira=$source_id" > "$output_file" 2>&1; then
                        exit_code=0
                    else
                        exit_code=1
                    fi
                    ;;
                local)
                    if claude --print "/wf1-kickoff local=$work_id" > "$output_file" 2>&1; then
                        exit_code=0
                    else
                        exit_code=1
                    fi
                    ;;
            esac
        else
            # Use wf0-nextstep for subsequent phases
            if claude --print "/wf0-nextstep $work_id" > "$output_file" 2>&1; then
                exit_code=0
            else
                exit_code=1
            fi
        fi

        if [ $exit_code -ne 0 ]; then
            step_failures=$((step_failures + 1))
            wf_batch_log "WARN" "Step failed ($step_failures/$MAX_STEP_FAILURES)"

            if [ "$VERBOSE" = "true" ]; then
                cat "$output_file" >&2
            fi

            if [ $step_failures -ge $MAX_STEP_FAILURES ]; then
                wf_batch_log "ERROR" "Max failures reached for $work_id"
                wf_batch_fail_work "$work_id" "$WORKER_ID" "Max step failures ($MAX_STEP_FAILURES) reached in $current_phase"
                workflow_failed=true
            fi

            rm -f "$output_file"
            sleep 5
            continue
        fi

        rm -f "$output_file"
        step_failures=0

        # Commit and push changes if any
        if [ -n "$(git status --porcelain)" ]; then
            if [ "$VERBOSE" = "true" ]; then
                wf_batch_log "INFO" "Changes detected, should be committed by workflow"
            fi
        fi

        # Push to remote
        if ! wf_batch_push_changes "$work_id" "$worktree_path"; then
            wf_batch_log "WARN" "Push failed, continuing..."
        fi

        # Check next phase from state.json
        next_phase=$(jq -r ".works[\"$work_id\"].next // empty" "$PROJECT_ROOT/.wf/state.json" 2>/dev/null)
        current_phase_state=$(jq -r ".works[\"$work_id\"].current // empty" "$PROJECT_ROOT/.wf/state.json" 2>/dev/null)

        if [ -z "$next_phase" ] || [ "$next_phase" = "null" ] || [ "$next_phase" = "completed" ]; then
            wf_batch_log "INFO" "Workflow completed for $work_id"
            workflow_complete=true
        elif [ "$next_phase" = "$current_phase" ]; then
            # Same phase, might be stuck
            wf_batch_log "WARN" "Phase unchanged, checking if complete..."

            # Check if this is wf6-verify completion
            if [ "$current_phase" = "wf6-verify" ]; then
                workflow_complete=true
            else
                step_failures=$((step_failures + 1))
                if [ $step_failures -ge $MAX_STEP_FAILURES ]; then
                    wf_batch_fail_work "$work_id" "$WORKER_ID" "Workflow stuck at $current_phase"
                    workflow_failed=true
                fi
            fi
        else
            current_phase="$next_phase"
            wf_batch_log "INFO" "Moving to: $current_phase"
        fi

        # Small delay between phases
        sleep 2
    done

    # Cleanup
    cd "$PROJECT_ROOT"

    if [ "$workflow_complete" = true ]; then
        wf_batch_complete_work "$work_id" "$WORKER_ID"
        wf_batch_log "INFO" "Work $work_id completed successfully"

        if [ "$CLEANUP_WORKTREE" = "true" ]; then
            wf_batch_log "INFO" "Cleaning up worktree..."
            wf_batch_cleanup_worktree "$work_id"
        fi
    fi

    wf_batch_log "INFO" "Worker $WORKER_NUM ready for next assignment"

    sleep "$POLL_INTERVAL"
done
