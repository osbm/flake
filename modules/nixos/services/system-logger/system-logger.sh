#!/usr/bin/env bash
set -euo pipefail

# Configuration
LOG_DIR="/var/lib/system-logger"
MAX_SIZE_MB=1
RETENTION_DAYS=30
DATE=$(date +%Y-%m-%d)
HOSTNAME=$(hostname)
TEMP_DIR=$(mktemp -d)

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Check if today's log already exists
if [ -f "$LOG_DIR/${DATE}-logs-${HOSTNAME}.zip" ]; then
    echo "Logs for today already exist. Exiting..."
    exit 0
fi

echo "Starting system log collection for $DATE"

# Function to collect logs with size limit
collect_logs() {
    local source="$1"
    local output="$2"
    local max_lines="$3"

    if [ -f "$source" ]; then
        # Get the last N lines to stay within size limit
        tail -n "$max_lines" "$source" > "$output" 2>/dev/null || true
        echo "Collected from $source"
    else
        echo "Source $source not found, skipping..."
    fi
}

# Function to get journal logs with filtering
get_journal_logs() {
    local output="$1"
    local filter="$2"
    local max_lines="$3"

    journalctl --since "00:00:00" --until "23:59:59" \
        --no-pager --output=short \
        | grep -i "$filter" | tail -n "$max_lines" > "$output" 2>/dev/null || true
    echo "Collected journal logs for $filter"
}

# Calculate approximate lines per log type to stay under 1MB
# Assuming average line is ~100 bytes, we aim for ~10,000 total lines
SSH_LINES=2000
KERNEL_LINES=2000
LOGIN_LINES=1000
SYSTEM_LINES=2000
AUTH_LINES=1000
FAILED_LOGIN_LINES=500
DISK_LINES=500
NETWORK_LINES=500
MEMORY_LINES=500

# Collect SSH connections
get_journal_logs "$TEMP_DIR/ssh.log" "sshd" "$SSH_LINES"

# Collect kernel warnings and errors
get_journal_logs "$TEMP_DIR/kernel.log" "kernel.*warning\|kernel.*error" "$KERNEL_LINES"

# Collect login/logout events
get_journal_logs "$TEMP_DIR/login.log" "session.*opened\|session.*closed\|login\|logout" "$LOGIN_LINES"

# Collect system messages
get_journal_logs "$TEMP_DIR/system.log" "systemd\|daemon" "$SYSTEM_LINES"

# Collect authentication events
get_journal_logs "$TEMP_DIR/auth.log" "authentication\|auth" "$AUTH_LINES"

# Collect failed login attempts
get_journal_logs "$TEMP_DIR/failed_login.log" "failed\|failure\|denied" "$FAILED_LOGIN_LINES"

# Collect disk usage and errors
get_journal_logs "$TEMP_DIR/disk.log" "disk\|storage\|iostat" "$DISK_LINES"

# Collect network events
get_journal_logs "$TEMP_DIR/network.log" "network\|connection\|interface" "$NETWORK_LINES"

# Collect memory usage
get_journal_logs "$TEMP_DIR/memory.log" "memory\|oom\|swap" "$MEMORY_LINES"

# Collect traditional log files if they exist
collect_logs "/var/log/auth.log" "$TEMP_DIR/auth_traditional.log" 1000
collect_logs "/var/log/syslog" "$TEMP_DIR/syslog_traditional.log" 1000
collect_logs "/var/log/messages" "$TEMP_DIR/messages_traditional.log" 1000

# Create a summary file
{
    echo "=== System Log Summary for $DATE ==="
    echo "Hostname: $HOSTNAME"
    echo "Collection time: $(date)"
    echo "Total lines collected:"
    wc -l "$TEMP_DIR"/*.log 2>/dev/null || true
    echo ""
    echo "=== System Information ==="
    echo "Uptime: $(uptime)"
    echo "Load average: $(cat /proc/loadavg)"
    echo "Memory usage:"
    free -h
    echo ""
    echo "Disk usage:"
    df -h
    echo ""
    echo "Active users:"
    who
} > "$TEMP_DIR/summary.txt"

# Create the zip file
cd "$TEMP_DIR"
zip -r "$LOG_DIR/${DATE}-logs-${HOSTNAME}.zip" ./* > /dev/null

# Check file size and warn if too large
FILE_SIZE=$(stat -c%s "$LOG_DIR/${DATE}-logs-${HOSTNAME}.zip")
FILE_SIZE_MB=$((FILE_SIZE / 1024 / 1024))

if [ "$FILE_SIZE_MB" -gt "$MAX_SIZE_MB" ]; then
    echo "WARNING: Log file size ($FILE_SIZE_MB MB) exceeds limit ($MAX_SIZE_MB MB)"
fi

echo "Log collection completed: $LOG_DIR/${DATE}-logs-${HOSTNAME}.zip ($FILE_SIZE_MB MB)"

# Clean up old logs (older than RETENTION_DAYS)
find "$LOG_DIR" -name "*-logs-*.zip" -type f -mtime +$RETENTION_DAYS -delete 2>/dev/null || true

# Clean up temporary directory
rm -rf "$TEMP_DIR"

echo "System log collection finished successfully"
