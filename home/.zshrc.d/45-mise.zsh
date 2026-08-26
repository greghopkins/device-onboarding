#
# mise — language runtime versions
#
# mise owns tool versions and PATH. direnv (85-direnv.zsh) owns per-directory
# environment variables and nothing else.
#
# That split is not a style preference, it is load-bearing: mise's maintainers
# state that mise and direnv should not be used together, because both diff the
# environment around their shell hooks and collide over PATH. Keeping direnv
# away from PATH is what makes the pair safe. See docs/mise-direnv.md.
#
# This loads BEFORE direnv on purpose, so PATH is settled before direnv layers
# environment variables on top.
#
# Replaces four overlapping version managers from the 2022 setup: asdf with
# asdf-direnv, nvm, pyenv, and sdkman.
#

if (( $+commands[mise] )); then
  eval "$(mise activate zsh)"
fi
