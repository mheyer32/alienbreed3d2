#!/usr/bin/env python3
"""Insert linked helper addresses into the packed-save IEScript."""

import argparse
import re
from pathlib import Path


PLACEHOLDER = re.compile(r"@([A-Za-z_][A-Za-z0-9_]*)@")
SYMBOL = re.compile(r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(0x[0-9A-Fa-f]+),?\s*$")


def generate(symbol_path: Path, template_path: Path, output_path: Path) -> None:
    symbols = {}
    for line in symbol_path.read_text(encoding="utf-8").splitlines():
        match = SYMBOL.match(line)
        if match:
            symbols[match.group(1)] = int(match.group(2), 16)

    def replace(match: re.Match[str]) -> str:
        name = match.group(1)
        if name not in symbols:
            raise ValueError(f"missing diagnostic symbol: {name}")
        return f"0x{symbols[name]:08X}"

    rendered = PLACEHOLDER.sub(replace, template_path.read_text(encoding="utf-8"))
    output_path.write_text(rendered, encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("symbols", type=Path)
    parser.add_argument("template", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    generate(args.symbols, args.template, args.output)


if __name__ == "__main__":
    main()
