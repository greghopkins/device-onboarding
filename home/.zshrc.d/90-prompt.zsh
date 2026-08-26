#
# Prompt
#
# Starship replaces Prezto's prompt module, which is why 'prompt' is absent from
# the pmodule list in .zpreztorc. Configuration and the One Dark palette live in
# ~/.config/starship.toml.
#
# Starship needs a Nerd Font to render its symbols. Both iTerm2 and Cursor's
# integrated terminal are configured with FiraCode Nerd Font Mono. If the
# prompt shows boxes or question marks, the terminal font is the cause — see
# docs/fonts.md.
#

if (( $+commands[starship] )); then
  eval "$(starship init zsh)"
fi

# Spelling-correction prompt.
#
# Prezto's prompt themes set this; Starship does not, so without it you get
# zsh's terse default. Only ever seen if CORRECT is enabled.
export SPROMPT='zsh: correct %F{red}%R%f to %F{green}%r%f [nyae]? '
