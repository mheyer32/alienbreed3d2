[Back To Overview](../README.md)

# Player Progression File

Please read the [Data Format](./DataFormat.md) document for further information on the file structure.

The Game Modification File is the binary encoded represntation of the data defined in the [RSON Source](../source/GameModification.md).

Unlike other files described here, the Player Progression File is a binary asset created by the game on exit and has no corresponding source format. The file contains key statistics about the player's current progess in the game. Note that is separate to the game save slots.

## Chunks

The following Chunks are included:

- [Index](./DataFormat.md#index-chunk)
- Inventory Limits
- Counters
- Achievements
- [String](./DataFormat.md#string-chunk)

### Inventory Limits Chunk

The Inventory Limits Chunk has the same format as the [Default Inventory Limits Chunk](./GameModification.md#defaultinventorylimits) and contains the _active_ set of limits for the Player, taking into account the impact of any achievement rewards so far.

| Offset In Chunk | Content | Type | Notes |
| :---- | :---- | :---- |  :---- |
| 0 | **Ident** | `char[4]` | `INVL` |
| 4 | **Length** | `uint32` |
| 8 | Max Health | `int16` |
| 10 | Max Fuel | `int16` |
| 12 | Max Ammo [0] | `int16` |
| ... | ... | ... | ... |
| 48 | Max Ammo [19] | `int16` |

### Counters Chunk

The Counters Chunk contains sets of counters that are updated by the game and used in the evaluation of Achievements. This chunk includes the count of the number of defined levels, ammunition classes, alien classes etc. This allows for the future expansion of these values while allowing the structure to remain compatible on loading into a version that has increased these limits. For the purposes of this documentation, these are considered constant.

| Offset In Chunk | Content | Type | Notes |
| :---- | :---- | :--- | :---- |
| 0 | **Ident** | `char[4]` | `CTRS` |
| 4 | **Length** | `uint32` | |
| 8 | Level Count | `uint16` | Contains the total number of defined levels (Default 16) |
| 10 | Ammo Count | `uint16` | Contains the total number defined Ammo classes (Default 20) |
| 12 | Alien Count | `uint16` | Contains the total number of Alien classes (Default 20) |
| 14 | Reserved | `uint16` | 0x0000 |
| 16 | Level Best Time [0] | `uint32` | Best completion time for the level, in centiseconds |
| ... | ... | ... | ... |
| 76 | Level Best Time [15] | `uint32` | |
| 80 | Level Play Count [0] | `uint16` | Number of times the level has been attempted |
| ... | ... | ... | ... |
| 110| Level Play Count [15] | `uint16` | |
| 112 | Level Won Count [0] | `uint16` | Number of times the level has been beaten |
| ... | ... | ... | ... |
| 142 | Level Won Count [15] | `uint16` | |
| 144 | Level Fail Count [0] | `uint16` | Number of times the level has been lost (player died) |
| ... | ... | ... | ... |
| 174 | Level Fail Count [15] | `uint16` | |
| 176 | Level Improved Count [0] | `uint16` | Number of times the level best time has been improved |
| ... | ... | ... | ... |
| 206 | Level Time Improved Count [15] | `uint16` | |
| 208 | Alien Kill Count [0] | `uint16` | Number of kills of this alien class |
| ... | ... | ... | ... |
| 246 | Alien Kill Count [19] | `uint16` | |
| 248 | Health Collected | `uint32` | Total count of health collected |
| 252 | Fuel Collected | `uint32 `| Total count of fuel collected |
| 256 | Ammo Collected [0] | `uint32` | Total count of this ammo class collected |
| ... | ... | ... | ... |
| 332 | Ammo Collected [19] | `uint32` | |


### Achievements Chunk

The Achievements Chunk contains a set of time/id pairs for the Achievements that have been awarded to the player.

| Offset In Chunk | Content | Type | Notes |
| :---- | :---- | :--- | :---- |
| 0 | **Ident** | `char[4]` | `CTRS` |
| 4 | **Length** | `uint32` | |
| 8 | Achievement [0] Date | `uint16` | Date awarded |
| 10 | Achievement [0] ID | `uint16` | ID (index in the Achievements data) |
| ... | ... | ... | ... |

The Date Awarded is a compact 11:5 format:

- 11-bit month count, since an epoch of 2022-01
- 5-bit day of month, 1-31

For example, a Date Awarded of 2026-04-22 would be encoded as 1654:

- Convert Years to months: 2026 - 2022 = 4 years => 48 months to Jan 2026
- Count to April: 48 + 3 => 51 months
- Shift into upper 11 bits: 51 << 5 => 1632
- Combine with day of month: 1632 | 22 => 1654
