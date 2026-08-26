#!/usr/bin/env bash
#
# Install the editor and terminal fonts.
#
#   Editor:   Operator Mono Lig  (licensed Operator Mono + Fira Code ligatures)
#   Terminal: FiraCode Nerd Font Mono  (installed by Homebrew, only verified here)
#
# Operator Mono ships without programming ligatures, so the Light and Book
# weights are patched with kiliman/operator-mono-lig. See docs/fonts.md for why
# only those two weights get ligatures.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FONT_ZIP="$REPO_ROOT/fonts/HCo_OperatorMono.zip"
BUILD_DIR="$REPO_ROOT/.build/fonts"
FONT_DEST="$HOME/Library/Fonts"

LIG_VERSION="2.5.2"
LIG_URL="https://github.com/kiliman/operator-mono-lig/archive/refs/tags/v${LIG_VERSION}.tar.gz"

# The patcher only ships ligature glyph sets for these four faces of the
# non-SSm family. Adding more here does nothing: build.sh skips any face
# without a matching ligature/<name>/glyphs directory.
PATCHABLE=(
  OperatorMono-Light
  OperatorMono-LightItalic
  OperatorMono-Book
  OperatorMono-BookItalic
)

log()  { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33m==>\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31m==>\033[0m %s\n' "$*" >&2; exit 1; }

# --- preconditions -----------------------------------------------------------

[[ -f "$FONT_ZIP" ]] || die "Missing $FONT_ZIP. See LICENSE-NOTICE.md."

mkdir -p "$FONT_DEST"

# --- FiraCode Nerd Font (terminal) -------------------------------------------

if ls "$FONT_DEST"/FiraCodeNerdFontMono-* >/dev/null 2>&1 \
  || ls /opt/homebrew/Caskroom/font-fira-code-nerd-font >/dev/null 2>&1; then
  log "FiraCode Nerd Font Mono present"
else
  warn "FiraCode Nerd Font Mono not found. Run 'make brew' first."
fi

# --- unpack Operator Mono ----------------------------------------------------

log "Unpacking Operator Mono"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
unzip -q -o "$FONT_ZIP" -d "$BUILD_DIR"

OTF_SRC="$BUILD_DIR/HCo_OperatorMono/OpenType"
[[ -d "$OTF_SRC" ]] || die "Unexpected archive layout: $OTF_SRC not found"

# --- install the unpatched family --------------------------------------------
#
# All ten faces go in, not just the patchable four, so the full weight range
# (XLight through Bold) is available for non-code use. Only Light and Book will
# get ligature-enabled counterparts.

log "Installing unpatched Operator Mono family"
installed=0
for otf in "$OTF_SRC"/*.otf; do
  name="$(basename "$otf")"
  if [[ ! -f "$FONT_DEST/$name" ]]; then
    cp "$otf" "$FONT_DEST/$name"
    installed=$((installed + 1))
  fi
done
log "  $installed new, $(ls "$OTF_SRC"/*.otf | wc -l | tr -d ' ') total"

# --- patch ligatures into Light and Book -------------------------------------

if [[ -f "$FONT_DEST/OperatorMonoLig-Book.otf" ]]; then
  log "Operator Mono Lig already installed, skipping build"
  log "  (delete $FONT_DEST/OperatorMonoLig-Book.otf to force a rebuild)"
  exit 0
fi

# node and python come from mise. When this script is invoked from a
# non-interactive context (a Makefile recipe, CI) the mise shell hook has not
# run, so PATH has neither. Resolve through mise explicitly rather than assuming
# an activated shell.
resolve() {
  local tool="$1" path
  if path="$(command -v "$tool" 2>/dev/null)"; then
    printf '%s' "$path"
    return 0
  fi
  if command -v mise >/dev/null 2>&1 && path="$(mise which "$tool" 2>/dev/null)"; then
    [[ -n "$path" ]] && { printf '%s' "$path"; return 0; }
  fi
  return 1
}

NODE="$(resolve node)" || die "node not found. Run 'make mise' first."
PY="$(resolve python3)" || PY="$(resolve python)" \
  || die "python3 not found. Run 'make mise' first."

# build.sh calls `node` by name, so its directory has to be on PATH.
export PATH="$(dirname "$NODE"):$PATH"

# fonttools goes in a throwaway venv rather than a global pip install: build.sh
# shells out to the `ttx` and `fonttools` executables directly, so they only
# need to be on PATH for the duration of the build.

log "Setting up fonttools in a scoped venv"
VENV="$BUILD_DIR/venv"
"$PY" -m venv "$VENV"
"$VENV/bin/pip" install --quiet --upgrade pip
"$VENV/bin/pip" install --quiet fonttools

log "Fetching operator-mono-lig v$LIG_VERSION"
LIG_DIR="$BUILD_DIR/operator-mono-lig"
mkdir -p "$LIG_DIR"
curl -fsSL "$LIG_URL" | tar -xz -C "$LIG_DIR" --strip-components=1

# Filenames must not contain spaces; the archive's names already comply.
log "Staging patchable faces"
for face in "${PATCHABLE[@]}"; do
  if [[ -f "$OTF_SRC/$face.otf" ]]; then
    cp "$OTF_SRC/$face.otf" "$LIG_DIR/original/$face.otf"
  else
    warn "  $face.otf not in the archive, skipping"
  fi
done

log "Building ligature fonts (this takes a minute)"
(
  cd "$LIG_DIR"
  export PATH="$VENV/bin:$PATH"
  npm install --silent --no-audit --no-fund
  ./build.sh
)

shopt -s nullglob
built=("$LIG_DIR"/build/*.otf)
shopt -u nullglob
[[ ${#built[@]} -gt 0 ]] || die "Build produced no fonts. Check the output above."

log "Installing ${#built[@]} ligature fonts"
for otf in "${built[@]}"; do
  cp "$otf" "$FONT_DEST/$(basename "$otf")"
  log "  $(basename "$otf")"
done

log "Done. Fonts are in $FONT_DEST"
