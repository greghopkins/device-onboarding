#!/usr/bin/env bash
#
# Install Prezto to ~/.zprezto.
#
# Prezto is cloned rather than installed by Homebrew because it expects to live
# in the home directory and its runcoms reference that path.
#
# Note this deliberately does NOT run Prezto's own installer, which symlinks its
# runcoms (including a .zshrc and .zpreztorc) into $HOME. Those files come from
# this repo via stow instead; letting Prezto place its own would either conflict
# with stow or silently win.

set -euo pipefail

PREZTO_DIR="$HOME/.zprezto"
PREZTO_URL="https://github.com/sorin-ionescu/prezto.git"

log()  { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33m==>\033[0m %s\n' "$*" >&2; }

if [[ -d "$PREZTO_DIR/.git" ]]; then
  log "Prezto already at $PREZTO_DIR, updating"
  git -C "$PREZTO_DIR" pull --quiet --ff-only 2>/dev/null || warn "  Pull failed, leaving as-is"
  git -C "$PREZTO_DIR" submodule update --init --recursive --quiet
else
  if [[ -e "$PREZTO_DIR" ]]; then
    warn "$PREZTO_DIR exists but is not a git checkout. Leaving it alone."
    exit 1
  fi
  log "Cloning Prezto to $PREZTO_DIR"
  # --recursive: the modules (autosuggestions, syntax-highlighting,
  # history-substring-search) are submodules. Without this they're empty dirs
  # and .zpreztorc's pmodule list fails silently.
  git clone --quiet --recursive "$PREZTO_URL" "$PREZTO_DIR"
fi

# Sanity-check the submodules that .zpreztorc depends on.
for mod in autosuggestions syntax-highlighting history-substring-search; do
  if [[ -z "$(ls -A "$PREZTO_DIR/modules/$mod/external" 2>/dev/null)" ]]; then
    warn "Module '$mod' has no external/ content; its submodule didn't check out"
  fi
done

log "Prezto ready"
