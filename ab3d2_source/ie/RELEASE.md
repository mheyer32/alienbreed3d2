# AB3D2 Intuition Engine Packaged Runtime

Build: `202605101918`

This directory contains the Karlos-TKG-High packaged builds of Alien
Breed 3D II for Intuition Engine:

| Binary | Host |
|--------|------|
| `IntuitionEngine-AB3D2-Karlos-TKG-High-darwin-amd64` | macOS Intel |
| `IntuitionEngine-AB3D2-Karlos-TKG-High-darwin-arm64` | macOS Apple Silicon |
| `IntuitionEngine-AB3D2-Karlos-TKG-High-linux-amd64` | Linux x86-64 |
| `IntuitionEngine-AB3D2-Karlos-TKG-High-linux-arm64` | Linux ARM64 |
| `IntuitionEngine-AB3D2-Karlos-TKG-High-windows-amd64.exe` | Windows x86-64 |
| `IntuitionEngine-AB3D2-Karlos-TKG-High-windows-arm64.exe` | Windows ARM64 |

These are self-contained runtime distributions, not `.ie68` ROM files. Each
binary bundles:

- Intuition Engine;
- one packed Karlos-TKG-High AB3D2 IE68 image containing the program and all
  runtime assets.

The binaries bundle the Redux High IE68 program and present its existing
320x240 CLUT8 renderer through Intuition Engine's host-side display fitting.

The runtime reads all game assets directly from the packed image. It does not
extract or create an asset directory. The packaged runtimes do not require the
original `media/` tree, the source repository, or a `karlos-tkg-main/` checkout.

## Running

Run the binary for your host platform directly. No command-line arguments are
required for the bundled game. The game can start from a read-only location,
but its folder must be writable to save progress.

Saved progress is stored in `ab3d2-save.dat` beside the executable. Back up that
file to preserve progress. Move it with the executable when moving the game.
If it is absent, the packed default `boot.dat` is used and a new save file is
created only when the game saves.

To quit, close the Intuition Engine window or use the in-game menu's exit
option.

On Linux, the binary may need executable permission:

```sh
chmod +x ./IntuitionEngine-AB3D2-Karlos-TKG-High-linux-amd64
./IntuitionEngine-AB3D2-Karlos-TKG-High-linux-amd64
```

The Linux binaries expect a working audio stack (ALSA, PulseAudio, or
PipeWire) and standard graphics libraries (X11 or Wayland with OpenGL) to be
present on the host. Most modern desktop distributions provide these by
default.

Use the matching macOS or Linux binary for your CPU architecture. On Windows,
run the matching `.exe`.

## macOS Gatekeeper

macOS may attach a quarantine attribute to binaries downloaded from the
internet. `chmod +x` only sets the Unix executable bit; it does not remove that
quarantine attribute. If macOS refuses to run the binary from Terminal, use
both commands:

```sh
chmod +x ./IntuitionEngine-AB3D2-Karlos-TKG-High-darwin-arm64
xattr -d com.apple.quarantine ./IntuitionEngine-AB3D2-Karlos-TKG-High-darwin-arm64
./IntuitionEngine-AB3D2-Karlos-TKG-High-darwin-arm64
```

Use `darwin-amd64` instead of `darwin-arm64` on Intel Macs. Removing
quarantine is a local trust override; do it only for binaries obtained from a
trusted source.

On macOS Ventura (13) or later, an unsigned binary may still be blocked even
after `xattr -d com.apple.quarantine`. Two fallbacks:

- In Finder, right-click (or Control-click) the binary and choose **Open**,
  then confirm at the warning dialog. macOS records the per-app override and
  Terminal launches succeed afterwards.
- If quarantine returns or extra attributes remain, run
  `xattr -cr ./IntuitionEngine-AB3D2-Karlos-TKG-High-darwin-arm64` to clear all
  extended attributes recursively.

## Windows SmartScreen

Windows may show a "Windows protected your PC" SmartScreen warning the first
time an unsigned `.exe` is launched. Two ways through it:

- In the SmartScreen dialog, click **More info**, then **Run anyway**.
- From PowerShell, unblock the file before launch:

```powershell
Unblock-File .\IntuitionEngine-AB3D2-Karlos-TKG-High-windows-amd64.exe
.\IntuitionEngine-AB3D2-Karlos-TKG-High-windows-amd64.exe
```

Bypassing SmartScreen is a local trust override; do it only for binaries
obtained from a trusted source.

## Input

Menus use absolute mouse input. Gameplay uses captured relative mouse input so
turning continues even when the host cursor would otherwise hit a window or
desktop edge.

During captured gameplay, press `Ctrl+Alt` to release the host mouse so window
controls are reachable. On macOS, this is left-Control + left-Option (the Alt
key). Left-click inside the Intuition Engine window to recapture the mouse
while gameplay is still active.

Intuition Engine reserves host function keys for runtime tools:

| Key | Action |
|-----|--------|
| F8 | Toggle Lua REPL overlay |
| F9 | Toggle machine monitor |
| F10 | Hard reset runtime |
| F11 | Toggle fullscreen / windowed |
| F12 | Toggle status bar |

F10 hard reset reboots the bundled IE68 program from scratch and discards any
unsaved in-game progress. Use the in-game save option before pressing F10 if
you want to keep the current run.

F11 toggles between fullscreen and windowed display. Packaged builds start
fullscreen; press F11 once to drop to a window.

Because F9 is reserved by Intuition Engine, this build uses Backtick for the
AB3D2 pixel/double-height mode toggle.

## Notes

The packaged runtimes use the Karlos-TKG-High profile. They are separate from
the raw `.ie68` artifacts used by developers with an external Intuition Engine
binary. Menus use the IE renderer but retain the original AB3D2 moving
background, palette fades, fire-colour text effect, and credits screen.

## Links

- GitHub: https://github.com/IntuitionAmiga
- YouTube: https://youtube.com/@IntuitionAmiga
- Intuition Subsynth: Turn your Raspberry Pi into a headless Pro-Audio synthesizer!
  https://intuitionsubsynth.com
