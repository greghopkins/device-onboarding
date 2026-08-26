#!/usr/bin/env bash
#
# Install iTerm2's shell integration and its it2* utilities from upstream.
#
# The 2022 dotfiles repo committed a snapshot of these — the integration script
# plus 15 helpers — which is exactly what docs/dotfiles-audit.md rejected. They
# are fetched here instead, so what lands is current rather than a copy aging in
# git.
#
# What the integration buys, none of which Starship provides: OSC 133 marks, so
# iTerm2 knows where prompts and command output begin and end. That powers
# cmd-shift-up/down to jump between prompts, "Select Output of Last Command",
# clickable marks, and the status bar's current-directory and command fields.
# Verified against `starship init zsh --print-full-init`, which emits no 133
# sequences at all.
#
# This deliberately does NOT use upstream's
# install_shell_integration_and_utilities.sh. That script appends a source line
# and 16 aliases to ~/.zshrc, which stow owns here — it would either be clobbered
# on the next `make link` or fight with it. The sourcing lives in
# home/.zshrc.d/92-iterm.zsh instead.

set -euo pipefail

INTEGRATION="$HOME/.iterm2_shell_integration.zsh"
UTIL_DIR="$HOME/.iterm2"
BASE_URL="https://iterm2.com"

# Upstream's own list, from install_shell_integration_and_utilities.sh. it2cat is
# newer than the 2022 snapshot, which is the argument for fetching over vendoring.
UTILITIES=(
  imgcat imgls it2api it2attention it2cat it2check it2copy it2dl it2getvar
  it2git it2profile it2setcolor it2setkeylabel it2tip it2ul it2universion
)

log()  { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33m==>\033[0m %s\n' "$*" >&2; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

log "Fetching the zsh shell integration"
if ! curl -fsSL --retry 2 -o "$tmp/integration.zsh" "$BASE_URL/shell_integration/zsh"; then
  warn "Download failed. Leaving any existing integration in place."
  exit 1
fi

# A captive portal or proxy returns 200 with an HTML body, which would install
# cleanly and then break every shell start. Check for a marker the real script
# always emits.
if ! grep -q 'ShellIntegrationVersion' "$tmp/integration.zsh"; then
  warn "Downloaded file is not the integration script (no version marker)."
  warn "  Got $(wc -c <"$tmp/integration.zsh" | tr -d ' ') bytes; check for a proxy."
  exit 1
fi

# Move into place only after validating, so a bad fetch cannot replace a good copy.
mv "$tmp/integration.zsh" "$INTEGRATION"
log "  $INTEGRATION ($(wc -c <"$INTEGRATION" | tr -d ' ') bytes)"

log "Fetching utilities to $UTIL_DIR"
mkdir -p "$UTIL_DIR"
failed=()
for util in "${UTILITIES[@]}"; do
  if curl -fsSL --retry 2 -o "$tmp/$util" "$BASE_URL/utilities/$util" \
     && [[ -s "$tmp/$util" ]]; then
    mv "$tmp/$util" "$UTIL_DIR/$util"
    chmod +x "$UTIL_DIR/$util"
  else
    failed+=("$util")
  fi
done

if (( ${#failed[@]} )); then
  warn "  Could not fetch: ${failed[*]}"
  warn "  The rest installed; re-run to retry."
else
  log "  ${#UTILITIES[@]} utilities installed"
fi

log "iTerm2 shell integration ready"
echo
echo "Open a new iTerm2 tab to load it. The utilities are on PATH via"
echo "~/.zshrc.d/92-iterm.zsh, which only activates inside iTerm2."
