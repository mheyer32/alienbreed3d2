#!/usr/bin/env python3
import argparse
import os
import pathlib
import shutil
import struct
import subprocess
import tempfile


def make_lha(payload: bytes, unpacked_size: int, name: str, method: bytes) -> bytes:
    encoded_name = name.encode("ascii", "replace")[:255]
    body = bytearray()
    body += method
    body += struct.pack("<I", len(payload))
    body += struct.pack("<I", unpacked_size)
    body += struct.pack("<I", 0)
    body += bytes([0x20, 0, len(encoded_name)])
    body += encoded_name
    body += struct.pack("<H", 0)
    header = bytearray([len(body), 0]) + body
    header[1] = sum(header[2 : 1 + header[0]]) & 0xFF
    return bytes(header) + payload + b"\0"


def extract_with_7z(lha_data: bytes, expected_size: int, output_name: str) -> bytes:
    with tempfile.TemporaryDirectory(prefix="ab3d2-sb-") as temp:
        temp_path = pathlib.Path(temp)
        archive_path = temp_path / "asset.lha"
        out_dir = temp_path / "out"
        archive_path.write_bytes(lha_data)
        out_dir.mkdir()
        subprocess.run(
            ["7z", "x", "-y", f"-o{out_dir}", archive_path],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        extracted = out_dir / output_name
        if not extracted.exists():
            raise RuntimeError("7z did not produce an output file")
        data = extracted.read_bytes()
        if len(data) != expected_size:
            raise RuntimeError(f"unexpected output size {len(data)} != {expected_size}")
        return data


def unpack_sb_file(source: pathlib.Path) -> bytes | None:
    data = source.read_bytes()
    if len(data) < 12 or data[:4] != b"=SB=":
        return None
    unpacked_size = struct.unpack(">I", data[4:8])[0]
    packed_size = struct.unpack(">I", data[8:12])[0]
    payload = data[12:]
    if packed_size != len(payload):
        raise RuntimeError(f"{source}: packed size {packed_size} != file payload {len(payload)}")
    if packed_size == unpacked_size:
        return payload
    for method in (b"-lh6-", b"-lh7-"):
        try:
            return extract_with_7z(make_lha(payload, unpacked_size, source.name, method), unpacked_size, source.name)
        except RuntimeError:
            pass
    raise RuntimeError(f"{source}: unable to unpack =SB= payload")


def write_aliases(out_root: pathlib.Path, rel: pathlib.Path, data: bytes) -> int:
    written = 0
    aliases = {rel, pathlib.Path(*[part.lower() for part in rel.parts])}
    for alias in aliases:
        dest = out_root / alias
        dest.parent.mkdir(parents=True, exist_ok=True)
        if dest.exists() and dest.read_bytes() == data:
            continue
        dest.write_bytes(data)
        written += 1
    return written


def main() -> None:
    parser = argparse.ArgumentParser(description="Unpack AB3D2 =SB= assets into an IE build mirror")
    parser.add_argument("--source", required=True, type=pathlib.Path)
    parser.add_argument("--out", required=True, type=pathlib.Path)
    args = parser.parse_args()

    if shutil.which("7z") is None:
        raise SystemExit("7z is required to unpack AB3D2 =SB= assets")

    source_root = args.source
    out_root = args.out
    unpacked_count = 0
    copied_count = 0
    alias_count = 0
    sources = []
    for root, _, files in os.walk(source_root, followlinks=True):
        root_path = pathlib.Path(root)
        for filename in files:
            sources.append(root_path / filename)

    for source in sorted(sources):
        rel = source.relative_to(source_root)
        unpacked = unpack_sb_file(source)
        if unpacked is None:
            alias_count += write_aliases(out_root, rel, source.read_bytes())
            copied_count += 1
        else:
            alias_count += write_aliases(out_root, rel, unpacked)
            unpacked_count += 1

    (out_root / ".stamp").write_text(f"{unpacked_count} {copied_count} {alias_count}\n", encoding="ascii")
    print(f"Mirrored {copied_count} raw assets and unpacked {unpacked_count} =SB= assets into {out_root}")


if __name__ == "__main__":
    main()
