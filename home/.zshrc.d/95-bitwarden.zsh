#
# SSH agent
#
# The Bitwarden desktop app exposes an SSH agent over this socket, so private
# keys live in the vault instead of on disk. This is the one line that was in
# ~/.zshrc before this repo existed.
#
# This is why Prezto's `ssh` module is not loaded (see .zpreztorc) and why the
# 2022 repo's .ssh/config, its two committed public keys, and its GPG-encrypted
# private keys were all dropped: starting a second agent would compete for
# SSH_AUTH_SOCK.
#
# If the socket is missing, the Bitwarden app either isn't running or doesn't
# have the SSH agent enabled in its settings.
#

if [[ -S "$HOME/.bitwarden-ssh-agent.sock" ]]; then
  export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"
fi
