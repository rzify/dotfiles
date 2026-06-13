#!/usr/bin/env bash
# Keep ~/Downloads tidy. Files untouched 30+ days → _archive; archive 90+ days → trash.
# Driven weekly by launchd/com.rz.clean-downloads.plist.

set -euo pipefail

DOWNLOADS="$HOME/Downloads"
ARCHIVE="$DOWNLOADS/_archive"
mkdir -p "$ARCHIVE"

# Top-level files idle 30+ days → archive (skip dotfiles and the archive itself)
find "$DOWNLOADS" -maxdepth 1 -type f -mtime +30 ! -name ".*" -exec mv -f {} "$ARCHIVE"/ \;

# Anything in archive idle 90+ days → delete
find "$ARCHIVE" -type f -mtime +90 -delete

echo "[$(date '+%Y-%m-%d %H:%M')] downloads cleaned"
