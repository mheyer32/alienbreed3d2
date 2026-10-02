# IE Source Patch Series

The AB3D2 source files at the repository root remain an unmodified upstream
checkout. This directory holds the IE port delta as an ordered patch series.

`series` is the authoritative order. `expected.sha256` records the reviewed
contents of every patched file after the series is applied. The build creates a
temporary overlay in `_build/ie-source/`, copies only files changed by a patch,
and symbolically links every other source file to the upstream tree.

## Verification

Run these commands from `ab3d2_source/`:

```sh
make -f ie/Makefile ie-patches-check
make -f ie/Makefile ie-source-overlay-test
```

The first command confirms that each patch applies without changing a source
file. The second creates an isolated overlay and checks all recorded hashes.

## Updating the series

Make a reviewed temporary copy of the upstream sources, make the port changes
there, then use `ie/tools/generate_source_patches.py` to regenerate the patch
files and hashes. Review the generated patch text before accepting it. Do not
copy patched upstream source files into `ie/`.
