# Core toolchain. Installed by 'make brew'.
#
# The baseline (Command Line Tools, git, Homebrew itself, Cursor, Claude Desktop)
# is assumed present and deliberately not listed here. See README.md. git is the
# one exception: Apple's build is needed to clone this repo in the first place,
# but it is then superseded — see the git section below. Claude Desktop is the
# other exception-that-isn't: it is the GUI app. Claude Code, the `claude` CLI,
# is listed below and is a different product.
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

# --- databases ---------------------------------------------------------------
# Client only, deliberately. Projects here run Postgres as a container (censinet's
# compose file builds from postgres:17.7 and publishes 5432), so installing
# postgresql@17 would add a second server competing for that port — and one that
# `brew services` is happy to start at login.
#
# libpq gives the client tools and the headers native gems build against; the
# precompiled arm64-darwin `pg` gem bundles its own, but a source install needs
# these. A newer client than server is the supported direction, so 18.x against
# the 17.7 container is fine.
#
# Keg-only: nothing lands on PATH. The tools are at
# $(brew --prefix)/opt/libpq/bin, and censinet puts them on PATH per-project via
# its mise.macos.toml rather than globally.
brew "libpq"          # psql, pg_dump, pg_restore

# --- containers --------------------------------------------------------------
# `docker-desktop` is the real cask token; `docker` is an alias for it, and the
# `docker` *formula* is a different thing (CLI only, no runtime).
#
# Docker Desktop is free for personal use and for small businesses, but requires a
# paid subscription above Docker's employee/revenue thresholds. Confirmed as fine
# for this machine's use; revisit if that changes.
#
# Two things this cask does not do:
#
#   1. It does not adopt an existing install. If Docker.app is already in
#      /Applications from a manual download, `brew bundle` fails with "It seems
#      there is already an App at ...". Hand it over once with:
#          brew install --cask --adopt docker-desktop
#   2. It does not keep it updated. The cask is auto_updates, so Docker Desktop
#      updates itself and `brew upgrade` leaves it alone.
#
# Compose is not listed separately: Docker Desktop bundles it as a CLI plugin
# (v5.4.0 here), and the standalone docker-compose formula would shadow it.
cask "docker-desktop"

# --- navigation --------------------------------------------------------------
brew "zoxide"     # replaces fasd (unmaintained since 2020)
brew "fzf"

# --- git ---------------------------------------------------------------------
# Xcode's git shadows everything else on PATH and lags upstream: the CLT build on
# this machine reported 2.50.1 (Apple Git-155). Apple also patches it, so version
# numbers do not map cleanly onto upstream behavior. Installing it here puts a
# current, unpatched git ahead of /usr/bin on PATH, which matters mainly for the
# config knobs that the tools below expect to exist.
brew "git"
brew "gh"
brew "git-delta"  # pager, replaces diff-so-fancy
brew "git-lfs"
brew "lazygit"
brew "git-absorb"

# --- editor ------------------------------------------------------------------
brew "neovim"     # EDITOR/VISUAL, used for commit messages

# --- AI coding CLI -----------------------------------------------------------
# Claude Code, not Claude Desktop. The desktop app is baseline (a DMG, like
# Cursor) and does not ship a `claude` binary. This cask does.
#
# Token is `claude-code`. `claude` is the desktop-app cask, which we do not
# list: Homebrew will not adopt the existing /Applications/Claude.app without
# --adopt, same trap as docker-desktop.
#
# Stable channel, not `claude-code@latest`. Stable trails by about a week and
# skips releases with major regressions, which is the right default for a
# machine-wide Brewfile. Homebrew does not auto-update this cask; `brew upgrade`
# (or a re-run of `make brew`) is how it moves. Native `curl | bash` installs
# auto-update instead, but live outside Homebrew.
cask "claude-code"

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
