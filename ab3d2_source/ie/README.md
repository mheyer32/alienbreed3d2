# IE Assembly Port (WIP)

This directory contains the in-progress Intuition Engine assembly port layer.

- `ie_main.s`: VideoChip path bootstrap.
- `ie_voodoo_main.s`: Voodoo path bootstrap with clear + triangle + swap loop.
- `ie_hal.s`: placeholder HAL routines to be filled during porting.
- `ie_input.s`: keyboard/mouse bridge stubs.
  - Exposes `KeyMap_vb` and `Sys_ReadMouse`/`Sys_MouseY` compatibility symbols.
  - Includes explicit `ie_scancode_to_rawkey` translation map (identity default, override-ready).
  - Exposes `Sys_ClearKeyboard` compatibility routine.
- `ie_audio.s`: exports legacy `mt_init`/`mt_music`/`mt_end` and `Aud_PlaySound`/`MakeSomeNoise` wrappers over IE MOD/SFX MMIO.
- `ie_audio.s`: MOD/SFX bridge stubs.
- `ie_fileio.s`: file I/O bridge stubs.
- `ie_present.s`: indexed chunky -> RGBA LUT conversion + Mode7 upscale submit.
  - Includes `ie_palette_upload_12bit` to convert 256-entry `0x0RGB` palettes to RGBA8888 LUT.
  - Includes `ie_palette_upload_rgb8` and `Vid_LoadMainPalette` compatibility entrypoint.
- `ie_hal.s`: includes `Vid_Present`, `Sys_WaitVBL`, `Sys_EvalFPS`, `Sys_FrameLap` compatibility entrypoints.
