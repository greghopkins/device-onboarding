#!/usr/bin/env bash
#
# Put Homebrew on the PATH that Dock-launched GUI apps inherit (Cursor MCP,
# Claude Desktop, etc.).
#
# Separate from 'make all' because it needs sudo, and a reboot, for
# `launchctl config user path` to take effect.
#
# The integrated terminal sources .zshrc, so `uvx` works there. MCP spawn does
# not: it uses launchd's PATH (/usr/bin:/bin:/usr/sbin:/sbin). Reloading the
# Cursor window does not change that.

set -euo pipefail

GUI_PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
PLIST="/var/db/com.apple.xpc.launchd/config/user.plist"

log()  { printf '\033[36m==>\033[0m %s\n' "$*"; }

current=""
if [[ -f "$PLIST" ]]; then
  current="$(plutil -extract Path raw "$PLIST" 2>/dev/null || true)"
fi

if [[ "$current" == "$GUI_PATH" ]]; then
  log "GUI PATH already includes Homebrew (reboot if Cursor MCP still cannot find uvx)"
  exit 0
fi

log "Setting launchd user PATH (needs sudo; reboot afterwards)"
log "  $GUI_PATH"
sudo launchctl config user path "$GUI_PATH"

log "Done. Log out or reboot, then fully quit and reopen Cursor."
