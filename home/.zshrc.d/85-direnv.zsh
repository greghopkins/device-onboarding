#
# direnv — per-directory environment variables
#
# Loads AFTER mise (45-mise.zsh) on purpose. mise establishes PATH; direnv then
# layers environment variables on top of a settled PATH.
#
# THE RULE: direnv must never touch PATH.
#
# mise's maintainers state that mise and direnv should not be used together —
# incompatibilities are explicitly not treated as bugs — because both tools diff
# the environment around their hooks and fight over PATH ordering. They coexist
# reliably only under a strict division of labor:
#
#   mise    tool versions and PATH          (mise.toml / .tool-versions)
#   direnv  env vars and secrets, no PATH   (.envrc)
#
# So in .envrc files, do NOT use:
#   layout python / layout node / layout ruby   -> use mise's [tools] instead
#   PATH_add <runtime bin>                      -> use mise's [tools] instead
#   use mise                                    -> deprecated and unsupported
#
# For Python virtualenvs specifically, use mise's automatic virtualenv
# activation rather than direnv's `layout python`.
#
# ~/.config/direnv/direnvrc has guards that make these mistakes loud rather
# than silent. See docs/mise-direnv.md for the full reasoning.
#
# Note: per-directory *git identity* is NOT a direnv job here. That is handled
# by git's conditional includes in ~/.gitconfig, which work regardless of which
# shell (or GUI, or IDE, or agent) invoked git. See docs/git-identity.md.
#

if (( $+commands[direnv] )); then
  eval "$(direnv hook zsh)"
fi
