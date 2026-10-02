import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("prepare_original_runtime.py")


def load_module():
    spec = importlib.util.spec_from_file_location("prepare_original_runtime", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class PrepareOriginalRuntimeTests(unittest.TestCase):
    def setUp(self):
        self.tool = load_module()
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.media = self.root / "media"
        self.output = self.root / "runtime"
        self.media.mkdir()

    def tearDown(self):
        self.temp.cleanup()

    def write(self, relative: str, data: bytes = b"data") -> None:
        path = self.media / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)

    def test_derives_runtime_inventory_and_ignores_editor_files(self):
        database = (
            b"TKG1:INCLUDES/ALIEN2\0"
            b"TKG1:INCLUDES/FLOORTILE\0"
            b"TKG1:INCLUDES/NEWTEXTUREMAPS\0"
            b"sfx:samples/Fire!.fib\0"
            b"TKG1:VECTOBJ/GENERATOR\0"
            b"TKG2:WALLINC/GIEGER.256WAD\0"
            b"tkg2:music/packedtest\0"
        )
        self.write("includes/test.lnk", database)
        self.write("includes/text_file")
        self.write("includes/floortile")
        self.write("includes/newtexturemaps")
        self.write("includes/newtexturemaps.pal")
        for suffix in ("wad", "ptr", "256pal"):
            self.write(f"includes/alien2.{suffix}", suffix.encode())
        self.write("ab3dsfx/samples/fire!.fib")
        self.write("vectobj/generator")
        self.write("wallinc/gieger.256wad")
        self.write("music/packedtest")
        for level in "abcdefghijklmnop":
            for filename in self.tool.LEVEL_FILES:
                self.write(f"levels_editor_uncompressed/level_{level}/{filename}")
        self.write("graphics/editor-only", b"exclude")

        paths = self.tool.prepare_runtime(self.media, self.output)

        self.assertIn("includes/alien2.wad", paths)
        self.assertIn("levels_editor_uncompressed/level_p/twolev.clips", paths)
        self.assertEqual((self.output / "includes/alien2.ptr").read_bytes(), b"ptr")
        self.assertFalse((self.output / "graphics/editor-only").exists())

    def test_fails_when_database_asset_is_missing(self):
        self.write("includes/test.lnk", b"TKG1:VECTOBJ/MISSING\0")
        self.write("includes/text_file")
        self.write("includes/floortile")
        self.write("includes/newtexturemaps")
        self.write("includes/newtexturemaps.pal")
        for level in "abcdefghijklmnop":
            for filename in self.tool.LEVEL_FILES:
                self.write(f"levels_editor_uncompressed/level_{level}/{filename}")

        with self.assertRaisesRegex(FileNotFoundError, "vectobj/missing"):
            self.tool.prepare_runtime(self.media, self.output)


if __name__ == "__main__":
    unittest.main()
