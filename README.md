# device-onboarding

Standardizes developer tooling on a macOS machine: Homebrew packages, a
Prezto + zplug + Starship zsh setup, Operator Mono Lig for editing, FiraCode
Nerd Font Mono for terminals, and One Dark theming throughout.

> **This repository must stay private.** It vendors a commercially licensed
> font. See [LICENSE-NOTICE.md](LICENSE-NOTICE.md) before changing its
> visibility or adding collaborators.

## Baseline

This repo starts from a machine that already has:

| Assumed present | Why it isn't automated |
| --- | --- |
| macOS Command Line Tools | Prerequisite for git and any compilation |
| `git` | Needed to clone this repo in the first place |
| Homebrew at `/opt/homebrew` | Bootstraps everything else; installing it needs its own sudo flow |
| Cursor | Primary editor; `make cursor` configures it but does not install it |
| Claude Desktop | GUI app, installed alongside Cursor. Does not include the `claude` CLI; that is `cask "claude-code"` in the Brewfile |

Everything past that baseline is installed by this repo.

## Install

```sh
git clone <this repo> ~/src/github.com/greghopkins/device-onboarding
cd ~/src/github.com/greghopkins/device-onboarding
make all
make shell     # separate: needs sudo
exec zsh
make doctor
```

`make all` runs
`brew → link → prezto → mise → fonts → iterm → iterm-integration → cursor`. Every
target is idempotent, so re-running it after editing a config is safe and cheap.

The order is load-bearing in two places: `link` has to come before `mise`,
because mise reads the global config that `link` puts at
`~/.config/mise/config.toml`; and `mise` has to come before `fonts`, because the
Operator Mono ligature build needs `node`.

Run `make` with no arguments for the full target list.

## What ends up where

```
home/                 stowed into $HOME as symlinks (make link)
  .zshrc              load order: homebrew -> prezto -> zplug -> .zshrc.d
  .zpreztorc          Prezto module + option config
  .zshrc.d/*.zsh      numbered fragments, loaded last so they win
                      92-iterm.zsh must sort after 90-prompt.zsh; see the file
  .gitconfig          global git config + per-org identity rules
  .gitignore          global ignore file
  .hushlogin          empty on purpose; silences login(1)'s "Last login:" banner
  .config/
    starship.toml     prompt, One Dark palette
    git/*.gitconfig   one file per git identity
    direnv/direnvrc   guardrails against colliding with mise
    mise/config.toml  machine-wide default runtime versions
Brewfile              core toolchain
Brewfile.optional     containers + cloud, opt in with 'make brew-optional'
fonts/                the licensed Operator Mono archive
iterm2/               iTerm2 preferences, loaded in place by iTerm
scripts/              the implementation behind each make target
docs/                 the reasoning; read these before changing things
```

`make link` uses `stow --no-folding`, which matters: without it stow symlinks
whole *directories*, so `~/.config` would become a link into this repo and any
app that writes there would be writing into your git working tree.

Existing real files are moved aside to `<name>.pre-onboarding` on first link
rather than clobbered.

## Manual steps

A few things can't be scripted:

1. **iTerm2 preferences.** `make iterm` points iTerm at `iterm2/` via the
   "Load preferences from a custom folder" setting, but iTerm only re-reads it
   on launch. Quit and reopen iTerm after the first run.
2. **Cursor theme.** `make cursor` installs the theme and writes settings, but
   Cursor must be restarted to pick up a newly installed extension.
3. **Login shell.** `make shell` needs sudo to add Homebrew's zsh to
   `/etc/shells`.
4. **Git identity.** The per-org rules in `home/.gitconfig` ship with
   placeholders. Fill them in — see [docs/git-identity.md](docs/git-identity.md).
   Until you do, `user.useConfigOnly` will make git refuse to commit, which is
   the intended behavior.
5. **SSH keys.** Handled by the Bitwarden SSH agent, not by this repo. No keys
   or secrets are stored here.

## Docs

- [docs/git-identity.md](docs/git-identity.md) — per-directory git identity
- [docs/mise-direnv.md](docs/mise-direnv.md) — why both, and the rules that keep them from fighting
- [docs/fonts.md](docs/fonts.md) — the Operator Mono ligature build, and which weights get ligatures
- [docs/theming.md](docs/theming.md) — One Dark: what's themed and what's left
- [docs/dotfiles-audit.md](docs/dotfiles-audit.md) — what carried over from the 2022 dotfiles repo, what didn't, and why
