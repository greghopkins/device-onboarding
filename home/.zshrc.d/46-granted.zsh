#
# Granted — switch AWS SSO profiles in the current shell.
#
# `assumego` is a normal binary and cannot export into the caller. Homebrew
# ships a small wrapper at $HOMEBREW_PREFIX/bin/assume that prints a
# GrantedAssume line; sourcing it is what sets AWS_PROFILE / session keys
# so Starship's aws module and the AWS CLI both see the change.
#
# Granted's first-run installer wants to write
#   alias assume="source .../assume"
# into ~/.zshenv. That file runs for every zsh, including scripts and
# Cursor agent snapshots. We own the bind here instead: a function so Tab
# completion can attach to `assume` rather than `source`, and
# GRANTED_ALIAS_CONFIGURED so the binary never rewrites zshenv.
#
# The wrapper unsets GRANTED_ALIAS_CONFIGURED on the way out; put it back
# so a later `assume` in the same session still skips the installer.
#
# Usage:
#   assume                  fuzzy-pick a profile (SSO login if needed)
#   assume prod-readonly    set that profile
#   assume -c               open the AWS console for the current/picked profile
#   assume -u               clear Granted's env vars
#
# Do not run `granted completion -s zsh`: it appends fpath to ~/.zshenv.
# Flag/profile completions call assumego --generate-bash-completion from
# ~/.zsh/tool-completions.zsh after zplug load.
#

if (( $+commands[assumego] )); then
  export GRANTED_ALIAS_CONFIGURED=true

  assume() {
    source "${HOMEBREW_PREFIX:-/opt/homebrew}/bin/assume" "$@"
    export GRANTED_ALIAS_CONFIGURED=true
  }
fi
