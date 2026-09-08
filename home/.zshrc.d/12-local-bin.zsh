#
# User-local binaries (XDG / pipx / official TWG installer).
#
# Homebrew stays first on PATH via .zshrc. This only adds ~/.local/bin so
# `twg` (and anything else that installs there) resolves without the
# Teamwork Graph installer rewriting ~/.zshrc, which stow owns.
#

if [[ -d "$HOME/.local/bin" ]]; then
  path=("$HOME/.local/bin" $path)
fi
