# IE Assembly Port (WIP)

This directory contains the in-progress Intuition Engine assembly port layer.

- `ie_main.s`: VideoChip path bootstrap.
- `ie_voodoo_main.s`: Voodoo path bootstrap with clear + triangle + swap loop.
- `ie_hal.s`: placeholder HAL routines to be filled during porting.
- `ie_input.s`: keyboard/mouse bridge stubs.
- `ie_audio.s`: MOD/SFX bridge stubs.
- `ie_fileio.s`: file I/O bridge stubs.
- `ie_present.s`: indexed chunky -> RGBA LUT conversion + Mode7 upscale submit.
