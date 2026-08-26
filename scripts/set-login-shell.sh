#!/usr/bin/env bash
#
# Make Homebrew's zsh the login shell.
#
# This is a separate make target rather than part of 'make all' because it needs
# sudo to edit /etc/shells, and 'make all' should never prompt for a password.
#
# macOS ships its own zsh, so this is not strictly required — the config in this
# repo works with either. Homebrew's is simply newer.

set -euo pipefail

BREW_ZSH="/opt/homebrew/bin/zsh"

log()  { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33m==>\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31m==>\033[0m %s\n' "$*" >&2; exit 1; }

[[ -x "$BREW_ZSH" ]] || die "$BREW_ZSH not found. Run 'make brew' first."

current="$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')"

if [[ "$current" == "$BREW_ZSH" ]]; then
  log "Login shell is already $BREW_ZSH"
  exit 0
fi

log "Current login shell: $current"

# chsh refuses any shell not listed in /etc/shells.
if grep -qxF "$BREW_ZSH" /etc/shells 2>/dev/null; then
  log "$BREW_ZSH already in /etc/shells"
else
  log "Adding $BREW_ZSH to /etc/shells (needs sudo)"
  echo "$BREW_ZSH" | sudo tee -a /etc/shells >/dev/null
fi

log "Changing login shell (you may be prompted for your password)"
chsh -s "$BREW_ZSH"

log "Done. Open a new terminal, or run: exec $BREW_ZSH -l"
