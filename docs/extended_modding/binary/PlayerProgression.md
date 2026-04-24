[Back To Overview](../README.md)

# Player Progression File

Please read the [Data Format](./DataFormat.md) document for further information on the file structure.

The Player Progression File stores key statistics pertaining to the progress that a player has made overall, as distinct from regular game saves that include only the level and inventory.

Unlike other files described here, the Player Progression File is a binary asset created by the game on exit and has no corresponding source format.

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
| 0 | **Ident** | `char[4]` | "INVL" |
| 4 | **Length** | `uint32` | |
| 8 | Max Health | `int16` | |
| 10 | Max Fuel | `int16` | |
| 12 | Max Ammo | `int16[20]` | One for each defined Ammo type |

### Counters Chunk

The Counters Chunk contains sets of counters that are updated by the game and used in the evaluation of Achievements. This chunk includes the count of the number of defined levels, ammunition classes, alien classes etc. This allows for the future expansion of these values while allowing the structure to remain compatible on loading into a version that has increased these limits. For the purposes of this documentation, these are considered constant.

| Offset In Chunk | Content | Type | Notes |
| :---- | :---- | :--- | :---- |
| 0 | **Ident** | `char[4]` | "CTRS" |
| 4 | **Length** | `uint32` | |
| 8 | Level Count | `uint16` | Contains the total number of defined levels (Default 16) |
| 10 | Ammo Count | `uint16` | Contains the total number defined Ammo classes (Default 20) |
| 12 | Alien Count | `uint16` | Contains the total number of Alien classes (Default 20) |
| 14 | Reserved | `uint16` | 0x0000 |
| 16 | Level Best Time | `uint32[16]` | Best completion time for each level, in centiseconds |
| 80 | Level Play Count | `uint16[16]` | Number of attempts for each level |
| 112 | Level Won Count | `uint16[16]` | Number of times completed for each level |
| 144 | Level Fail Count | `uint16[16]` | Number of times player died for each level |
| 176 | Level Improved Count | `uint16[16]` | Number of times the level best time has been improved for each level |
| 208 | Alien Kill Count | `uint16[20]` | Number of Alien kills for each Alien class |
| 248 | Health Collected | `uint32` | Total count of Health collected |
| 252 | Fuel Collected | `uint32` | Total count of Fuel collected |
| 256 | Ammo Collected | `uint32[20]` | Total count of ammunition collected for each Ammo class |

### Achievements Chunk

The Achievements Chunk contains a set of time/id pairs for the Achievements that have been awarded to the player.

| Offset In Chunk | Content | Type | Notes |
| :---- | :---- | :--- | :---- |
| 0 | **Ident** | `char[4]` | `ACHD` |
| 4 | **Length** | `uint32` | This will be 8 for an initially empty list |
| - | Record [0] | struct {| Structure of ... |
| 8 | - Date Awarded | `uint16` | 11:5 Format |
| 10 | - Achievement ID | `uint16` | ID (index in the Achievements data) |
| - | | } |
| ... | ... | ... | Structure repeated per completed Achievement |


The Date Awarded is a compact 11:5 format:

- 11-bit zero-indexed month count, since the AmigaDOS epoch of 1978-01-01 00:00:00
- 5-bit day of month, 1-31

For example, a Date Awarded of 2026-04-24 would be encoded as follows:

- Months:
    - Convert Year (2026) to months since epoch: 2026 - 1978 = 48, 48 * 12 = 576
    - Convert ordinal month (4) number to zero-indexed: 4 - 1 = 3
    - Add to months count: 576 + 3 = 579
    - Shift into upper 11 bits: 579 << 5 => 18528
- Days:
    - OR combine ordinal day of month: 18528 | 24 = 18522

To convert this value back to Year, Month and Day for presentation:

- Year:
    - Extract the high 11-bit month count: 18552 >> 5 = 579
    - Divide by 12 to get the Year count: 579/12 = 48, remainder 3
    - Add the Epoch Year: 48 + 1978 = 2026
- Month:
    - Take the remainder from the Year division and add 1 to convert to ordinal month: 3 + 1 = 4
- Day:
    - Extract the low 5-bit day count: 18552 & 31 = 24

The Date and Achievement ID fields are packaged together as a fully date-sortable 32-bit integer.
