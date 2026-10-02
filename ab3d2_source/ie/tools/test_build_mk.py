import os
import pathlib
import re
import subprocess
import unittest


REPO_ROOT = pathlib.Path(__file__).resolve().parents[2]


def dry_run(*assignments: str, target: str = "ie68-jit-progress-test") -> str:
    env = os.environ.copy()
    env.pop("IE_BUILD_HEADLESS", None)
    env.pop("IE_HEADLESS_ENGINE", None)
    env.pop("IE_ENGINE_SOURCE", None)
    env.pop("MAKEFLAGS", None)
    env.pop("MFLAGS", None)
    env.pop("MAKEOVERRIDES", None)
    env.pop("GNUMAKEFLAGS", None)
    result = subprocess.run(
        ["make", "-f", "ie/Makefile", "-n", *assignments, target],
        cwd=REPO_ROOT,
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        env=env,
    )
    return result.stdout


class JITProgressTargetTests(unittest.TestCase):
    def test_progress_target_uses_the_standard_redux_image(self) -> None:
        output = dry_run("IE_BUILD_HEADLESS=0")
        self.assertIn("MEDIA_PROFILE=redux-high", output)
        self.assertIn("ab3d2_ie68_redux_high.ie68", output)
        self.assertIn("ab3d2_ie68_redux_high_progress.ies", output)
        self.assertNotIn("IE_" + "OVER" + "DRIVE=1", output)

    def test_standard_redux_progress_script_uses_the_native_cadence_floor(self) -> None:
        script = (REPO_ROOT / "ie/bin/ab3d2_ie68_redux_high_progress.ies").read_text()
        self.assertIn("local minimum_guest_ticks_per_second = 30", script)

    def test_overridden_runner_does_not_build_sibling_engine(self) -> None:
        output = dry_run("IE_HEADLESS_ENGINE=/opt/ie/bin/ie_headless")
        self.assertNotIn("make -C ../../IntuitionEngine headless", output)
        self.assertIn("/opt/ie/bin/ie_headless", output)

    def test_configured_engine_source_is_built_by_default(self) -> None:
        engine_source = (REPO_ROOT / "../../IntuitionEngine").resolve()
        output = dry_run(f"IE_ENGINE_SOURCE={engine_source}")
        self.assertIn(f"make -C {engine_source} headless", output)
        self.assertIn(f"{engine_source}/bin/ie_headless", output)

    def test_ie_entry_point_uses_the_generated_source_overlay(self) -> None:
        result = subprocess.run(
            ["make", "-f", "ie/Makefile", "-n", "ie68"],
            cwd=REPO_ROOT,
            check=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
        output = result.stdout
        self.assertIn("prepare_source_overlay.py", output)
        self.assertIn("cd _build/ie-source", output)
        self.assertIn("-Fhunk hires.s", output)
        self.assertIn("ie/platform/ie_hires_platform.s", output)
        self.assertNotIn("-Fhunk ie/hires.s", output)


class GamepadTargetTests(unittest.TestCase):
    def test_automated_target_defaults_to_headless_engine(self) -> None:
        output = dry_run(target="ie68-gamepad-test")
        self.assertIn("../../IntuitionEngine/bin/ie_headless", output)
        self.assertNotIn("../../IntuitionEngine/bin/IntuitionEngine --script-owned-term", output)

    def test_manual_acceptance_target_defaults_to_gui_engine(self) -> None:
        output = dry_run(target="ie68-gamepad-acceptance")
        self.assertIn("../../IntuitionEngine/bin/IntuitionEngine --script-owned-term", output)
        self.assertNotIn("../../IntuitionEngine/bin/ie_headless --script-owned-term", output)
        self.assertIn("MEDIA_PROFILE=redux-high", output)
        self.assertIn("ab3d2_ie68_redux_high.ie68", output)
        self.assertNotIn("-script ie/bin/gamepad_acceptance.ies ie/bin/ab3d2_ie68.ie68", output)

    def test_manual_acceptance_records_canonical_live_input(self) -> None:
        script = (REPO_ROOT / "ie/gamepad_acceptance.ies").read_text()
        self.assertIn("GAMEPAD_STATUS", script)
        self.assertIn("GAMEPAD_PAD0", script)
        self.assertIn("gamepad-live.result", script)
        self.assertIn("canonical_bits", script)
        self.assertIn('require("gamepad_acceptance_symbols")', script)
        self.assertIn("ie_gamepad_actions_w", script)
        self.assertIn("Plr1_TmpSpcTap_b", script)
        self.assertIn("Conditions", script)
        self.assertIn("sys.wait_ms(500)", script)
        output = dry_run(target="ie68-gamepad-acceptance")
        self.assertIn("gamepad_acceptance_symbols.lua", output)
        self.assertIn(
            "cp _build/diag_symbols_ie68_redux_high.lua "
            "ie/bin/gamepad_acceptance_symbols.lua",
            output,
        )
        self.assertNotIn(
            "cp ie/diag_symbols.lua ie/bin/gamepad_acceptance_symbols.lua",
            output,
        )
        self.assertNotIn("Xbox", script)
        self.assertNotIn("Nintendo", script)
        self.assertNotIn("PlayStation", script)

    def test_automated_runner_override_skips_sibling_engine_build(self) -> None:
        output = dry_run(
            "IE_GAMEPAD_ENGINE=/opt/ie/bin/ie_headless",
            target="ie68-gamepad-test",
        )
        self.assertNotIn("make -C ../../IntuitionEngine headless", output)
        self.assertIn("/opt/ie/bin/ie_headless --script-owned-term", output)


class BlitterTargetTests(unittest.TestCase):
    def test_automated_target_builds_test_variant_and_runs_headless(self) -> None:
        output = dry_run(
            "IE_BUILD_HEADLESS=0",
            target="ie68-blitter-test",
        )
        self.assertIn("IE_BLITTER_TEST=1", output)
        self.assertIn("ab3d2_ie68_blitter_test.ie68", output)
        self.assertIn("../../IntuitionEngine/bin/ie_headless --script-owned-term", output)
        self.assertIn("AB3D2_BLITTER PASS", output)

    def test_production_build_rejects_blitter_test_symbols(self) -> None:
        output = dry_run(
            "IE_BUILD_HEADLESS=0",
            target="ie68",
        )
        self.assertIn("production IE map contains blitter test-seam symbols", output)


class VariantInventoryTests(unittest.TestCase):
    def test_all_target_builds_only_original_and_standard_redux_images(self) -> None:
        output = dry_run("IE_BUILD_HEADLESS=0", target="ie68-all")
        self.assertIn("ab3d2_ie68_raw.ie68", output)
        self.assertIn("ab3d2_ie68_redux_high_raw.ie68", output)
        self.assertIn("ab3d2_ie68_redux_high.ie68", output)
        self.assertNotIn("over" + "drive", output.lower())

    def test_build_fragment_contains_no_retired_high_resolution_interface(self) -> None:
        source = (REPO_ROOT / "ie/build.mk").read_text()
        self.assertNotIn("over" + "drive", source.lower())

    def test_port_contains_no_retired_music_backend_interface(self) -> None:
        token = "s" + "id"
        for relative in (
            "ie/build.mk",
            "ie/platform/ie_music.i",
            "ie/README.md",
        ):
            source = (REPO_ROOT / relative).read_text().lower()
            self.assertIsNone(
                re.search(rf"\b{token}\b|{token}_|f0e2[0-9a-f]", source),
                relative,
            )


class PackedImageTargetTests(unittest.TestCase):
    def test_canonical_original_target_packs_the_advertised_image(self) -> None:
        output = dry_run("IE_BUILD_HEADLESS=0", target="ie68")
        self.assertIn("ie/tools/pack_ie68.py", output)
        self.assertIn("ie/tools/prepare_original_runtime.py", output)
        self.assertIn("_build/ab3d2_ie68_raw.ie68", output)
        self.assertIn("_build/ie_original_runtime", output)
        self.assertIn("ie/bin/ab3d2_ie68.ie68", output)

    def test_original_linker_never_writes_the_canonical_image(self) -> None:
        output = dry_run("IE_BUILD_HEADLESS=0", target="ie68")
        self.assertIn("IE_TARGET=_build/ab3d2_ie68_raw.ie68", output)
        self.assertNotIn("IE_TARGET=ie/bin/ab3d2_ie68.ie68", output)

    def test_all_variants_reaches_both_canonical_packers(self) -> None:
        output = dry_run("IE_BUILD_HEADLESS=0", target="ie68-all")
        self.assertIn("_build/ab3d2_ie68_raw.ie68", output)
        self.assertIn("_build/ab3d2_ie68_redux_high_raw.ie68", output)
        self.assertNotIn("over" + "drive", output.lower())
        self.assertEqual(output.count("ie/tools/pack_ie68.py"), 2)

    def test_canonical_standard_redux_target_packs_the_advertised_image(self) -> None:
        output = dry_run("IE_BUILD_HEADLESS=0", target="ie68-redux-high")
        self.assertIn("MEDIA_PROFILE=redux-high", output)
        self.assertIn("_build/ab3d2_ie68_redux_high_raw.ie68", output)
        self.assertIn("ie/bin/ab3d2_ie68_redux_high.ie68", output)
        self.assertIn("ie/tools/pack_ie68.py", output)

    def test_pack_alias_builds_the_canonical_original_image(self) -> None:
        output = dry_run("IE_BUILD_HEADLESS=0", target="ie68-pack")
        self.assertIn("_build/ab3d2_ie68_raw.ie68", output)
        self.assertIn("ie/bin/ab3d2_ie68.ie68", output)
        self.assertNotIn("ab3d2_ie68_redux_high.ie68", output)

    def test_specialised_test_build_uses_explicit_raw_target(self) -> None:
        output = dry_run("IE_BUILD_HEADLESS=0", target="ie68-fps-test")
        self.assertIn("ie68-raw IE_FPS_TEST=1", output)
        self.assertNotIn("ie/tools/pack_ie68.py", output)

    def test_pack_test_runs_format_inventory_and_build_tests(self) -> None:
        output = dry_run("IE_BUILD_HEADLESS=0", target="ie68-pack-test")
        self.assertIn("test_pack_ie68.py", output)
        self.assertIn("test_build_mk.py", output)

    def test_pack_smoke_runs_from_an_isolated_directory_without_file_root(self) -> None:
        output = dry_run("IE_BUILD_HEADLESS=0", target="ie68-pack-smoke")
        self.assertIn("mktemp -d", output)
        self.assertIn("ab3d2_ie68_redux_high.ie68", output)
        self.assertIn("ab3d2_ie68_redux_high_progress.ies", output)
        self.assertNotIn("over" + "drive", output.lower())
        self.assertNotIn("-file-root", output)
        self.assertIn("AB3D2_GUEST_PROGRESS", output)
        self.assertIn("unexpected runtime file", output)

    def test_original_pack_smoke_is_isolated_without_file_root(self) -> None:
        output = dry_run("IE_BUILD_HEADLESS=0", target="ie68-original-pack-smoke")
        self.assertIn("ab3d2_ie68.ie68", output)
        self.assertIn("mktemp -d", output)
        self.assertNotIn("-file-root", output)
        self.assertIn("AB3D2_GUEST_PROGRESS", output)
        self.assertIn("unexpected runtime file", output)

    def test_original_save_test_proves_override_and_no_save_fallback(self) -> None:
        output = dry_run("IE_BUILD_HEADLESS=0", target="ie68-original-pack-save-test")
        self.assertIn("pack_save_smoke_original.ies", output)
        self.assertIn("AB3D2_PACK_SAVE PASS", output)
        self.assertIn("ab3d2-save.dat", output)
        self.assertIn("rm -f", output)
        self.assertIn("ab3d2_ie68.ie68", output)

    def test_pack_save_test_proves_external_override_and_embedded_fallback(self) -> None:
        output = dry_run("IE_BUILD_HEADLESS=0", target="ie68-pack-save-test")
        self.assertIn("pack_save_smoke.ies", output)
        self.assertIn("AB3D2_PACK_SAVE PASS", output)
        self.assertIn("ab3d2-save.dat", output)
        self.assertIn("rm -f", output)
        self.assertIn("ab3d2_ie68_redux_high_progress.ies", output)
        self.assertIn("ab3d2_ie68_redux_high.ie68", output)
        self.assertNotIn("over" + "drive", output.lower())


if __name__ == "__main__":
    unittest.main()
