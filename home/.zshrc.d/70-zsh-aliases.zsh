#
# zsh-specific aliases and functions
#
# Global aliases (alias -g) expand anywhere on the line, not just in command
# position. They are genuinely useful shorthand and also the single most
# surprising thing in this config for anyone else using your shell — a stray
# capital G in a filename or argument will silently become `| grep`.
#
# Drop the `alias -g` block if that ever bites you.
#

# --- directory traversal -----------------------------------------------------
# Prezto's editor dot-expansion already turns .... into ../.., so these are
# belt-and-braces for the cases expansion doesn't cover.
alias -g ...='../..'
alias -g ....='../../..'
alias -g .....='../../../..'

# --- pipe shorthands ---------------------------------------------------------
alias -g G='| grep'          # ls foo G something
alias -g H='| head'
alias -g L='| less'
alias -g S='| sort'
alias -g C='| wc -l'
alias -g N='| /dev/null'     # note: this pipes INTO /dev/null as a command,
                             # which is not the same as `> /dev/null`. Kept as
                             # it was in 2022; use `>/dev/null` if you want
                             # redirection.

# --- functions ---------------------------------------------------------------

# (f)ind by (n)ame — recursive glob for a substring.
# `fd` does this better and faster (fd foo). Kept for muscle memory.
function fn() { ls **/*$1* }
