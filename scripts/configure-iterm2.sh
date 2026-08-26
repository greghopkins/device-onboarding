#!/usr/bin/env bash
#
# Point iTerm2 at this repo's preferences.
#
# Rather than copying settings into iTerm's own plist, this uses iTerm's
# "Load preferences from a custom folder" feature so that iterm2/ in this repo
# IS the live configuration. Changes made in iTerm's UI are saved back here and
# show up as a git diff.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PREFS_DIR="$REPO_ROOT/iterm2"
DOMAIN="com.googlecode.iterm2"

log()  { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33m==>\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31m==>\033[0m %s\n' "$*" >&2; exit 1; }

[[ -f "$PREFS_DIR/$DOMAIN.plist" ]] || die "Missing $PREFS_DIR/$DOMAIN.plist"

plutil -lint "$PREFS_DIR/$DOMAIN.plist" >/dev/null \
  || die "$PREFS_DIR/$DOMAIN.plist is not a valid plist"

# iTerm rewrites its preferences on quit. If it's running while we change where
# it reads from, it can clobber these settings on exit.
if pgrep -xq iTerm2; then
  warn "iTerm2 is running. Quit it, then re-run 'make iterm'."
  warn "Otherwise iTerm may overwrite these settings when it exits."
fi

log "Pointing iTerm2 at $PREFS_DIR"
defaults write "$DOMAIN" PrefsCustomFolder -string "$PREFS_DIR"
defaults write "$DOMAIN" LoadPrefsFromCustomFolder -bool true

# Save changes back to the folder automatically, so UI tweaks land in git
# instead of being silently lost on the next 'make relink'.
defaults write "$DOMAIN" NoSyncNeverRemindPrefsChangesLostForFile_selection -int 2
defaults write "$DOMAIN" NoSyncNeverRemindPrefsChangesLostForFile -bool true

log "Done. Configured in $PREFS_DIR/$DOMAIN.plist:"
log "  font       FiraCodeNFM-Ret (FiraCode Nerd Font Mono Retina)"
log "  ligatures  ASCII + non-ASCII enabled"
log "  colors     One Dark"
log ""
log "iTerm only reads this at launch. Quit and reopen iTerm2 to see it."
