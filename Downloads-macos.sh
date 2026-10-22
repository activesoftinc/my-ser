#!/usr/bin/env bash
set -euo pipefail

LOG="${TMPDIR:-/tmp}/Downloads-install.log"
: > "$LOG"
log() { echo "$*" | tee -a "$LOG"; }

trap 'rc=$?; if [ $rc -ne 0 ]; then
  echo "FAILED at $(date) (exit $rc)"; cat "$LOG"
fi' EXIT

log "Started at $(date) as $(whoami)"
command -v brew >/dev/null || { log "ERROR: Homebrew not found."; exit 1; }

log "[1/1] Installing 7-Zip..."
brew install sevenzip >> "$LOG" 2>&1
log "7-Zip installed."

# Example cask install:
# brew install --cask telegram >> "$LOG" 2>&1

log "SUCCESS at $(date)"
