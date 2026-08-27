#
# .zshrc — interactive shell configuration
#
# The load order below is deliberate, and it is the opposite of what the 2022
# dotfiles repo did. That version bootstrapped zplug in .zshrc and then sourced
# Prezto from *inside* a zplug-loaded fragment, which put the base framework
# underneath the plugin manager that was supposed to sit on top of it.
#
# Here the layering runs outermost-first, so each layer can override the one
# before it:
#
#   1. Homebrew   — everything below lives under $HOMEBREW_PREFIX
#   2. Prezto     — the base framework (see .zpreztorc)
#   3. zplug      — plugin manager; declares the oh-my-zsh borrowings
#   4. .zshrc.d/  — personal fragments, loaded last so they win
#

# ---------------------------------------------------------------------------
# 1. Homebrew
#
# Must come first: zplug, starship, mise and the rest all live under the
# Homebrew prefix, so nothing below can be found until this runs. Prezto's
# `homebrew` module also runs shellenv (with caching), but ZPLUG_HOME needs
# $HOMEBREW_PREFIX before Prezto has finished loading.
# ---------------------------------------------------------------------------

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# ---------------------------------------------------------------------------
# 2. Prezto
#
# Sources ~/.zprezto/init.zsh directly. The 2022 repo sourced
# ~/.zprezto/runcoms/zshrc instead, which is a thin wrapper around this — one
# less layer of indirection.
#
# Prezto's `completion` module runs compinit. Do not run it again in a
# fragment; a second compinit is slow and can shadow completions.
# ---------------------------------------------------------------------------

if [[ -s "$HOME/.zprezto/init.zsh" ]]; then
  source "$HOME/.zprezto/init.zsh"
else
  print -u2 "zshrc: Prezto not installed. Run 'make prezto'."
fi

# ---------------------------------------------------------------------------
# 3. zplug
#
# Plugins are borrowed from oh-my-zsh rather than depending on all of oh-my-zsh.
#
# Deliberately NOT listed here: zsh-autosuggestions and zsh-syntax-highlighting.
# Prezto already provides both (see .zpreztorc). Loading them twice binds the
# widgets twice and produces duplicated suggestions.
#
# Also dropped from the 2022 list: plugins/fasd. fasd has been unmaintained
# since 2020 and is replaced by zoxide in .zshrc.d/40-zoxide.zsh.
# ---------------------------------------------------------------------------

export ZPLUG_HOME="${HOMEBREW_PREFIX:-/opt/homebrew}/opt/zplug"

# Keep zplug's mutable state OUT of the Homebrew Cellar.
#
# ZPLUG_HOME has to point at the Homebrew install because that's where
# init.zsh lives. But zplug defaults every writable path to $ZPLUG_HOME too,
# which resolves into /opt/homebrew/Cellar/zplug/<version>/. Cloned plugins
# would then live inside a versioned Cellar directory that `brew upgrade zplug`
# replaces and `brew cleanup` deletes — losing every plugin without warning.
export ZPLUG_REPOS="$HOME/.zplug/repos"
export ZPLUG_CACHE_DIR="$HOME/.zplug/cache"
export ZPLUG_BIN="$HOME/.zplug/bin"
export ZPLUG_LOADFILE="$HOME/.zplug/packages.zsh"

if [[ -s "$ZPLUG_HOME/init.zsh" ]]; then
  source "$ZPLUG_HOME/init.zsh"

  zplug "plugins/git", from:oh-my-zsh
  zplug "plugins/macos", from:oh-my-zsh
  zplug "plugins/aliases", from:oh-my-zsh
  zplug "plugins/aws", from:oh-my-zsh
  zplug "plugins/sudo", from:oh-my-zsh
  zplug "plugins/dirhistory", from:oh-my-zsh
  zplug "plugins/history", from:oh-my-zsh

  # zsh-navigation-tools, from its own upstream rather than the oh-my-zsh copy.
  #
  # oh-my-zsh vendors a copy, but every `from:oh-my-zsh` entry clones the same
  # oh-my-zsh repo, and zplug runs those clones in parallel — so on a first run
  # one entry loses the race and is reported as "Failed to install" even though
  # it loads correctly. Sourcing this one directly avoids the shared clone and
  # keeps the first-run output honest.
  zplug "zdharma-continuum/zsh-navigation-tools"

  # Sources ~/.zshrc.d/*.zsh in sorted order, like fish's conf.d.
  zplug "mattmc3/zshrc.d"

  # `zplug check` verifies every declared plugin is present on disk on every
  # shell start. The plugin list only changes when this file changes, so gate it
  # on a stamp file.
  #
  # Measured on this machine, so the trade is clear — this saves the smallest
  # piece of a startup that is mostly zplug itself:
  #
  #     zplug init.zsh        ~170ms   fixed overhead
  #     9 zplug declarations   ~95ms
  #     zplug check            ~28ms   <- what this gate skips
  #     zplug load            ~261ms   sourcing the plugins; irreducible
  #
  # So this is worth ~28ms, not the bulk of startup. Kept because it is cheap
  # and correct, not because it is a large win.
  #
  # ~/.zshrc is a stow symlink and -nt follows symlinks, so this compares against
  # the mtime of the real file in the repo.
  #
  # The trade-off: adding a `zplug` line above no longer auto-installs on the
  # next shell. Editing this file updates its mtime, which invalidates the stamp,
  # so in practice it still does. To force a re-check:
  #
  #     rm ~/.zplug/check.stamp && exec zsh
  #
  # `make doctor` verifies every declared plugin is actually installed, which is
  # what catches a plugin that went missing without this file changing.
  _zplug_stamp="${ZPLUG_CACHE_DIR}/check.stamp"
  if [[ ! -f "$_zplug_stamp" || "$HOME/.zshrc" -nt "$_zplug_stamp" ]]; then
    if ! zplug check; then
      zplug install
    fi
    mkdir -p "${_zplug_stamp:h}" && touch "$_zplug_stamp"
  fi
  unset _zplug_stamp

  # ------------------------------------------------------------------------
  # 4. Fragments
  #
  # `zplug load` runs mattmc3/zshrc.d, which sources ~/.zshrc.d/*.zsh. Because
  # this is the last thing to run, the fragments override Prezto and the
  # oh-my-zsh plugins above.
  # ------------------------------------------------------------------------
  zplug load
else
  print -u2 "zshrc: zplug not found at $ZPLUG_HOME. Run 'make brew'."

  # Fall back to loading the fragments directly, so a missing zplug degrades
  # to a usable shell instead of an unconfigured one.
  for _frag in "$HOME"/.zshrc.d/*.zsh(N); do
    [[ ${_frag:t} != '~'* ]] || continue
    source "$_frag"
  done
  unset _frag
fi

# After zplug load. oh-my-zsh's lib/functions.zsh is sourced once per
# from:oh-my-zsh plugin and overwrites anything that ran inside .zshrc.d.
# See ~/.zsh/omz-urlencode.zsh for why Cursor agents need this.
if [[ -r "$HOME/.zsh/omz-urlencode.zsh" ]]; then
  source "$HOME/.zsh/omz-urlencode.zsh"
fi
