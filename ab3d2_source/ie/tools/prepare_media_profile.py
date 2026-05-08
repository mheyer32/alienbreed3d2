#!/usr/bin/env python3
import argparse
import os
import shutil
from pathlib import Path

from unpack_sb_assets import unpack_sb_file


def rel_link_target(src: Path, dst: Path) -> str:
    return os.path.relpath(src.resolve(), dst.parent.resolve())


def reset_dir(path: Path) -> None:
    if path.is_symlink() or path.is_file():
        path.unlink()
    elif path.exists():
        shutil.rmtree(path)
    path.mkdir(parents=True)


def link_file(src: Path, dst: Path) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.exists() or dst.is_symlink():
        dst.unlink()
    dst.symlink_to(rel_link_target(src, dst))


def mirror_file(src: Path, dst: Path) -> None:
    unpacked = unpack_sb_file(src)
    if unpacked is None:
        link_file(src, dst)
        return
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.exists() or dst.is_symlink():
        dst.unlink()
    dst.write_bytes(unpacked)


def overlay_tree(src_root: Path, dst_root: Path) -> None:
    if not src_root.exists():
        return
    for src in sorted(src_root.rglob("*")):
        if not src.is_file():
            continue
        rel = Path(*(part.lower() for part in src.relative_to(src_root).parts))
        mirror_file(src, dst_root / rel)


def prepare_redux(repo_root: Path, profile: str, out: Path) -> None:
    game = repo_root / "karlos-tkg-main" / "Game"
    if not game.is_dir():
        raise SystemExit(f"missing Redux game tree: {game}")

    spec = {
        "redux-high": "HighSpec",
        "redux-low": "LowSpec",
    }[profile]

    reset_dir(out)
    overlay_tree(game / "Includes", out / "includes")
    overlay_tree(game / spec / "Includes", out / "includes")
    overlay_tree(game / "Levels", out / "levels_editor_uncompressed")
    overlay_tree(game / spec / "Levels", out / "levels_editor_uncompressed")
    overlay_tree(game / "GFX", out / "gfx")
    overlay_tree(game / "SoundFX", out / "soundfx")
    overlay_tree(game / "Models", out / "models")
    overlay_tree(game / "VectObj", out / "vectobj")

    main_palette = game / "pal"
    if main_palette.is_file():
        link_file(main_palette, out / "includes" / "256pal")
        link_file(main_palette, out / "pal")

    for name in ("boot.dat",):
        src = game / name
        if src.is_file():
            link_file(src, out / name.lower())


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--profile", choices=("redux-high", "redux-low"), required=True)
    parser.add_argument("--repo-root", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()

    prepare_redux(args.repo_root, args.profile, args.out)


if __name__ == "__main__":
    main()
