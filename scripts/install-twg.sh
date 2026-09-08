#!/usr/bin/env bash
#
# Install the Atlassian Teamwork Graph CLI (`twg`).
#
# There is no Homebrew formula. Atlassian retired the beta tap and ships a
# curl installer that writes ~/.local/bin/twg. Login and skill install open a
# browser, so this script only places the binary. Run `twg setup` once in a
# real terminal after `make twg`.
#
# The official installer will append a PATH line to ~/.zshrc unless
# ~/.local/bin is already on PATH. Stow owns ~/.zshrc, so we export that
# directory first. Persistent PATH is home/.zshrc.d/12-local-bin.zsh.

set -euo pipefail

INSTALL_DIR="${HOME}/.local/bin"
INSTALL_URL="https://teamwork-graph.atlassian.com/cli/install"

log()  { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33m==>\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31m==>\033[0m %s\n' "$*" >&2; exit 1; }

if [[ -z "${TWG_FORCE:-}" && -x "${INSTALL_DIR}/twg" ]]; then
  log "twg already installed at ${INSTALL_DIR}/twg"
  exit 0
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

log "Fetching the official TWG installer"
curl -fsSL --retry 2 -o "$tmp/install" "$INSTALL_URL" \
  || die "Download failed from $INSTALL_URL"

# Captive portals return 200 with HTML. The real installer is a bash script
# that names the public CDN in the first screenful.
if ! grep -q 'teamwork-graph.atlassian.com/cli' "$tmp/install"; then
  die "Installer download did not look like the TWG script; not running it"
fi

# Already on PATH so the installer does not write into stowed ~/.zshrc.
export PATH="${INSTALL_DIR}:${PATH}"

log "Installing twg to ${INSTALL_DIR}"
bash "$tmp/install" --yes --skip-login --skip-skills --plugin cursor

[[ -x "${INSTALL_DIR}/twg" ]] || die "Installer finished but ${INSTALL_DIR}/twg is missing"

log "Done. In a real terminal run: twg setup"
