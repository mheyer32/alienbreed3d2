#!/usr/bin/env python3
"""Regression tests for the IE Redux media-profile preparation."""

import tempfile
import unittest
from pathlib import Path

from prepare_media_profile import prepare_redux


class PrepareReduxTests(unittest.TestCase):
    def test_keeps_renderer_palette_separate_from_root_palette(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo = Path(tmp) / "repo"
            game = repo / "karlos-tkg-main" / "Game"
            includes = game / "Includes"
            includes.mkdir(parents=True)

            renderer_palette = bytes((0, 0, 0, 8, 8, 8))
            root_palette = bytes((30, 30, 30, 71, 71, 71))
            (includes / "256PAL").write_bytes(renderer_palette)
            (game / "pal").write_bytes(root_palette)

            out = repo / "out"
            prepare_redux(repo, "redux-high", out)

            self.assertEqual((out / "includes" / "256pal").read_bytes(), renderer_palette)
            self.assertEqual((out / "pal").read_bytes(), root_palette)


if __name__ == "__main__":
    unittest.main()
