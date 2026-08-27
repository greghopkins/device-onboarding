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

  # `assume` is a function (46-granted.zsh), not Granted's zshenv alias.
  # Bind after zplug's second compinit; `granted completion -s zsh` is not
  # used because it writes ~/.zshenv.
  if (( $+functions[assume] )) && [[ -z ${_onboarding_assume_comp:-} ]]; then
    _onboarding_assume() {
      local -a profiles
      profiles=(${(f)"$(aws configure list-profiles 2>/dev/null)"})
      _describe 'AWS profile' profiles
    }
    compdef _onboarding_assume assume
    _onboarding_assume_comp=1
  fi
}

_onboarding_register_tool_completions

autoload -Uz add-zsh-hook
add-zsh-hook chpwd _onboarding_register_tool_completions
