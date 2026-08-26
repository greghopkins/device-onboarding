#
# Key bindings
#
# Nearly all of the 2022 file is gone, and intentionally so. It ran
# `bindkey -v` (already set by Prezto's editor module in .zpreztorc) and then
# rebound ^a, ^e and ^r to emacs behavior — a vi mode with emacs habits bolted
# on top. Bindings are now vi, set once, in .zpreztorc.
#
# What was dropped and where it went:
#   bindkey -v   now .zpreztorc `key-bindings 'vi'`
#   ^a / ^e      removed; use vi normal mode (0 / $)
#   ^r           provided by Prezto's history-substring-search module
#
# Only the numpad fix survives, since nothing else provides it.
#

# Make numpad Enter and the decimal key send what they should, instead of the
# raw escape sequences some terminals emit. Harmless on a keyboard with no
# numpad — drop it if you never use one.
bindkey -s '^[Op' '0'
bindkey -s '^[Ol' '.'
bindkey -s '^[OM' '^M'
