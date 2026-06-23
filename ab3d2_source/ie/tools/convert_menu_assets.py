#!/usr/bin/env python3
import argparse
import struct
from pathlib import Path


def read_exact(path, size):
    data = path.read_bytes()
    if len(data) != size:
        raise SystemExit(f"{path}: got {len(data)} bytes, expected {size}")
    return data


def planar_to_chunky(data, width, height, planes):
    row_bytes = width // 8
    plane_size = row_bytes * height
    out = bytearray(width * height)
    for y in range(height):
        row = y * row_bytes
        dst = y * width
        for xb in range(row_bytes):
            src = row + xb
            plane_bytes = [data[p * plane_size + src] for p in range(planes)]
            for bit in range(8):
                mask = 0x80 >> bit
                value = 0
                for p, b in enumerate(plane_bytes):
                    if b & mask:
                        value |= 1 << p
                out[dst + xb * 8 + bit] = value
    return out


def read_palette(path):
    data = path.read_bytes()
    if len(data) % 4:
        raise SystemExit(f"{path}: palette size is not a multiple of 4")
    return [struct.unpack(">I", data[i:i + 4])[0] & 0x00FFFFFF for i in range(0, len(data), 4)]


def build_menu_palette(back, fire, font):
    palette = []
    for c in range(256):
        if c & 0xE0:
            palette.append(font[c >> 5])
        elif c & 0x1C:
            c1 = fire[(c & 0x1C) >> 2]
            c2 = fire[c & 3]
            r = min(255, (c1 >> 16) + (c2 >> 16))
            g = min(255, (((c1 >> 8) & 0xFF) * 3) // 4 + ((c2 >> 8) & 0xFF))
            b = min(255, (c1 & 0xFF) + (c2 & 0xFF))
            palette.append((r << 16) | (g << 8) | b)
        else:
            palette.append(back[c & 3])
    return palette


def write_palette(path, palette):
    with path.open("wb") as f:
        for value in palette:
            f.write(struct.pack(">I", value & 0x00FFFFFF))


def main():
    parser = argparse.ArgumentParser(description="Convert AB3D2 menu planar assets to IE CLUT8 assets")
    parser.add_argument("--source", type=Path, default=Path("menu"))
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()

    src = args.source
    out = args.out
    out.mkdir(parents=True, exist_ok=True)

    back_raw = read_exact(src / "back2.raw", 2 * 40 * 256)
    credits_raw = read_exact(src / "credits_only.raw", 3 * 40 * 192)
    font_raw = read_exact(src / "font16x16.raw2", 3 * 40 * 176)

    background = planar_to_chunky(back_raw, 320, 256, 2)[:320 * 240]
    credits = planar_to_chunky(credits_raw, 320, 192, 3)
    font = planar_to_chunky(font_raw, 320, 176, 3)

    (out / "menu_background_320x240.bin").write_bytes(background)
    (out / "menu_credits_320x192.bin").write_bytes(credits)
    (out / "menu_font_320x176.bin").write_bytes(font)

    back_pal = read_palette(src / "back.pal")
    fire_pal = read_palette(src / "firepal.pal2")
    font_pal = read_palette(src / "font16x16.pal2")
    if len(back_pal) != 4 or len(fire_pal) != 8 or len(font_pal) != 8:
        raise SystemExit("unexpected menu palette entry count")
    write_palette(out / "menu_palette_rgb32.bin", build_menu_palette(back_pal, fire_pal, font_pal))

    (out / "menu_assets.stamp").write_text("ok\n", encoding="ascii")


if __name__ == "__main__":
    main()
