#
# git shell integration
#
# Note this is only about the *shell* side of git. Config lives in ~/.gitconfig,
# and the per-org author identity is handled by git's own conditional includes —
# see docs/git-identity.md. The 2022 setup used a .envrc per org directory for
# that, which only worked inside an interactive shell.
#

# Speeds up git completion noticeably in large repos by not trying to compute
# every possible completion candidate.
#
# The trade-off: completion for some git subcommands becomes less clever, since
# it falls back to plain file completion. Remove this function to get the full
# (slower) behavior back.
__git_files() {
  _wanted files expl 'local files' _files
}

# Let git see glob characters instead of having zsh expand them first, so
# `git add *foo*` reaches git intact and git's own pathspec matching applies.
#
# Downside: zsh no longer errors on a glob that matches nothing, git does.
alias git='noglob git'
