[Back To Overview](../README.md)

# Level Modification File

Please read the [Data Format](./DataFormat.md) document for further information on the file structure.

The Game Modification File is the binary encoded represntation of the data defined in the [RSON Source](../source/GameModification.md).

## Chunks

The following Chunks are included:

- [Index](./DataFormat.md#index-chunk)
- Zone PVS Deletions
- Zone Backdrop Deletions
- Zone Messages
- Object Messages
- [String](./DataFormat.md#string-chunk)

Only the Index, Inventory Limits and String chunks are mandatory.

### Zone PVS Deletions

The Zone PVS Deletions Chunk contains the binary encoded data from the source [ZoneErrata > PVSDeletions](../source/LevelModification.md#zoneerrata) node. These are encoded as varying length `int16` strings that are terminated by 0xFFFF.

| Offset In Chunk | Content |
| :---- | :---- |
| 0 | **Ident** `"PVSD"` |
| 4 | **Length** `uint32` |
| 8 | **ZoneList \[0\].Zone ID** `int16` |
| 10 | **ZoneList \[0\].Delete ID \[0\]** `int16` |
| 12 | **ZoneList \[0\].Delete ID \[1\]** `int16` |
| x  | **ZoneList \[0\].End Marker** `int16` 0xFFFF |
| ... | ... |
| x \+ 2 | **ZoneList \[1\].Zone ID** `int16` |
| x \+ 4 | **ZoneList \[1\].Delete ID \[0\]** `int16` |
| ... | ... |
| y | **ZoneList \[1\].End Marker** `int16` 0xFFFF |
| ... | ... |
| z | **ZoneList End Marker** `int16` 0xFFFF |

**Notes:**

- The data stream are processed as an array of int16.
- When the delete end marker is reached, the next word is assumed to be the next Zone to process.
- A Zone ID of 0xFFFF terminates the set of records.
- The data in the list are processed before the load-time Per Edge PVS processing are performed.

### Zone Backdrop Deletions

The Zone Backdrop Deletions Chunk contains the binary encoded data from the source [ZoneErrata > BackdropDeletions](../source/LevelModification.md#zoneerrata) node.

| Offset In Chunk | Content |
| :---- | :---- |
| 0 | **Ident** `"BCKD"` |
| 4 | **Length** `uint32` |
| 8 | **Zone ID \[0\]** `int16` |
| 10 | **Zone ID \[1\]** `int16` |
| ... | ... |
| x | **List End Marker** `int16` 0xFFFF |

### Zone Messages

The Zone Messages Chunk contains the binary encoded data from the source [ZoneMessages](../source/LevelModification.md#zonemessages) node. Each entry is a fixed size.

| Offset In Chunk | Content |
| :---- | :---- |
| 0 | **Ident** `"ZMSG"` |
| 4 | **Length** `uint32` |
| 8 | **Zone \[0\].Zone ID** `int16` |
| 10 | **Zone \[0\].Attributes** `uint16` |
| 12 | **Zone \[0\].Message Offset** `uint32` Offset into String Chunk |

**Notes:**

- The Attributes field combines the display attributes in the upper two bits and text length in the remainder.
- Storing the length explicitly allows the renderer to make optimisations for shorter texts that won't span multiple lines.
- The maximum allowed text length is 240 characters.

Attributes are mapped as follows:

| Name | Value |
| :---- | :---- |
| Narrative | 0x0000 |
| Default | 0x4000 |
| Options | 0x8000 |
| Other | 0xC000 |

### Object Messages
The Zone Messages Chunk contains the binary encoded data from the source [ObjectMessages](../source/LevelModification.md#objectmessages) node. The data format is identical to the Zone Messages except for the Ident value, which is `OMSG`.

