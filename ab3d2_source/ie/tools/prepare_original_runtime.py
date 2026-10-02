#!/usr/bin/env python3
"""Prepare the original AB3D2 runtime files for an embedded IE68 pack."""

from __future__ import annotations

import argparse
import re
import shutil
from pathlib import Path


LEVEL_FILES = ("twolev.map", "twolev.flymap", "twolev.bin", "twolev.graph.bin", "twolev.clips")
CORE_FILES = {
    "includes/test.lnk",
    "includes/text_file",
    "includes/floortile",
    "includes/newtexturemaps",
    "includes/newtexturemaps.pal",
}
VOLUME_PATH = re.compile(rb"(?:TKG1|TKG2):([A-Za-z0-9_./!-]+)", re.IGNORECASE)
SAMPLE_PATH = re.compile(rb"sfx:samples/([A-Za-z0-9_.!+-]+)", re.IGNORECASE)


def runtime_paths(database: bytes) -> set[str]:
    paths = set(CORE_FILES)
    for match in VOLUME_PATH.finditer(database):
        relative = match.group(1).decode("ascii").lower()
        if relative.startswith(("includes/", "hqn/")):
            if relative in ("includes/floortile", "includes/newtexturemaps"):
                paths.add(relative)
                continue
            name = relative.rsplit("/", 1)[-1]
            if "." not in name:
                paths.update(f"{relative}.{suffix}" for suffix in ("wad", "ptr", "256pal"))
            else:
                paths.add(relative)
        elif relative.startswith(("vectobj/", "wallinc/", "music/")):
            paths.add(relative)
    for match in SAMPLE_PATH.finditer(database):
        paths.add(f"ab3dsfx/samples/{match.group(1).decode('ascii').lower()}")
    return paths


def prepare_runtime(media_root: Path, output: Path) -> tuple[str, ...]:
    database_path = media_root / "includes/test.lnk"
    selected = runtime_paths(database_path.read_bytes())
    for level in "abcdefghijklmnop":
        for filename in LEVEL_FILES:
            relative = f"levels_editor_uncompressed/level_{level}/{filename}"
            if (media_root / relative).is_file():
                selected.add(relative)
    paths = tuple(sorted(selected))
    missing = [path for path in paths if not (media_root / path).is_file()]
    if missing:
        raise FileNotFoundError(f"missing original runtime asset: {missing[0]}")
    if output.exists():
        shutil.rmtree(output)
    for relative in paths:
        destination = output / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(media_root / relative, destination)
    return paths


def main() -> int:
    parser = argparse.ArgumentParser(description="Prepare original AB3D2 runtime assets")
    parser.add_argument("--media-root", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    paths = prepare_runtime(args.media_root, args.output)
    print(f"Prepared {len(paths)} original runtime assets in {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
