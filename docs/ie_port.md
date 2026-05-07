# Intuition Engine Port

This document tracks the Alien Breed 3D II bare-metal target for Intuition
Engine (IE). Intuition Engine is a fantasy computer that never existed; this
port runs AB3D2 as a raw M68K program on that machine rather than through
AmigaOS, Exec, Intuition, Paula, CIA, or real Amiga custom-chip MMIO.

## Current Scope

- Target: full software-renderer build from `ab3d2_source/hires.s`.
- Platform layer: `ab3d2_source/ie/ie_hires_platform.s`, selected with
  `IS_IE`.
- Binary format: raw `.ie68` linked at `0x001000`.
- Build target: `make ie68` from `ab3d2_source/`.
- Output: `ab3d2_source/ab3d2_ie68.ie68`.
- Runtime cwd: run Intuition Engine from `ab3d2_source/` so raw file I/O sees
  the expected `media/` tree.

The IE build keeps the AB3D2 software renderer and menu state machine. The
Amiga screen, blitter, input, file, music, SFX, and compatibility entrypoints
that the original code expects are satisfied by IE-specific glue.

The old bootstrap and Voodoo entry paths are not current root build targets.
The maintained IE target is `ie68`, which assembles `hires.s` and
`ie/ie_hires_platform.s`, then links them with `vlink -b rawbin1 -Ttext 0x1000`.

## Build Flow

From `ab3d2_source/`:

```sh
make ie68
```

The IE make fragment:

- converts original planar menu art into CLUT8 artifacts under
  `_build/ie_menu/`;
- unpacks runtime media into `_build/ie_unpacked/media/`;
- assembles `hires.s` with `-DIS_IE=1`;
- assembles `ie/ie_hires_platform.s`;
- links `ab3d2_ie68.ie68`;
- writes `_build/ie68.map`;
- generates `diag_symbols.lua` and copies it to `ie/diag_symbols.lua`.

Generated `_build/` files and diagnostics are build artifacts, not source.

## Memory Layout

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

## IE MMIO Used By The Port

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

| Register range | Use |
|----------------|-----|
| `0xF0BC0-0xF0BD7` | Legacy MOD stop/reset compatibility writes |
| `0xF0E20` | SID file pointer |
| `0xF0E24` | SID file length |
| `0xF0E28` | SID control (`1` start, `2` stop/reset) |
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

## Media Layout

Run from `ab3d2_source/`. Intuition Engine's `--media` argument does not
currently re-root the raw file-I/O MMIO loads used by this port.

Expected paths include:

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

Prepare the tree from extracted media with:

```sh
ie/tools/normalize_media.sh .
```

The current IE music override starts `media/includes/At_Dooms_Gate_E1M1.sid`
through IE SID playback instead of playing the legacy ProTracker title module.

## Source Boundaries

IE-specific platform code belongs under `ab3d2_source/ie/` wherever possible.
Non-IE source touches should remain limited to build wiring, `IS_IE` include
selection, and unavoidable callsite guards around Amiga-specific hardware or OS
assumptions.

Key files:

- `ie/build.mk`: IE build target and generated diagnostics.
- `ie/ie_hires_platform.s`: video, input, audio, menu, system, fake-library,
  message, and zone compatibility entrypoints.
- `ie/controlloop.s`: IE startup/menu/game outer-loop flow selected by `IS_IE`.
- `ie/ie_file_io_runtime.i`: IE raw file loader and media path normalization.
- `ie/ie_music.i`: legacy `mt_*` entrypoints backed by IE SID playback.
- `ie/MEDIA_LAYOUT.md`: focused media-tree notes.
