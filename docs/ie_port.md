# Intuition Engine Port (WIP)

This document tracks the Alien Breed 3D II bare-metal port target for Intuition Engine (IE).
It describes the intended MMIO contract, memory layout, and build entry points.

## Scope

- Version 1 target: keep software renderer, replace Amiga HAL with IE HAL.
- Version 2 target: optional Voodoo hardware triangle submission path.
- Binary format: flat `.ie68` image loaded at `0x001000` with supervisor mode.

## IE MMIO Contract (Version 1)

- Video init:
  - `VIDEO_CTRL` `0xF0000` (`1` = enable)
  - `VIDEO_MODE` `0xF0004` (`0` = 640x480)
- VBlank poll:
  - `VIDEO_STATUS` `0xF0008` (bit 1)
- Keyboard queue:
  - `SCAN_CODE` `0xF0740`
  - `SCAN_STATUS` `0xF0744`
- Mouse:
  - `MOUSE_X/Y/BUTTONS` `0xF0730-0xF073C`
  - `MOUSE_RELATIVE_MODE` `0xF074C`
- MOD playback:
  - `0xF0BC0-0xF0BD7`
- SFX playback:
  - `0xF2380-0xF23BF`
- File I/O:
  - `0xF2200-0xF221F`

## Memory Layout (Version 1)

- Code/data entry: `0x001000+`
- 8-bit chunky buffer (320x240): `0x060000`
- Palette LUT (256 RGBA entries): `0x073000`
- VRAM framebuffer RGBA (640x480): `0x100000`
- VRAM scratch RGBA (320x240): `0x22C000`
- High RAM assets:
  - textures `0x600000+`
  - level/object `0x700000+`
  - sound `0x800000+`

## Endianness Notes

- MMIO writes are numeric (no byte swap at register boundary).
- Main RAM/VRAM round-trips are M68K-transparent via emulator conversion.
- VRAM RGBA write form from M68K:
  - `(R<<24)|(G<<16)|(B<<8)|A`

## Planned Source Additions

Under `ab3d2_source/ie/`:

- `ie_main.s` (VideoChip path)
- `ie_voodoo_main.s` (Voodoo path)
- `ie_hal.s`
- `ie_present.s`
- `ie_input.s`
- `ie_audio.s`
- `ie_fileio.s`

## Build Targets

From `ab3d2_source/`:

- `make ie68`
- `make ie68_voodoo`

These currently expect:

- `ie/ie_main.s`
- `ie/ie_voodoo_main.s`

If missing, Make exits with a clear error until the assembly entry files are added.
