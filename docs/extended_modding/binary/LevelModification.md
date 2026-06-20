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

| Offset In Chunk | Content | Type | Notes |
| :---- | :---- | :---- | :---- |
| 0 | **Ident** | `char[4]` | "PVSD" |
| 4 | **Length** | `uint32` | Size of complete chunk |
| - | Zone List [0] | struct { | |
| 8 | - Zone ID | `int16` | ID of Zone the deletion list applies to |
| 10 | - Delete ID | `int16[N]` | List of _N_ PVS Zone IDs to remove |
| 10 \+ _N_ \* 2 | - End Marker | `int16` | 0xFFFF Terminates deletion list |
| - | | } | |
| ... | ... | ... | Structure repeated per Zone List entry |
| _x_ | Zone List End Marker | `int16` | 0xFFFF Terminates zone list |
| _x_ \+ 2 | Pad | `uint8[2]` | Only included if the varying length data is not a multiple of 4 |

**Notes:**

- The data stream are processed as an array of int16.
- When the delete end marker is reached, the next word is assumed to be the next Zone to process.
- A Zone ID of 0xFFFF terminates the set of records.
- The data in the list are processed before the load-time Per Edge PVS processing are performed.

### Zone Backdrop Deletions

The Zone Backdrop Deletions Chunk contains the binary encoded data from the source [ZoneErrata > BackdropDeletions](../source/LevelModification.md#zoneerrata) node.

| Offset In Chunk | Content | Type | Notes |
| :---- | :---- | :---- | :---- |
| 0 | **Ident** | `char[4]` | "BCKD" |
| 4 | **Length** | `uint32` | Size of complete chunk |
| 8 | Zone IDs | `int16[...]`| |
| _x_ | List End Marker | `int16`| 0xFFFF Terminates list |
| _x_ \+ 2 | Pad | `uint8[2]` | Only included if the varying length data is not a multiple of 4 |

### Zone Messages

The Zone Messages Chunk contains the binary encoded data from the source [ZoneMessages](../source/LevelModification.md#zonemessages) node. Each entry is a fixed size.

| Offset In Chunk | Content | Type | Notes |
| :---- | :---- | :---- | :---- |
| 0 | **Ident** | `char[4]` | "ZMSG" |
| 4 | **Length** | `uint32` | Size of complete chunk. (Length - 8) / 16 gives record count |
| - | Zone Message [0] | struct { | |
| 8 | - Zone ID | `int16` | ID of the Zone that triggers the message |
| 10 | - Attributes | `uint16` | Formatting and message length |
| 12 | - Message Offset | `uint32` | Offset into String Chunk |
| - | | } | |
| ... | ... | ... | Structure repeated per Zone Message entry |

**Notes:**

- The Attributes field combines the display attributes in the upper two bits and text length in the remainder.
- Storing the length explicitly allows the renderer to make optimisations for shorter texts that won't span multiple lines.
- The maximum allowed text length is 240 characters.

Attribute bits are mapped as follows:

| **Name** | **Value** |
| :---- | :---- |
| Narrative | 0x0000 |
| Default | 0x4000 |
| Options | 0x8000 |
| Other | 0xC000 |

### Object Messages
The Zone Messages Chunk contains the binary encoded data from the source [ObjectMessages](../source/LevelModification.md#objectmessages) node. The data format is identical to the Zone Messages except for the Ident value, which is `OMSG`.

| Offset In Chunk | Content | Type | Notes |
| :---- | :---- | :---- | :---- |
| 0 | **Ident** | `char[4]` | "OMSG" |
| 4 | **Length** | `uint32` | Size of complete chunk. (Length - 8) / 16 gives record count |
| - | Object Message [0] | struct { | |
| 8 | - Object ID | `int16` | ID of the Object that triggers the message |
| 10 | - Attributes | `uint16` | Formatting and message length |
| 12 | - Message Offset | `uint32` | Offset into String Chunk |
| - | | } | |
| ... | ... | ... | Structure repeated per Object Message entry |

