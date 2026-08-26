# mise and direnv

Both are installed. They can break each other. This is the contract that keeps
them apart.

| Tool | Owns | Config file |
| --- | --- | --- |
| mise | tool versions, `PATH` | `~/.config/mise/config.toml`, per-project `mise.toml` / `.tool-versions` |
| direnv | environment variables, secrets | `.envrc` |

direnv must never touch `PATH`.

## Where the runtime versions live

Machine-wide defaults are in `home/.config/mise/config.toml`, stowed to
`~/.config/mise/config.toml`:

```toml
[tools]
node = "lts"
python = "3.13"
java = "temurin-21"
```

They are **global** rather than a `.tool-versions` in this repo's root on
purpose. A repo-local file only applies inside that repo, so `mise ls --current`
in `$HOME` would be empty and `node` would not exist anywhere except here —
not much use on a machine that is supposed to be ready for development.

Projects still override freely: a `mise.toml` or `.tool-versions` in a project
directory takes precedence. That layering is the reason to use mise at all
instead of installing runtimes from Homebrew, which can only give you one
version of each, globally.

Because `mise install` reads the stowed config, `make link` must run before
`make mise`. `make all` already orders them that way.

One consequence worth knowing: mise activates via a shell hook, so a
non-interactive context (a Makefile recipe, CI) has no mise-managed tools on
`PATH`. `scripts/install-fonts.sh` resolves `node` and `python3` through
`mise which` rather than assuming an activated shell, which is why `make fonts`
works from a bare `make` invocation.

## Why this needs a rule at all

mise's documentation is blunt about it:

> The official stance is you should not use direnv with mise. Issues arising
> from incompatibilities are not considered bugs and PRs to improve direnv
> compatibility will not be accepted.

The mechanism: both tools hook the shell, snapshot the environment before and
after, and diff it to decide what to add and remove. Run two of those against
each other and `PATH` ordering becomes a race — whichever hook ran last wins,
and which one that is depends on directory changes and prompt redraws.

mise also notes that the conflict is *specifically* about `PATH`. For unrelated
environment variables the two coexist fine. So the split above isn't a
compromise; it's the whole reason both can be installed.

## What not to put in .envrc

These all manipulate `PATH`, which is mise's job:

| Don't | Do instead |
| --- | --- |
| `layout python` | `[tools] python = "3.13"` in `mise.toml` |
| `layout node` | `[tools] node = "lts"` in `mise.toml` |
| `PATH_add ./node_modules/.bin` | mise task, or a shell alias |
| `use mise` | nothing — mise is already active |

For Python virtualenvs specifically, use mise's automatic virtualenv activation
rather than `layout python`. That is the single most common collision, because
`layout python` is the most popular direnv feature and Python is the runtime
people most often manage in both places at once.

`use mise` deserves its own note: it *was* the official integration, generated
by `mise direnv activate`. It is now deprecated and unsupported upstream. Don't
reintroduce it — mise is activated directly in `~/.zshrc.d/45-mise.zsh`, so
there is nothing for it to do.

`~/.config/direnv/direnvrc` overrides `layout`, `PATH_add`, and `use_mise` to
fail with a pointer to this document, so a mistake surfaces at the call site
rather than as a mysterious PATH bug later. If you truly need one in a specific
project, the originals are preserved as `direnv_layout` and `direnv_PATH_add` —
prefixed so that using one is a visible decision.

## Load order

`~/.zshrc.d/` is sourced in sorted order, so the numbering is the mechanism:

```
45-mise.zsh     eval "$(mise activate zsh)"    # establishes PATH
85-direnv.zsh   eval "$(direnv hook zsh)"      # layers env vars on top
```

mise first, so `PATH` is settled before direnv runs.

## Secrets

```
.envrc          committed. Non-secret setup, safe to share.
.envrc.local    gitignored. Credentials, tokens, machine-local paths.
```

`~/.config/direnv/direnvrc` calls `dotenv_if_exists .envrc.local`, so the local
file loads automatically when present without each project's `.envrc` having to
remember.

`.envrc.local` is in the global gitignore (`home/.gitignore`). This is a change
from the 2022 setup, which ignored `.envrc` and `.tool-versions` outright — that
made it impossible to commit either file in any project, which is the opposite
of what you want now that projects are expected to carry both.

## What this replaced

The 2022 setup ran four overlapping version managers: asdf with asdf-direnv,
nvm, pyenv, and sdkman. All four are gone, replaced by mise.

One of them was never actually working. `~/.zshrc.d/~sdkman.zsh` was named with
a leading tilde in the belief that it would sort last, since sdkman insists on
being initialized at the end of the file. But the fragment loader
(`mattmc3/zshrc.d`) contains:

```zsh
[[ ${_zshrcd_file:t} != '~'* ]] || continue  # ignore tilde files
```

Tilde-prefixed files are treated as **disabled**, not last. sdkman was silently
never initialized. This is why no file in `home/.zshrc.d/` uses a `~` prefix,
and why ordering is expressed with numbers.

## First run in a new project

```sh
cd some-project
mise install        # if mise.toml / .tool-versions is present
direnv allow        # if .envrc is present; required once per file change
```

## Idiomatic version files, and the Ruby trap

mise calls files like `.ruby-version` and `.node-version` **idiomatic** version
files, and it ignores every one of them unless the tool is explicitly listed in
`idiomatic_version_file_enable_tools`. The default is an empty list.

For Ruby that default is a trap. Essentially every Rails app ships a
`.ruby-version` and no `mise.toml`, so a fresh checkout resolves to **no Ruby at
all** — silently, with no hint that a version file was seen and skipped:

```console
$ cat .ruby-version
3.3.6
$ mise ls --current          # before opting in
node    24.19.0   ~/.config/mise/config.toml
python  3.13.15   ~/.config/mise/config.toml
                             # ...no ruby
```

Hence, in `~/.config/mise/config.toml`:

```toml
[settings]
idiomatic_version_file_enable_tools = ["ruby"]
```

Node is deliberately left out. `package.json`'s `engines` field, `.nvmrc` and
`.node-version` disagree often enough that an explicit `mise.toml` is the less
surprising option there.

### Setting up a checked-out Rails app

```sh
cd myapp
mise install        # reads .ruby-version, installs that Ruby
bundle install
bin/rails s
```

No `bundle exec` prefix and no rbenv-style `rehash`: `gem`, `bundle` and
`bin/rails` all resolve through mise's shims to the project's Ruby.

Two things worth knowing about the install step:

- **Current Ruby is not compiled.** 3.3 and 4.0 arrive as prebuilt,
  attestation-verified binaries in about five seconds. mise only falls back to
  `ruby-build` for versions with no prebuilt (roughly 2.7 and older), which does
  compile from source and even builds its own OpenSSL 1.1.1. The `Brewfile`
  carries `libyaml` and `autoconf` for that case.
- **Don't reach for `layout ruby`.** `~/.config/direnv/direnvrc` rejects it on
  purpose, because it manipulates `PATH`, which mise owns. Use `.envrc` for
  things like `RAILS_ENV` and `.envrc.local` for `RAILS_MASTER_KEY` or
  `DATABASE_URL` — the latter is in the global gitignore.

direnv refuses to load an `.envrc` it hasn't been told to trust, and re-asks
whenever the file changes. That is a feature — an `.envrc` is arbitrary shell
code from whoever wrote the repo.

## Do you even need direnv

mise can set environment variables itself via `[env]` in `mise.toml`, which
covers a good share of what direnv is typically used for. direnv is here because
of the secrets workflow and arbitrary per-directory variables. If you find
yourself only ever setting plain variables, dropping direnv would remove this
whole class of problem — remove it from `Brewfile`, delete
`home/.zshrc.d/85-direnv.zsh` and `home/.config/direnv/`, then `make relink`.

Note that per-directory *git identity* is no longer a reason to keep direnv.
That moved to git's own conditional includes — see
[git-identity.md](git-identity.md).
