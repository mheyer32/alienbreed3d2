# AB3D2 Intuition Engine Packaged Runtime

Build: `202605101918`

This directory contains platform-specific packaged builds of Alien Breed 3D II
for Intuition Engine. The standard Karlos-TKG-High builds are:

| Binary | Host |
|--------|------|
| `IntuitionEngine-AB3D2-Karlos-TKG-High-darwin-amd64` | macOS Intel |
| `IntuitionEngine-AB3D2-Karlos-TKG-High-darwin-arm64` | macOS Apple Silicon |
| `IntuitionEngine-AB3D2-Karlos-TKG-High-linux-amd64` | Linux x86-64 |
| `IntuitionEngine-AB3D2-Karlos-TKG-High-linux-arm64` | Linux ARM64 |
| `IntuitionEngine-AB3D2-Karlos-TKG-High-windows-amd64.exe` | Windows x86-64 |
| `IntuitionEngine-AB3D2-Karlos-TKG-High-windows-arm64.exe` | Windows ARM64 |

The Overdrive Karlos-TKG-High builds are:

| Binary | Host |
|--------|------|
| `IntuitionEngine-AB3D2-Karlos-TKG-High-Overdrive-darwin-amd64` | macOS Intel |
| `IntuitionEngine-AB3D2-Karlos-TKG-High-Overdrive-darwin-arm64` | macOS Apple Silicon |
| `IntuitionEngine-AB3D2-Karlos-TKG-High-Overdrive-linux-amd64` | Linux x86-64 |
| `IntuitionEngine-AB3D2-Karlos-TKG-High-Overdrive-linux-arm64` | Linux ARM64 |
| `IntuitionEngine-AB3D2-Karlos-TKG-High-Overdrive-windows-amd64.exe` | Windows x86-64 |
| `IntuitionEngine-AB3D2-Karlos-TKG-High-Overdrive-windows-arm64.exe` | Windows ARM64 |

These are self-contained runtime distributions, not `.ie68` ROM files. Each
binary bundles:

- Intuition Engine;
- the selected Karlos-TKG-High AB3D2 IE68 program;
- the prepared Karlos-TKG-High asset pack.

The Overdrive binaries bundle the Overdrive IE68 program, start fullscreen, and
present the existing 320x240 CLUT8 renderer as a full-frame 1920x1080 stretch.
They use the same prepared Karlos-TKG-High asset pack as the standard packaged
runtimes. The Overdrive runtime requires a display capable of 1920x1080. Press
F11 to drop out of fullscreen into a window if the host desktop is smaller or
fullscreen is otherwise unwanted.

On first launch, the runtime extracts its bundled asset tree (a directory named
`ab3d2_source/_build`) beside the executable if it is not already present, uses
the executable's folder as its working directory, then starts the bundled game.
The executable's folder must be writable on first launch. The packaged runtimes
do not require the original `media/` tree, the source repository, or a
`karlos-tkg-main/` checkout at runtime.

## Running

Run the binary for your host platform directly. No command-line arguments are
required for the bundled game. Put the binary in a normal writable folder, such
as your Downloads folder or a games/tools folder in your home directory, before
first launch. Do not run it from a read-only disk image or any location where
the executable cannot create files beside itself.

Keep the extracted `ab3d2_source/_build` directory beside the executable after
first launch; the runtime uses it for game media and saved progress. Saved
games live inside that directory tree, so back up the whole `ab3d2_source/_build`
folder if you want to preserve progress. If that directory is deleted, the
runtime recreates it from the bundled asset pack on the next launch and saved
progress stored there is lost. If the executable is moved, copy the
`ab3d2_source/_build` directory beside it in the new location to keep saves.

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

For Overdrive on Linux, use the matching Overdrive binary name, for example:

```sh
chmod +x ./IntuitionEngine-AB3D2-Karlos-TKG-High-Overdrive-linux-amd64
./IntuitionEngine-AB3D2-Karlos-TKG-High-Overdrive-linux-amd64
```

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

Use `darwin-amd64` instead of `darwin-arm64` on Intel Macs, and insert
`-Overdrive` in the filename when running an Overdrive package. Removing
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

F11 toggles between fullscreen and windowed display. Overdrive packages start
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
