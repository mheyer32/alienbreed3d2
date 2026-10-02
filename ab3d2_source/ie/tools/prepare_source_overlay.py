#!/usr/bin/env python3
"""Create a disposable IE source overlay from upstream AB3D2 sources."""

from __future__ import annotations

import argparse
import re
import shutil
import subprocess
from pathlib import Path


PATCH_PATH = re.compile(r"^(?:--- a/|\+\+\+ b/)(.+)$")


def patch_paths(patch_dir: Path) -> set[Path]:
    paths: set[Path] = set()
    for name in (patch_dir / "series").read_text(encoding="utf-8").splitlines():
        if not name or name.startswith("#"):
            continue
        for line in (patch_dir / name).read_text(encoding="utf-8").splitlines():
            match = PATCH_PATH.match(line)
            if match and match.group(1) != "/dev/null":
                paths.add(Path(match.group(1)))
    return paths


def contains_patched_child(relative: Path, patched_paths: set[Path]) -> bool:
    return any(path == relative or relative in path.parents for path in patched_paths)


def materialise(source_root: Path, output_root: Path, relative: Path, patched_paths: set[Path]) -> None:
    source = source_root / relative
    output = output_root / relative
    if relative in patched_paths:
        output.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, output)
        return
    if source.is_dir() and contains_patched_child(relative, patched_paths):
        output.mkdir(parents=True, exist_ok=True)
        for child in source.iterdir():
            materialise(source_root, output_root, relative / child.name, patched_paths)
        return
    output.parent.mkdir(parents=True, exist_ok=True)
    output.symlink_to(source)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-root", type=Path, default=Path("."))
    parser.add_argument("--patch-dir", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    source_root = args.source_root.resolve()
    patch_dir = args.patch_dir.resolve()
    output = args.output.resolve()
    if source_root == output or output in source_root.parents:
        raise SystemExit("overlay output must not contain the source root")
    if output.exists():
        shutil.rmtree(output)
    output.mkdir(parents=True)

    patched_paths = patch_paths(patch_dir)

    for child in source_root.iterdir():
        if child.name in {".git", "_build"}:
            continue
        materialise(source_root, output, Path(child.name), patched_paths)
    for relative in patched_paths:
        (output / relative).parent.mkdir(parents=True, exist_ok=True)

    for name in (patch_dir / "series").read_text(encoding="utf-8").splitlines():
        if not name or name.startswith("#"):
            continue
        command = ["patch", "--batch", "--forward", "--strip=1", f"--directory={output}", f"--input={patch_dir / name}"]
        subprocess.run(command, check=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
