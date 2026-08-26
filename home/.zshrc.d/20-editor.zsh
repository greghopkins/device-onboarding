#
# Editor
#
# nvim is the terminal editor: commit messages, quick edits, anything that
# blocks a shell. Cursor is the primary editor but is a poor fit for $EDITOR
# because git waits on the process and Cursor returns immediately unless passed
# --wait.
#
# If you'd rather commit messages open in Cursor:
#   export EDITOR='cursor --wait'
#

if (( $+commands[nvim] )); then
  export EDITOR="$commands[nvim]"
  export VISUAL="$EDITOR"

  # Muscle memory. Note these shadow the real vi/vim if you ever install them.
  alias vi='nvim'
  alias vim='nvim'
fi
