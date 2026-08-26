#
# Assorted overrides carried forward from the 2022 dotfiles repo.
#
# Each is annotated with what it does and why you might want to remove it.
# Nothing in this file is required for a working shell — it is all preference,
# collected in one place so it's easy to prune later.
#

# --- rm ----------------------------------------------------------------------
# `nocorrect` stops zsh's spelling correction from prompting on rm arguments.
#
# Historically this also defeated an `rm -i` alias inherited from a framework.
# Neither Prezto nor the plugins loaded here alias rm anymore, so this is now
# only about correction. Safe to delete.
alias rm='nocorrect rm'

# --- zmv ---------------------------------------------------------------------
# Pattern-based bulk rename: zmv '(*).txt' '$1.md'
#
# -W lets you write wildcards on both sides instead of capture groups, which is
# easier but less precise. noglob keeps zsh from expanding the patterns before
# zmv can see them. Genuinely worth keeping.
autoload -Uz zmv
alias zmv='noglob zmv -W'

# --- last command output -----------------------------------------------------
# ^X^L inserts the *output* of the previous command onto the current line.
#
# It works by re-running that command, so it is only safe for read-only
# commands. Re-running a `git push` or an `rm` because you wanted its output on
# the line is a bad afternoon. Remove if that risk isn't worth it.
zmodload -i zsh/parameter
insert-last-command-output() {
  LBUFFER+="$(eval $history[$((HISTCMD-1))])"
}
zle -N insert-last-command-output
bindkey '^X^L' insert-last-command-output

# --- fragment helper ---------------------------------------------------------
# `zshrc` with no argument lists the fragments; `zshrc 80-misc` opens one.
#
# Note these files are stow symlinks into this repo, so editing them edits the
# repo — which is the point, but means a careless change is a git diff.
alias zshrc='(){ if [[ -n "$1" ]]; then $EDITOR $HOME/.zshrc.d/$1.zsh; else ls $HOME/.zshrc.d/; fi }'

# --- grep color --------------------------------------------------------------
# Yellow matches. GREP_COLOR is the deprecated single-color variable; modern
# grep prefers GREP_COLORS (plural, with per-element settings). Kept as-is
# because BSD grep on macOS still honors it. Switch to GREP_COLORS if you ever
# want to color line numbers and filenames separately.
export GREP_COLOR='1;33'

# --- aws prompt --------------------------------------------------------------
# Stops the oh-my-zsh aws plugin from injecting the current profile into the
# prompt. Starship's `aws` module handles that instead, so leaving this unset
# would show the profile twice.
export SHOW_AWS_PROMPT=false

# --- JetBrains Toolbox -------------------------------------------------------
# Puts the `idea`, `pycharm` etc. launcher scripts on PATH.
#
# The directory does not exist unless JetBrains Toolbox is installed, hence the
# guard — the 2022 version appended unconditionally, leaving a dead PATH entry.
if [[ -d "$HOME/Library/Application Support/JetBrains/Toolbox/scripts" ]]; then
  export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
fi
