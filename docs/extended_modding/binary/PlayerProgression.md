[Back To Overview](../README.md)

# Player Progression File

Please read the [Data Format](./DataFormat.md) document for further information on the file structure.

The Player Progression File stores key statistics pertaining to the progress that a player has made overall, as distinct from regular game saves that include only the level and inventory.

Unlike other files described here, the Player Progression File is a binary asset created by the game on exit and has no corresponding source format.

## Chunks

The following Chunks are included:

- [Index](./DataFormat.md#index-chunk)
- Inventory Limits
- Weapon Adjustments
- Counters
- Unlocked
- [String](./DataFormat.md#string-chunk)

### Header

The header ident for this file is `GPRG`.

### Inventory Limits Chunk

The Inventory Limits Chunk has the same format as the [Default Inventory Limits Chunk](./GameModification.md#defaultinventorylimits) and contains the _active_ set of limits for the Player, taking into account the impact of any achievement rewards so far.

| Offset In Chunk | Content | Type | Notes |
| :---- | :---- | :---- |  :---- |
| 0 | **Ident** | `char[4]` | "INVL" |
| 4 | **Length** | `uint32` | Size of complete chunk. Fixed length: 52 |
| 8 | Max Health | `int16` | |
| 10 | Max Fuel | `int16` | |
| 12 | Max Ammo | `int16[20]` | One for each defined Ammo type |

### Weapon Adjustment

The Weapon Adjusment Chunk has the same format as the [Default Weapon Adjustment](../GameModification.md#weaponadjustment) and contains the _active_ set of modifications for the Player, taking into account the impact of any specific alterations so far.

| Offset In Chunk | Content | Type | Notes |
| :---- | :---- | :---- | :---- |
| 0 | **Ident** | `char[4]` | "WADJ" |
| 4 | **Length** | `uint32` | Size of complete chunk. (Length - 8) / 16 gives record count |
| - | Record [0] | struct { | |
| 8 | - Slot ID | `uint16` | Which weapon slot the adjustment is for |
| 10 | - XOffset | `int16` | |
| 12 | - YOffset | `int16` | |
| 14 | - Recoil | `int16` | |
| 16 | - Spray | `int16` | |
| 18 | - Burst Limit | `uint16` | Zero implies no limit |
| 20 | - Cooldown | `uint16` | Zero implies no cooldown |
| 22 | - Flags | `uint16` | Flags |
| - | | } |
| ... | ... | ... | Structure repeated per defined Weapon Adjustment |

### Counters Chunk

The Counters Chunk contains sets of counters that are updated by the game and used in the evaluation of Achievements. This chunk includes the count of the number of defined levels, ammunition classes, alien classes etc. This allows for the future expansion of these values while allowing the structure to remain compatible on loading into a version that has increased these limits. For the purposes of this documentation, these are considered constant.

| Offset In Chunk | Content | Type | Notes |
| :---- | :---- | :--- | :---- |
| 0 | **Ident** | `char[4]` | "CTRS" |
| 4 | **Length** | `uint32` | Size of complete chunk. Fixed Length: 336 |
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

### Unlocked Chunk

The Unlocked Chunk contains a set of time/id pairs for the Achievements that have been awarded to the player.

| Offset In Chunk | Content | Type | Notes |
| :---- | :---- | :--- | :---- |
| 0 | **Ident** | `char[4]` | `UNLK` |
| 4 | **Length** | `uint32` | Size of complete chunk. (Length - 8) / 4 gives record count |
| - | Record [0] | struct {| |
| 8 | - Date Awarded | `uint16` | Custom Date Format |
| 10 | - Achievement ID | `uint16` | ID (index in the Achievements data) |
| - | | } |
| ... | ... | ... | Structure repeated per completed Achievement |


The Date Awarded is a compact 11:5 _MonthsSinceEpoch_:_DayOfMonth_ format:

- 11-bit zero-indexed month count, since the AmigaDOS epoch of 1978-01-01 00:00:00
    - This provides approximately 170 years of range since the epoch.

- 5-bit day of month, 1-31
- Date = (12 * (**_Year_** - 1978) + **_Month_** - 1) << 5 | **_Day_**


**Date Conversion Example**

A date of **2026-04-24** would be encoded as follows:

- Calculate Months Fo:
    - 12 * (**_2026_** - 1978) + **_4_** - 1 = 579
    - 579 << 5 => 18528
- Days:
    - 18528 | **_24_** = 18552

To decode, the reverse steps are taken:

- Day:
    - 18552 & 31 = **_24_**
- Month:
    - ((18552 >> 5) % 12) + 1 = **_4_**
- Year:
    - ((18522 >> 5) / 12) + 1978 = **_2026_**


The Date and Achievement ID fields are packaged together as a fully date-sortable 32-bit integer.
