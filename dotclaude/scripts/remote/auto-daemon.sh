#!/usr/bin/env bash
#
# WF Auto Daemon
# Automatically discovers and processes GitHub Issues with auto-workflow label
#
# Usage: auto-daemon.sh [options]
#
# Options:
#   --max <N>          Maximum issues to process (default: 5)
#   --cooldown <MIN>   Cooldown between issues in minutes (default: 5)
#   --dry-run          Query issues without executing workflows
#   --once             Process once and exit (no continuous loop)
#
# Configuration (Environment Variables):
#   POLL_INTERVAL - Polling interval in seconds (default: 60)
#   MAX_ISSUES    - Maximum issues to process per session (default: 5)
#   COOLDOWN_MIN  - Cooldown between issues in minutes (default: 5)
#   VERBOSE       - Enable detailed logging (default: false)
#
# Examples:
#   auto-daemon.sh                    # Start with defaults
#   auto-daemon.sh --max 3            # Process max 3 issues
#   auto-daemon.sh --dry-run          # List issues without executing
#   auto-daemon.sh --once --max 1     # Process 1 issue and exit
#

set -euo pipefail

# Directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# Load utilities
UTILS_FILE="${SCRIPT_DIR}/auto-utils.sh"
if [ ! -f "$UTILS_FILE" ]; then
    echo "ERROR: Required utility file not found: $UTILS_FILE"
    echo "Please ensure auto-utils.sh exists in the same directory as this script."
    exit 1
fi
source "$UTILS_FILE"

# Default configuration
POLL_INTERVAL="${POLL_INTERVAL:-60}"
MAX_ISSUES="${MAX_ISSUES:-5}"
COOLDOWN_MIN="${COOLDOWN_MIN:-5}"
VERBOSE="${VERBOSE:-false}"
DRY_RUN=false
RUN_ONCE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --max)
            MAX_ISSUES="$2"
            shift 2
            ;;
        --cooldown)
            COOLDOWN_MIN="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --once)
            RUN_ONCE=true
            shift
            ;;
        --help|-h)
            head -30 "$0" | tail -n +2 | sed 's/^# //' | sed 's/^#//'
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Get project root
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

# Get configuration from config.json
QUERY_LABEL=$(wf_auto_get_config "auto.query" "auto-workflow")
# Extract label name if format is "label:xxx"
QUERY_LABEL="${QUERY_LABEL#label:}"

EXCLUDE_LABELS=$(wf_auto_get_config "auto.exclude_labels" "blocked,wip")
# Convert JSON array to comma-separated if needed
if [[ "$EXCLUDE_LABELS" == "["* ]]; then
    EXCLUDE_LABELS=$(echo "$EXCLUDE_LABELS" | jq -r 'join(",")')
fi

COMPLETE_LABEL=$(wf_auto_get_config "auto.complete_label" "completed")

echo "==================================="
echo "WF Auto Daemon"
echo "==================================="
echo "Project:     $PROJECT_ROOT"
echo "Query:       label:$QUERY_LABEL"
echo "Exclude:     $EXCLUDE_LABELS"
echo "Complete:    $COMPLETE_LABEL"
echo "Max issues:  $MAX_ISSUES"
echo "Cooldown:    ${COOLDOWN_MIN}m"
echo "Poll:        ${POLL_INTERVAL}s"
echo "Dry run:     $DRY_RUN"
echo "Run once:    $RUN_ONCE"
echo "==================================="
echo ""

# Initialize state
PROCESSED_COUNT=0
START_TIME=$(date +%s)

# Update state file
wf_auto_update_state "enabled" "true"
wf_auto_update_state "session_start" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
wf_auto_update_state "processed_count" "0"
wf_auto_update_state "tmux_session" "wf-auto"

# Signal handling for graceful shutdown
cleanup() {
    echo ""
    echo "[INFO] Received shutdown signal, cleaning up..."
    wf_auto_update_state "enabled" "false"
    wf_auto_update_state "current_issue" "null"
    echo "[INFO] Auto daemon exiting gracefully."
    exit 0
}
trap cleanup SIGTERM SIGINT

# Main loop
process_issues() {
    while true; do
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Querying issues with label:$QUERY_LABEL..."

        # Query issues
        local issues
        issues=$(wf_auto_query_issues "$QUERY_LABEL" "$COMPLETE_LABEL,$EXCLUDE_LABELS")

        local issue_count
        issue_count=$(echo "$issues" | jq 'length')

        if [ "$issue_count" -eq 0 ]; then
            echo "[INFO] No pending issues found"

            if [ "$RUN_ONCE" = true ]; then
                echo "[INFO] Run-once mode, exiting"
                break
            fi

            sleep "$POLL_INTERVAL"
            continue
        fi

        echo "[INFO] Found $issue_count pending issue(s)"

        if [ "$VERBOSE" = "true" ]; then
            echo "$issues" | jq -r '.[] | "  #\(.number): \(.title)"'
        fi

        # Check if we've hit the limit
        if [ "$PROCESSED_COUNT" -ge "$MAX_ISSUES" ]; then
            echo "[INFO] Reached maximum issues ($MAX_ISSUES), stopping"
            break
        fi

        # Pick next issue
        local issue_num
        issue_num=$(wf_auto_pick_next "$issues")

        if [ -z "$issue_num" ]; then
            echo "[WARN] Failed to pick next issue"
            sleep "$POLL_INTERVAL"
            continue
        fi

        echo "[INFO] Processing issue #$issue_num..."

        # Update state
        wf_auto_update_state "current_issue" "$issue_num"

        if [ "$DRY_RUN" = true ]; then
            echo "[DRY-RUN] Would process issue #$issue_num"
            echo "[DRY-RUN] Would create branch and execute workflow"
            echo "[DRY-RUN] Would mark as $COMPLETE_LABEL on success"
            PROCESSED_COUNT=$((PROCESSED_COUNT + 1))
            wf_auto_update_state "processed_count" "$PROCESSED_COUNT"

            if [ "$RUN_ONCE" = true ]; then
                break
            fi

            sleep "$POLL_INTERVAL"
            continue
        fi

        # Create branch
        local branch
        if ! branch=$(wf_auto_create_branch "$issue_num"); then
            echo "[ERROR] Failed to create branch for issue #$issue_num"
            wf_auto_mark_failed "$issue_num" "Failed to create branch"
            wf_auto_update_state "current_issue" "null"

            # Continue to next issue
            sleep "$POLL_INTERVAL"
            continue
        fi

        echo "[INFO] Created branch: $branch"

        # Extract work-id from branch
        local work_id
        work_id="${branch#*/}"

        # Execute workflow
        if wf_auto_execute_workflow "$issue_num" "$work_id"; then
            echo "[INFO] Workflow completed for issue #$issue_num"

            # Push changes
            if wf_auto_push_changes; then
                # Mark as complete
                wf_auto_mark_complete "$issue_num" "$COMPLETE_LABEL"
                PROCESSED_COUNT=$((PROCESSED_COUNT + 1))
                wf_auto_update_state "processed_count" "$PROCESSED_COUNT"
            else
                echo "[WARN] Failed to push changes for issue #$issue_num"
                wf_auto_mark_failed "$issue_num" "Failed to push changes"
            fi
        else
            echo "[ERROR] Workflow failed for issue #$issue_num"
            wf_auto_mark_failed "$issue_num" "Workflow execution failed"

            # Clean up branch on failure
            wf_auto_cleanup_branch "$branch"
        fi

        wf_auto_update_state "current_issue" "null"

        if [ "$RUN_ONCE" = true ]; then
            break
        fi

        # Check if we've hit the limit
        if [ "$PROCESSED_COUNT" -ge "$MAX_ISSUES" ]; then
            echo "[INFO] Reached maximum issues ($MAX_ISSUES), stopping"
            break
        fi

        # Cooldown before next issue
        echo "[INFO] Cooling down for ${COOLDOWN_MIN} minutes..."
        sleep "$((COOLDOWN_MIN * 60))"
    done
}

# Run the processor
process_issues

# Final stats
CURRENT_TIME=$(date +%s)
ELAPSED=$((CURRENT_TIME - START_TIME))
ELAPSED_MIN=$((ELAPSED / 60))

echo ""
echo "==================================="
echo "Session Complete"
echo "==================================="
echo "Processed:   $PROCESSED_COUNT issue(s)"
echo "Duration:    ${ELAPSED_MIN}m"
echo "==================================="

# Clean up state
wf_auto_update_state "enabled" "false"
wf_auto_update_state "current_issue" "null"
