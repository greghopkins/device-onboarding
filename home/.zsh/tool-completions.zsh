#
# Completions for CLIs that use bash-style `complete -C`.
#
# Sourced from ~/.zshrc AFTER `zplug load`. It cannot live in .zshrc.d:
# zplug's loader runs `compinit` a second time after sourcing plugins
# (see __zplug::core::load::from_cache), which rebuilds `_comps` and
# throws away any `compdef` that ran in a fragment. That is why
# `exec zsh` still Tab-completed `aws e` as files: the bind happened,
# then zplug wiped it, and chpwd never fired because the directory
# did not change.
#
# AWS CLI v2 ships `aws_completer`. Official snippet:
#   autoload bashcompinit && bashcompinit
#   complete -C aws_completer aws
# The oh-my-zsh aws plugin runs that during zplug load, before mise
# activate and before this file, so it never sees aws_completer.
#
# aws is a global mise tool (~/.config/mise/config.toml), so the
# completer is on PATH in every directory. terraform/kubectl stay
# project-scoped; those binds also run from chpwd once mise adds them.
#

autoload -Uz bashcompinit
bashcompinit

# typeset -g: this file is sourced from .zshrc at top level, but
# chpwd runs inside a hook. omz plugins use the same -g for _comps.
typeset -g -A _comps

# urfave/cli zsh autocomplete, with $words[1] swapped for the real binary.
# See github.com/urfave/cli autocomplete/zsh_autocomplete. Call assumego,
# not the `assume` function: sourcing the wrapper during Tab would mutate
# AWS_* in the current shell.
_onboarding_granted_cli() {
  local bin=$1
  local -a opts words_copy
  local cur=${words[-1]}
  words_copy=("${words[@]}")
  words_copy[1]=$bin
  if [[ "$cur" == -* ]]; then
    opts=("${(@f)$(
      GRANTED_ALIAS_CONFIGURED=true GRANTED_QUIET=true \
      _CLI_ZSH_AUTOCOMPLETE_HACK=1 \
        "${words_copy[@]:0:#words_copy[@]-1}" "$cur" --generate-bash-completion 2>/dev/null
    )}")
  else
    opts=("${(@f)$(
      GRANTED_ALIAS_CONFIGURED=true GRANTED_QUIET=true \
      _CLI_ZSH_AUTOCOMPLETE_HACK=1 \
        "${words_copy[@]:0:#words_copy[@]-1}" --generate-bash-completion 2>/dev/null
    )}")
  fi
  (( $#opts )) || return 1
  _describe 'values' opts
}

_onboarding_assume()  { _onboarding_granted_cli assumego }
_onboarding_granted() { _onboarding_granted_cli granted }

_onboarding_register_tool_completions() {
  if (( $+commands[aws_completer] )) && [[ -z ${_onboarding_aws_comp:-} ]]; then
    complete -C aws_completer aws
    _onboarding_aws_comp=1
  fi

  if (( $+commands[terraform] )) && [[ -z ${_onboarding_tf_comp:-} ]]; then
    complete -C terraform terraform
    _onboarding_tf_comp=1
  fi

  if [[ -z "${CURSOR_AGENT:-}" ]] \
     && (( $+commands[kubectl] )) \
     && [[ -z ${_onboarding_kubectl_comp:-} ]]; then
    source <(kubectl completion zsh)
    _onboarding_kubectl_comp=1
  fi

  # Granted's Homebrew formula ships no zsh completions. `granted completion
  # -s zsh` writes fpath into ~/.zshenv, which we refuse. Bind after zplug's
  # second compinit instead.
  if (( $+commands[assumego] )) && [[ -z ${_onboarding_assume_comp:-} ]]; then
    compdef _onboarding_assume assume
    compdef _onboarding_granted granted
    _onboarding_assume_comp=1
  fi
}

_onboarding_register_tool_completions

autoload -Uz add-zsh-hook
add-zsh-hook chpwd _onboarding_register_tool_completions
