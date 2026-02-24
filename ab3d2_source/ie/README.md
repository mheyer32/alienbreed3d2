# IE Assembly Port (WIP)

This directory contains the in-progress Intuition Engine assembly port layer.

- `ie_main.s`: VideoChip path bootstrap.
- `ie_voodoo_main.s`: Voodoo path bootstrap (kept separate; software path is primary).
- `ie_hal.s`: core IE loop routines + compatibility entrypoints (`Vid_Present`, `Sys_WaitVBL`, `Sys_EvalFPS`, `Sys_FrameLap`).
- `ie_input.s`: keyboard/mouse bridge.
  - Exposes `KeyMap_vb` and `Sys_ReadMouse`/`Sys_MouseY` compatibility symbols.
  - Includes explicit `ie_scancode_to_rawkey` translation map (identity default, override-ready).
  - Exposes `Sys_ClearKeyboard` compatibility routine.
- `ie_audio.s`: legacy `mt_init`/`mt_music`/`mt_end` and `Aud_PlaySound`/`MakeSomeNoise` wrappers over IE MOD/SFX MMIO.
  - `MakeSomeNoise` now resolves `Aud_SampleNum_w` through `Aud_SampleList_vl` and packs volume/channel into IE SFX control.
  - Adds `ie_sfx_set_sample` / `ie_sfx_get_sample` / `ie_sfx_clear_samples` helpers for managing the 64-entry SFX table.
- `ie_mem.s`: static-memory compatibility layer (`Sys_AllocVec`, `Sys_FreeVec`, `Sys_MemFillLong`, `Sys_Init`, `Sys_Done`, `Sys_FatalError`, `Sys_Workspace_vl`).
- `ie_fileio.s`: file I/O bridge + `IO_LoadFile` / `IO_LoadFileOptional` compatibility wrappers.
  - Adds `IO_InitQueue` / `IO_QueueFile` / `IO_FlushQueue` immediate-mode compatibility.
  - Uses static high-RAM bump allocation for queued file loads (`0x700000` .. `0xFE0000`).
- `ie_present.s`: indexed chunky -> RGBA LUT conversion + Mode7 upscale submit.
  - Includes `ie_palette_upload_12bit` to convert 256-entry `0x0RGB` palettes to RGBA8888 LUT.
  - Includes `ie_palette_upload_rgb8` and `Vid_LoadMainPalette` compatibility entrypoint.
  - Exposes `Vid_UpdatePalette_b` and `Draw_TexturePalettePtr_l` compatibility symbols.
  - `ie_palette_poll_update` applies palette reload when `Vid_UpdatePalette_b` is set.
