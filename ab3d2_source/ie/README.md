# IE Native Port

This directory contains the Intuition Engine support layer for the
software-rendered `hires.s` build. The target is selected with `IS_IE` and runs
AB3D2 as a raw M68K program on IE rather than through AmigaOS, Exec, Intuition,
Paula, CIA, or real Amiga custom-chip MMIO.

## Scope

- Target: full software-renderer build from `ab3d2_source/hires.s`.
- Platform layer: `ab3d2_source/ie/ie_hires_platform.s`.
- Binary format: raw `.ie68` linked at `0x001000`.
- Build target: `make ie68` from `ab3d2_source/`.
- Overdrive build target: `make ie68-overdrive` from `ab3d2_source/`.
- Redux convenience targets: `make ie68-redux-high` and
  `make ie68-redux-low` from `ab3d2_source/`.
- Default output: `ab3d2_source/ab3d2_ie68.ie68`.
- Overdrive output: `ab3d2_source/ab3d2_ie68_overdrive.ie68`.
- Raw `.ie68` runtime cwd: run Intuition Engine from `ab3d2_source/` so raw
  file I/O sees the expected media tree.

The IE build keeps the AB3D2 software renderer and menu state machine. The
Amiga screen, blitter, input, file, music, SFX, and compatibility entrypoints
that the original code expects are satisfied by IE-specific glue.

## Build

From `ab3d2_source/`:

```sh
make ie68
make ie68-overdrive
make ie68-redux-high
make ie68-redux-low
make ie68-all
```

The IE `.ie68` binaries are committed in `ab3d2_source/` as playable artifacts
so users can download the repository and run them without first setting up the
Amiga build toolchain:

| Binary | Profile | SID fallback |
|--------|---------|--------------|
| `ab3d2_ie68.ie68` | Original | No |
| `ab3d2_ie68_overdrive.ie68` | Redux high Overdrive | No |
| `ab3d2_ie68_sid.ie68` | Original | Yes |
| `ab3d2_ie68_redux_high.ie68` | Redux high | No |
| `ab3d2_ie68_redux_high_sid.ie68` | Redux high | Yes |
| `ab3d2_ie68_redux_low.ie68` | Redux low | No |
| `ab3d2_ie68_redux_low_sid.ie68` | Redux low | Yes |

The `ie/` directory also contains platform-specific packaged runtime binaries
named `IntuitionEngine-AB3D2-Karlos-TKG-High-*` and
`IntuitionEngine-AB3D2-Karlos-TKG-High-Overdrive-*`. These are special
distributions, not `.ie68` ROMs: each one bundles Intuition Engine, the selected
Karlos-TKG-High AB3D2 IE68 program, and the Karlos-TKG-High asset pack. On first
launch, the packaged runtime extracts its bundled `_build` asset tree beside
the executable if it is not already present, switches the runtime base to that
executable directory, then runs the bundled game. These packaged runtimes do
not require the original `media/` tree or a `karlos-tkg-main/` checkout at
runtime.

| Binary | Host |
|--------|------|
| `IntuitionEngine-AB3D2-Karlos-TKG-High-darwin-amd64` | macOS Intel |
| `IntuitionEngine-AB3D2-Karlos-TKG-High-darwin-arm64` | macOS Apple Silicon |
| `IntuitionEngine-AB3D2-Karlos-TKG-High-linux-amd64` | Linux x86-64 |
| `IntuitionEngine-AB3D2-Karlos-TKG-High-linux-arm64` | Linux ARM64 |
| `IntuitionEngine-AB3D2-Karlos-TKG-High-windows-amd64.exe` | Windows x86-64 |
| `IntuitionEngine-AB3D2-Karlos-TKG-High-windows-arm64.exe` | Windows ARM64 |
| `IntuitionEngine-AB3D2-Karlos-TKG-High-Overdrive-darwin-amd64` | macOS Intel |
| `IntuitionEngine-AB3D2-Karlos-TKG-High-Overdrive-darwin-arm64` | macOS Apple Silicon |
| `IntuitionEngine-AB3D2-Karlos-TKG-High-Overdrive-linux-amd64` | Linux x86-64 |
| `IntuitionEngine-AB3D2-Karlos-TKG-High-Overdrive-linux-arm64` | Linux ARM64 |
| `IntuitionEngine-AB3D2-Karlos-TKG-High-Overdrive-windows-amd64.exe` | Windows x86-64 |
| `IntuitionEngine-AB3D2-Karlos-TKG-High-Overdrive-windows-arm64.exe` | Windows ARM64 |

SID music fallback is disabled by default so the IE build has functional parity
with the Amiga build. To opt into the IE SID fallback:

```sh
make ie68 IE_ENABLE_SID_MUSIC=1
```

With `IE_ENABLE_SID_MUSIC=0`, IE still plays the level ProTracker MOD music
when the GLF database provides one, but missing level music is treated as no
music. With `IE_ENABLE_SID_MUSIC=1`, missing level MOD music falls back to
`ie/at_dooms_gate_e1m1.sid`.

The Redux and Overdrive targets require the Redux data checkout at
`karlos-tkg-main/` in the `alienbreed3d2` repository root. The expected data
root is `karlos-tkg-main/Game`, and the build prepares the selected profile
under `ab3d2_source/_build/ie_media/`. This requirement applies to building the
raw Redux and Overdrive `.ie68` artifacts; the packaged runtime binaries
already contain the prepared Karlos-TKG-High program and assets.

The IE make fragment:

- converts original planar menu art into CLUT8 artifacts under
  `_build/ie_menu/`;
- unpacks runtime media into `_build/ie_unpacked/media/`;
- prepares Redux profile media under `_build/ie_media/` when requested;
- assembles `hires.s` with `-DIS_IE=1`;
- assembles `ie/ie_hires_platform.s`;
- links the selected `.ie68` target;
- writes the selected map file under `_build/`;
- generates `diag_symbols.lua` and copies it to `ie/diag_symbols.lua`.

Generated `_build/` files and `diag_symbols.lua` are build artifacts, not
source.

## Memory

The current IE software-renderer path uses these fixed addresses:

| Address | Use |
|---------|-----|
| `0x001000` | Raw `.ie68` code/data link address |
| `0x100000` | Main 320x240 CLUT8 chunky framebuffer (`CHUNKY_BASE`) |
| `0x113000` | Secondary 320x240 CLUT8 framebuffer (`CHUNKY_BACK_BASE`) |
| `0x126000` | 320x240 CLUT8 staging framebuffer for small viewport presentation (`PRESENT_BASE`) |
| `0x240000` | Primary 640x480 CLUT8 scaled presentation framebuffer for normal IE builds (`SCALE_BASE`) |
| `0x28B000` | Secondary 640x480 CLUT8 scaled presentation framebuffer for normal IE builds (`SCALE_BACK_BASE`) |
| `0x6F0000` | Fake library/vector base for compatibility entrypoints |
| `0x00C00000` | IE file-loader heap base (`ie_sys_heap_ptr` initial value) |
| `0xFE0000` | IE file-loader heap limit |
| `0x02000000` | Primary 1920x1080 CLUT8 high presentation framebuffer for Overdrive builds (`SCALE_BASE`) |
| `0x02200000` | Secondary 1920x1080 CLUT8 high presentation framebuffer for Overdrive builds (`SCALE_BACK_BASE`) |
| `0x02800000` | IE menu background/work buffer (`_mnu_screen`) |
| `0x02840000` | IE menu 8-plane work buffer (`_mnu_morescreen`) |

The renderer and converted menu assets remain 320x240 CLUT8 internally. IE
opens a 640x480 CLUT8 display and uses the VideoChip scale blitter to present
that 320x240 source at exactly 2x. Menus fill the display, and gameplay forces
the AB3D2 fullscreen viewport by default so the in-game view also fills the IE
display. The scaled presentation buffers are placed outside the active
VideoChip front-buffer span so `VIDEO_FB_BASE` presents the bus-backed CLUT8
pixels written by the scale blitter.

The Overdrive build is selected with `make ie68-overdrive`, which defines
`IE_OVERDRIVE=1`, selects `MEDIA_PROFILE=redux-high`, and produces
`ab3d2_ie68_overdrive.ie68`. It keeps the renderer, menus, gameplay drawing,
palettes, sprites, and bullets at the existing 320x240 CLUT8 resolution, loads
the Karlos-TKG-High asset profile, then uses `BLT_OP_SCALE` to stretch the full
source framebuffer to a 1920x1080 CLUT8 presentation buffer. This first
Overdrive build intentionally uses every output pixel, so it does not preserve
the original aspect ratio with letterboxing or pillarboxing. It requires an IE
runtime that supports `MODE_1920x1080` (`0x06`) and high bus-backed CLUT8
framebuffers large enough for two `1920 * 1080` buffers. It is presentation
upscaling only, not native 1080p rendering, Mode 7, Copper, Voodoo, side HUD
columns, bottom bars, transition effects, or debug overlays.

Overdrive clears the selected 1920x1080 CLUT8 presentation buffer before each
scale blit. Keep this clear in place: the scaled source is still a 320x240
software-rendered frame, and stale high-buffer pixels can otherwise show up as
missing small sprites or corrupted projectile edges.

## MMIO

Video:

| Register | Address | Use |
|----------|---------|-----|
| `VIDEO_CTRL` | `0xF0000` | Enable video |
| `VIDEO_MODE` | `0xF0004` | Set mode `0x00` for 640x480, or `0x06` for Overdrive 1920x1080 |
| `VIDEO_STATUS` | `0xF0008` | VBlank polling, bit `1` |
| `BLT_CTRL` | `0xF001C` | Start scale blit |
| `BLT_OP` | `0xF0020` | `BLT_OP_SCALE` (`7`) for presentation |
| `BLT_SRC` | `0xF0024` | 320x240 CLUT8 source buffer |
| `BLT_DST` | `0xF0028` | Scaled CLUT8 presentation buffer |
| `BLT_WIDTH` | `0xF002C` | Source width (`320`) |
| `BLT_HEIGHT` | `0xF0030` | Source height (`240`) |
| `BLT_SRC_STRIDE` | `0xF0034` | Source row bytes (`320`) |
| `BLT_DST_STRIDE` | `0xF0038` | Destination row bytes (`640`, or `1920` in Overdrive) |
| `BLT_COLOR` | `0xF003C` | Packed destination size `(480 << 16) | 640`, or `(1080 << 16) | 1920` in Overdrive |
| `VIDEO_PAL_INDEX` | `0xF0078` | Palette index |
| `VIDEO_PAL_DATA` | `0xF007C` | Palette RGBA data |
| `VIDEO_COLOR_MODE` | `0xF0080` | CLUT8 mode (`1`) |
| `VIDEO_FB_BASE` | `0xF0084` | Active scaled presentation framebuffer pointer |
| `BLT_FLAGS` | `0xF0488` | CLUT8 BPP selector (`1`) |

Input:

| Register | Address | Use |
|----------|---------|-----|
| Mouse X | `0xF0730` | Absolute X for menu compatibility |
| Mouse Y | `0xF0734` | Absolute Y for menu compatibility |
| Mouse buttons | `0xF0738` | Left/right button state |
| Scan code | `0xF0740` | Keyboard queue data |
| Scan status | `0xF0744` | Keyboard queue status, bit `0` means data available |
| Modifiers | `0xF0748` | Shift/Ctrl/Alt state |
| Mouse control | `0xF074C` | Bit `0` requests captured relative mouse mode |
| Mouse DX | `0xF0754` | Signed accumulated relative X delta, clears on read |
| Mouse DY | `0xF0758` | Signed accumulated relative Y delta, clears on read |

File I/O:

| Register | Address | Use |
|----------|---------|-----|
| `FILE_IO_NAME` | `0xF2200` | Pointer to NUL-terminated path |
| `FILE_IO_DATA` | `0xF2204` | Read destination or write source pointer |
| `FILE_IO_DATA_LEN` | `0xF2208` | Write byte length |
| `FILE_IO_CTRL` | `0xF220C` | Command; `1` loads file, `2` writes file |
| `FILE_IO_STATUS` | `0xF2210` | Zero on success |
| `FILE_IO_LEN` | `0xF2214` | Loaded byte length |

Audio:

| Register | Use |
|----------|-----|
| `0xF0BC0` | MOD file pointer |
| `0xF0BC4` | MOD file length |
| `0xF0BC8` | MOD control (`1` start, `2` stop/reset, `4` loop; IE writes `5`) |
| `0xF0BCC` | MOD status |
| `0xF0E20` | SID file pointer |
| `0xF0E24` | SID file length |
| `0xF0E28` | SID control (`1` start, `2` stop/reset, `4` loop; IE writes `5`) |
| `0xF0E80+` | IE SFX/sample playback path used by the platform layer |

Runtime control:

| Register | Address | Use |
|----------|---------|-----|
| `EXEC_CTRL` | `0xF2324` | ProgramExecutor control; IE writes `EXEC_OP_HARD_RESET` (`5`) when the game exits |

## Rendering And Presentation

The IE path keeps AB3D2's 8-bit chunky software renderer. `ie_hires_platform.s`
opens a CLUT8 IE video mode, uploads palettes through IE video MMIO, and uses
`BLT_OP_SCALE` to present either:

- the full 320x240 source buffer for menus/fullscreen gameplay paths; or
- the 192x160 game viewport copied into a 320x240 staging buffer.

After presenting the small viewport, the source viewport region is cleared so
old rows do not smear when the view moves. The v1 IE path forces gameplay into
AB3D2 fullscreen mode, so the small-viewport path is retained as compatibility
coverage for older viewport states.

Build and script verification should use the freshly built local engine binary
at `../IntuitionEngine/bin/IntuitionEngine`.

## Input And Menus

`ie_poll_input` reads IE keyboard and mouse MMIO directly. It updates AB3D2's
existing raw-key table (`KeyMap_vb`), enables IE captured relative mouse mode
for gameplay, accumulates `MOUSE_DY` into `_Sys_MouseY`, accumulates gameplay
`MOUSE_DX` in `ie_mouse_delta_x_w` until player control applies it to
`Vis_AngPos_w`, and mirrors buttons into the fake custom/CIA state expected by
the original mouse-control code. Menus disable captured mode and keep using
absolute mouse coordinates, so menu movement and clicks remain compatible with
existing IE scripts. In desktop IE builds, press `Ctrl+Alt` during captured
gameplay to release the host mouse so window controls are reachable; left-click
inside the IE window to recapture while gameplay still requests relative mode.

The native AB3D2 menu flow is retained. The Amiga menu blitter/screen path is
replaced by converted CLUT8 menu assets and IE framebuffer rendering. The IE
menu renderer recreates the original moving background, palette fades,
fire-colour text effect, and credits screen by updating the legacy menu
bitplanes before presenting them through IE video MMIO. Enter, Space, and left
mouse activate menu items; cursor-key menu movement is debounced in the IE menu
wait loop. Choosing Exit Game requests the Intuition Engine ProgramExecutor
hard-reset operation, so the game returns through the same reset-to-BASIC path
as the IE F10 hotkey.

The large menu work buffers are absolute high-memory symbols in IE builds, not
`.bsschip` allocations. This keeps `_mnu_screen` and `_mnu_morescreen` away
from the low-memory audio and runtime scratch areas.

Intuition Engine reserves host function keys for runtime tools: F8 toggles the
Lua REPL overlay, F9 toggles the machine monitor, F10 hard-resets the runtime,
F11 toggles fullscreen, and F12 toggles the status bar. The IE build therefore
uses replacement keys for the conflicting fixed in-game AB3D2 controls:

| Amiga key | IE key | Game action |
|-----------|--------|-------------|
| F9 | Backtick | Toggle pixel/double-height mode |

The upstream viewport-size key is disabled in IE because the port forces the
AB3D2 fullscreen viewport for scaled presentation. Other fixed AB3D2 in-game
keys keep their normal raw-key behavior in IE.

IE supplies small platform implementations for game services that are C-backed
in the Amiga/RTG path. `_Game_AddToInventory` updates the assembler inventory
layout directly: shield, jetpack, and weapon item words are ORed into the
player inventory, while health, fuel, and ammo words are saturated-added. Weapon
pickup, ammo pickup, weapon cycling, and number-key weapon selection depend on
this routine doing real work rather than acting as a stub.

## Media

For raw `.ie68` runs with an external Intuition Engine binary, run from
`ab3d2_source/`. Intuition Engine's `--media` argument does not currently
re-root the raw file-I/O MMIO loads used by this port. The packaged
`IntuitionEngine-AB3D2-Karlos-TKG-High-*` runtimes are different: they extract
their prepared assets beside the executable and run relative to that directory.

Expected original-profile paths include:

```text
media/
  includes/
    main.256pal
    test.lnk
    title.mod
    *.wad
    *.ptr
    *.256pal
  levels/
    level_a/
    level_b/
    ...
ie/
  at_dooms_gate_e1m1.sid
```

Prepare the original media tree from extracted media with:

```sh
ie/tools/normalize_media.sh .
```

The IE `mt_init` implementation loads the current level MOD from the GLF
`LevelMusic` entry with the IE file loader and starts it through IE MOD MMIO.
If no level MOD is available, SID-enabled builds fall back to
`ie/at_dooms_gate_e1m1.sid` through IE SID playback; default non-SID builds
treat missing level music as no music.

IE save/load uses the same host file-I/O path. The game keeps the original
`boot.dat` save format; loading reads the active profile `boot.dat`, and saving
writes the modified save-slot buffer back through `FILE_IO_CTRL=2`. For Redux
profiles this persists under the selected `_build/ie_media/.../boot.dat` tree.
Packaged runtime builds store progress in the extracted
`ab3d2_source/_build/ie_media/redux-high/boot.dat` tree beside the executable.

## Redux Diagnostics

The Redux-focused IEScript diagnostics avoid IE function-key mappings by using
scripted scancodes and direct memory writes to dev flags. The shared Lua helper
is `ie/diag_redux_common.lua`; local `ie/diag_redux_*.ies` scripts can use it to
drive gameplay, sample renderer/audio state and dump framebuffer histograms.
Build the desired profile first, then run the scripts from `ab3d2_source`:

```sh
make ie68-redux-high
```

Expected diagnostic coverage includes path resolution, render pointers, palette
and texture hashes, lighting/debug flags, wall-brightness scratch values,
framebuffer histograms, freeze/progress sampling, and MOD/SID playback
registers. The local Redux scripts default to `ab3d2_ie68_redux_high.ie68`. If
the IEScript host predefines `IE_TARGET` or `TARGET`, that value is loaded
instead.

## Source Boundaries

IE-specific platform code belongs under `ab3d2_source/ie/` wherever possible.
Non-IE source touches should remain limited to build wiring, `IS_IE` include
selection, and unavoidable callsite guards around Amiga-specific hardware or OS
assumptions.

Key IE files:

- `build.mk`: IE build targets and generated diagnostics.
- `ie_keymap.i`: IE-only replacement keys for fixed AB3D2 controls that collide
  with IE host shortcuts.
- `ie_hires_platform.s`: video, input, audio, menu, system, fake-library,
  message, inventory, and zone compatibility entrypoints.
- `controlloop.s`: IE startup/menu/game outer-loop flow selected by `IS_IE`.
- `ie_file_io_runtime.i`: IE raw file loader and media path normalization.
- `ie_music.i`: legacy `mt_*` entrypoints backed by IE MOD MMIO with SID
  fallback.
- `MEDIA_LAYOUT.md`: focused media-tree notes.
- `tools/normalize_media.sh`: prepares the original local media layout.
- `tools/convert_menu_assets.py`: converts original planar menu art and
  palettes into IE CLUT8 build artifacts.
- `tools/prepare_media_profile.py`: prepares Redux high/low media profiles.

## Intuition Engine Links

- https://github.com/IntuitionAmiga/IntuitionEngine
- https://www.youtube.com/@intuitionamiga

## Shared Source Differences From Upstream

The port keeps IE-specific code under `ab3d2_source/ie/` where possible. These
files are shared with upstream `mheyer32/alienbreed3d2` and currently differ on
disk. `.gitignore` intentionally remains byte-identical to upstream.

- `README.md`: documents the IE port at the repository root.
- `ab3d2_source/Makefile`: includes `ie/build.mk`. The IE targets themselves
  live in that IE-only make fragment.
- `ab3d2_source/bss/draw_bss.s`: under `IS_IE`, raises
  `DRAW_MAX_POLY_POINTS` and associated scratch buffers so IE object clipping
  cannot overrun the original 250-point allocation.
- `ab3d2_source/bss/player_bss.s`: under `IS_IE`, aligns and widens selected
  control/runtime flags used by IE input and emulator-sensitive byte writes.
- `ab3d2_source/hires.s`: contains `IS_IE` include selection and callsite
  guards for IE platform glue, Amiga custom-chip/Paula/CIA paths, IE input,
  menu, file I/O, music, presentation, pause, and exit-zone behavior.
- `ab3d2_source/menu/menunb.s`: under `IS_IE`, uses the IE key-read path and
  skips Amiga fire-button wait logic that depends on custom hardware while
  retaining the menu credits wait loop through the IE WaitTOF path.
- `ab3d2_source/modules/player.s`: under `IS_IE`, applies accumulated mouse X
  to `Vis_AngPos_w`, reads fake custom/CIA button state, disables viewport-size
  switching, and gates emulator-sensitive byte writes.
- `ab3d2_source/modules/res.s`: under `IS_IE`, does not load level MODs through
  the upstream Paula-specific `MEMF_CHIP` path. IE level music is loaded
  optionally by `ie_music.i` and played through IE MOD MMIO instead.
- `ab3d2_source/objdrawhires.s`: under `IS_IE`, guards zero or oversized object
  polygon point counts before clipping/drawing.
