#!/usr/bin/env bash
#
# Verify the install. Read-only: reports, never fixes.
#
# Exits non-zero if any check fails, so it can gate a CI job or a git hook.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKG_DIR="$REPO_ROOT/home"

pass=0; fail=0; warned=0

ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; pass=$((pass+1)); }
bad()  { printf '  \033[31m✗\033[0m %s\n' "$*"; fail=$((fail+1)); }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; warned=$((warned+1)); }
# Named 'section', not 'head': a function called head shadows /usr/bin/head for
# the whole script, so any `... | head -n` silently returns nothing and prints a
# bold "-n" instead. That had already broken the error detail below.
section() { printf '\n\033[1m%s\033[0m\n' "$*"; }

# ---------------------------------------------------------------------------
section "Homebrew packages"
# ---------------------------------------------------------------------------
for c in zsh starship mise direnv zoxide delta nvim stow gh jq bat eza fd rg; do
  if command -v "$c" >/dev/null 2>&1; then ok "$c"; else bad "$c not on PATH"; fi
done

# ---------------------------------------------------------------------------
section "Symlinks"
# ---------------------------------------------------------------------------
while IFS= read -r -d '' src; do
  rel="${src#"$PKG_DIR"/}"
  # Not stowed by design; it configures stow itself.
  [[ "$rel" == ".stow-local-ignore" ]] && continue
  dest="$HOME/$rel"
  # stow writes RELATIVE symlinks, so compare what the link resolves to rather
  # than the literal target text. -ef tests same-file after following links.
  if [[ -L "$dest" && "$dest" -ef "$src" ]]; then
    ok "$rel"
  elif [[ -L "$dest" ]]; then
    bad "$rel links to $(readlink "$dest"), not into this repo"
  elif [[ -e "$dest" ]]; then
    bad "$rel exists but is not a symlink (run 'make link')"
  else
    bad "$rel is not linked (run 'make link')"
  fi
done < <(find "$PKG_DIR" -type f -print0)

# ~/.config must be a real directory, not a symlink into the repo. If stow ran
# without --no-folding, every app writing to ~/.config writes into git.
if [[ -L "$HOME/.config" ]]; then
  bad "~/.config is a symlink — stow folded it. Run 'make unlink && make link'."
else
  ok "~/.config is a real directory (not folded)"
fi

# ---------------------------------------------------------------------------
section "Prezto"
# ---------------------------------------------------------------------------
if [[ -s "$HOME/.zprezto/init.zsh" ]]; then
  ok "~/.zprezto/init.zsh"
  for mod in autosuggestions syntax-highlighting history-substring-search; do
    if [[ -n "$(ls -A "$HOME/.zprezto/modules/$mod/external" 2>/dev/null)" ]]; then
      ok "module $mod"
    else
      bad "module $mod is empty (submodule not checked out)"
    fi
  done
else
  bad "Prezto not installed (run 'make prezto')"
fi

# ---------------------------------------------------------------------------
section "Fonts"
# ---------------------------------------------------------------------------
FD="$HOME/Library/Fonts"
for f in OperatorMonoLig-Book OperatorMonoLig-BookItalic \
         OperatorMonoLig-Light OperatorMonoLig-LightItalic; do
  [[ -f "$FD/$f.otf" ]] && ok "$f" || bad "$f.otf missing (run 'make fonts')"
done
n_unpatched=$(ls "$FD"/OperatorMono-*.otf 2>/dev/null | wc -l | tr -d ' ')
[[ "$n_unpatched" == "10" ]] && ok "unpatched Operator Mono family (10 faces)" \
  || warn "expected 10 unpatched Operator Mono faces, found $n_unpatched"
ls "$FD"/FiraCodeNerdFontMono-*.ttf >/dev/null 2>&1 \
  && ok "FiraCode Nerd Font Mono" || bad "FiraCode Nerd Font Mono missing"

# ---------------------------------------------------------------------------
section "Shell startup"
# ---------------------------------------------------------------------------
if command -v zsh >/dev/null 2>&1; then
  # OSC sequences are stripped before judging. Run from inside iTerm2, the shell
  # integration emits its RemoteHost/CurrentDir/ShellIntegrationVersion escapes at
  # source time, which are terminal control rather than diagnostic output — left
  # in, they make this check fail in iTerm2 and pass everywhere else.
  errs="$(zsh -i -c 'exit' 2>&1 \
    | perl -pe 's/\e\][^\a\e]*(?:\a|\e\\)//g' \
    | grep -v '^$' || true)"
  if [[ -z "$errs" ]]; then
    ok "interactive zsh starts clean"
  else
    bad "interactive zsh printed output on startup:"
    printf '      %s\n' "$errs" | head -10
  fi

  # A second compinit is slow and can shadow completions. Prezto's completion
  # module owns it; nothing in .zshrc.d should call it.
  if grep -rq '^\s*compinit' "$PKG_DIR/.zshrc.d/" 2>/dev/null; then
    bad "a fragment calls compinit (Prezto's completion module already does)"
  else
    ok "no duplicate compinit"
  fi

  # Tilde-prefixed fragments are silently SKIPPED by mattmc3/zshrc.d, not
  # sorted last. This is the bug that kept sdkman from ever loading.
  if ls "$PKG_DIR"/.zshrc.d/'~'* >/dev/null 2>&1; then
    bad "tilde-prefixed fragment found — the loader ignores these entirely"
  else
    ok "no tilde-prefixed fragments"
  fi
fi

# ---------------------------------------------------------------------------
section "zplug plugins"
# ---------------------------------------------------------------------------
# .zshrc gates `zplug check` behind a stamp file, so it no longer runs on every
# shell start. That verification moves here: this is now the thing that catches a
# plugin which vanished without .zshrc changing (a brew upgrade wiping the
# Cellar, a half-finished clone, a manual rm).
ZPLUG_REPOS="${ZPLUG_REPOS:-$HOME/.zplug/repos}"
OMZ_DIR="$ZPLUG_REPOS/robbyrussell/oh-my-zsh"

if [[ -d "$ZPLUG_REPOS" ]]; then
  # Guard against the old default, which put clones inside the versioned
  # Homebrew Cellar where `brew upgrade zplug` would delete them.
  case "$ZPLUG_REPOS" in
    */Cellar/*) bad "ZPLUG_REPOS is inside the Homebrew Cellar; a brew upgrade would wipe it" ;;
    *)          ok "zplug repos are outside the Homebrew Cellar" ;;
  esac

  while read -r spec from; do
    if [[ "$from" == "oh-my-zsh" ]]; then
      # plugins/foo from oh-my-zsh lives inside the shared oh-my-zsh clone.
      target="$OMZ_DIR/$spec"
    else
      target="$ZPLUG_REPOS/$spec"
    fi
    if [[ -d "$target" ]] && [[ -n "$(ls -A "$target" 2>/dev/null)" ]]; then
      ok "$spec${from:+ (oh-my-zsh)}"
    else
      bad "$spec not installed — rm ~/.zplug/check.stamp && exec zsh"
    fi
  done < <(sed -n 's/^[[:space:]]*zplug[[:space:]]*"\([^"]*\)".*/\1/p' "$PKG_DIR/.zshrc" \
            | while IFS= read -r line; do
                # Re-read the original line to recover a trailing from: tag.
                if grep -q "zplug \"$line\".*from:oh-my-zsh" "$PKG_DIR/.zshrc"; then
                  echo "$line oh-my-zsh"
                else
                  echo "$line"
                fi
              done)

  stamp="${ZPLUG_CACHE_DIR:-$HOME/.zplug/cache}/check.stamp"
  if [[ -f "$stamp" ]]; then
    ok "startup check is stamped (skips ~28ms per shell)"
  else
    warn "no stamp yet; the next shell start will run the full zplug check"
  fi
else
  bad "$ZPLUG_REPOS does not exist — start a shell to install plugins"
fi

# ---------------------------------------------------------------------------
section "mise / direnv separation"
# ---------------------------------------------------------------------------
if command -v mise >/dev/null 2>&1; then
  # Checked from $HOME: the pins are global, so they must resolve outside this
  # repo. If they only worked here, node would not exist machine-wide.
  for t in node python java; do
    if (cd "$HOME" && mise which "$t" >/dev/null 2>&1); then
      ok "mise provides $t globally"
    else
      bad "mise does not provide $t in \$HOME (run 'make mise')"
    fi
  done
fi
mise_line=$(grep -c 'mise activate' "$PKG_DIR/.zshrc.d/45-mise.zsh" 2>/dev/null || echo 0)
dir_line=$(grep -c 'direnv hook'   "$PKG_DIR/.zshrc.d/85-direnv.zsh" 2>/dev/null || echo 0)
if [[ "$mise_line" -gt 0 && "$dir_line" -gt 0 ]]; then
  ok "mise (45) loads before direnv (85)"
else
  bad "mise/direnv fragments not as expected"
fi

# .ruby-version is ignored unless ruby is opted in, and it fails silently: a
# Rails checkout would resolve to no Ruby with no warning.
if command -v mise >/dev/null 2>&1; then
  if mise settings get idiomatic_version_file_enable_tools 2>/dev/null | grep -q ruby; then
    ok "mise honors .ruby-version"
  else
    bad ".ruby-version is ignored; Rails checkouts will resolve to no Ruby"
  fi
fi
for f in libyaml autoconf; do
  brew list --formula "$f" >/dev/null 2>&1 \
    && ok "ruby-build dep $f" \
    || warn "ruby-build dep $f missing (only needed for Ruby <= 2.7)"
done

# POSIX ERE has no \s, so this uses an explicit space class.
if grep -qE '^[[:space:]]*(layout|PATH_add)\(\)' "$HOME/.config/direnv/direnvrc" 2>/dev/null; then
  ok "direnvrc guards against PATH-manipulating helpers"
else
  warn "direnvrc guards missing — direnv could fight mise over PATH"
fi

# ---------------------------------------------------------------------------
section "Git identity"
# ---------------------------------------------------------------------------
# gitdir: patterns are matched against resolved real paths. A symlinked ~/src
# breaks every rule at once.
if [[ -L "$HOME/src" ]]; then
  bad "~/src is a symlink; gitdir: patterns match real paths and will not fire"
else
  ok "~/src is a real directory"
fi

if git config --global --get user.email >/dev/null 2>&1; then
  warn "a global user.email is set; it will mask the per-org rules"
else
  ok "no global user.email (per-org rules are authoritative)"
fi

[[ "$(git config --global --get user.useConfigOnly)" == "true" ]] \
  && ok "useConfigOnly is on (unmapped repos error instead of guessing)" \
  || bad "user.useConfigOnly is not true"

# Check each includeIf rule resolves inside its directory.
while IFS= read -r pat; do
  dir="${pat#gitdir:}"
  dir="${dir/#\~/$HOME}"
  if [[ "$dir" == *CHANGEME* ]]; then
    warn "placeholder org still in .gitconfig: ${dir/#$HOME/~}"
    continue
  fi
  repo="$(find "$dir" -maxdepth 2 -type d -name .git -print -quit 2>/dev/null)"
  if [[ -z "$repo" ]]; then
    warn "no repo under ${dir/#$HOME/~} to test"
    continue
  fi
  email="$(git -C "$(dirname "$repo")" config --get user.email 2>/dev/null || true)"
  if [[ -z "$email" ]]; then
    bad "${dir/#$HOME/~} -> no identity resolved"
  elif [[ "$email" == *CHANGEME* || "$email" == *example.com ]]; then
    warn "${dir/#$HOME/~} -> $email (placeholder; see docs/git-identity.md)"
  else
    ok "${dir/#$HOME/~} -> $email"
  fi
done < <(git config --global --name-only --get-regexp '^includeif\.' 2>/dev/null \
          | sed -n 's/^[^.]*\.\(gitdir:.*\)\.path$/\1/p')
# The capture above is greedy on purpose: the directory contains dots
# ("github.com"), so a [^.]* pattern would match nothing.

[[ "$(git config --global --get core.pager)" == "delta" ]] \
  && ok "delta is the git pager" || warn "git pager is not delta"

# ---------------------------------------------------------------------------
section "Theming"
# ---------------------------------------------------------------------------
CURSOR_SETTINGS="$HOME/Library/Application Support/Cursor/User/settings.json"
if [[ -f "$CURSOR_SETTINGS" ]] && command -v jq >/dev/null 2>&1; then
  theme="$(jq -r '."workbench.colorTheme" // empty' "$CURSOR_SETTINGS" 2>/dev/null)"
  [[ -n "$theme" ]] && ok "Cursor theme: $theme" || bad "Cursor colorTheme unset"

  # Not `// empty`: jq's // treats `false` as absent, so a correctly-disabled
  # setting would read as unset. Ask whether the key exists instead.
  auto="$(jq -r 'if has("window.autoDetectColorScheme")
                 then ."window.autoDetectColorScheme" | tostring
                 else "unset" end' "$CURSOR_SETTINGS" 2>/dev/null)"
  [[ "$auto" == "false" ]] && ok "Cursor autoDetectColorScheme off" \
    || warn "Cursor autoDetectColorScheme is '$auto' — it can override the theme"

  jq -e '."editor.fontLigatures" == true' "$CURSOR_SETTINGS" >/dev/null 2>&1 \
    && ok "Cursor editor ligatures on" || bad "Cursor editor ligatures off"
  jq -e '."terminal.integrated.fontLigatures.enabled" == true' "$CURSOR_SETTINGS" >/dev/null 2>&1 \
    && ok "Cursor terminal ligatures on" || warn "Cursor terminal ligatures off"
else
  warn "Cursor settings.json not found or jq missing"
fi

if [[ "$(defaults read com.googlecode.iterm2 LoadPrefsFromCustomFolder 2>/dev/null)" == "1" ]]; then
  folder="$(defaults read com.googlecode.iterm2 PrefsCustomFolder 2>/dev/null)"
  [[ "$folder" == "$REPO_ROOT/iterm2" ]] && ok "iTerm2 reads prefs from the repo" \
    || warn "iTerm2 custom folder is $folder"
else
  warn "iTerm2 not pointed at the repo (run 'make iterm')"
fi

# --- iTerm2 shell integration ---
if [[ -r "$HOME/.iterm2_shell_integration.zsh" ]]; then
  if grep -q 'ShellIntegrationVersion' "$HOME/.iterm2_shell_integration.zsh"; then
    ok "iTerm2 shell integration installed"
  else
    bad "~/.iterm2_shell_integration.zsh is not the real script (bad download?)"
  fi

  util_count="$(find "$HOME/.iterm2" -maxdepth 1 -type f -perm -u+x 2>/dev/null | wc -l | tr -d ' ')"
  [[ "${util_count:-0}" -ge 16 ]] && ok "it2* utilities present ($util_count)" \
    || warn "only ${util_count:-0} it2* utilities (expected 16; run 'make iterm-integration')"

  # The fragment must sort AFTER the one that runs `starship init`, or the
  # integration decorates a prompt Starship then overwrites and the OSC 133 marks
  # disappear with no other symptom. Compare filenames rather than trusting the
  # numbers to stay put.
  prompt_frag="$(basename "$(grep -rl 'starship init' "$PKG_DIR/.zshrc.d/" 2>/dev/null | head -1)" 2>/dev/null)"
  iterm_frag="$(basename "$(grep -rl 'iterm2_shell_integration' "$PKG_DIR/.zshrc.d/" 2>/dev/null | head -1)" 2>/dev/null)"
  if [[ -n "$prompt_frag" && -n "$iterm_frag" ]]; then
    if [[ "$iterm_frag" > "$prompt_frag" ]]; then
      ok "$iterm_frag loads after $prompt_frag"
    else
      bad "$iterm_frag loads before $prompt_frag — OSC 133 marks will be lost"
    fi
  fi

  # End-to-end: the marks only work if iterm2_precmd ends up after Starship's in
  # precmd_functions. TERM_PROGRAM is forced because doctor may run anywhere.
  order="$(TERM_PROGRAM=iTerm.app TERM=xterm-256color zsh -i -c \
    'print -r -- "${precmd_functions[*]}"' 2>/dev/null | tail -1)"
  if [[ "$order" == *prompt_starship_precmd*iterm2_precmd* ]]; then
    ok "iterm2_precmd runs after starship's precmd"
  elif [[ "$order" == *iterm2_precmd* ]]; then
    bad "iterm2_precmd is registered before starship's precmd"
  else
    warn "could not confirm precmd order (integration did not load)"
  fi
else
  warn "iTerm2 shell integration missing (run 'make iterm-integration')"
fi

grep -q 'palette = "onedark"' "$PKG_DIR/.config/starship.toml" 2>/dev/null \
  && ok "starship One Dark palette" || bad "starship palette not set"

# Starship's Nerd Font glyphs are Private Use Area codepoints. They render as
# nothing when lost, and a blank symbol is indistinguishable from a space in
# both the editor and a diff -- every symbol in this config was silently blanked
# once without anything noticing. Two checks, because they catch different
# failures:
#
#   1. the config still declares glyphs (they weren't stripped again)
#   2. the glyphs survive to the rendered prompt (the font actually has them,
#      which matters because Nerd Fonts v3 moved codepoints v2 used)
blanks="$(grep -cE '^[[:space:]]*(symbol|read_only)[[:space:]]*=[[:space:]]*"[[:space:]]*"' \
  "$PKG_DIR/.config/starship.toml" 2>/dev/null || true)"
[[ "$blanks" -eq 0 ]] && ok "starship symbols all declare a glyph" \
  || bad "$blanks starship symbol(s) are blank — glyphs were stripped"

if command -v starship >/dev/null 2>&1 && git -C "$REPO_ROOT" rev-parse >/dev/null 2>&1; then
  # Strip ASCII (which removes the ANSI color codes too); anything left is the
  # glyph's UTF-8 bytes.
  glyph_bytes="$(cd "$REPO_ROOT" && starship module git_branch 2>/dev/null \
    | LC_ALL=C tr -d '\000-\177' | wc -c | tr -d ' ')"
  [[ "${glyph_bytes:-0}" -gt 0 ]] && ok "starship renders the git branch glyph" \
    || bad "starship git branch glyph renders blank"
fi

# ---------------------------------------------------------------------------
section "Login shell"
# ---------------------------------------------------------------------------
shell="$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')"
case "$shell" in
  /opt/homebrew/bin/zsh) ok "login shell is Homebrew zsh" ;;
  */zsh)                 warn "login shell is $shell (run 'make shell' for Homebrew's)" ;;
  *)                     bad "login shell is $shell, not zsh" ;;
esac

# ---------------------------------------------------------------------------
printf '\n\033[1m%d passed, %d failed, %d warnings\033[0m\n' "$pass" "$fail" "$warned"
(( fail == 0 )) || exit 1
