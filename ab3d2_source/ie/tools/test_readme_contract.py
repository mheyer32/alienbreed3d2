#!/usr/bin/env python3
"""Regression checks for IE README claims that mirror runtime contracts."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
README = (ROOT / "ie" / "README.md").read_text(encoding="utf-8")


def main() -> int:
    required = (
        "runtimes read the program and assets",
        "directly from the embedded IE68 image",
        "They do not extract an asset directory",
        "Redux High packed images contain a default `boot.dat`",
        "original packed image",
        "host working directory",
        "Packaged\nruntimes store progress in `ab3d2-save.dat` beside the",
        "prepares the Redux High media profile",
        "`ie/README.md`: documents the IE port.",
        "The `ie68` and `ie68-redux-high` targets link raw intermediates",
        "The aggregate `ie68-all` target invokes both image\nbuilds.",
        "0x00700000",
        "0x003FFF00",
        "0x00C00000",
        "pack header is at guest address `0x00600000` (file offset `0x005FF000`)",
        "indexed asset data begins at guest address `0x01000000` (file offset",
        "`BLT_STATUS` | `0xF0044`",
        "`0xF25C0`",
        "`0xF25D0`",
        "`0xF0BD4` | MOD playback position",
        "four legacy SFX channels at `0xF0E80 + channel*0x20`",
        "signed 8-bit format (`0`)",
        "`Aud_ChannelPick_b` to the channel selector",
        "../../IntuitionEngine/bin/IntuitionEngine",
        "make -f ie/Makefile ie68-redux-high IE_DIAG_SYMBOLS_OUT=ie/diag_symbols.lua",
        "../../IntuitionEngine/bin/ie_headless --script-owned-term",
        "The scripts do not select an image themselves.",
        "Build `202605101918`",
        "no archive checksum is recorded here",
        "Selects the original or Redux High guest media paths.",
        "prepares Redux High profile media under `_build/ie_media/redux-high/`",
        "`ie/platform/ie_keymap.i`",
        "`modules/player.s` in the generated",
    )
    forbidden = (
        "extract their prepared assets beside the executable",
        "the extracted `ab3d2_source/_build/ie_media/redux-high/boot.dat`",
        "Redux high/low media profiles",
        "`README.md`: documents the IE port at the repository root.",
        "ie/platform/ie_hires_platform.s:862-884",
        "Redux High with host fit/stretch presentation",
        "0x00C00000` | IE file-loader heap base",
        "0xFE0000` | IE file-loader heap limit",
        "at `../IntuitionEngine/bin/IntuitionEngine`",
        "Packed images contain their default `boot.dat`",
        "The local Redux scripts default to",
        "If\nthe IEScript host predefines `IE_TARGET` or `TARGET`",
        "`IntuitionEngine-AB3D2-Karlos-TKG-High.zip` (~450 MB)",
        "Selects which prepared media tree the build links against.",
        "prepares Redux profile media under `_build/ie_media/<profile>/`",
        "`ie/ie_keymap.i`",
        "`ie/modules/player.s`",
        "The v1 IE path forces gameplay",
        "and texture hashes",
    )
    missing = [text for text in required if text not in README]
    stale = [text for text in forbidden if text in README]
    if missing or stale:
        if missing:
            print("missing README contract text:", ", ".join(missing))
        if stale:
            print("stale README contract text:", ", ".join(stale))
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
