#!/bin/bash
# Clover Dock — COSMIC's app list with hover window previews, installed as its own applet.
#   curl -fsSL https://github.com/onuraksoy3/cosmic-ext-applet-clover-dock/raw/main/build.sh | bash
# Builds cosmic-app-list from the exact upstream revision your system runs, with the hover-preview
# patch applied, and installs it as ~/.local/bin/clover-dock plus a "Clover Dock" applet entry.
# Flags: --no-swap   don't replace "App Tray" with "Clover Dock" in the dock configuration
set -euo pipefail
REPO_RAW="https://github.com/onuraksoy3/cosmic-ext-applet-clover-dock/raw/main"
UPSTREAM="https://github.com/pop-os/cosmic-applets.git"
APPLET_ID="io.github.onuraksoy3.CloverDock"
STOCK_ID="com.system76.CosmicAppList"
SWAP=1; for a in "$@"; do [ "$a" = --no-swap ] && SWAP=0; done
log()  { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || true)
WORK=${CLOVER_DOCK_SRC:-$HOME/src/clover-dock-build}; mkdir -p "$WORK"
PATCH="$WORK/hover-preview.patch"
if [ -n "$HERE" ] && [ -f "$HERE/patches/hover-preview.patch" ]; then
  cp "$HERE/patches/hover-preview.patch" "$PATCH"; PIN=$(cat "$HERE/UPSTREAM_REV")
else
  curl -fsSL "$REPO_RAW/patches/hover-preview.patch" -o "$PATCH" || die "cannot download the patch"
  PIN=$(curl -fsSL "$REPO_RAW/UPSTREAM_REV" || echo 63292ab)
fi

# --- toolchain
if ! command -v cargo >/dev/null; then
  die "Rust is not installed. Install it with: curl https://sh.rustup.rs -sSf | sh   (then re-run)"
fi
log "installing build dependencies (sudo)"
sudo apt-get install -y -q build-essential pkg-config git libxkbcommon-dev libwayland-dev libssl-dev >/dev/null

# --- source at the revision matching the installed cosmic-applets
REV=$(dpkg -s cosmic-applets 2>/dev/null | sed -n 's/^Version: .*~\([0-9a-f]\{7,\}\)$/\1/p')
[ -n "$REV" ] || REV=$PIN
log "cosmic-applets revision: $REV"
if [ ! -d "$WORK/cosmic-applets/.git" ]; then
  git clone -q "$UPSTREAM" "$WORK/cosmic-applets"
fi
cd "$WORK/cosmic-applets"
git fetch -q origin
git checkout -q -f "$REV" 2>/dev/null || { log "revision $REV not found upstream, using pinned $PIN"; git checkout -q -f "$PIN"; }
git clean -qfd cosmic-app-list

# --- patch + rename
log "applying hover-preview patch"
git apply --3way "$PATCH" || die "patch did not apply to $REV — open an issue with this revision"
grep -q '<<<<<<<' cosmic-app-list/src/app.rs && die "patch left conflicts in app.rs"
# Present as our own applet; keep the stock config id so favourites and settings are shared.
sed -i "s|    const APP_ID: &'static str = APP_ID;|    const APP_ID: \&'static str = \"$APPLET_ID\";|" cosmic-app-list/src/app.rs
grep -q "\"$APPLET_ID\"" cosmic-app-list/src/app.rs || die "applet id rename failed (upstream layout changed?)"

# --- build
log "building (first time ~15 min on a laptop)"
cargo build --release -p cosmic-app-list 2>&1 | grep -E '^error|Finished' || true
[ -x target/release/cosmic-app-list ] || die "build failed"

# --- install
install -Dm755 target/release/cosmic-app-list "$HOME/.local/bin/clover-dock"
mkdir -p "$HOME/.local/share/applications"
sed -e 's/^Name=.*/Name=Clover Dock/' \
    -e 's/^Comment=.*/Comment=App list with hover window previews (Clover)/' \
    -e "s|^Exec=.*|Exec=$HOME/.local/bin/clover-dock|" \
    "/usr/share/applications/$STOCK_ID.desktop" > "$HOME/.local/share/applications/$APPLET_ID.desktop"
mkdir -p "$HOME/.config/cosmic/$STOCK_ID/v1"
echo true > "$HOME/.config/cosmic/$STOCK_ID/v1/hover_preview"

DOCK="$HOME/.config/cosmic/com.system76.CosmicPanel.Dock/v1/plugins_center"
if [ "$SWAP" = 1 ] && [ -f "$DOCK" ] && grep -q "$STOCK_ID" "$DOCK"; then
  cp "$DOCK" "$DOCK.clover-dock.bak"
  sed -i "s/$STOCK_ID/$APPLET_ID/g" "$DOCK"
  log "dock now uses Clover Dock (backup: plugins_center.clover-dock.bak)"
else
  log "add it yourself: Settings → Desktop → Panel → Dock → Configure applets → Clover Dock (remove App Tray)"
fi
log "done. Hover a running app in the dock."
