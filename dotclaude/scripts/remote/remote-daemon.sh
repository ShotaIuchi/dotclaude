#!/usr/bin/env bash
#
# WF Remote Daemon
# Polls GitHub Issue comments for workflow commands
#
# Usage: remote-daemon.sh <work-id>
#
# Configuration (Environment Variables):
#   POLL_INTERVAL - Polling interval in seconds (default: 60)
#   MAX_STEPS     - Maximum workflow steps before requiring restart (default: 10)
#   VERBOSE       - Enable detailed logging with remaining steps and elapsed time (default: false)
#
# Examples:
#   remote-daemon.sh FEAT-123
#   POLL_INTERVAL=30 MAX_STEPS=20 remote-daemon.sh FEAT-123
#   VERBOSE=true remote-daemon.sh FEAT-123
#

set -euo pipefail

# Directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# Load utilities
UTILS_FILE="${SCRIPT_DIR}/remote-utils.sh"
if [ ! -f "$UTILS_FILE" ]; then
    echo "ERROR: Required utility file not found: $UTILS_FILE"
    echo "Please ensure remote-utils.sh exists in the same directory as this script."
    exit 1
fi
source "$UTILS_FILE"

# Configuration (can be overridden via environment variables)
POLL_INTERVAL="${POLL_INTERVAL:-60}"
MAX_STEPS="${MAX_STEPS:-10}"
VERBOSE="${VERBOSE:-false}"
STEP_COUNT=0
START_TIME=$(date +%s)

# Work ID from argument
WORK_ID="${1:-}"

if [ -z "$WORK_ID" ]; then
    echo "ERROR: work-id is required"
    echo "Usage: remote-daemon.sh <work-id>"
    exit 1
fi

# Validate WORK_ID format (alphanumeric, hyphen, underscore only)
if ! [[ "$WORK_ID" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "ERROR: Invalid work-id format: $WORK_ID"
    echo "Work ID must contain only alphanumeric characters, hyphens, and underscores."
    exit 1
fi

# Get project root
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
STATE_FILE="$PROJECT_ROOT/.wf/state.json"

if [ ! -f "$STATE_FILE" ]; then
    echo "ERROR: state.json not found"
    exit 1
fi

# Get source issue number
SOURCE_ISSUE=$(jq -r ".works[\"$WORK_ID\"].source.issue // empty" "$STATE_FILE")

if [ -z "$SOURCE_ISSUE" ]; then
    echo "ERROR: No source issue found for $WORK_ID"
    exit 1
fi

# Validate SOURCE_ISSUE is a positive integer
if ! [[ "$SOURCE_ISSUE" =~ ^[0-9]+$ ]]; then
    echo "ERROR: Invalid source issue format: $SOURCE_ISSUE"
    echo "Source issue must be a positive integer."
    exit 1
fi

echo "==================================="
echo "WF Remote Daemon"
echo "==================================="
echo "Work ID:  $WORK_ID"
echo "Issue:    #$SOURCE_ISSUE"
echo "Interval: ${POLL_INTERVAL}s"
echo "Max steps: $MAX_STEPS"
echo "Verbose:   $VERBOSE"
echo "==================================="
echo ""

# Signal handling for graceful shutdown
cleanup() {
    echo ""
    echo "[INFO] Received shutdown signal, cleaning up..."
    wf_remote_update_status "$WORK_ID" "status" "stopped" 2>/dev/null || true
    echo "[INFO] Daemon exiting gracefully."
    exit 0
}
trap cleanup SIGTERM SIGINT

# Track last processed comment ID
# Initialize with the latest comment ID to skip existing comments
LAST_COMMENT_ID=$(wf_remote_get_latest_comment_id "$SOURCE_ISSUE" 2>/dev/null || echo "")
if [ -n "$LAST_COMMENT_ID" ]; then
    echo "[INFO] Initialized with last comment ID: $LAST_COMMENT_ID (skipping existing comments)"
fi

# Main polling loop
while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    ELAPSED_MIN=$((ELAPSED / 60))
    REMAINING_STEPS=$((MAX_STEPS - STEP_COUNT))

    if [ "$VERBOSE" = "true" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Polling issue #$SOURCE_ISSUE... (elapsed: ${ELAPSED_MIN}m, steps: $STEP_COUNT/$MAX_STEPS, remaining: $REMAINING_STEPS)"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Polling issue #$SOURCE_ISSUE..."
    fi

    # Update last_check in state.json
    wf_remote_update_status "$WORK_ID" "last_check" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    # Check for new commands
    COMMAND=$(wf_remote_check_commands "$SOURCE_ISSUE" "$LAST_COMMENT_ID")
    COMMENT_ID=$(echo "$COMMAND" | jq -r '.comment_id // empty')
    CMD_TYPE=$(echo "$COMMAND" | jq -r '.command // empty')
    CMD_AUTHOR=$(echo "$COMMAND" | jq -r '.author // empty')

    if [ -n "$CMD_TYPE" ] && [ "$CMD_TYPE" != "null" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Command detected: $CMD_TYPE (by @$CMD_AUTHOR)"

        # Verify author is a collaborator
        if ! wf_remote_is_collaborator "$CMD_AUTHOR"; then
            echo "[WARN] Ignoring command from non-collaborator: @$CMD_AUTHOR"
            LAST_COMMENT_ID="$COMMENT_ID"
            sleep "$POLL_INTERVAL"
            continue
        fi

        # Update last processed comment
        LAST_COMMENT_ID="$COMMENT_ID"

        case "$CMD_TYPE" in
            approve|next)
                if [ "$STEP_COUNT" -ge "$MAX_STEPS" ]; then
                    echo "[WARN] Maximum steps ($MAX_STEPS) reached"
                    wf_remote_post_status "$SOURCE_ISSUE" "warning" \
                        "Maximum steps ($MAX_STEPS) reached. Please restart remote monitoring."
                    wf_remote_update_status "$WORK_ID" "status" "max_steps_reached"
                else
                    STEP_COUNT=$((STEP_COUNT + 1))
                    echo "[INFO] Executing step $STEP_COUNT of $MAX_STEPS"

                    wf_remote_update_status "$WORK_ID" "status" "executing"
                    wf_remote_post_status "$SOURCE_ISSUE" "progress" \
                        "Executing step $STEP_COUNT..."

                    # Execute wf0-nextstep via Claude Code
                    if wf_remote_invoke_claude "$WORK_ID"; then
                        # Push changes
                        if wf_remote_push_changes "$WORK_ID"; then
                            wf_remote_post_step_complete "$SOURCE_ISSUE" "$WORK_ID"
                        else
                            wf_remote_post_status "$SOURCE_ISSUE" "error" \
                                "Failed to push changes"
                        fi
                    else
                        wf_remote_post_status "$SOURCE_ISSUE" "error" \
                            "Failed to execute next step"
                    fi

                    wf_remote_update_status "$WORK_ID" "status" "waiting_approval"
                fi
                ;;

            pause)
                echo "[INFO] Pausing remote monitoring"
                wf_remote_update_status "$WORK_ID" "status" "paused"
                wf_remote_post_status "$SOURCE_ISSUE" "info" \
                    "Remote monitoring paused. Use \`/approve\` to resume."
                ;;

            stop)
                echo "[INFO] Stopping remote monitoring"
                wf_remote_update_status "$WORK_ID" "status" "stopped"
                wf_remote_update_status "$WORK_ID" "enabled" "false"
                wf_remote_post_status "$SOURCE_ISSUE" "info" \
                    "Remote monitoring stopped."
                echo "[INFO] Daemon exiting..."
                exit 0
                ;;

            *)
                echo "[WARN] Unknown command: $CMD_TYPE"
                ;;
        esac

        # Check status only after command processing
        CURRENT_STATUS=$(jq -r ".works[\"$WORK_ID\"].remote.status // \"running\"" "$STATE_FILE")

        if [ "$CURRENT_STATUS" = "stopped" ]; then
            echo "[INFO] Status is 'stopped', exiting..."
            exit 0
        fi
    fi

    sleep "$POLL_INTERVAL"
done
