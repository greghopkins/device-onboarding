#!/usr/bin/env bash
#
# Install kubeswitch (`switcher` binary). The `switch` command is a sourced
# shell function (home/.zshrc.d/47-kubeswitch.zsh), same shape as `assume`.
#
# Not Homebrew: the official tap is danielfoehrkn/switch and current Homebrew
# refuses to load it without `brew trust`. The GitHub release is first-party
# and lands in ~/.local/bin next to twg. PATH is 12-local-bin.zsh.
#
# Do not append `source <(switcher init zsh)` to ~/.zshrc — stow owns that file.

set -euo pipefail

VERSION="0.9.3"
INSTALL_DIR="${HOME}/.local/bin"

log()  { printf '\033[36m==>\033[0m %s\n' "$*"; }
die()  { printf '\033[31m==>\033[0m %s\n' "$*" >&2; exit 1; }

arch="$(uname -m)"
case "$arch" in
  arm64)  asset="switcher_darwin_arm64" ;;
  x86_64) asset="switcher_darwin_amd64" ;;
  *)      die "Unsupported architecture: $arch" ;;
esac

if [[ -z "${KUBESWITCH_FORCE:-}" && -x "${INSTALL_DIR}/switcher" ]]; then
  log "switcher already installed at ${INSTALL_DIR}/switcher"
  exit 0
fi

url="https://github.com/danielfoehrKn/kubeswitch/releases/download/${VERSION}/${asset}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

log "Fetching kubeswitch ${VERSION} (${asset})"
curl -fsSL --retry 5 --retry-delay 2 --retry-all-errors -o "$tmp/switcher" "$url" \
  || die "Download failed from $url"

# Captive portals return 200 with HTML. The real binary is a Mach-O.
if ! file "$tmp/switcher" | grep -q 'Mach-O'; then
  die "Download did not look like a Mach-O binary; not installing it"
fi

mkdir -p "$INSTALL_DIR"
chmod +x "$tmp/switcher"
mv "$tmp/switcher" "${INSTALL_DIR}/switcher"

"${INSTALL_DIR}/switcher" version >/dev/null \
  || die "switcher ran but version failed"

log "Done. New shells get \`switch\` from 47-kubeswitch.zsh (run make link)."
