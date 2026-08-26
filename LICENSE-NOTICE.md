# This repository must remain private

`fonts/HCo_OperatorMono.zip` contains **Operator Mono**, a commercial typeface
licensed from [Hoefler & Co.](https://www.typography.com). Their license grants
the purchaser the right to use the font, not to redistribute it.

Committing the archive here is a deliberate trade-off: it makes onboarding a
single `make all` instead of a manual font hunt. The cost is that this
repository can never be made public, forked publicly, or shared with anyone not
covered by the font license.

Concretely, do not:

- Flip this repository to public visibility.
- Add collaborators who are not covered by the Operator Mono license.
- Mirror it to a public host, a gist, a pastebin, or a CI cache that is
  publicly readable.
- Include `fonts/` in any archive or release artifact that leaves this machine.

If any of the above becomes necessary, remove `fonts/HCo_OperatorMono.zip` from
the working tree **and from git history** first, then have
`scripts/install-fonts.sh` source the archive from a private location instead.
Deleting the file in a new commit is not sufficient; the blob remains reachable
in history.

The patched output (`Operator Mono Lig`) is a derivative of the licensed font
and carries the same restriction. The ligature glyphs merged into it come from
[kiliman/operator-mono-lig](https://github.com/kiliman/operator-mono-lig), which
is MIT licensed, but the merged result is not redistributable.

FiraCode Nerd Font, by contrast, is freely licensed and is installed from
Homebrew rather than vendored here.
