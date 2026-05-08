# AB3D2 Intuition Engine Packaged Runtime

This directory contains platform-specific packaged builds of Alien Breed 3D II
for Intuition Engine:

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
- the Karlos-TKG-High AB3D2 IE68 program;
- the prepared Karlos-TKG-High asset pack.

On first launch, the runtime extracts its bundled `ab3d2_source/_build` asset
tree beside the executable if it is not already present, switches the runtime
base to that executable directory, then starts the bundled game. The executable
directory must be writable on first launch. The packaged runtimes do not
require the original `media/` tree, the source repository, or a
`karlos-tkg-main/` checkout at runtime.

## Running

Run the binary for your host platform directly. No command-line arguments are
required for the bundled game. Put the binary in a normal writable folder, such
as your Downloads folder or a games/tools folder in your home directory, before
first launch. Do not run it from a read-only disk image or any location where
the executable cannot create files beside itself.

Keep the extracted `ab3d2_source/_build` directory beside the executable after
first launch; the runtime uses it for game media. If that directory is deleted,
the runtime recreates it from the bundled asset pack on the next launch. If the
executable is moved, assets are expected beside the executable in its new
location.

On Linux, the binary may need executable permission:

```sh
chmod +x ./IntuitionEngine-AB3D2-Karlos-TKG-High-linux-amd64
./IntuitionEngine-AB3D2-Karlos-TKG-High-linux-amd64
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

Use `darwin-amd64` instead of `darwin-arm64` on Intel Macs. Removing quarantine
is a local trust override; do it only for binaries obtained from a trusted
source.

## Input

Menus use absolute mouse input. Gameplay uses captured relative mouse input so
turning continues even when the host cursor would otherwise hit a window or
desktop edge.

During captured gameplay, press `Ctrl+Alt` to release the host mouse so window
controls are reachable. Left-click inside the Intuition Engine window to
recapture the mouse while gameplay is still active.

Intuition Engine reserves host function keys for runtime tools:

| Key | Action |
|-----|--------|
| F8 | Toggle Lua REPL overlay |
| F9 | Toggle machine monitor |
| F10 | Hard reset runtime |
| F11 | Toggle fullscreen |
| F12 | Toggle status bar |

Because F9 is reserved by Intuition Engine, this build uses Backtick for the
AB3D2 pixel/double-height mode toggle.

## Notes

The packaged runtime is the Karlos-TKG-High profile. It is separate from the
raw `.ie68` artifacts used by developers with an external Intuition Engine
binary.
