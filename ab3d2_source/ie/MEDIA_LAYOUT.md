# IE Media Layout

The native IE build uses one deterministic media tree. Runtime file I/O strips
source volume prefixes such as `AB3:`, but it does not probe alternate case or
parent-directory fallbacks.

For the current IE file-I/O MMIO device, run Intuition Engine with
`ab3d2_source` as the current working directory. The VM's `--media` argument is
for the media-player loader and does not currently re-root raw file I/O loads.
These paths must resolve exactly from the process working directory:

```text
media/
  includes/
    main.256pal
    title.mod  (legacy ProTracker file, not played by the current SID override)
    test.lnk
    *.wad
    *.ptr
    *.256pal
    <sound-bank files>
  levels/
    level_a/
    level_b/
    ...
ie/
  at_dooms_gate_e1m1.sid
```

To prepare that layout from an extracted local media tree, run from
`ab3d2_source`:

```sh
ie/tools/normalize_media.sh .
```

The GLF database remains `media/includes/test.lnk`. Filenames stored inside the
database are loaded relative to the current working directory after the source
volume prefix has been stripped.
