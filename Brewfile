# Core toolchain. Installed by 'make brew'.
#
# The baseline (Command Line Tools, git, Homebrew itself, Cursor, Claude) is
# assumed present and deliberately not listed here. See README.md.
#
# Containers and cloud tooling live in Brewfile.optional.

# --- shell -------------------------------------------------------------------
brew "zsh"        # newer than the system zsh; 'make shell' makes it the login shell
brew "zplug"      # plugin manager; see home/.zshrc for the load order
brew "starship"   # prompt, replaces Prezto's theme

# --- runtimes and per-directory environment ----------------------------------
brew "mise"       # owns tool versions and PATH
brew "direnv"     # owns per-directory env vars ONLY. See docs/mise-direnv.md
                  # before using layout/PATH_add with it.

# Ruby build dependencies — a fallback, not the common path.
#
# Measured on mise 2026.8: current Ruby (3.3, 4.0) installs as a prebuilt,
# attestation-verified binary in about 5 seconds, needing none of this. But mise
# falls back to ruby-build for versions with no prebuilt available — Ruby 2.7,
# for instance, compiles from source and even builds its own OpenSSL 1.1.1.
#
# These are here so that inheriting an old Rails app pinned to such a version
# doesn't turn into a yak shave. libyaml is the one worth having: Ruby 3.2+ split
# psych out into a separate libyaml dependency, and when it's absent the build
# fails partway with an error that reads like a Ruby problem rather than a
# missing C library.
brew "libyaml"
brew "autoconf"
# ruby-build also wants openssl@3 and readline; both already arrive as
# dependencies of other formulas here, so they are not listed explicitly.

# --- navigation --------------------------------------------------------------
brew "zoxide"     # replaces fasd (unmaintained since 2020)
brew "fzf"

# --- git ---------------------------------------------------------------------
brew "gh"
brew "git-delta"  # pager, replaces diff-so-fancy
brew "git-lfs"
brew "lazygit"
brew "git-absorb"

# --- editor ------------------------------------------------------------------
brew "neovim"     # EDITOR/VISUAL, used for commit messages

# --- modern CLI core ---------------------------------------------------------
brew "bat"
brew "eza"
brew "fd"
brew "ripgrep"
brew "jq"         # also used by scripts/configure-cursor.sh to merge settings
brew "tree"
brew "wget"
brew "btop"

# --- dotfile management ------------------------------------------------------
brew "stow"       # 'make link' symlinks home/ into $HOME

# --- terminal and fonts ------------------------------------------------------
cask "iterm2"
cask "font-fira-code-nerd-font"  # provides FiraCodeNerdFontMono-*, used by every
                                 # terminal. Operator Mono is built separately
                                 # by 'make fonts'.
