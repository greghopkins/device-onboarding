# Fonts

Two fonts, split by role.

| Role | Font | Source |
| --- | --- | --- |
| Editors | `Operator Mono Lig Book` | Built locally by `make fonts` |
| Terminals | `FiraCode Nerd Font Mono` | Homebrew cask `font-fira-code-nerd-font` |

Both have ligatures. The terminal font additionally carries Nerd Font glyphs,
which Starship's prompt symbols depend on — Operator Mono has none, which is
why the two roles use different fonts.

## Why Operator Mono needs a build step

Operator Mono ships **without programming ligatures**. To get them, the Fira
Code ligature glyphs are merged into a copy of the licensed font using
[kiliman/operator-mono-lig](https://github.com/kiliman/operator-mono-lig) v2.5.2.
The output family is named `Operator Mono Lig`, so it installs side by side with
the original.

`make fonts` does this end to end: unpack the archive, install the unpatched
family, fetch the patcher, stage the patchable faces, build, install the result.
It is idempotent — it skips the build entirely if
`~/Library/Fonts/OperatorMonoLig-Book.otf` already exists. Delete that file to
force a rebuild.

## Only Light and Book get ligatures

This is the surprising part. The archive contains ten faces:

```
XLight  Light  Book  Medium  Bold        (+ an Italic for each)
```

Only **four** come out with ligatures: `Light`, `LightItalic`, `Book`,
`BookItalic`. The patcher's `build.sh` builds a face only when *both* of these
exist:

- `original/<face>.otf` — the licensed input, which we supply
- `ligature/<face>/glyphs` — the hand-drawn ligature set, which ships with the patcher

For the non-SSm Operator Mono family, upstream has only drawn glyph sets for
Light and Book. XLight, Medium, and Bold are **silently skipped** — no error, no
warning, they simply don't appear in `build/`. Upstream documents this as known
and asks for help completing the other weights.

The unpatched faces are still installed, so the full XLight-to-Bold range is
available for non-code use. They just won't render `!=` as a single glyph.

`Book` is Operator's name for its regular weight, which makes
`Operator Mono Lig Book` the natural editor default.

## Font naming

Font configuration is fussy about names, and these two differ in an easy-to-miss
way. Read from the actual `name` tables:

| File | Family (nameID 1) | Typographic family (16) | PostScript (6) |
| --- | --- | --- | --- |
| `OperatorMonoLig-Book.otf` | `Operator Mono Lig Book` | `Operator Mono Lig` | `OperatorMonoLig-Book` |
| `OperatorMonoLig-BookItalic.otf` | `Operator Mono Lig Book` | `Operator Mono Lig` | `OperatorMonoLig-BookItalic` |
| `FiraCodeNerdFontMono-Regular.ttf` | `FiraCode Nerd Font Mono` | — | `FiraCodeNFM-Reg` |
| `FiraCodeNerdFontMono-Retina.ttf` | `FiraCode Nerd Font Mono Ret` | `FiraCode Nerd Font Mono` | `FiraCodeNFM-Ret` |

Two consequences:

1. **Roman and italic share the family `Operator Mono Lig Book`.** So Cursor
   only needs `"editor.fontFamily": "Operator Mono Lig Book"` and italic scopes
   resolve to `OperatorMonoLig-BookItalic` on their own. That is what makes
   Operator's cursive italics show up under the One Dark Operator theme.
2. **The Retina face has its own family name**, `FiraCode Nerd Font Mono Ret`,
   not `FiraCode Nerd Font Mono`. iTerm2 is configured with the PostScript name
   (`FiraCodeNFM-Ret`), which is unambiguous. Cursor's terminal uses the plain
   `FiraCode Nerd Font Mono` family, which resolves to the Regular weight.

Retina is a hair heavier than Regular and was the weight in use in the 2022
setup, so iTerm keeps it.

## Enabling ligatures is a separate step per app

Installing the font is not enough — every app gates ligatures behind its own
setting, and most default to off:

| App | Setting | Configured by |
| --- | --- | --- |
| iTerm2 | `ASCII Ligatures` (per profile) | `iterm2/com.googlecode.iterm2.plist` |
| Cursor editor | `editor.fontLigatures` | `scripts/configure-cursor.sh` |
| Cursor terminal | `terminal.integrated.fontLigatures.enabled` | `scripts/configure-cursor.sh` |

iTerm2 also needs `Use Non-ASCII Font` **off**. If it's on, box-drawing and
Nerd Font glyphs get pulled from the fallback font instead of FiraCode, and the
prompt symbols render as tofu.

## Licensing

Operator Mono is commercial and non-redistributable, and the patched output
inherits that. See [../LICENSE-NOTICE.md](../LICENSE-NOTICE.md).

The build intermediates land in `.build/fonts/` (gitignored), including a
throwaway virtualenv for `fonttools`. `fonttools` is installed there rather than
globally because the patcher shells out to the `ttx` and `fonttools`
executables, so they only need to be on `PATH` while the build runs.
