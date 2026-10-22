#!/usr/bin/env bash
set -euo pipefail

LOG="${TMPDIR:-/tmp}/Downloads-install.log"
: > "$LOG"
log() { echo "$*" | tee -a "$LOG"; }
trap 'rc=$?; [ $rc -ne 0 ] && { echo "FAILED (exit $rc)"; cat "$LOG"; }' EXIT

log "Started at $(date) as $(whoami)"

# Parallel downloads: add lines like these, then `wait`
# curl -fsSL --retry 3 -o "$TMPDIR/app.deb" "https://example.com/app.deb" & 
# wait

log "Installing 7-Zip..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
  --no-install-recommends p7zip-full >> "$LOG" 2>&1

log "SUCCESS at $(date)"
