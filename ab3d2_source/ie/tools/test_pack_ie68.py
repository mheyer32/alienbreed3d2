import importlib.util
import struct
import subprocess
import sys
import tempfile
import unittest
import zlib
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("pack_ie68.py")


def load_module():
    spec = importlib.util.spec_from_file_location("pack_ie68", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class PackIE68Tests(unittest.TestCase):
    def setUp(self):
        self.pack = load_module()
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.program = self.root / "game.ie68"
        self.assets = self.root / "assets"
        self.output = self.root / "packed.ie68"
        self.program.write_bytes(b"PROGRAM")
        self.assets.mkdir()

    def tearDown(self):
        self.temp.cleanup()

    def build(self, prefix="_build/ie_media/redux-high"):
        self.pack.build_pack(self.program, self.assets, prefix, self.output)
        return self.pack.inspect_pack(self.output)

    def test_recursively_packs_exact_asset_bytes(self):
        (self.assets / "Includes").mkdir()
        (self.assets / "Includes" / "Main.256PAL").write_bytes(b"palette")
        (self.assets / "boot.dat").write_bytes(b"save-default")

        image = self.build()

        self.assertEqual(self.output.read_bytes()[:7], b"PROGRAM")
        self.assertEqual(
            {entry.path: entry.data for entry in image.entries},
            {
                "_build/ie_media/redux-high/boot.dat": b"save-default",
                "_build/ie_media/redux-high/includes/main.256pal": b"palette",
            },
        )

    def test_output_is_deterministic(self):
        (self.assets / "z").write_bytes(b"last")
        (self.assets / "a").write_bytes(b"first")
        self.build()
        first = self.output.read_bytes()
        self.build()
        self.assertEqual(self.output.read_bytes(), first)

    def test_rejects_duplicate_paths_after_case_normalisation(self):
        (self.assets / "PAL").write_bytes(b"one")
        (self.assets / "pal").write_bytes(b"two")
        with self.assertRaisesRegex(ValueError, "duplicate canonical asset path"):
            self.build()

    def test_collapses_byte_identical_case_aliases(self):
        (self.assets / "PAL").write_bytes(b"same")
        (self.assets / "pal").write_bytes(b"same")

        image = self.build()

        self.assertEqual(len(image.entries), 1)
        self.assertEqual(image.entries[0].path, "_build/ie_media/redux-high/pal")
        self.assertEqual(image.entries[0].data, b"same")

    def test_rejects_unsafe_prefix(self):
        (self.assets / "asset").write_bytes(b"data")
        for prefix in ("/absolute", "../escape", "safe/../escape", "safe\\bad"):
            with self.subTest(prefix=prefix):
                with self.assertRaisesRegex(ValueError, "unsafe asset path"):
                    self.build(prefix)

    def test_reads_symlinked_prepared_assets_as_bytes(self):
        outside = self.root / "outside"
        outside.write_bytes(b"secret")
        (self.assets / "escape").symlink_to(outside)
        image = self.build()
        self.assertEqual(image.entries[0].data, b"secret")

    def test_rejects_program_overlapping_pack_header(self):
        self.program.write_bytes(b"x" * (self.pack.HEADER_FILE_OFFSET + 1))
        with self.assertRaisesRegex(ValueError, "program overlaps pack header"):
            self.build()

    def test_rejects_data_past_pack_limit(self):
        old_limit = self.pack.DATA_LIMIT_FILE_OFFSET
        self.pack.DATA_LIMIT_FILE_OFFSET = self.pack.DATA_FILE_OFFSET + 3
        (self.assets / "asset").write_bytes(b"four")
        try:
            with self.assertRaisesRegex(ValueError, "pack data exceeds"):
                self.build()
        finally:
            self.pack.DATA_LIMIT_FILE_OFFSET = old_limit

    def test_inspector_rejects_bad_header_checksum(self):
        (self.assets / "asset").write_bytes(b"data")
        self.build()
        data = bytearray(self.output.read_bytes())
        checksum_offset = self.pack.HEADER_FILE_OFFSET + 7 * 4
        data[checksum_offset] ^= 1
        self.output.write_bytes(data)
        with self.assertRaisesRegex(ValueError, "header checksum"):
            self.pack.inspect_pack(self.output)

    def test_inspector_rejects_bad_table_checksum(self):
        (self.assets / "asset").write_bytes(b"data")
        self.build()
        data = bytearray(self.output.read_bytes())
        data[self.pack.HEADER_FILE_OFFSET + self.pack.HEADER_SIZE] ^= 1
        self.output.write_bytes(data)
        with self.assertRaisesRegex(ValueError, "table checksum"):
            self.pack.inspect_pack(self.output)

    def test_inspector_rejects_bad_asset_checksum(self):
        (self.assets / "asset").write_bytes(b"data")
        image = self.build()
        data = bytearray(self.output.read_bytes())
        data[image.entries[0].file_offset] ^= 1
        self.output.write_bytes(data)
        with self.assertRaisesRegex(ValueError, "asset checksum"):
            self.pack.inspect_pack(self.output)

    def test_inspector_rejects_truncation(self):
        (self.assets / "asset").write_bytes(b"data")
        self.build()
        self.output.write_bytes(self.output.read_bytes()[:-1])
        with self.assertRaisesRegex(ValueError, "truncated"):
            self.pack.inspect_pack(self.output)

    def test_header_and_entries_are_big_endian_and_four_byte_aligned(self):
        (self.assets / "odd").write_bytes(b"123")
        image = self.build()
        raw = self.output.read_bytes()
        magic = struct.unpack_from(">I", raw, self.pack.HEADER_FILE_OFFSET)[0]
        self.assertEqual(magic, self.pack.MAGIC)
        self.assertEqual(image.entries[0].file_offset % 4, 0)
        self.assertEqual(
            zlib.crc32(image.entries[0].data) & 0xFFFFFFFF,
            image.entries[0].checksum,
        )

    def test_cli_inspects_with_only_the_packed_image_argument(self):
        (self.assets / "asset").write_bytes(b"data")
        image = self.build()

        result = subprocess.run(
            [sys.executable, str(MODULE_PATH), str(self.output), "--inspect"],
            check=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

        self.assertEqual(
            result.stdout.strip(),
            f"{len(image.entries)} assets, {image.data_end_file_offset} bytes",
        )

    def test_cli_rejects_incomplete_build_arguments_clearly(self):
        result = subprocess.run(
            [sys.executable, str(MODULE_PATH), str(self.program)],
            check=False,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

        self.assertEqual(result.returncode, 2)
        self.assertIn("build mode requires asset_root, prefix and output", result.stderr)


if __name__ == "__main__":
    unittest.main()
