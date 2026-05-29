[Back To Overview](../README.md)

# TKGD Binary Format

This document describes the binary format used to define the behavioural modification asset files used by the TKG engine.

## Overview

The format is inspired by IFF and comprises a chunk based layout. A file contains a header section, followed by one or more Chunks. Each Chunk has a short-form header that identifies the type of data in the Chunk and the total length of the Chunk in bytes, including the short-form header.

- All chunks are aligned to 32-bit offsets.

The Chunk based approach allows for the easy inclusion of new features by encoding the required data into a new Chunk that oder versions of the engine are safe to ignore.

## Basic File Layout

The general structure of the file is shown in the table below. The first 20 bytes encode the [Document Header](../source/SourceFormat.md#document-header)

This is immediately followed by one or more Chunks.

| Offset | Content | Type | Notes |
| :---- | :---- | :---- | :---- |
| 0 | **Ident** | `char[4]` | "TKGD" |
| 4 | **Subformat** | `char[4]` | Depends on file |
| 8 | Requires | `uint16[2]` | Major.Minor version of game required |
| 12 | Version | `uint16[2]` | Major.Minor version of this asset |
| 16 | Description Offset | `uint32` | Offset in String Heap Chunk |
| - | Chunk [0] | struct { | |
| 20 | - Ident | `char[4]` | |
| 24 | - Length | `uint32` | Always a multiple of 4 |
| 28 | - Data | `uint8[...]` | Varying data, tail padded to 4-byte boundary |
| - | | } | |
| ... | ... | ... | Additional Chunks |
## Common Chunks

Depending on the Subformat, various Chunk types are defined that are documented in their repsective pages. The following Chunk types are universal.

### Index Chunk

The Index Chunk contains a list of all of the Chunks in the file, complete with their Ident and Offset relative to the start of the file. While not mandatory, if the Index chunk is present, the convention is that it must be the first Chunk after the header, thereby having a fixed loction to facilitate locating the resources in the file more easily.

| Offset In Chunk | Content | Type | Notes |
| :---- | :---- | :---- | :---- |
| 0 | **Ident** | `char[4]` | "INDX" |
| 4 | **Length** | `uint32` | Size of complete chunk. (Length - 8) / 8 gives record count |
| - | Record [0] | struct { | |
| 8 | - Ident | `char[4]` | |
| 12 | - Offset | `uint32` | Relative to start of file |
| - | | } | |
| ... | ... | ... | Structure repeated |

Notes:

- The Index chunk does not index itself. Rather it is assumed to immediately follow the Header.
- The Offsets are measured in bytes from the start of the file.
- Records in the Index should be in the same order the Chunks occur in the file.

### String Chunk

The String Chunk contains all of the unique strings that are encountered, which are then referenced by offset in other locations. This includes the Description string from the Header. Since this is a mandatory field, it follows that all valid files contain the String Chunk. By convention, the String Chunk should be the last chunk in the file.

The chunk data comprises of each distinct string that was parsed out of the source asset, placed sequentially with a null termination byte. No alignment is enforced on the start address of a sting. If length of all the null terminated strings combined is not a multiple of 4, additional null bytes are added at the end as padding.

| Offset In Chunk | Content | Type | Notes
| :---- | :---- | :---- | :---- |
| 0 | **Ident** | `char[4]` | "STRH" |
| 4 | **Length** | `uint32` | Size of complete chunk |
| 8 | Data | `char[...]` | Catenated sequence of null-terminated strings |

Notes:

- References to Strings in the String Chunk elsewhere in the data are represented as `uint32` offsets relative to the start of the Sting Chunk.
- Since the String Chunk contains an 8-byte short-form header, an offset of 0 implies a null reference. Only offsets of 8 or greater reference actual string content.

## Loading Behaviour

It is expected that behavioural modifcation files are small and loaded into memory at a 32-bit aligned location, in their entirety. Version and subformat checks are performed on the Header data before proceeding.

Once the Header is validated, if the Index ident is found after the Header, a minimum validation should be carried out, to ensure that:

- The expected Chunk Ident value is found at each of the corresponding offsets specified in the Index.
- The expected String Chunk Ident is located in the Index.
- The Chunk Length field value is at least 12 for every Chunk visited.
    - The Chunk short-form header is 8 bytes.
    - A minimum 1-byte of data will be padded to 4 bytes for alignment purposes.

- Each Chunk Offset in the Index is updated to be the actual in-memory address of the respective Chunk by adding the base address of the loaded file.
- The Description Offset in the Header is updated to point to the actual start address of the String in the String Chunk by adding the in-memory address.

After this point, custom Chunk-specific parsing can proceed.
