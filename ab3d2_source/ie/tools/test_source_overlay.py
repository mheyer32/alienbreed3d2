#!/usr/bin/env python3
"""Regression tests for the IE source overlay and patch series."""

from __future__ import annotations

import hashlib
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PATCH_DIR = ROOT / "ie" / "patches"
PREPARE = ROOT / "ie" / "tools" / "prepare_source_overlay.py"
GENERATE = ROOT / "ie" / "tools" / "generate_source_patches.py"


class SourceOverlayTests(unittest.TestCase):
    def test_regeneration_preserves_compatibility_patch_and_full_manifest(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            temporary_root = Path(temporary)
            reviewed = temporary_root / "reviewed"
            patch_dir = temporary_root / "patches"
            shutil.copytree(PATCH_DIR, patch_dir)
            subprocess.run(
                ["python3", str(PREPARE), "--source-root", str(ROOT), "--patch-dir", str(patch_dir), "--output", str(reviewed)],
                check=True,
            )
            subprocess.run(
                ["python3", str(GENERATE), "--source-root", str(ROOT), "--reviewed-root", str(reviewed), "--patch-dir", str(patch_dir)],
                check=True,
            )
            self.assertEqual((patch_dir / "series").read_text(encoding="utf-8").splitlines()[0], "0000-upstream-compatibility.patch")
            self.assertIn('include\t"ie/platform/system.i"', (patch_dir / "0001-build-and-runtime.patch").read_text(encoding="utf-8"))
            manifest = (patch_dir / "expected.sha256").read_text(encoding="utf-8").splitlines()
            self.assertGreater(len(manifest), 9)

    def test_patch_series_creates_the_reviewed_sources(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            overlay = Path(temporary) / "overlay"
            subprocess.run(
                [
                    "python3",
                    str(PREPARE),
                    "--source-root",
                    str(ROOT),
                    "--patch-dir",
                    str(PATCH_DIR),
                    "--output",
                    str(overlay),
                ],
                check=True,
            )
            for line in (PATCH_DIR / "expected.sha256").read_text(encoding="utf-8").splitlines():
                expected, relative = line.split("  ", 1)
                actual = hashlib.sha256((overlay / relative).read_bytes()).hexdigest()
                self.assertEqual(actual, expected, relative)

            manifest_paths = {
                line.split("  ", 1)[1]
                for line in (PATCH_DIR / "expected.sha256").read_text(encoding="utf-8").splitlines()
            }
            patched_paths: set[str] = set()
            for name in (PATCH_DIR / "series").read_text(encoding="utf-8").splitlines():
                for line in (PATCH_DIR / name).read_text(encoding="utf-8").splitlines():
                    if line.startswith(("--- a/", "+++ b/")):
                        relative = line[6:]
                        if relative != "/dev/null" and (overlay / relative).is_file():
                            patched_paths.add(relative)
            self.assertEqual(manifest_paths, patched_paths)

    def test_no_upstream_source_copy_is_tracked_under_ie(self) -> None:
        forbidden = (
            "hires.s",
            "controlloop.s",
            "pauseopts.s",
            "objdrawhires.s",
            "bss/draw_bss.s",
            "bss/player_bss.s",
            "modules/player.s",
            "modules/res.s",
            "menu/menunb.s",
        )
        for relative in forbidden:
            self.assertFalse((ROOT / "ie" / relative).exists(), relative)


if __name__ == "__main__":
    unittest.main()
