#
# Directory jumping
#
# Replaces fasd, which has been unmaintained since 2020. The 2022 setup used
# the oh-my-zsh fasd plugin plus a fragment defining a/s/d/f/z/zz.
#
# zoxide covers the common case (jump to a frecent directory) but not all of
# fasd's modes — fasd could match files as well as directories, hence the old
# a/s/f aliases. Those have no zoxide equivalent; use fzf for file finding.
#

if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh)"

  # zoxide init already defines `z` and `zi`. These keep the old names working:
  #   z   jump to a directory (same name fasd used)
  #   zz  interactive picker (was fasd_cd -d -i)
  alias zz='zi'
fi
