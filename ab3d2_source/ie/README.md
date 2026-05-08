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
- Redux convenience targets: `make ie68-redux-high` and
  `make ie68-redux-low` from `ab3d2_source/`.
- Default output: `ab3d2_source/ab3d2_ie68.ie68`.
- Runtime cwd: run Intuition Engine from `ab3d2_source/` so raw file I/O sees
  the expected media tree.

The IE build keeps the AB3D2 software renderer and menu state machine. The
Amiga screen, blitter, input, file, music, SFX, and compatibility entrypoints
that the original code expects are satisfied by IE-specific glue.

## Build

From `ab3d2_source/`:

```sh
make ie68
make ie68-redux-high
make ie68-redux-low
```

The Redux targets require the Redux data checkout at `karlos-tkg-main/` in the
`alienbreed3d2` repository root. The expected data root is
`karlos-tkg-main/Game`, and the build prepares the selected profile under
`ab3d2_source/_build/ie_media/`.

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
| `0x126000` | Presented 320x240 CLUT8 framebuffer (`PRESENT_BASE`) |
| `0x139000` | Secondary presented framebuffer (`PRESENT_BACK_BASE`) |
| `0x3FFF00` | IE file-loader heap pointer |
| `0x6F0000` | Fake library/vector base for compatibility entrypoints |
| `0x700000` | IE file-loader heap base |
| `0xFE0000` | IE file-loader heap limit |

The game viewport is currently presented as a 192x160 region at `(64,20)` inside
the 320x240 IE framebuffer. The full menu uses the 320x240 framebuffer.

## MMIO

Video:

| Register | Address | Use |
|----------|---------|-----|
| `VIDEO_CTRL` | `0xF0000` | Enable video |
| `VIDEO_MODE` | `0xF0004` | Set mode `0x05` for 320x240 |
| `VIDEO_STATUS` | `0xF0008` | VBlank polling, bit `1` |
| `VIDEO_PAL_INDEX` | `0xF0078` | Palette index |
| `VIDEO_PAL_DATA` | `0xF007C` | Palette RGBA data |
| `VIDEO_COLOR_MODE` | `0xF0080` | CLUT8 mode (`1`) |
| `VIDEO_FB_BASE` | `0xF0084` | Active framebuffer base pointer |

Input:

| Register | Address | Use |
|----------|---------|-----|
| Mouse X | `0xF0730` | Absolute X sampled and converted to delta |
| Mouse Y | `0xF0734` | Absolute Y sampled and converted to delta |
| Mouse buttons | `0xF0738` | Left/right button state |
| Scan code | `0xF0740` | Keyboard queue data |
| Scan status | `0xF0744` | Keyboard queue status, bit `0` means data available |
| Modifiers | `0xF0748` | Shift/Ctrl/Alt state |

File I/O:

| Register | Address | Use |
|----------|---------|-----|
| `FILE_IO_NAME` | `0xF2200` | Pointer to NUL-terminated path |
| `FILE_IO_DATA` | `0xF2204` | Destination pointer |
| `FILE_IO_CTRL` | `0xF220C` | Command; `1` loads file |
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

## Rendering And Presentation

The IE path keeps AB3D2's 8-bit chunky software renderer. `ie_hires_platform.s`
opens a 320x240 CLUT8 IE video mode, uploads palettes through IE video MMIO, and
presents either:

- the full 320x240 source buffer for menus/fullscreen paths; or
- the 192x160 game viewport copied into the 320x240 presentation buffer.

After presenting the small viewport, the source viewport region is cleared so
old rows do not smear when the view moves. Floors and ceilings are drawn by the
legacy flat renderer in `hires.s`; the IE build avoids relying on an unreliable
`st drawit` memory flag write in that path.

## Input And Menus

`ie_poll_input` reads IE keyboard and mouse MMIO directly. It updates AB3D2's
existing raw-key table (`KeyMap_vb`), accumulates mouse Y into `_Sys_MouseY`,
stores mouse X in `ie_mouse_delta_x_w`, and mirrors buttons into the fake
custom/CIA state expected by the original mouse-control code.

The native AB3D2 menu flow is retained. The Amiga menu blitter/screen path is
replaced by converted CLUT8 menu assets and IE framebuffer rendering. Enter,
Space, and left mouse activate menu items; cursor-key menu movement is debounced
in the IE menu wait loop.

## Media

Run from `ab3d2_source/`. Intuition Engine's `--media` argument does not
currently re-root the raw file-I/O MMIO loads used by this port.

Expected original-profile paths include:

```text
media/
  includes/
    main.256pal
    test.lnk
    At_Dooms_Gate_E1M1.sid
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
If no level MOD is available, it falls back to
`media/includes/At_Dooms_Gate_E1M1.sid` through IE SID playback.

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
- `ie_hires_platform.s`: video, input, audio, menu, system, fake-library,
  message, and zone compatibility entrypoints.
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
disk:

- `.gitignore`: ignores generated IE binaries and build artifacts.
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
  menu, file I/O, music, presentation, pause, exit-zone behavior, and the gated
  `drawit` word-access workaround.
- `ab3d2_source/menu/menunb.s`: under `IS_IE`, uses the IE key-read path and
  skips Amiga timer/fire-button wait logic that depends on custom hardware.
- `ab3d2_source/modules/player.s`: under `IS_IE`, reads IE mouse deltas and
  fake custom/CIA button state, and gates emulator-sensitive byte writes.
- `ab3d2_source/modules/res.s`: under `IS_IE`, does not load level MODs through
  the upstream Paula-specific `MEMF_CHIP` path. IE level music is loaded
  optionally by `ie_music.i` and played through IE MOD MMIO instead.
- `ab3d2_source/objdrawhires.s`: under `IS_IE`, guards zero or oversized object
  polygon point counts before clipping/drawing.
