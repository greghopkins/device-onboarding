#!/usr/bin/env bash
#
# Configure Cursor: One Dark Operator theme, Operator Mono Lig for the editor,
# FiraCode Nerd Font Mono for the integrated terminal.
#
# Settings are merged with jq rather than overwritten, so anything already in
# settings.json survives.

set -euo pipefail

CURSOR_APP="/Applications/Cursor.app"
CURSOR_CLI="$CURSOR_APP/Contents/Resources/app/bin/cursor"
USER_DIR="$HOME/Library/Application Support/Cursor/User"
SETTINGS="$USER_DIR/settings.json"
EXT_DIR="$HOME/.cursor/extensions"

EXT_PUBLISHER="kvnxush"
EXT_NAME="one-dark-operator-theme"
EXT_ID="$EXT_PUBLISHER.$EXT_NAME"

# Fallback if the theme can't be installed. Atom One Dark without the
# Operator-specific italic tuning.
THEME_FALLBACK="Default Dark Modern"

log()  { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33m==>\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31m==>\033[0m %s\n' "$*" >&2; exit 1; }

[[ -d "$CURSOR_APP" ]] || die "Cursor is not installed at $CURSOR_APP"
[[ -x "$CURSOR_CLI" ]] || die "Cursor CLI not found at $CURSOR_CLI"
command -v jq >/dev/null || die "jq not found. Run 'make brew' first."

# ---------------------------------------------------------------------------
# Theme extension
#
# Cursor resolves extension IDs against OpenVSX by default, and this theme is
# not published there, so 'cursor --install-extension <id>' may fail. The
# fallback downloads the .vsix straight from the VS Code marketplace gallery API
# and installs from file.
# ---------------------------------------------------------------------------

installed_ext_dir() {
  find "$EXT_DIR" -maxdepth 1 -type d -iname "$EXT_ID-*" 2>/dev/null | sort | tail -1
}

install_from_marketplace_vsix() {
  local api="https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery"
  local version vsix

  log "  Querying the VS Code marketplace for the latest version"
  version="$(curl -fsSL "$api" \
    -H 'Accept: application/json;api-version=7.2-preview.1' \
    -H 'Content-Type: application/json' \
    --data-binary "$(jq -nc --arg n "$EXT_ID" '{
        filters: [ { criteria: [ { filterType: 7, value: $n } ], pageSize: 1 } ],
        flags: 914
      }')" \
    2>/dev/null | jq -r '.results[0].extensions[0].versions[0].version // empty')" || true

  [[ -n "$version" ]] || { warn "  Could not determine the latest version"; return 1; }
  log "  Latest is $version"

  vsix="$(mktemp -t one-dark-operator).vsix"
  local url="https://marketplace.visualstudio.com/_apis/public/gallery/publishers/$EXT_PUBLISHER/vsextensions/$EXT_NAME/$version/vspackage"

  # The gallery serves this gzip-encoded; --compressed lets curl decode it.
  if ! curl -fsSL --compressed -o "$vsix" "$url"; then
    warn "  Download failed"
    rm -f "$vsix"
    return 1
  fi

  log "  Installing from $vsix"
  "$CURSOR_CLI" --install-extension "$vsix" --force >/dev/null 2>&1 || {
    warn "  Install from .vsix failed"
    rm -f "$vsix"
    return 1
  }
  rm -f "$vsix"
}

theme_installed=false
if [[ -n "$(installed_ext_dir)" ]]; then
  log "One Dark Operator already installed"
  theme_installed=true
else
  log "Installing One Dark Operator ($EXT_ID)"
  if "$CURSOR_CLI" --install-extension "$EXT_ID" --force >/dev/null 2>&1 \
    && [[ -n "$(installed_ext_dir)" ]]; then
    log "  Installed by extension ID"
    theme_installed=true
  else
    warn "  Not resolvable by ID (expected: absent from OpenVSX). Falling back."
    if install_from_marketplace_vsix && [[ -n "$(installed_ext_dir)" ]]; then
      log "  Installed from .vsix"
      theme_installed=true
    fi
  fi
fi

# ---------------------------------------------------------------------------
# Determine the theme's display name
#
# workbench.colorTheme wants the theme's label, not the extension ID. Read it
# from the installed extension rather than hardcoding a guess.
# ---------------------------------------------------------------------------

THEME_NAME="$THEME_FALLBACK"
if [[ "$theme_installed" == true ]]; then
  ext_pkg="$(installed_ext_dir)/package.json"
  if [[ -f "$ext_pkg" ]]; then
    label="$(jq -r '
      [ .contributes.themes[]? | select((.uiTheme // "") == "vs-dark") | (.label // .id) ]
      | first // empty' "$ext_pkg" 2>/dev/null || true)"
    [[ -n "$label" ]] && THEME_NAME="$label"
  fi
fi

if [[ "$theme_installed" == true ]]; then
  log "Theme: $THEME_NAME"
else
  warn "Could not install One Dark Operator. Falling back to '$THEME_FALLBACK'."
  warn "  Install it manually: Extensions -> search 'One Dark Operator'"
  warn "  then set workbench.colorTheme to its name."
fi

# ---------------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------------

mkdir -p "$USER_DIR"
[[ -f "$SETTINGS" ]] || echo '{}' > "$SETTINGS"

# Cursor tolerates comments and trailing commas in settings.json; jq does not.
# Bail out rather than mangling a file we can't parse.
if ! jq empty "$SETTINGS" >/dev/null 2>&1; then
  die "$SETTINGS is not strict JSON (comments or trailing commas?). Fix it, then re-run."
fi

log "Merging settings into $SETTINGS"
tmp="$(mktemp)"

# Notes on specific settings:
#
#   window.autoDetectColorScheme  Was true. It switches themes to follow the OS
#                                 light/dark setting, which overrides
#                                 workbench.colorTheme and would undo One Dark
#                                 every time macOS flipped to light mode.
#
#   editor.fontFamily             "Operator Mono Lig Book" is the family name
#                                 covering roman AND italic, so italic scopes in
#                                 the theme resolve to OperatorMonoLig-BookItalic
#                                 automatically. Falls back to the unpatched
#                                 Operator Mono, then Menlo.
#
#   terminal.integrated.fontLigatures.enabled
#                                 Verified as the correct key for Cursor 3.17.
#                                 Older builds used experimentalFontLigatures.
jq --arg theme "$THEME_NAME" '. + {
  "workbench.colorTheme": $theme,
  "window.autoDetectColorScheme": false,
  "editor.fontFamily": "'\''Operator Mono Lig Book'\'', '\''Operator Mono Book'\'', Menlo, Monaco, monospace",
  "editor.fontLigatures": true,
  "editor.fontSize": 14,
  "editor.fontWeight": "normal",
  "terminal.integrated.fontFamily": "'\''FiraCode Nerd Font Mono'\''",
  "terminal.integrated.fontLigatures.enabled": true
}' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"

log "Done:"
log "  theme            $THEME_NAME"
log "  editor font      Operator Mono Lig Book (ligatures on)"
log "  terminal font    FiraCode Nerd Font Mono (ligatures on)"
log ""
log "Restart Cursor to pick up the theme extension."
