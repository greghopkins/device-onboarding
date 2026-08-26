# Theming

One Dark, Atom's palette, applied consistently. The reference colors:

| Role | Hex |
| --- | --- |
| Background | `#282c34` |
| Foreground | `#abb2bf` |
| Comment / grey | `#5c6370` |
| Red | `#e06c75` |
| Orange | `#d19a66` |
| Yellow | `#e5c07b` |
| Green | `#98c379` |
| Cyan | `#56b6c2` |
| Blue | `#61afef` |
| Purple | `#c678dd` |

## Themed now

| Target | How | Configured in |
| --- | --- | --- |
| iTerm2 | One Dark preset applied to both profiles | `iterm2/com.googlecode.iterm2.plist` |
| Starship | `palette = "onedark"` + `[palettes.onedark]` | `home/.config/starship.toml` |
| Cursor | One Dark Operator extension | `scripts/configure-cursor.sh` |

### iTerm2

The 2022 plist already carried a `One Dark` custom color preset **and had it
applied to both profiles** — all 26 color keys already matched. Nothing needed
changing there. Solarized Dark and Solarized Light remain available as presets
in the same file if you ever want to switch.

The one thing that did need fixing was the font. The profile referenced
`FiraCodeNerdFontCompleteM-Retina`, the old Nerd Fonts naming for the Mono
variant, which no longer exists in the current cask. It is now
`FiraCodeNFM-Ret`. See [fonts.md](fonts.md).

### Starship

The One Dark palette is the only color addition; the Nerd Font symbols came from
the 2022 config. Those symbols are written as `\uXXXX` escapes rather than pasted
literally, which is worth preserving:

- The glyphs live in the Unicode Private Use Area, so they are invisible in most
  editors and a lost glyph looks exactly like a plain space — including in a
  diff. All 23 symbols were blanked at one point, and the only visible sign was a
  gap where the branch icon should have been.
- Nerd Fonts v3 relocated the Material Design range (`F500-FD46` to
  `F0001-F1AF0`). Five symbols carried over from 2022 pointed at codepoints that
  no longer exist and rendered blank even when the glyph was intact:
  `read_only`, `memory_usage`, `nim`, `package`, and `spack`. The first four now
  use their v3 equivalents; the `spack` module was dropped, since its symbol was
  never a Nerd Font glyph at all.

`doctor.sh` checks both halves of this: that the config still declares glyphs,
and that they survive into the rendered prompt.

### Cursor

`One Dark Operator` rather than the more popular One Dark Pro, because it tunes
its italic scopes for Operator Mono. Since `Operator Mono Lig Book` is one family
containing both roman and italic, those scopes resolve to the cursive italic face
automatically — that's the point of pairing this theme with this font.

Two settings interact badly and are worth knowing about:

- `window.autoDetectColorScheme` was `true` in the pre-existing settings. It
  follows the macOS light/dark setting and **overrides `workbench.colorTheme`**,
  so One Dark would revert whenever macOS switched to light mode. It is now
  `false`. If you'd rather keep OS-following behavior, set
  `workbench.preferredDarkColorTheme` and `workbench.preferredLightColorTheme`
  instead of turning it off.
- The theme is not published on OpenVSX, which is Cursor's default extension
  registry, so `cursor --install-extension` by ID may not resolve it.
  `configure-cursor.sh` falls back to downloading the `.vsix` from the VS Code
  marketplace. If both fail it settles for `Default Dark Modern` and says so
  rather than leaving the setting pointing at a theme that isn't installed.

## Not themed yet

Deliberately out of scope. Each is small on its own; grouped here so it's clear
what's left rather than looking like an oversight.

### bat

Ships `OneHalfDark`, which is close to One Dark but not identical. For exact
colors, add a `.tmTheme` to `~/.config/bat/themes/` and run `bat cache --build`.

```sh
export BAT_THEME="OneHalfDark"
```

Worth doing at the same time: `bat` makes a good pager for `man` and `--help`.

### delta

delta is already the git pager but uses its default colors. It takes a bat
syntax theme, so this becomes trivial once bat is themed:

```gitconfig
[delta]
	syntax-theme = OneHalfDark
```

### eza / LS_COLORS

`eza` is installed but `30-aliases.zsh` still aliases `ls` to BSD `ls` for
muscle memory. Theming directory listings means generating an `LS_COLORS` value
(via `vivid`, which is in Homebrew) and switching those aliases to `eza`.

### fzf

Colors are passed as flags, not a config file:

```sh
export FZF_DEFAULT_OPTS="--color=bg+:#3e4451,bg:#282c34,fg:#abb2bf,fg+:#ffffff,\
hl:#61afef,hl+:#61afef,info:#e5c07b,prompt:#e06c75,pointer:#c678dd,\
marker:#98c379,spinner:#c678dd,header:#5c6370"
```

### zsh-syntax-highlighting and autosuggestions

Both come from Prezto. Colors are set with `ZSH_HIGHLIGHT_STYLES` and
`ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE`. These must be set *after* Prezto loads, so a
new fragment numbered above `45` is the place for it — the suggestion grey
(`#5c6370`) is the main one worth setting, since the default can be hard to read
against `#282c34`.

### btop

Ships several themes. Drop a One Dark `.theme` into
`~/.config/btop/themes/` and set `color_theme` in `btop.conf`.

### Editors and terminals not in scope

VS Code (separate `settings.json` from Cursor), JetBrains IDEs (needs an editor
scheme XML plus separate font settings for editor and console), Neovim
colorscheme, Xcode, Zed, and Terminal.app. Terminal.app is worth noting
specifically: it has no ligature support at all, so it can take the font but not
the ligatures.
