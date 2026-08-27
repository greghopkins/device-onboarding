#
# omz_urlencode quoting that survives `typeset -f` → eval
#
# Sourced from ~/.zshrc AFTER `zplug load`. It cannot live in .zshrc.d: zplug
# sources oh-my-zsh's lib/functions.zsh once per `from:oh-my-zsh` plugin, and
# that happens after the zshrc.d fragments, overwriting any earlier fix.
#
# Cursor agent shells snapshot the interactive zsh with `typeset -f` and later
# `eval` that dump. Oh-my-zsh's omz_urlencode (pulled in by plugins/git, aws,
# macos, …) is written as:
#
#     local mark='_.!~*''()-'
#
# Two adjacent single-quoted strings. `typeset -f` pretty-prints that as:
#
#     local mark='_.!~*'()-'
#
# which is a parse error near `()`. Eval of the snapshot then fails around
# line 10700, Cursor's injected `dump_zsh_state` is never defined, and every
# agent command prints both:
#
#     (eval):10724: parse error near `()'
#     zsh:1: command not found: dump_zsh_state
#
# Skipping iTerm2 integration under CURSOR_AGENT is still correct (OSC / prompt
# wrapping), but the snapshot is taken with `zsh -ilc` and includes every
# function from .zshrc regardless. Dump-safe quoting is the actual fix.
#
# Double quotes around the RFC 2396 mark set (`_.!~*'()-`) dump and eval
# cleanly. Behavior is identical.
#

if (( $+functions[omz_urlencode] )); then
  omz_urlencode() {
    emulate -L zsh
    setopt norematchpcre

    local -a opts
    zparseopts -D -E -a opts r m P

    local in_str="$@"
    local url_str=""
    local spaces_as_plus
    if [[ -z $opts[(r)-P] ]]; then spaces_as_plus=1; fi
    local str="$in_str"

    local encoding=$langinfo[CODESET]
    local safe_encodings
    safe_encodings=(UTF-8 utf8 US-ASCII)
    if [[ -z ${safe_encodings[(r)$encoding]} ]]; then
      str=$(echo -E "$str" | iconv -f $encoding -t UTF-8)
      if [[ $? != 0 ]]; then
        echo "Error converting string from $encoding to UTF-8" >&2
        return 1
      fi
    fi

    local i byte ord LC_ALL=C
    export LC_ALL
    local reserved=';/?:@&=+$,'
    local mark="_.!~*'()-"
    local dont_escape="[A-Za-z0-9"
    if [[ -z $opts[(r)-r] ]]; then
      dont_escape+=$reserved
    fi
    if [[ -z $opts[(r)-m] ]]; then
      dont_escape+=$mark
    fi
    dont_escape+="]"

    local url_str=""
    for (( i = 1; i <= ${#str}; ++i )); do
      byte="$str[i]"
      if [[ "$byte" =~ "$dont_escape" ]]; then
        url_str+="$byte"
      else
        if [[ "$byte" == " " && -n $spaces_as_plus ]]; then
          url_str+="+"
        elif [[ "$PREFIX" = *com.termux* ]]; then
          url_str+="$byte"
        else
          ord=$(( [##16] #byte ))
          url_str+="%$ord"
        fi
      fi
    done
    echo -E "$url_str"
  }
fi
