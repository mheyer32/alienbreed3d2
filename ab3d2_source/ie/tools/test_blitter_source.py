import pathlib
import re
import unittest


SOURCE = pathlib.Path(__file__).resolve().parents[1] / "platform" / "ie_hires_platform.s"


def routine(source: str, name: str, next_name: str) -> str:
    match = re.search(
        rf"(?ms)^{re.escape(name)}:\n(.*?)(?=^{re.escape(next_name)}:)",
        source,
    )
    if not match:
        raise AssertionError(f"could not find {name} before {next_name}")
    return match.group(1)


class BlitterMigrationSourceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.source = SOURCE.read_text()

    def test_helpers_fully_program_clut8_operations(self) -> None:
        fill = routine(self.source, "ie_blt_fill_clut8", "ie_blt_memcopy")
        for register in (
            "BLT_OP", "BLT_DST", "BLT_WIDTH", "BLT_HEIGHT",
            "BLT_DST_STRIDE", "BLT_COLOR", "BLT_FLAGS", "BLT_CTRL",
        ):
            self.assertIn(register, fill)
        copy = routine(self.source, "ie_blt_memcopy", "ie_blt_test_status")
        for register in (
            "BLT_OP", "BLT_SRC", "BLT_DST", "BLT_WIDTH", "BLT_HEIGHT",
            "BLT_SRC_STRIDE", "BLT_DST_STRIDE", "BLT_FLAGS", "BLT_CTRL",
        ):
            self.assertIn(register, copy)
        self.assertIn("BLT_FLAGS_CLUT8_COPY", copy)
        self.assertIn("#BLT_OP_MEMCOPY,BLT_OP", copy)

    def test_reset_display_uses_three_hardware_fills(self) -> None:
        body = routine(self.source, "_Draw_ResetGameDisplay", "ie_present_small")
        self.assertEqual(body.count("bsr\t\tie_blt_fill_clut8"), 3)
        self.assertNotIn("dbra", body)

    def test_source_contains_no_retired_high_resolution_path(self) -> None:
        self.assertNotIn("over" + "drive", self.source.lower())

    def test_menu_background_uses_four_hardware_copies(self) -> None:
        body = routine(self.source, "ie_menu_copy_background", "ie_menu_render_frame")
        self.assertEqual(body.count("bsr\t\tie_blt_memcopy"), 4)
        self.assertNotIn("dbra", body)

    def test_menu_fire_uses_three_hardware_copies(self) -> None:
        body = routine(self.source, "_mnu_dofire", "_ReadJoy1")
        self.assertEqual(body.count("bsr\t\tie_blt_memcopy"), 3)
        self.assertNotIn("dbra", body)

    def test_menu_fire_preserves_legacy_source_destination_direction(self) -> None:
        body = routine(self.source, "_mnu_dofire", "_ReadJoy1")
        calls = body.split("bsr\t\tie_blt_memcopy")
        self.assertEqual(len(calls), 4)
        for call in calls[:-1]:
            self.assertRegex(
                call,
                r"exg\s+a0,a1\s+move\.l\s+#SCREEN_HEIGHT\*MENU_ROW_BYTES,d0\s*$",
            )

    def test_menu_background_keeps_natural_helper_direction(self) -> None:
        body = routine(self.source, "ie_menu_copy_background", "ie_menu_render_frame")
        self.assertNotIn("exg", body)


if __name__ == "__main__":
    unittest.main()
