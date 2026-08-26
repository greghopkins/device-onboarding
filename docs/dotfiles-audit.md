# Audit of the 2022 dotfiles repo

What carried over from [greghopkins/dotfiles](https://github.com/greghopkins/dotfiles),
what didn't, and why. That repo was private, 23 commits, June–October 2022,
managed with [yadm](https://yadm.io).

The single biggest difference: that repo only *placed configuration*. It had no
README, no Brewfile, and no install script, so it assumed every tool it
configured had already been installed by hand. This repo installs the toolchain
too.

## Two things in it were silently broken

Worth calling out separately, because both failed without any error message.

**`core.excludesfile` pointed nowhere.** It was set to
`/Users/gregoryhopkins/.gitignore` — an absolute path with a username that no
longer exists on this machine. The global gitignore had therefore been doing
nothing at all. Now `~/.gitignore`.

**`~sdkman.zsh` was never sourced.** The file was named with a leading tilde in
the belief that it would sort last, since sdkman insists on being initialized at
the end of the shell config. But the fragment loader (`mattmc3/zshrc.d`)
contains:

```zsh
[[ ${_zshrcd_file:t} != '~'* ]] || continue  # ignore tilde files
```

A tilde prefix means **disabled**, not last. sdkman never initialized. This is
why no fragment here uses a `~` prefix and why ordering is numeric. `make doctor`
checks for it.

## Structure

| 2022 | Now | Why |
| --- | --- | --- |
| yadm with a GPG-encrypted secrets archive | stow, no secrets | Keys live in the Bitwarden SSH agent |
| Prezto sourced from inside a zplug fragment | Prezto sourced from `.zshrc`, before zplug | The base framework belongs under the plugin manager, not inside it |
| `.zshrc.d` order via `00-`, `zz-`, `~` prefixes | numeric prefixes only | See the tilde bug above |
| asdf + asdf-direnv + nvm + pyenv + sdkman | mise | Four overlapping managers, one of which never loaded |
| `.envrc` per org dir for git identity | git `includeIf` | Works outside an interactive shell — [git-identity.md](git-identity.md) |

## Kept

- **Prezto module list**, minus `ssh`. `osx` and `homebrew` are both still
  maintained upstream and stay.
- **The `.zshrc.d` fragment pattern** and `mattmc3/zshrc.d` as its loader.
- **Eight of nine oh-my-zsh plugins** via zplug: git, macos, aliases, aws,
  zsh-navigation-tools, sudo, dirhistory, history.
- **Starship** with its Nerd Font symbols and the terraform workspace format. One
  Dark colors added. `cmd_duration` was carried over disabled but has since been
  re-enabled above a 2s threshold: the censinet monorepo's terragrunt runs, `uv
  sync`, and Rails suites are slow enough that the timing is worth seeing, which
  was not true of the 2022 workload.
- **The full `.gitconfig`** — see the deferred audit below.
- **The global `.gitignore`**, minus two entries (see below).
- **The iTerm2 plist**, including its One Dark preset and hotkey window profile.
- **All the small overrides**, each now annotated with why you might remove it:
  `noglob git`, `nocorrect rm`, global pipe aliases, `zmv`, `^X^L`, the `zshrc`
  helper, `fn()`, `GREP_COLOR`, `HOMEBREW_NO_ENV_HINTS`, `SHOW_AWS_PROMPT`,
  `SPROMPT`, JetBrains Toolbox on `PATH`.

## Dropped

**`fasd`** — unmaintained since 2020, replaced by zoxide. The `z`/`zz` aliases
carry over; `a`/`s`/`f` (which matched *files*, not just directories) have no
zoxide equivalent — use `fzf` or `fd`.

**Emacs keybinding overrides** — the old setup set vi bindings, then re-set them,
then rebound `^a`/`^e`/`^r` to emacs behavior. Now pure vi, set once in
`.zpreztorc`. `^r` search comes from Prezto's `history-substring-search`.

**Two thirds of `aliases.zsh`** — the file opened with "a bunch of hangover stuff
from prezto — do I need it?". Gone: Ruby/Rails (`rails c`, `script/console`,
thin, mongrel, 10 zeus aliases, 7 rspec/spring aliases, rake db:migrate
variants, `sgi`); sprintly/`spb`; `hpr` (hub); `todo` (NValt); `portforward`
(`ipfw`, removed from macOS); Docker aliases and the commented docker-machine
and dinghy archaeology; Finder show/hide toggles; `brewu`; and the `TRAPHUP`
trap that re-sourced the alias file on SIGHUP. Recoverable from git history in
the old repo.

**Linux branches** — the platform detection in `aliases.zsh` had a Linux arm that
was dead code on a macOS-only machine.

**`diff-so-fancy`** — replaced by `delta`, which is maintained and can take a
One Dark syntax theme later.

**Prezto's `ssh` module** and `.ssh/config` — the module loaded `personal` and
`work` identities with agent forwarding, and the config pointed at
`~/.ssh/personal` and `~/.ssh/personal_rsa`. All superseded by the Bitwarden
agent; re-enabling would start a second agent competing for `SSH_AUTH_SOCK`.

**The vendored iTerm2 scripts** — 15 `it2*` helpers plus
`.iterm2_shell_integration.zsh`, copied into the repo. The *integration* is kept
but no longer vendored: `make iterm-integration` fetches it and the helpers from
upstream. Fetching turned out to be the right call on its own merits — upstream
now ships 16 helpers, so the committed copy was already missing one (`it2cat`),
and the script has since grown a `tmux-256color` case its guard lacked.

**`.config/Lumina/`** — webcam software config, not dev tooling. It also
contained a license key, user id, and email in plaintext.

**All committed secrets** — `.config/yadm/encrypt`,
`.local/share/yadm/archive`, and two committed public keys.

**`.envrc` and `.tool-versions` from the global gitignore** — ignoring them
globally meant neither could ever be committed in any project, which is exactly
backwards now that projects are expected to carry both. `.envrc.local` replaces
them as the machine-local, secret-bearing file.

## Deferred: the .gitconfig alias audit

The whole file was carried forward verbatim to avoid a decision. Things to
scrutinize when you get to it:

- **svn helpers** — `svnr`, `svnd`, `svnl`. Presumably dead.
- **`ammend`** — a deliberate misspelling kept alongside `amend`. Removed here;
  mentioned in case the muscle memory is real.
- **`push.default = upstream`** — pushes to the tracking branch regardless of
  name. Modern git defaults to `simple`, which additionally requires the names
  to match; `upstream` will silently push to a differently-named remote branch.
- **`merge.summary`** — deprecated in favor of `merge.log`. Currently a no-op.
- **`[color] ui = true`** — the modern default is `auto`, which does the right
  thing for pipes. `true` is an old alias for it and harmless.
- **`format.pretty`** — a global override, so any `git log` without an explicit
  format uses it. Worth confirming that's still wanted, since it affects tooling
  that parses log output.
- **~100 single and double letter aliases** — many overlap with the oh-my-zsh
  git plugin loaded via zplug, so some are shadowed or redundant.

## Secrets in the old repo

It contains a plaintext Lumina license key and a GPG-encrypted secrets archive.
Since it's superseded, consider archiving the repo and rotating that key.
