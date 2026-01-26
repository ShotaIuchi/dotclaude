#!/usr/bin/env bash
#
# WF Batch Scheduler Daemon
# Coordinates batch workflow execution across multiple workers
#
# Usage: batch-daemon.sh
#
# Configuration (Environment Variables):
#   POLL_INTERVAL - Status check interval in seconds (default: 10)
#   VERBOSE       - Enable detailed logging (default: false)
#
# Examples:
#   batch-daemon.sh
#   POLL_INTERVAL=5 VERBOSE=true batch-daemon.sh
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
POLL_INTERVAL="${POLL_INTERVAL:-10}"
VERBOSE="${VERBOSE:-false}"

# Get project root
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SCHEDULE_FILE="$PROJECT_ROOT/.wf/schedule.json"

echo "==================================="
echo "WF Batch Scheduler Daemon"
echo "==================================="
echo "Project:  $PROJECT_ROOT"
echo "Interval: ${POLL_INTERVAL}s"
echo "Verbose:  $VERBOSE"
echo "==================================="
echo ""

# Validate schedule exists
if [ ! -f "$SCHEDULE_FILE" ]; then
    echo "ERROR: schedule.json not found"
    echo "Use '/wf0-schedule create' to create a schedule first"
    exit 1
fi

# Signal handling for graceful shutdown
cleanup() {
    echo ""
    wf_batch_log "INFO" "Received shutdown signal, cleaning up..."

    # Update schedule status
    wf_batch_update_schedule '.status = "paused"'

    wf_batch_log "INFO" "Scheduler daemon exiting gracefully."
    exit 0
}
trap cleanup SIGTERM SIGINT

# Main scheduling loop
wf_batch_log "INFO" "Scheduler started"

while true; do
    # Check if schedule is still running
    if ! wf_batch_is_running; then
        wf_batch_log "INFO" "Schedule is not in running state, checking..."

        status=$(jq -r '.status' "$SCHEDULE_FILE")
        case "$status" in
            completed)
                wf_batch_log "INFO" "All works completed! Exiting."
                exit 0
                ;;
            paused|failed)
                wf_batch_log "INFO" "Schedule is $status, waiting for resume..."
                sleep "$POLL_INTERVAL"
                continue
                ;;
            *)
                wf_batch_log "WARN" "Unexpected status: $status"
                sleep "$POLL_INTERVAL"
                continue
                ;;
        esac
    fi

    # Get progress summary
    if [ "$VERBOSE" = "true" ]; then
        progress=$(wf_batch_get_progress)
        completed=$(echo "$progress" | jq -r '.completed')
        in_progress=$(echo "$progress" | jq -r '.in_progress')
        pending=$(echo "$progress" | jq -r '.pending')
        total=$(echo "$progress" | jq -r '.total')

        wf_batch_log "INFO" "Progress: $completed/$total completed, $in_progress running, $pending pending"
    fi

    # Check for idle workers
    idle_workers=$(jq -r '.execution.sessions | to_entries | map(select(.value.status == "idle" or .value.work_id == null)) | .[].key' "$SCHEDULE_FILE" 2>/dev/null)

    for worker in $idle_workers; do
        # Get next available work
        next_work=$(wf_batch_get_next_work)

        if [ -z "$next_work" ]; then
            if [ "$VERBOSE" = "true" ]; then
                wf_batch_log "INFO" "No available work for $worker (dependencies pending or queue empty)"
            fi
            continue
        fi

        # Try to claim the work
        if wf_batch_claim_work "$next_work" "$worker"; then
            wf_batch_log "INFO" "Assigned $next_work to $worker"

            # Signal the worker (workers poll schedule.json, no direct signaling needed)
            # The worker will pick up the assignment on its next poll
        else
            if [ "$VERBOSE" = "true" ]; then
                wf_batch_log "INFO" "Failed to claim $next_work for $worker (already claimed)"
            fi
        fi
    done

    # Check for stale running works (workers that crashed)
    running_works=$(jq -r '.works | to_entries | map(select(.value.status == "running")) | .[].key' "$SCHEDULE_FILE" 2>/dev/null)

    for work in $running_works; do
        # Find which worker has this work
        worker=$(jq -r ".execution.sessions | to_entries | map(select(.value.work_id == \"$work\")) | .[0].key // empty" "$SCHEDULE_FILE")

        if [ -n "$worker" ]; then
            # Check if worker session is still alive
            worker_num="${worker#worker-}"
            session_name="wf-batch-worker-$worker_num"

            if ! tmux has-session -t "$session_name" 2>/dev/null; then
                wf_batch_log "WARN" "Worker $worker crashed while running $work"

                # Reset work to pending
                wf_batch_update_schedule ".works[\"$work\"].status = \"pending\""
                wf_batch_release_worker "$worker"
            fi
        fi
    done

    # Check for completion
    pending_count=$(jq '[.works[] | select(.status == "pending" or .status == "running")] | length' "$SCHEDULE_FILE")

    if [ "$pending_count" -eq 0 ]; then
        wf_batch_log "INFO" "All works completed!"
        wf_batch_update_schedule '.status = "completed"'

        # Print summary
        echo ""
        echo "==================================="
        echo "Batch Execution Complete"
        echo "==================================="

        completed=$(jq '.progress.completed' "$SCHEDULE_FILE")
        failed=$(jq '[.works[] | select(.status == "failed")] | length' "$SCHEDULE_FILE")

        echo "Completed: $completed"
        if [ "$failed" -gt 0 ]; then
            echo "Failed:    $failed"
            echo ""
            echo "Failed works:"
            jq -r '.works | to_entries | map(select(.value.status == "failed")) | .[] | "  - \(.key): \(.value.error // "Unknown error")"' "$SCHEDULE_FILE"
        fi

        echo "==================================="
        exit 0
    fi

    sleep "$POLL_INTERVAL"
done
