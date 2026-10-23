#!/bin/bash
# Removes Clover Dock and puts the stock App Tray back in the dock.
set -euo pipefail
APPLET_ID="io.github.onuraksoy3.CloverDock"; STOCK_ID="com.system76.CosmicAppList"
DOCK="$HOME/.config/cosmic/com.system76.CosmicPanel.Dock/v1/plugins_center"
[ -f "$DOCK" ] && sed -i "s/$APPLET_ID/$STOCK_ID/g" "$DOCK"
rm -f "$HOME/.local/bin/clover-dock" "$HOME/.local/share/applications/$APPLET_ID.desktop"
rm -f "$HOME/.config/cosmic/$STOCK_ID/v1/hover_preview" "$HOME/.config/cosmic/$STOCK_ID/v1/hover_preview_delay_ms"
echo "Clover Dock removed; the dock uses the stock App Tray again. Build directory left at ~/src/clover-dock-build."
