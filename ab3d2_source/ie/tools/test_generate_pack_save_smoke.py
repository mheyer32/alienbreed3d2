import tempfile
import unittest
from pathlib import Path

from generate_pack_save_smoke import generate


class GeneratePackSaveSmokeTests(unittest.TestCase):
    def test_replaces_every_required_symbol(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            symbols = root / "symbols.lua"
            template = root / "template.ies.in"
            output = root / "output.ies"
            symbols.write_text(
                "return {\n  io_ie_load_to_heap = 0x1234,\n  io_ie_write_buffer = 0x5678,\n}\n"
            )
            template.write_text("load=@io_ie_load_to_heap@ write=@io_ie_write_buffer@\n")
            generate(symbols, template, output)
            self.assertEqual(output.read_text(), "load=0x00001234 write=0x00005678\n")

    def test_rejects_a_missing_symbol(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            symbols = root / "symbols.lua"
            template = root / "template.ies.in"
            symbols.write_text("return {}\n")
            template.write_text("@io_ie_load_to_heap@\n")
            with self.assertRaisesRegex(ValueError, "missing diagnostic symbol"):
                generate(symbols, template, root / "output.ies")


if __name__ == "__main__":
    unittest.main()
