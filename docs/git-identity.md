# Per-directory git identity

The goal: repos under `~/src/github.com/orgA/` commit as one identity, repos
under `~/src/github.com/orgB/` commit as another, with no per-repo setup.

The 2022 setup did this with a `.envrc` per org directory, setting
`GIT_AUTHOR_EMAIL` and friends. This repo uses git's own conditional includes
instead.

## How it works

`~/.gitconfig` ends with:

```gitconfig
[user]
	useConfigOnly = true

[includeIf "gitdir:~/src/github.com/greghopkins/"]
	path = ~/.config/git/personal.gitconfig
```

and `~/.config/git/personal.gitconfig` holds only:

```gitconfig
[user]
	name = Greg Hopkins
	email = greg@example.com
```

Git evaluates the `includeIf` on every invocation, matching the repository's
resolved git directory against the pattern.

## Why not direnv

direnv exports environment variables into an **interactive shell** that has
`cd`'d into the directory. That covers `git commit` typed at a prompt and
nothing else.

It does not cover git invoked by Cursor's source control panel, a GUI client, a
JetBrains IDE, a background agent, a cron job, or a script run from elsewhere.
In all of those, the `.envrc` was never loaded, so git falls back to the global
identity and commits under the wrong address — silently, and often for a long
time before anyone notices.

`includeIf` is evaluated by git itself, so it applies no matter who invoked git.
It also needs no `direnv allow` per directory, adds no dependency, and resolves
correctly inside worktrees and submodules because matching happens on the real
git directory.

## The safety net

`user.useConfigOnly = true`, with **no** `user.name` or `user.email` in the
global config, makes git refuse to commit when no rule matched:

```
*** Please tell me who you are.
fatal: no email was given and auto-detection is disabled
```

Without this, git guesses an identity from your login and hostname and commits
happily. That guess is what turns a missing mapping into a quiet, months-long
mistake. The error is the feature.

Consequence worth knowing: a repo outside any mapped directory — say a quick
clone in `/tmp` — cannot be committed to until you either add a rule or set
`user.email` locally in that repo.

## Adding an org

1. Create `home/.config/git/<org>.gitconfig` with the `[user]` block.
2. Append to the **bottom** of `home/.gitconfig`:

   ```gitconfig
   [includeIf "gitdir:~/src/github.com/<org>/"]
   	path = ~/.config/git/<org>.gitconfig
   ```

3. `make relink` (stow needs to link the new file).
4. Verify: `cd` into a repo under that org and run `git config user.email`.

## Three ways this breaks

**Ordering.** Git applies config in read order and the last value wins. An
`includeIf` placed *above* a `[user]` block gets overridden by it. This is why
the include rules live at the very bottom of `~/.gitconfig` and why nothing
should be appended after them.

**The trailing slash.** `gitdir:~/src/github.com/org/` implies a recursive
`/**` match. Drop the slash and it matches only that exact directory, so every
repo *inside* it goes unmapped. Easy to miss because it fails open into the
`useConfigOnly` error rather than something that names the cause.

**Symlinks.** `gitdir` matching resolves symlinks and compares real paths. If
`~/src` ever becomes a symlink to, say, an external volume, none of the patterns
match anymore and every repo goes unmapped at once. Use `gitdir:` with the real
path, or add a second rule for the resolved location. `make doctor` checks
whether `~/src` is a symlink for exactly this reason.

## Verifying

```sh
make doctor                    # checks all mapped orgs at once
git config user.email          # inside a repo: the effective address
git config --show-origin user.email   # which file it came from
```

`--show-origin` is the fastest way to confirm a rule fired, since it prints the
path of the config file that supplied the value.

## Alternative: keying on the remote instead of the path

Git also supports matching on the remote URL:

```gitconfig
[includeIf "hasconfig:remote.*.url:git@github.com:orgA/**"]
	path = ~/.config/git/orgA.gitconfig
```

This works regardless of where the repo lives on disk, which is useful if you
clone outside the `~/src/<host>/<org>/` convention. It needs git 2.36+ (you have
2.50+). The path-based rules are the primary mechanism here because they match
the existing directory layout; add `hasconfig` rules alongside them if you start
cloning to arbitrary locations.
