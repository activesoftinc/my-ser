#!/usr/bin/env bash
set -euo pipefail

LOG="${TMPDIR:-/tmp}/Downloads-install.log"
DESKTOP_DIR="/usr/share/applications"

: > "$LOG"
log() { echo "$*" | tee -a "$LOG"; }

trap 'rc=$?; if [ $rc -ne 0 ]; then
  echo "FAILED at $(date) (exit $rc)" | tee -a "$LOG"
  echo "===== Installer log ====="; cat "$LOG"
fi' EXIT

echo "=========================================="
echo "  Downloads and Installation"
echo "=========================================="
log "Current user: $(whoami)"
log "Log file: $LOG"
log "Started at $(date)"

command -v curl >/dev/null || { log "ERROR: curl is not available."; exit 1; }

# download <url> <output-file>  (3 attempts)
download() {
  local url="$1" out="$2" attempt
  log "Downloading: $url"
  for attempt in 1 2 3; do
    log "Attempt $attempt of 3..."
    rm -f "$out"
    if curl --fail --location --show-error \
         --connect-timeout 20 --max-time 240 \
         --retry 2 --retry-delay 3 \
         --output "$out" "$url" >> "$LOG" 2>&1 && [ -s "$out" ]; then
      log "Download successful: $out ($(stat -c%s "$out") bytes)"
      return 0
    fi
    log "Download attempt failed."
    rm -f "$out"
    sleep 3
  done
  log "ERROR: Download failed after 3 attempts."
  return 1
}

# install_apt <package...>  (180s timeout)
install_apt() {
  log "Installing: $*"
  sudo apt-get update >> "$LOG" 2>&1
  if ! sudo DEBIAN_FRONTEND=noninteractive timeout 180 \
       apt-get install -y "$@" >> "$LOG" 2>&1; then
    log "ERROR: Installation failed or timed out: $*"
    return 1
  fi
  log "Installed: $*"
}

echo
echo "[1/1] Installing 7-Zip..."
install_apt p7zip-full
7z i >/dev/null 2>&1 || 7z | head -n 2 | tee -a "$LOG"

# Example of using download() for a .deb package:
# download "https://example.com/app.deb" "$TMPDIR/app.deb"
# sudo apt-get install -y "$TMPDIR/app.deb"

echo
echo "=========================================="
echo "  All requested steps completed."
echo "=========================================="
echo "7-Zip installed successfully."
log "SUCCESS at $(date)"
