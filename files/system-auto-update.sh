#!/usr/bin/env bash
# Performs an unattended package update using the configured repositories.
set -euo pipefail

LOG_FILE="${LOG_FILE:-/var/log/system-auto-update.log}"
LOCK_FILE="${LOCK_FILE:-/var/run/system-auto-update.lock}"

# Prevent overlapping runs
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') : another update is already running, exiting." >>"$LOG_FILE"
    exit 0
fi

exec >>"$LOG_FILE" 2>&1

echo "===== $(date '+%Y-%m-%d %H:%M:%S') : starting system update ====="

if command -v dnf >/dev/null 2>&1; then
    PKG_MGR="dnf"
elif command -v yum >/dev/null 2>&1; then
    PKG_MGR="yum"
else
    echo "ERROR: no supported package manager found (dnf/yum)."
    exit 1
fi

"$PKG_MGR" clean all
"$PKG_MGR" makecache
"$PKG_MGR" -y update

echo "===== $(date '+%Y-%m-%d %H:%M:%S') : update finished ====="

# Reboot if the kernel was updated (newest installed kernel differs from the running one)
RUNNING_KERNEL="$(uname -r)"
LATEST_KERNEL="$(rpm -q --last kernel | head -1 | awk '{print $1}' | sed 's/^kernel-//')"

if [ -n "$LATEST_KERNEL" ] && [ "$RUNNING_KERNEL" != "$LATEST_KERNEL" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') : kernel updated ($RUNNING_KERNEL -> $LATEST_KERNEL), rebooting."
    # Release the lock before rebooting so the next run is not blocked
    flock -u 9
    grubby --set-default-index=0
    grubby --update-kernel=ALL --default-kernel
    /sbin/shutdown -r now "Rebooting to apply updated kernel"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') : kernel unchanged ($RUNNING_KERNEL), no reboot required."
fi
