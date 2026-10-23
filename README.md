# Clover Dock

COSMIC's dock app list with **window previews on hover** — slide along the dock and each running app
shows its windows, macOS/Windows style, without clicking. Closed apps show their name in the same
bubble style as COSMIC's tooltips.

It is the stock `cosmic-app-list` from [pop-os/cosmic-applets](https://github.com/pop-os/cosmic-applets)
plus one patch, built from the exact revision your system runs and installed as a separate applet
(**Clover Dock**). Favourites and settings are shared with the stock applet, so switching back is one
click. Requires Pop!_OS 24.04 / COSMIC and a Rust toolchain.

## Install

```sh
curl -fsSL https://github.com/onuraksoy3/cosmic-ext-applet-clover-dock/raw/main/build.sh | bash
```

The script installs build dependencies, clones cosmic-applets at your installed revision, applies the
patch, builds (~15 min the first time), installs `~/.local/bin/clover-dock`, and swaps "App Tray" for
"Clover Dock" in the dock (`--no-swap` to do that yourself in Settings → Desktop → Panel → Dock).

Settings (no restart needed): `~/.config/cosmic/com.system76.CosmicAppList/v1/hover_preview`
(`true`/`false`) and `hover_preview_delay_ms` (default 350). The [Clover](https://github.com/onuraksoy3/cosmic-ext-applet-clover)
applet exposes both as a toggle.

Uninstall: `./uninstall.sh` (or `curl -fsSL …/uninstall.sh | bash`).

## How it works

`patches/hover-preview.patch`, against upstream revision in `UPSTREAM_REV`:

- `hover_preview` / `hover_preview_delay_ms` in the applet config (off by default upstream-style; the
  installer turns it on).
- Hover-opened previews are non-grabbing popups with their own close logic (switch when another icon is
  hovered, close ~0.4 s after the pointer leaves both icon and preview).
- Icon hover events proved unreliable while a popup exists, so icon switching uses hit-testing of
  pointer motion against the applet's tracked icon rectangles; a 250 ms gap after a close avoids a
  silently dropped popup; screenshots are requested at hover start.
- Tooltips are replaced by a hover bubble through the same path (a tooltip is a popup too and collided
  with previews).

Click behaviour is unchanged, and with `hover_preview = false` the applet behaves exactly like stock.
The patch is being proposed upstream; once merged, this repo becomes unnecessary.

## Updating

After a COSMIC update changes `cosmic-applets`, run the installer again: it rebuilds against the new
revision. If the patch no longer applies, open an issue with the revision from
`dpkg -s cosmic-applets | grep Version`.

## Licence

GPL-3.0, like cosmic-applets. Copyright System76 for the applet; patch and scripts © Onur Aksoy.
