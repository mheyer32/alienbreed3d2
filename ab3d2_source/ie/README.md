# IE Native Port

This directory contains the Intuition Engine support layer for the
software-rendered `hires.s` build. The target is selected with `IS_IE` and runs
AB3D2 as a raw M68K program on IE rather than through AmigaOS, Exec, Intuition,
Paula, CIA, or real Amiga custom-chip MMIO.

## Scope

- Target: full software-renderer build from the upstream `ab3d2_source/hires.s`.
- Platform layer: `ab3d2_source/ie/platform/ie_hires_platform.s`.
- Binary format: the `.ie68` program is linked at guest address `0x001000`. The
  pack header is at guest address `0x00600000` (file offset `0x005FF000`), and
  indexed asset data begins at guest address `0x01000000` (file offset
  `0x00FFF000`).
- Build target: `make -f ie/Makefile ie68` from `ab3d2_source/`.
- Redux High build target: `make -f ie/Makefile ie68-redux-high` from `ab3d2_source/`.
- Default output: `ab3d2_source/ie/bin/ab3d2_ie68.ie68`.
- Development-only `ie68-raw` builds use the current working directory for
  File MMIO assets. Canonical `ie68` and `ie68-redux-high` builds are
  self-contained.
- End-user run instructions for the packaged runtime binaries live in
  `ab3d2_source/ie/RELEASE.md`.

The IE build keeps the AB3D2 software renderer and menu state machine. The
Amiga screen, blitter, input, file, music, SFX, and compatibility entrypoints
that the original code expects are satisfied by IE-specific glue.

## Build

From `ab3d2_source/`:

```sh
make -f ie/Makefile ie68               # original profile
make -f ie/Makefile ie68-redux-high    # Redux High guest image
make -f ie/Makefile ie68-all           # build every variant above
```

The `ie68` and `ie68-redux-high` targets link raw intermediates under
`ab3d2_source/_build/`, then write packed `.ie68` artifacts under
`ab3d2_source/ie/bin/`. The aggregate `ie68-all` target invokes both image
builds. Their map files also go under `ab3d2_source/_build/`. Standard builds
generate the diagnostic symbol file from the map and copy it to
`ab3d2_source/ie/diag_symbols.lua`.
Specialised diagnostic targets may write profile-specific symbol files under
`ie/bin/` instead.

### Source boundary

The upstream source tree is never edited for the IE port. `ie/patches/series`
defines the ordered port patch series, and `ie/tools/prepare_source_overlay.py`
applies it to `_build/ie-source/` for each build. Files that patches do not
change are symbolic links to the upstream source. IE-owned assembly includes
and platform code live in `ie/platform/`.

Use `make -f ie/Makefile ie-patches-check` to dry-run the patch series and
`make -f ie/Makefile ie-source-overlay-test` to verify the resulting patched
sources against their reviewed SHA-256 values. See
[`ie/patches/README.md`](patches/README.md) for patch maintenance.

### Build flags

| Flag | Values | Effect |
|------|--------|--------|
| `MEDIA_PROFILE` | `original` (default), `redux-high` | Selects the original or Redux High guest media paths. |

IE plays the level ProTracker MOD music selected by the GLF database.

### Output overrides

The build fragment exposes path overrides for callers that need to relocate
artifacts:

| Variable | Default | Purpose |
|----------|---------|---------|
| `IE_BIN_DIR` | `ie/bin` | Directory the `.ie68` artifact is written to. |
| `IE_TARGET` | `$(IE_BIN_DIR)/ab3d2_ie68.ie68` | Raw linker output used by `ie68-raw` and specialised diagnostic builds. Canonical targets override it with an intermediate under `$(BUILD_DIR)`. |
| `IE_MAP` | `$(BUILD_DIR)/ie68.map` | vlink map output path. |
| `IE_SYMBOLS` | `diag_symbols.lua` | Generated Lua diagnostic symbol file. Standard builds copy it to `ie/diag_symbols.lua`; specialised targets may override the output path. |
| `IE_DIAG_SYMBOLS_FILE` | `ie/diag_symbols.txt` | Plain-text list of symbol names extracted from the map into `IE_SYMBOLS`. |
| `IE_HIRES_SOURCE` | `$(BUILD_DIR)/ie-source/hires.s` | Patched overlay source assembled for the IE link. |
| `BUILD_DIR` | `_build` | Root directory for generated files. |

### Redux High prerequisites

The Redux High target requires the Redux data checkout at
`karlos-tkg-main/` in the `alienbreed3d2` repository root. The expected data
root is `karlos-tkg-main/Game`, and the build prepares the selected profile
under `ab3d2_source/_build/ie_media/`. This requirement applies to building the
raw Redux `.ie68` artifacts; the packaged runtime binaries
already contain the prepared Karlos-TKG-High program and assets.

### Pipeline overview

The IE make fragment:

- converts original planar menu art into CLUT8 artifacts under
  `_build/ie_menu/`;
- unpacks runtime media into `_build/ie_unpacked/media/`;
- prepares Redux High profile media under `_build/ie_media/redux-high/` when
  requested (stamp file: `_build/ie_media/redux-high/.stamp`);
- writes the selected media-profile include (`media_profile.i`) under
  `_build/ie/<profile>/`;
- creates `_build/ie-source/` from upstream source plus the reviewed patch series;
- assembles `_build/ie-source/hires.s` with `-DIS_IE=1`;
- assembles `ie/platform/ie_hires_platform.s`;
- links the selected `.ie68` target into `$(IE_TARGET)`;
- packs the selected program and prepared media into the final `.ie68`, with a
  checksummed index and checksummed asset data;
- writes the selected map file under `_build/` (path: `$(IE_MAP)`);
- generates `$(IE_SYMBOLS)` from the map by extracting the symbol names listed
  in `$(IE_DIAG_SYMBOLS_FILE)`, then copies it to the configured diagnostic
  output path.

Generated `_build/` files and `diag_symbols.lua` are build artifacts, not
source.

## Distribution

Two kinds of pre-built artifact ship for users who do not want to set up the
Amiga toolchain.

### Committed `.ie68` artifacts

Pre-built `.ie68` binaries are committed in this repository so users can clone
and run them through an external Intuition Engine binary without first building
the Amiga code. Fresh local builds emit to `ab3d2_source/ie/bin/`.

| Binary | Profile |
|--------|---------|
| `ab3d2_ie68.ie68` | Original, packed |
| `ab3d2_ie68_redux_high.ie68` | Redux High, packed |

All images contain every file needed at runtime. The original build derives a
201-file runtime inventory from its game database and level set, excluding the
editor archive from the pack. The guest checks the pack header, index and
selected asset before copying data to its heap. File MMIO remains available as
a fallback for development images and as the persistent save path. A host file
named `ab3d2-save.dat` overrides `boot.dat` when present, and save operations
write that file without changing the packed image. Redux supplies an embedded
default `boot.dat`; the original build starts without one when no save exists.

### Packaged runtime binaries

Six platform-specific packaged runtime binaries named
`IntuitionEngine-AB3D2-Karlos-TKG-High-*` are distributed in
`IntuitionEngine-AB3D2-Karlos-TKG-High.zip`. The packaged release documented
by `ie/RELEASE.md` is Build `202605101918`; the archive is hosted at:

<https://drive.google.com/file/d/1Jg4A1V_HLtTfFQ3Z1ATE_b2JtkBvMVjv/view>

The zip is an external release asset and is not committed to this repository
because of its size. The repository does not verify the archive or its contents,
and no archive checksum is recorded here. Use a checksum supplied with the
release to verify the download. The binaries are not standalone `.ie68` files:
each bundles Intuition Engine and the packed Karlos-TKG-High AB3D2 IE68 image.
The runtime does not extract assets.
Only `ab3d2-save.dat` may be created beside the executable when the game is
saved. These packaged runtimes do not require the original `media/` tree or a
`karlos-tkg-main/` checkout at runtime. End-user instructions live in
`ab3d2_source/ie/RELEASE.md`.

| Binary | Host |
|--------|------|
| `IntuitionEngine-AB3D2-Karlos-TKG-High-darwin-amd64` | macOS Intel |
| `IntuitionEngine-AB3D2-Karlos-TKG-High-darwin-arm64` | macOS Apple Silicon |
| `IntuitionEngine-AB3D2-Karlos-TKG-High-linux-amd64` | Linux x86-64 |
| `IntuitionEngine-AB3D2-Karlos-TKG-High-linux-arm64` | Linux ARM64 |
| `IntuitionEngine-AB3D2-Karlos-TKG-High-windows-amd64.exe` | Windows x86-64 |
| `IntuitionEngine-AB3D2-Karlos-TKG-High-windows-arm64.exe` | Windows ARM64 |

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
| `0x00700000` | IE file-loader heap base (`IO_IE_HEAP_BASE`) |
| `0x00FE0000` | IE file-loader and system allocator heap limit |
| `0x003FFF00` | File-loader heap cursor (`IO_IE_HEAP_PTR`) |
| `0x00C00000` | System allocator heap cursor initial value (`ie_sys_heap_ptr`) |
| `0x02800000` | IE menu background/work buffer (`_mnu_screen`) |
| `0x02840000` | IE menu 8-plane work buffer (`_mnu_morescreen`) |

The renderer and converted menu assets remain 320x240 CLUT8 internally. IE
opens a 640x480 CLUT8 display and uses the VideoChip scale blitter to present
that 320x240 source at exactly 2x. Menus fill the display, and gameplay forces
the AB3D2 fullscreen viewport by default so the in-game view also fills the IE
display. The scaled presentation buffers are placed outside the active
VideoChip front-buffer span so `VIDEO_FB_BASE` presents the bus-backed CLUT8
pixels written by the scale blitter.

The port also uses synchronous VideoChip `FILL` operations for render-buffer
reset. Menu background and fire-plane transfers use `MEMCOPY`. Gameplay remains
full-screen; the legacy small-viewport staging path is not part of this
acceleration work.

## MMIO

Video:

| Register | Address | Use |
|----------|---------|-----|
| `VIDEO_CTRL` | `0xF0000` | Enable video |
| `VIDEO_MODE` | `0xF0004` | Set mode `0x00` for 640x480 |
| `VIDEO_STATUS` | `0xF0008` | VBlank polling, bit `1` |
| `BLT_CTRL` | `0xF001C` | Start a synchronous blit |
| `BLT_OP` | `0xF0020` | `FILL` (`1`), `SCALE` (`7`), or `MEMCOPY` (`8`) |
| `BLT_SRC` | `0xF0024` | 320x240 CLUT8 source buffer |
| `BLT_DST` | `0xF0028` | Scaled CLUT8 presentation buffer |
| `BLT_WIDTH` | `0xF002C` | Source width (`320`) |
| `BLT_HEIGHT` | `0xF0030` | Source height (`240`) |
| `BLT_SRC_STRIDE` | `0xF0034` | Source row bytes (`320`) |
| `BLT_DST_STRIDE` | `0xF0038` | Destination row bytes (`640`) |
| `BLT_COLOR` | `0xF003C` | Packed destination size `(480 << 16) | 640` |
| `BLT_STATUS` | `0xF0044` | Blitter status; bit `0` reports an error |
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

Timing:

| Register | Address | Use |
|----------|---------|-----|
| Monotonic microseconds low | `0xF075C` | Lower 32 bits of the monotonic microsecond counter |
| Monotonic microseconds high | `0xF0760` | Upper 32 bits of the monotonic microsecond counter |

Gamepad:

| Register | Address | Use |
|----------|---------|-----|
| Gamepad status | `0xF25C0` | Controller availability; bit `0` means record zero is present |
| Gamepad record zero | `0xF25D0` | Buttons, left-stick axes, and right-stick axes; each field is 32 bits |

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
| `0xF0BD4` | MOD playback position |

The platform layer uses four legacy SFX channels at `0xF0E80 + channel*0x20`.
Each channel contains a sample pointer at offset `0x00`, sample length at
`0x04`, loop pointer at `0x08`, loop length at `0x0C`, sample rate at `0x10`,
volume at `0x14`, a reserved word at `0x16`, format at `0x18`, and control at
`0x1C`. IE uses signed 8-bit format (`0`) and writes trigger (`1`) to control;
the current platform code uses a sample rate of `11025` and four output
channels. The platform passes `Aud_ChannelPick_b` to the channel selector: zero
uses round-robin, and non-zero values select one of the four channels.

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
old rows do not smear when the view moves. The current IE path forces gameplay
into AB3D2 fullscreen mode, so the small-viewport path is retained as
compatibility coverage for older viewport states.

Build and script verification should use the freshly built local engine binary
at `../../IntuitionEngine/bin/IntuitionEngine`.

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

### FPS counter

The original Custom Options `Display FPS` setting is available in the IE port
and remains off by default. When enabled it measures completed gameplay frames
against Intuition Engine's monotonic microsecond clock, averages the last eight
samples, and renders the resulting `FPS.tenths` value into the guest 320×240
framebuffer beside the existing HUD. It is therefore present in screenshots and
scales with the standard presentation path; it is not a host status-bar
measurement. The counter is intentionally inactive in menus,
which do not execute the gameplay frame loop.

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
AB3D2 fullscreen viewport for scaled presentation. `IE_KEY_SCREEN_SIZE` is
still defined in `ie/platform/ie_keymap.i` (mapped to `RAWKEY_DEL`) but the
consumer in `modules/player.s` in the generated `_build/ie-source/` overlay is
bypassed under `IS_IE`, so the binding is effectively dead. Other fixed AB3D2
in-game keys keep their normal raw-key behaviour in IE.

### Game controllers

The IE build reads controller record zero from Intuition Engine's gamepad MMIO
block. Controller input is active alongside the existing Player 1 keyboard and
mouse paths because the IE menu exposes key bindings but no legacy joystick
mode selector. Disconnecting clears controller-generated actions without
disabling keyboard or captured relative-mouse control. This release does not
add player-two controller support.

| Controller input | AB3D2 action |
|------------------|--------------|
| Left stick Y or D-pad up/down | Forwards/backwards |
| Left stick X | Step left/right |
| Right stick X or D-pad left/right | Turn left/right |
| Right stick Y | Look up/down |
| A, X, B, Y | Fire, use/open, duck toggle, jump |
| LB, RB, Start | Run, next weapon, pause |

Axes are digital. They engage at 8192 and release below 6144, providing
hysteresis around the dead zone. Use remains asserted while X is held so the
existing player-control edge detector cannot miss it. Duck, next weapon, and
pause use controller-layer pulses where their consumers require them.

`make -f ie/Makefile ie68-gamepad-test` builds a test-only variant whose
controller reader can consume a guest-RAM snapshot and runs
`ie/gamepad_test.ies` with the headless Intuition Engine runner by default, so
the automated target requires no display or physical controller. Production
builds contain no snapshot input path.
Real-device results are recorded in `ie/GAMEPAD_ACCEPTANCE.md` using the
non-headless build. Run `make -f ie/Makefile ie68-gamepad-acceptance` to copy
the manual acceptance script beside the Redux High `.ie68` binary and launch
that profile in the GUI. Redux High is required because the level-one switch
scenario is not present in the original profile. The script does not synthesise
input. It records canonical button and axis transitions in
`ie/bin/gamepad-live.result`, using positional face-button names so the output
remains valid for different printed controller layouts.
Press and release every physical button, close the engine, then inspect that
result file. Hold each tested input for at least one second; the diagnostic
samples twice per second to avoid materially slowing gameplay.

`make -f ie/Makefile ie68-blitter-test` builds a test-only Redux High variant
and runs it with the headless engine. The diagnostic checks guarded strided fills,
odd-sized linear copies, production menu operation counts, blitter status, and
the full-screen-only display contract. Production maps reject the test command
dispatcher and scratch memory.

IE supplies small platform implementations for game services that are C-backed
in the Amiga/RTG path. `_Game_AddToInventory` in
`ie/platform/ie_hires_platform.s` updates the assembler inventory layout
directly. It walks twelve item words at offset 44 of the player struct
supplied via `a0` and ORs them with the corresponding source words from `a2`
(shield, jetpack, weapon-class item flags). It then walks twenty-two
consumable words from offset 0 of the player struct against `a1` and applies
saturated 16-bit add (health, fuel, ammo). Weapon pickup, ammo pickup, weapon
cycling, and number-key weapon selection depend on this routine doing real
work rather than acting as a stub.

## Media

For raw `.ie68` runs with an external Intuition Engine binary, run from
`ab3d2_source/`. Intuition Engine's `--media` argument does not currently
re-root the raw file-I/O MMIO loads used by this port. The packaged
`IntuitionEngine-AB3D2-Karlos-TKG-High-*` runtimes read the program and assets
directly from the embedded IE68 image. They do not extract an asset directory
and do not require the original media tree or Redux checkout.

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
```

Prepare the original media tree from extracted media with:

```sh
ie/tools/normalize_media.sh .
```

The IE `mt_init` implementation loads the current level MOD from the GLF
`LevelMusic` entry with the IE file loader and starts it through IE MOD MMIO.

IE save/load uses the same host file-I/O path and keeps the original `boot.dat`
save format. Redux High packed images contain a default `boot.dat`; the
original packed image starts without one. When `ab3d2-save.dat` exists in the
host working directory, it overrides the packed default, and saves are written
to that file through `FILE_IO_CTRL=2`. Raw development runs may also fall back
to the relevant `media/boot.dat` when no packed asset is available. Packaged
runtimes store progress in `ab3d2-save.dat` beside the executable.

## Redux Diagnostics

The Redux-focused IEScript diagnostics avoid IE function-key mappings by using
scripted scancodes and direct memory writes to dev flags. The shared Lua helper
is `ie/diag_redux_common.lua`; local `ie/diag_redux_*.ies` scripts can use it to
drive gameplay, sample renderer/audio state and dump framebuffer histograms.
Build the desired profile first, then run the scripts from `ab3d2_source`. For
the Redux High scripts, generate matching diagnostic symbols and run the smoke
script with the headless engine:

```sh
make -f ie/Makefile ie68-redux-high IE_DIAG_SYMBOLS_OUT=ie/diag_symbols.lua
../../IntuitionEngine/bin/ie_headless --script-owned-term \
  -file-root "$PWD" \
  -script ie/diag_redux_smoke.ies \
  ie/bin/ab3d2_ie68_redux_high.ie68
```

The smoke command above only checks diagnostic-helper loading and a small set of
startup values. For broader checks, replace `ie/diag_redux_smoke.ies` with the
appropriate script: `ie/diag_redux_boot.ies`, `ie/diag_redux_bisect.ies`,
`ie/diag_redux_freeze_watch.ies`, `ie/diag_redux_lighting.ies`,
`ie/diag_redux_motion_corruption.ies`, `ie/diag_redux_palette.ies`, or
`ie/diag_redux_watch_ptrs.ies`.

Expected diagnostic coverage includes path resolution, render pointers, palette
and texture-palette byte dumps, lighting/debug flags, wall-brightness scratch
values, framebuffer histograms, freeze/progress sampling, and MOD playback
registers.
The scripts do not select an image themselves. Pass the image to the engine as
the final argument, as in the example above, and ensure that
`ie/diag_symbols.lua` was generated from the same build.

## Source Boundaries

IE-specific platform code belongs under `ab3d2_source/ie/` wherever possible.
Non-IE source touches should remain limited to build wiring, `IS_IE` include
selection, and unavoidable callsite guards around Amiga-specific hardware or OS
assumptions.

Key IE files:

- `build.mk`: IE build targets and generated diagnostics.
- `platform/ie_keymap.i`: IE-only replacement keys for fixed AB3D2 controls that collide
  with IE host shortcuts.
- `platform/ie_hires_platform.s`: video, input, audio, menu, system, fake-library,
  message, inventory, and zone compatibility entrypoints.
- `../controlloop.s`: IE startup/menu/game outer-loop flow selected by `IS_IE`.
- `platform/ie_file_io_runtime.i`: embedded-pack loader, File MMIO fallback and media
  path normalisation.
- `platform/ie_music.i`: legacy `mt_*` entrypoints backed by IE MOD MMIO.
- `tools/normalize_media.sh`: prepares the original local media layout.
- `tools/convert_menu_assets.py`: converts original planar menu art and
  palettes into IE CLUT8 build artifacts.
- `tools/prepare_media_profile.py`: prepares the Redux High media profile.
- `tools/prepare_original_runtime.py`: derives the original runtime inventory
  from its database and available level files.
- `tools/pack_ie68.py`: builds and inspects deterministic self-contained IE68
  images.

## Intuition Engine Links

- https://github.com/IntuitionAmiga/IntuitionEngine
- https://www.youtube.com/@intuitionamiga

## Shared Source Differences From Upstream

The port keeps IE-specific code under `ab3d2_source/ie/` where possible. These
files are shared with upstream `mheyer32/alienbreed3d2` and currently differ on
disk. `.gitignore` intentionally remains byte-identical to upstream.

- `ie/README.md`: documents the IE port.
- `ab3d2_source/Makefile`: includes `ie/build.mk`. The IE targets themselves
  live in that IE-only make fragment.
- `ab3d2_source/bss/draw_bss.s`: under `IS_IE`, raises
  `DRAW_MAX_POLY_POINTS` and associated scratch buffers so IE object clipping
  cannot overrun the original 250-point allocation.
- `ab3d2_source/bss/player_bss.s`: under `IS_IE`, aligns and widens selected
  control/runtime flags used by IE input and emulator-sensitive byte writes.
- `ab3d2_source/hires.s`: contains `IS_IE` include selection and callsite
  guards for IE platform glue, Amiga custom-chip/Paula/CIA paths, IE input,
  menu, file I/O, music, presentation, pause, and exit-zone behaviour.
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
