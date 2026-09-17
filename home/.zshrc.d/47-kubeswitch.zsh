#
# kubeswitch — switch kube context/namespace in the current shell.
#
# `switcher` is a normal binary and cannot export into the caller. Official
# setup is `source <(switcher init zsh)`, which also dumps cobra completions.
# Completions cannot live here: zplug's second `compinit` wipes them. The
# function is defined here; Tab completion binds after zplug load in
# ~/.zsh/tool-completions.zsh.
#
# oh-my-zsh `kubectl` aliases (`k`, `keti`, …) load in 48-kubectl-aliases.zsh.
# That fragment drops `kcuc` / `kcsc` / `kcn` so they cannot write the
# shared kubeconfig. Do not add `kubectx`: it is a prompt helper, and
# Starship's kubernetes module already does that.
#
# Do not `echo 'source <(switcher init zsh)' >> ~/.zshrc` — stow owns it.
# Do not alias `s=switch`; type the full command.
#
# Usage:
#   switch              fuzzy-pick a context (this shell only)
#   switch ns           fuzzy-pick a namespace
#   switch -            previous {context,namespace}
#   switch .            last used tuple (handy in a new terminal)
#
# Pair with Granted: `assume <profile>` then `switch` so EKS auth uses
# this shell's AWS_PROFILE. Default store is ~/.kube/config.
#

if (( $+commands[switcher] )); then
  # init zsh prints the function, then cobra's #compdef block. Drop the
  # completions; they are rebound after zplug load.
  source <(switcher init zsh | awk 'BEGIN{p=1} /^#compdef/{exit} p')
fi
