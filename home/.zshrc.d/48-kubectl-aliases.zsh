#
# oh-my-zsh kubectl aliases (`k`, `keti`, `kgp`, …).
#
# Declared in .zshrc as zplug "plugins/kubectl". The plugin file returns
# immediately if kubectl is not on PATH, and zplug loads before mise
# activate, so the aliases often never bind. Source it here once mise
# has put kubectl on PATH. Re-sourcing is cheap: it is all aliases.
#
# Drop the aliases that write kubeconfig. `.zshrc` repeats the unalias
# after zplug load — this fragment can run before plugins/kubectl.
#

_omz_kubectl="${ZPLUG_REPOS:-$HOME/.zplug/repos}/robbyrussell/oh-my-zsh/plugins/kubectl/kubectl.plugin.zsh"

if (( $+commands[kubectl] )) && [[ -r "$_omz_kubectl" ]]; then
  if ! alias k >/dev/null 2>&1; then
    source "$_omz_kubectl"
  fi
  unalias kcuc kcsc kcn 2>/dev/null
fi

unset _omz_kubectl
