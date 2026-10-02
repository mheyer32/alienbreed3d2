#!/usr/bin/env python3
"""Check IE documentation and comments for the project's prose conventions."""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
FILES = (
    ROOT / "ie" / "README.md",
    ROOT / "ie" / "RELEASE.md",
    ROOT / "ie" / "patches" / "README.md",
    ROOT / "ie" / "Makefile",
    ROOT / "ie" / "build.mk",
    ROOT / "ie" / "tools" / "generate_source_patches.py",
    ROOT / "ie" / "tools" / "prepare_source_overlay.py",
    ROOT / "ie" / "tools" / "test_source_overlay.py",
    ROOT / "ie" / "tools" / "test_build_mk.py",
    ROOT / "ie" / "tools" / "pack_ie68.py",
    ROOT / "ie" / "tools" / "test_pack_ie68.py",
    ROOT / "ie" / "tools" / "test_pack_loader_source.py",
    ROOT / "ie" / "tools" / "generate_pack_save_smoke.py",
    ROOT / "ie" / "tools" / "test_generate_pack_save_smoke.py",
    ROOT / "ie" / "tools" / "prepare_original_runtime.py",
    ROOT / "ie" / "tools" / "test_prepare_original_runtime.py",
    ROOT / "ie" / "platform" / "ie_file_io_runtime.i",
)
FORBIDDEN = {
    "—": "use punctuation rather than an em dash",
    "behavior": "use behaviour",
    "Behavior": "use Behaviour",
    "color": "use colour",
    "Color": "use Colour",
    "initialize": "use initialise",
    "Initialize": "use Initialise",
    "organization": "use organisation",
    "Organization": "use Organisation",
}


def prose_lines(path: Path) -> list[tuple[int, str]]:
    lines: list[tuple[int, str]] = []
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        stripped = line.lstrip()
        if path.suffix == ".md" or stripped.startswith(("#", ";", "//")):
            lines.append((number, line))
    return lines


def main() -> int:
    failures: list[str] = []
    for path in FILES:
        for number, line in prose_lines(path):
            for word, guidance in FORBIDDEN.items():
                if word in line:
                    failures.append(f"{path.relative_to(ROOT)}:{number}: {guidance}")
            if re.search(r"\b(?:simply|just|seamlessly)\b", line, flags=re.IGNORECASE):
                failures.append(f"{path.relative_to(ROOT)}:{number}: use direct technical prose")
    if failures:
        print("\n".join(failures), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
