#!/usr/bin/env python3
"""Build and inspect a self-contained AB3D2 IE68 image."""

from __future__ import annotations

import argparse
import dataclasses
import struct
import zlib
from pathlib import Path, PurePosixPath


LOAD_BASE = 0x00001000
HEADER_FILE_OFFSET = 0x005FF000
DATA_FILE_OFFSET = 0x00FFF000
DATA_LIMIT_FILE_OFFSET = 0x01FFF000
MAGIC = 0x41423344
MAGIC2 = 0x50414B31
VERSION = 1
HEADER_FORMAT = ">9I"
HEADER_SIZE = struct.calcsize(HEADER_FORMAT)
ENTRY_FORMAT = ">HHIII"
ENTRY_SIZE = struct.calcsize(ENTRY_FORMAT)


@dataclasses.dataclass(frozen=True)
class PackEntry:
    path: str
    file_offset: int
    size: int
    checksum: int
    data: bytes


@dataclasses.dataclass(frozen=True)
class PackImage:
    entries: tuple[PackEntry, ...]
    data_file_offset: int
    data_end_file_offset: int


def align4(value: int) -> int:
    return (value + 3) & ~3


def canonical_path(path: str) -> str:
    if not path or "\\" in path or path.startswith("/"):
        raise ValueError(f"unsafe asset path: {path!r}")
    parts = PurePosixPath(path).parts
    if any(part in ("", ".", "..") for part in parts):
        raise ValueError(f"unsafe asset path: {path!r}")
    try:
        encoded = "/".join(part.lower() for part in parts).encode("ascii")
    except UnicodeEncodeError as exc:
        raise ValueError(f"asset path is not ASCII: {path!r}") from exc
    if len(encoded) > 0xFFFF:
        raise ValueError(f"asset path is too long: {path!r}")
    return encoded.decode("ascii")


def collect_assets(asset_root: Path, prefix: str) -> list[tuple[str, bytes]]:
    canonical_prefix = canonical_path(prefix)
    entries: list[tuple[str, bytes]] = []
    seen: dict[str, bytes] = {}
    for source in sorted(asset_root.rglob("*"), key=lambda item: item.as_posix().lower()):
        if not source.is_file():
            continue
        relative = source.relative_to(asset_root).as_posix()
        path = canonical_path(f"{canonical_prefix}/{relative}")
        data = source.read_bytes()
        if path in seen:
            if seen[path] != data:
                raise ValueError(f"duplicate canonical asset path: {path}")
            continue
        seen[path] = data
        entries.append((path, data))
    return entries


def encode_table(assets: list[tuple[str, bytes]]) -> tuple[bytes, list[PackEntry]]:
    table_size = sum(align4(ENTRY_SIZE + len(path.encode("ascii"))) for path, _ in assets)
    if HEADER_FILE_OFFSET + HEADER_SIZE + table_size > DATA_FILE_OFFSET:
        raise ValueError("asset table exceeds header area")
    data_offset = DATA_FILE_OFFSET
    records: list[bytes] = []
    entries: list[PackEntry] = []
    for path, data in assets:
        encoded_path = path.encode("ascii")
        checksum = zlib.crc32(data) & 0xFFFFFFFF
        record = struct.pack(ENTRY_FORMAT, len(encoded_path), 0, data_offset, len(data), checksum)
        record += encoded_path
        record += bytes(align4(len(record)) - len(record))
        records.append(record)
        entries.append(PackEntry(path, data_offset, len(data), checksum, data))
        data_offset = align4(data_offset + len(data))
    if data_offset > DATA_LIMIT_FILE_OFFSET:
        raise ValueError(
            f"pack data exceeds limit 0x{DATA_LIMIT_FILE_OFFSET:x}: 0x{data_offset:x}"
        )
    return b"".join(records), entries


def build_pack(program: Path, asset_root: Path, prefix: str, output: Path) -> PackImage:
    program_data = program.read_bytes()
    if len(program_data) > HEADER_FILE_OFFSET:
        raise ValueError("program overlaps pack header")
    assets = collect_assets(asset_root, prefix)
    table, entries = encode_table(assets)
    data_end = entries[-1].file_offset + entries[-1].size if entries else DATA_FILE_OFFSET
    data_end = align4(data_end)
    first_fields = (
        MAGIC,
        MAGIC2,
        VERSION,
        len(entries),
        len(table),
        DATA_FILE_OFFSET,
        data_end,
    )
    header_checksum = zlib.crc32(struct.pack(">7I", *first_fields)) & 0xFFFFFFFF
    table_checksum = zlib.crc32(table) & 0xFFFFFFFF
    header = struct.pack(HEADER_FORMAT, *first_fields, header_checksum, table_checksum)

    with output.open("wb") as stream:
        stream.write(program_data)
        stream.write(bytes(HEADER_FILE_OFFSET - stream.tell()))
        stream.write(header)
        stream.write(table)
        stream.write(bytes(DATA_FILE_OFFSET - stream.tell()))
        for entry in entries:
            if stream.tell() < entry.file_offset:
                stream.write(bytes(entry.file_offset - stream.tell()))
            stream.write(entry.data)
        if stream.tell() < data_end:
            stream.write(bytes(data_end - stream.tell()))
    return PackImage(tuple(entries), DATA_FILE_OFFSET, data_end)


def inspect_pack(path: Path) -> PackImage:
    raw = path.read_bytes()
    if len(raw) < HEADER_FILE_OFFSET + HEADER_SIZE:
        raise ValueError("truncated pack header")
    fields = struct.unpack_from(HEADER_FORMAT, raw, HEADER_FILE_OFFSET)
    magic, magic2, version, count, table_size, data_offset, data_end, header_crc, table_crc = fields
    if (magic, magic2) != (MAGIC, MAGIC2):
        raise ValueError("invalid pack magic")
    if version != VERSION:
        raise ValueError(f"unsupported pack version: {version}")
    if zlib.crc32(struct.pack(">7I", *fields[:7])) & 0xFFFFFFFF != header_crc:
        raise ValueError("invalid header checksum")
    table_start = HEADER_FILE_OFFSET + HEADER_SIZE
    table_end = table_start + table_size
    if table_end > len(raw) or table_end > data_offset:
        raise ValueError("truncated asset table")
    table = raw[table_start:table_end]
    if zlib.crc32(table) & 0xFFFFFFFF != table_crc:
        raise ValueError("invalid table checksum")
    if data_offset != DATA_FILE_OFFSET or data_end > DATA_LIMIT_FILE_OFFSET or data_end > len(raw):
        raise ValueError("truncated pack data")

    entries: list[PackEntry] = []
    cursor = 0
    previous_end = data_offset
    seen: set[str] = set()
    for _ in range(count):
        if cursor + ENTRY_SIZE > len(table):
            raise ValueError("truncated asset entry")
        path_len, flags, file_offset, size, checksum = struct.unpack_from(ENTRY_FORMAT, table, cursor)
        record_size = align4(ENTRY_SIZE + path_len)
        if flags != 0 or cursor + record_size > len(table):
            raise ValueError("invalid asset entry")
        try:
            name = table[cursor + ENTRY_SIZE : cursor + ENTRY_SIZE + path_len].decode("ascii")
        except UnicodeDecodeError as exc:
            raise ValueError("invalid asset path encoding") from exc
        if canonical_path(name) != name or name in seen:
            raise ValueError("invalid or duplicate canonical asset path")
        if file_offset < previous_end or file_offset % 4 or file_offset + size > data_end:
            raise ValueError("invalid asset data range")
        data = raw[file_offset : file_offset + size]
        if len(data) != size:
            raise ValueError("truncated asset data")
        if zlib.crc32(data) & 0xFFFFFFFF != checksum:
            raise ValueError(f"asset checksum mismatch: {name}")
        entries.append(PackEntry(name, file_offset, size, checksum, data))
        seen.add(name)
        previous_end = align4(file_offset + size)
        cursor += record_size
    if cursor != len(table):
        raise ValueError("asset table contains trailing data")
    return PackImage(tuple(entries), data_offset, data_end)


def main() -> int:
    parser = argparse.ArgumentParser(description="Build a self-contained AB3D2 IE68 image")
    parser.add_argument("program", type=Path)
    parser.add_argument("asset_root", type=Path, nargs="?")
    parser.add_argument("prefix", nargs="?")
    parser.add_argument("output", type=Path, nargs="?")
    parser.add_argument("--inspect", action="store_true")
    args = parser.parse_args()
    if args.inspect:
        if any(value is not None for value in (args.asset_root, args.prefix, args.output)):
            parser.error("inspect mode accepts only the packed image argument")
        image = inspect_pack(args.program)
        print(f"{len(image.entries)} assets, {image.data_end_file_offset} bytes")
        return 0
    if args.asset_root is None or args.prefix is None or args.output is None:
        parser.error("build mode requires asset_root, prefix and output")
    image = build_pack(args.program, args.asset_root, args.prefix, args.output)
    print(f"Packed {len(image.entries)} assets into {args.output} ({args.output.stat().st_size} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
