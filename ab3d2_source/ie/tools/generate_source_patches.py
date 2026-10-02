#!/usr/bin/env python3
"""Generate the IE source-overlay patch series from a reviewed source tree.

This tool is deliberately not part of the normal build. It is used when a
reviewed port change needs to be expressed as an update to the patch series.
"""

from __future__ import annotations

import argparse
import difflib
import hashlib
import re
import shutil
import subprocess
import tempfile
from pathlib import Path


PATCH_GROUPS = (
    (
        "0001-build-and-runtime.patch",
        ("hires.s", "controlloop.s", "pauseopts.s"),
    ),
    (
        "0002-input-and-layout.patch",
        ("bss/draw_bss.s", "bss/player_bss.s", "modules/player.s"),
    ),
    (
        "0003-menu-and-resources.patch",
        ("menu/menunb.s", "modules/res.s"),
    ),
    ("0004-renderer-safety.patch", ("objdrawhires.s",)),
)
PATCH_PATH = re.compile(r"^(?:--- a/|\+\+\+ b/)(.+)$")


def content_hash(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def changed_paths(patch_dir: Path, series: list[str]) -> list[Path]:
    paths: set[Path] = set()
    for name in series:
        for line in (patch_dir / name).read_text(encoding="utf-8").splitlines():
            match = PATCH_PATH.match(line)
            if match and match.group(1) != "/dev/null":
                paths.add(Path(match.group(1)))
    return sorted(paths)


def final_paths(patch_dir: Path, series: list[str]) -> list[Path]:
    paths: set[Path] = set()
    for name in series:
        for line in (patch_dir / name).read_text(encoding="utf-8").splitlines():
            match = re.match(r"^\+\+\+ b/(.+)$", line)
            if match and match.group(1) != "/dev/null":
                paths.add(Path(match.group(1)))
    return sorted(paths)


def reviewed_source(path: Path, relative: str) -> list[str]:
    source = path.read_text(encoding="utf-8")
    if relative == "hires.s":
        source = source.replace('include\t"system.i"', 'include\t"ie/platform/system.i"', 1)
    return source.splitlines(keepends=True)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-root", type=Path, default=Path("."))
    parser.add_argument("--reviewed-root", type=Path, required=True)
    parser.add_argument("--patch-dir", type=Path, required=True)
    args = parser.parse_args()

    source_root = args.source_root.resolve()
    reviewed_root = args.reviewed_root.resolve()
    patch_dir = args.patch_dir.resolve()
    patch_dir.mkdir(parents=True, exist_ok=True)

    compatibility = "0000-upstream-compatibility.patch"
    compatibility_path = patch_dir / compatibility
    if not compatibility_path.is_file():
        raise SystemExit(f"missing required compatibility patch: {compatibility}")

    with tempfile.TemporaryDirectory() as temporary:
        temporary_root = Path(temporary)
        compatibility_dir = temporary_root / "patches"
        compatibility_dir.mkdir()
        shutil.copy2(compatibility_path, compatibility_dir / compatibility)
        (compatibility_dir / "series").write_text(f"{compatibility}\n", encoding="utf-8")
        base_root = temporary_root / "base"
        prepare = Path(__file__).with_name("prepare_source_overlay.py")
        subprocess.run(
            ["python3", str(prepare), "--source-root", str(source_root), "--patch-dir", str(compatibility_dir), "--output", str(base_root)],
            check=True,
        )

        series = [compatibility]
        for patch_name, paths in PATCH_GROUPS:
            patch_lines: list[str] = []
            for relative in paths:
                source = (base_root / relative).read_text(encoding="utf-8").splitlines(keepends=True)
                reviewed_path = reviewed_root / relative
                reviewed = reviewed_source(reviewed_path, relative)
                patch_lines.extend(difflib.unified_diff(source, reviewed, fromfile=f"a/{relative}", tofile=f"b/{relative}", n=3))
            if not patch_lines:
                raise SystemExit(f"{patch_name}: no source differences")
            (patch_dir / patch_name).write_text("".join(patch_lines), encoding="utf-8")
            series.append(patch_name)

    (patch_dir / "series").write_text("".join(f"{name}\n" for name in series), encoding="utf-8")
    with tempfile.TemporaryDirectory() as temporary:
        final_root = Path(temporary) / "final"
        prepare = Path(__file__).with_name("prepare_source_overlay.py")
        subprocess.run(
            ["python3", str(prepare), "--source-root", str(source_root), "--patch-dir", str(patch_dir), "--output", str(final_root)],
            check=True,
        )
        hashes = [
            f"{content_hash((final_root / relative).read_bytes())}  {relative}\n"
            for relative in changed_paths(patch_dir, series)
            if (final_root / relative).is_file()
        ]
    (patch_dir / "expected.sha256").write_text("".join(hashes), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
