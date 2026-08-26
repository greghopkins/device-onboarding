#
# iTerm2 shell integration
#
# Installed by 'make iterm-integration' (scripts/install-iterm-integration.sh),
# not by this file — it is fetched from upstream at install time rather than
# vendored. See docs/dotfiles-audit.md.
#
# Numbered 92 to land AFTER 90-prompt.zsh, and that ordering is load-bearing.
# The integration appends iterm2_precmd to precmd_functions, so it runs after
# Starship's precmd and therefore sees the prompt Starship just assigned, wraps
# it, and stores the result to compare against next time. Sourced BEFORE Starship
# it would decorate a prompt that Starship then overwrites, and the OSC 133 marks
# would silently vanish. (In zsh, PROMPT and PS1 are the same parameter, which is
# why the integration reading $PS1 sees Starship's work at all.)
#
# Starship emits no 133 sequences itself, so nothing here is redundant.
#

# Only inside iTerm2. The upstream script guards on $TERM and interactivity but
# not on which terminal is attached, so without this it also runs in Cursor's
# integrated terminal and Terminal.app, emitting iTerm-specific escapes at
# emulators that did not ask for them. Cursor ships its own shell integration and
# is the case that actually matters here.
#
# LC_TERMINAL is checked too: iTerm2 forwards it over ssh, where TERM_PROGRAM is
# not inherited.
#
# CURSOR_AGENT is a second gate, and it is not redundant with TERM_PROGRAM.
# Cursor agent shells spawned from iTerm inherit TERM_PROGRAM=iTerm.app (and
# often LC_TERMINAL), so the check above still matches. The integration then
# poisons Cursor's zsh snapshot: iterm2_precmd / precmd wrapping leaves
# dump_zsh_state undefined and produces `(eval):… parse error near '()'` on
# every agent command. Skip sourcing so Cursor's own injector can define that
# function. Utilities on PATH are harmless and stay.
if [[ "$TERM_PROGRAM" == "iTerm.app" || "$LC_TERMINAL" == "iTerm2" ]]; then
  if [[ -z "${CURSOR_AGENT:-}" ]]; then
    [[ -e "${HOME}/.iterm2_shell_integration.zsh" ]] && source "${HOME}/.iterm2_shell_integration.zsh"
  fi

  # The it2* helpers. Upstream aliases each one individually; a PATH entry is
  # preferred here because aliases only exist in interactive shells, so scripts
  # and `command -v imgcat` would not see them.
  #
  # This is a static directory, not a tool version, so it does not cross mise's
  # ownership of PATH for runtimes. See docs/mise-direnv.md.
  if [[ -d "$HOME/.iterm2" ]]; then
    path=("$HOME/.iterm2" $path)
  fi
fi
