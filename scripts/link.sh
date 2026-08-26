#!/usr/bin/env bash
#
# Symlink home/ into $HOME with stow.
#
# Two things this handles that a bare 'stow home' does not:
#
#   1. --no-folding. Without it, stow symlinks whole DIRECTORIES when the target
#      doesn't exist yet. ~/.config would become a symlink into this repo, so
#      every app that writes to ~/.config would be writing into a git working
#      tree. --no-folding creates real directories and links only files.
#
#   2. Pre-existing real files. stow refuses to overwrite them and aborts the
#      whole operation. Anything in the way is moved to <name>.pre-onboarding
#      first, so nothing is destroyed and the original is recoverable.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKG="home"
PKG_DIR="$REPO_ROOT/$PKG"

log()  { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33m==>\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31m==>\033[0m %s\n' "$*" >&2; exit 1; }

command -v stow >/dev/null || die "stow not found. Run 'make brew' first."
[[ -d "$PKG_DIR" ]] || die "Missing $PKG_DIR"

# --- move conflicting real files aside ---------------------------------------

log "Checking for existing files"
moved=0
while IFS= read -r -d '' src; do
  rel="${src#"$PKG_DIR"/}"
  # Configures stow itself; never linked into $HOME.
  [[ "$rel" == ".stow-local-ignore" ]] && continue
  dest="$HOME/$rel"

  # A symlink already pointing into this repo is ours; leave it.
  if [[ -L "$dest" ]]; then
    target="$(readlink "$dest")"
    case "$target" in
      "$PKG_DIR"/*|*/"$PKG"/"$rel") continue ;;
    esac
    warn "  $rel is a symlink elsewhere ($target), moving aside"
  elif [[ ! -e "$dest" ]]; then
    continue
  fi

  backup="$dest.pre-onboarding"
  n=1
  while [[ -e "$backup" ]]; do backup="$dest.pre-onboarding.$n"; n=$((n+1)); done
  mv "$dest" "$backup"
  warn "  $rel -> $(basename "$backup")"
  moved=$((moved+1))
done < <(find "$PKG_DIR" -type f -print0)

if (( moved )); then
  log "Moved $moved existing file(s) aside"
else
  log "  Nothing in the way"
fi

# --- stow --------------------------------------------------------------------

log "Linking $PKG -> $HOME"
stow --dir="$REPO_ROOT" --target="$HOME" --no-folding --restow "$PKG"

log "Done. Run 'make doctor' to verify."
