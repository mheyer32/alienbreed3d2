import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "ie/platform/ie_file_io_runtime.i"


class PackLoaderSourceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = SOURCE.read_text(encoding="utf-8")

    def test_loader_checks_pack_before_file_mmio_for_immutable_assets(self):
        body = self.source.split("io_ie_load_to_heap:", 1)[1].split("io_ie_write_buffer:", 1)[0]
        ordinary = body.split(".try_pack_ie:", 1)[1]
        self.assertLess(ordinary.index("bsr\t\tio_ie_pack_find"), ordinary.index(".try_file_ie:"))

    def test_each_generated_fallback_candidate_checks_the_pack(self):
        for start, end in (
            (".try_file_ie:", ".try_parent_media_ie:"),
            (".try_parent_media_ie:", ".try_normal_ie:"),
            ("bsr\t\tio_ie_make_repo_root_ie_path", ".try_unpacked_ie:"),
            (".try_unpacked_ie:", ".loaded_ie:"),
        ):
            block = self.source.split(start, 1)[1].split(end, 1)[0]
            self.assertIn("bsr\t\t.try_pack_candidate_ie", block)

    def test_pack_lookup_validates_header_table_and_asset_checksums(self):
        self.assertIn("io_ie_pack_validate:", self.source)
        self.assertGreaterEqual(self.source.count("bsr\t\tio_ie_crc32"), 3)

    def test_pack_copy_checks_heap_limit_before_writing(self):
        body = self.source.split("io_ie_pack_copy:", 1)[1].split("io_ie_pack_find:", 1)[0]
        self.assertLess(body.index("IO_IE_HEAP_LIMIT"), body.index(".copy_pack_byte"))

    def test_saved_boot_override_is_read_before_embedded_default(self):
        body = self.source.split("io_ie_load_to_heap:", 1)[1].split(".try_pack_ie:", 1)[0]
        self.assertIn("io_ie_is_boot_path", body)
        self.assertIn("io_ie_save_name", body)
        self.assertIn("FILE_IO_CTRL", body)

    def test_boot_writes_use_the_external_save_name(self):
        body = self.source.split("io_ie_write_buffer:", 1)[1].split("io_ie_make_unpacked_media_path:", 1)[0]
        self.assertIn("io_ie_is_boot_path", body)
        self.assertIn("io_ie_save_name", body)

    def test_pack_constants_match_the_python_format(self):
        for value in ("$00600000", "$01000000", "$02000000", "$41423344", "$50414B31"):
            self.assertIn(value, self.source)

    def test_no_em_dash_in_new_loader_comments(self):
        self.assertNotIn("—", self.source)


if __name__ == "__main__":
    unittest.main()
