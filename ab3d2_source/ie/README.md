# IE Native Port

This directory contains the Intuition Engine support layer for the
software-rendered `hires.s` build. The target is selected with `IS_IE` and is
kept separate from the Amiga-specific code wherever possible.

Build with:

```sh
make ie68
```

The build assembles `hires.s` and `ie/ie_hires_platform.s`, then links them into
`ab3d2_ie68.ie68`. The generated map is written under `_build/`; diagnostic
symbols are generated as `diag_symbols.lua` and copied to `ie/diag_symbols.lua`.
Those generated files are ignored by git.

- `ie_hires_platform.s`: IE platform implementation linked beside `hires.s`.
  It supplies the legacy system, video, input, audio, menu, message, and zone
  compatibility entrypoints the game expects and presents the chunky 320x240
  CLUT8 framebuffer through IE.
- `system.i`: IE replacement for the top-level `system.i` include.
- `build.mk`: IE-specific `make ie68` target included by the top-level
  Makefile.
- `controlloop.s`: IE game startup and outer-loop flow included by `hires.s`
  when `IS_IE` is set.
- `ie_file_io_runtime.i`: IE file loader selected by `hires.s` when `IS_IE` is
  set. It loads through IE file I/O MMIO and preserves the upstream file I/O
  entrypoints expected by the game.
- `ie_music.i`: legacy `mt_*` music entrypoints backed by IE audio hardware.
  The current IE build starts `media/includes/At_Dooms_Gate_E1M1.sid` through
  the SID player instead of playing the ProTracker module.
- `ie_system.i`: fallback constants and structure offsets used by `system.i`
  when Amiga NDK include files are not present.
- `ie_system_runtime.i`: IE runtime system helpers selected by `hires.s` when
  `IS_IE` is set.
- `pauseopts.s`: IE pause-loop handling included by `hires.s` when `IS_IE` is
  set.
- `diag_symbols.txt`: symbol names exported from the link map into the generated
  Lua table used by IEScript diagnostics.
- `tools/normalize_media.sh`: prepares the local `media/` layout described in
  `MEDIA_LAYOUT.md`.

## Input

`ie_poll_input` reads IE keyboard and mouse MMIO directly. It updates the
game's existing `KeyMap_vb` raw-key table, accumulates mouse Y movement into
`_Sys_MouseY`, and mirrors mouse buttons into the fake custom/CIA state used by
the existing AB3D2 mouse-control path. IE does not emulate Amiga input devices
for this port.

The game calls `ie_poll_input` from the frame/wait paths and immediately before
`plr_KeyboardControl` reads `KeyMap_vb`.

## Media

Run the binary from `ab3d2_source` so runtime file loads resolve against the
expected `media/` tree. The current SID music override requires:

```text
media/includes/At_Dooms_Gate_E1M1.sid
```

Use `ie/tools/normalize_media.sh .` to prepare the local tree from extracted
media files.

## Boundaries

The IE target does not require an AmigaOS runtime and must not rely on Paula,
CIA, Exec, Intuition, or real custom-chip MMIO. Compatibility symbols in
`ie_hires_platform.s` exist to satisfy the original game code while routing
behavior to IE hardware services.

## Upstream Touches

The IE port keeps platform code under `ie/`. The remaining changes outside this
directory are limited to build wiring and `IS_IE` callsite guards where
`hires.s` directly touches Amiga hardware or selects platform-specific include
files.

- `Makefile`: includes `ie/build.mk` so the IE target can be built without
  putting IE build logic in the upstream Makefile.
- `hires.s`: selects IE-specific include files; guards Paula, CIA, custom-chip,
  CD32, and serial accesses; polls IE input during waits; routes SFX through IE;
  enables the combined keyboard and mouse control path used by the IE build; and
  ignores exit-zone `0` so an unset exit zone does not end a level immediately.
