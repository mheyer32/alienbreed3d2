# IE Assembly Port (WIP)

This directory contains the in-progress Intuition Engine assembly port layer.
Most compatibility routines export both plain and underscore-prefixed symbols to
match mixed assembly/C callsites.

- `ie_main.s`: VideoChip path bootstrap.
- `ie_voodoo_main.s`: Voodoo path bootstrap (kept separate; software path is primary).
- `ie_game.s`: higher-level bootstrap compatibility glue.
  - Applies level-letter filename selection from `Game_LevelNumber_w`.
  - Exposes compatibility entrypoints: `Game_Start`, `DEFAULTGAME`, `game_SetMenuLevelNames`.
  - Runs a Game_Start-style sequence: screen open, queue init, explicit GLF DB load attempt, legacy `Res_*` load chain, queue flush, story/backdrop loads, level music handoff to `mt_init`.
  - Explicit DB load includes in-module path variants (`ab3:includes/...`, `media/includes/...`) before generic probe fallback.
  - Falls back to `ie_res_bootstrap_assets` when explicit DB load fails.
  - Saves `sys_RecoveryStack` from current SP for fatal-error recovery compatibility.
- `ie_hal.s`: core IE loop routines + compatibility entrypoints (`Vid_Present`, `Sys_WaitVBL`, `Sys_EvalFPS`, `Sys_FrameLap`).
  - Adds `Vid_OpenMainScreen` / `Vid_CloseMainScreen` and low-level init/close stubs (`_InitLowLevel`, `_CloseLowLevel`) for legacy outer-loop compatibility.
- `ie_input.s`: keyboard/mouse bridge.
  - Exposes `KeyMap_vb` and `Sys_ReadMouse`/`Sys_MouseY` compatibility symbols.
  - Includes explicit `ie_scancode_to_rawkey` translation map (identity default, override-ready).
  - Exposes `Sys_ClearKeyboard` compatibility routine.
- `ie_audio.s`: legacy `mt_init`/`mt_music`/`mt_end` and `Aud_PlaySound`/`MakeSomeNoise` wrappers over IE MOD/SFX MMIO.
  - `MakeSomeNoise` now resolves `Aud_SampleNum_w` through `Aud_SampleList_vl` and packs volume/channel into IE SFX control.
  - Accepts SFX table entries as either `{ptr,len}` or patched `{ptr,end_ptr}` format.
  - Adds `ie_sfx_set_sample` / `ie_sfx_get_sample` / `ie_sfx_clear_samples` helpers for managing the 64-entry SFX table.
  - Helper APIs also export underscore-prefixed aliases for C/ASM interop.
- `ie_mem.s`: static-memory/system compatibility layer.
  - Allocation: `Sys_AllocVec`, `Sys_FreeVec`, `Sys_MemFillLong`, `Sys_Workspace_vl`.
  - System stubs: `Sys_Init`, `Sys_Done`, `Sys_OpenLibs`, `Sys_CloseLibs`, `Sys_ShowFPS`, `Sys_DisplayError`.
  - Timing stubs: `Sys_MarkTime`, `Sys_TimeDiff`, `Sys_EClockRate`.
  - Adds `Zone_FreeEdgePVS` compatibility stub for legacy level teardown paths.
  - Adds `sys_RecoveryStack` compatibility storage and uses it in `Sys_FatalError`.
- `ie_fileio.s`: file I/O bridge + `IO_LoadFile` / `IO_LoadFileOptional` compatibility wrappers.
  - Adds `IO_InitQueue` / `IO_QueueFile` / `IO_FlushQueue` immediate-mode compatibility.
  - Uses static high-RAM bump allocation for queued file loads (`0x700000` .. `0xFE0000`).
  - `IO_LoadFileOptional` returns per-load heap allocations from the same range.
  - `ie_fopen` normalizes Amiga-style paths (`VOL:name/path`) to host-friendly relative paths by stripping volume prefix.
  - `ie_fread` retries failed loads across lowercase plus `media/` and `../media/` prefixed fallbacks for case-sensitive/working-dir variance.
  - Exports `io_ObjectName_vb` / `io_FileExtPointer_l` compatibility scratch symbols used by legacy resource code.
- `ie_res.s`: resource helper wrappers.
  - `ie_res_init` clears SFX table and initializes queue state.
  - `ie_res_bootstrap_assets` tries default palette/MOD candidate filenames at startup.
  - `ie_res_bootstrap_assets` also probes optional GLF database candidates (`test.lnk`) and, when found, auto-loads legacy object/sound/texture/wall/level resources for the compatibility path.
  - `ie_res_load_palette_file` loads a palette file and activates it via `ie_palette_set_texture_ptr`.
  - `ie_res_load_sfx_file` loads a sample file and registers it in `Aud_SampleList_vl`.
  - `ie_res_load_sfx_table_ex` supports explicit table stride; wrappers cover 64-byte and AB3D2 GLF 60-byte filename entries.
  - Adds `Res_LoadObjects` / `Res_FreeObjects` / `Res_LoadSoundFx` / `Res_LoadFloorsAndTextures` / `Res_LoadWallTextures` / `Res_LoadLevelData` / `Res_FreeFloorsAndTextures` / `Res_FreeWallTextures` / `Res_FreeLevelData` / `Res_ReleaseScreenMemory` / `Res_PatchSoundFx` / `Res_FreeSoundFx` plus `Lvl_InitLevelMods` compatibility entrypoints and `ie_res_set_sfx_filename_table` / `ie_res_load_game_db_file` for GLF table binding.
  - `Lvl_InitLevelMods` now mirrors legacy behavior: updates `Zone_BackdropDisable_vb` from level properties when present, otherwise clears it.
  - Object resource extension probes use lowercase (`.wad`, `.ptr`, `.256pal`) to match host assets.
  - Uses assembler-derived GLF offsets (from `defs.i`) for SFX/floor/texture/wall filename tables.
  - Expands GLF DB probe candidates to include `media/includes/...` variants used by this repo layout.
  - Exports legacy level filename/pointer symbols (`Lvl_*`) plus wall/floor pointer tables so existing game resource callsites can link against IE layer symbols.
- `ie_present.s`: indexed chunky -> RGBA LUT conversion + Mode7 upscale submit.
  - Includes `ie_palette_upload_12bit` to convert 256-entry `0x0RGB` palettes to RGBA8888 LUT.
  - Includes `ie_palette_upload_rgb8` and `Vid_LoadMainPalette` compatibility entrypoint.
  - Exposes `Vid_UpdatePalette_b` and `Draw_TexturePalettePtr_l` compatibility symbols.
  - `ie_palette_poll_update` applies palette reload when `Vid_UpdatePalette_b` is set.
  - `ie_palette_set_texture_ptr` updates `Draw_TexturePalettePtr_l` and marks palette dirty.
