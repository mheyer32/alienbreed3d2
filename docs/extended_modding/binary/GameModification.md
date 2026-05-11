[Back To Overview](../README.md)

# Game Modification File

Please read the [Data Format](./DataFormat.md) document for further information on the file structure.

The Game Modification File is the binary encoded represntation of the data defined in the [RSON Source](../source/GameModification.md).

## Chunks

The following Chunks are included:

- [Index](./DataFormat.md#index-chunk)
- Inventory Limits
- Special Ammo Bonuses
- Weapon Adjustment
- Achievements
- Rewards
- [String](./DataFormat.md#string-chunk)

Only the Index, Inventory Limits and String chunks are mandatory.

### Inventory Limits Chunk

The Inventory Limits Chunk contains the binary encoded limits defined in the source [Default Inventory Limits](../source/GameModification.md#defaultinventorylimits) node. A Limit is defined for each of the 20 Ammunition types, along with Health and Fuel. Where these were not specified in the source, the respective internal default is used.

| Offset In Chunk | Content | Type | Notes |
| :---- | :---- | :---- | :---- |
| 0 | **Ident** | `char[4]` | "INVL" |
| 4 | **Length** | `uint32` | Size of complete chunk. Fixed size: 52 |
| 8 | Max Health | `int16` | |
| 10 | Max Fuel | `int16` | |
| 12 | Max Ammo | `int16[20]` | One for each defined Ammo class |

Notes:

- The default maximum value for Ammunition is 32767
- The default maximum value for Health is 32767
- The default maximum value for Fuel is 255
- The values in this chunk represent the initial limits for a new game. Player progression files are saved that include the impact of any bonuses added to these limits due to locating special bonuses or completing achievements.

### Special Ammo Bonuses

The Special Ammo Bonuses Chunk contains the binary encoded values defined in the [Special Ammo Bonuses](../source/GameModification.md#specialammobonuses) node. If the node is omitted, no Chunk is generated.

| Offset In Chunk | Content | Type | Notes |
| :---- | :---- | :---- | :---- |
| 0 | **Ident** | `char[4]` | "SPAB" |
| 4 | **Length** | `uint32` | Size of complete chunk. (Length - 8) / 8 gives record count |
| - | Record [0] | struct { | Structure of ... |
| 8 | - Reserved | `uint16` | Reserved for expansion |
| 10 | - Ammo Type ID | `uint16` | Defined Ammo Class |
| 12 | - Reward Offset | `uint32` | Offset into Reward Chunk |
| - | | } |
| ... | ... | ... | Structure repeated per defined Ammo Bonus |

Notes:

- Since each special bonus defines a corresponding Reward, the Reward Chunk must also be present.
- The Ammo Type values can only be those defined in the SpecialAmmoTypes list.
- After loading, the Special Ammo Bonuses Chunk is parsed to update teh Reward Offset to the corresponding in-memory location of the Reward data.

### Weapon Adjustment

The Weapon Adjusment Chunk contains the binary encoded data defined in the  [Weapon Adjustment](../source/GameModification.md#weaponadjustment) node. If the node is ommited, no Chunk is generated.

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

Notes:

- The Flags field contains the boolean options defined in the source node:
    - NoRun `0x0001`
    - NoCrouch `0x0002`
    - NoFly `0x0004`
    - NoFireSubmerged `0x0008`
    - All other bits are reserved.

The data in the Weapon Adjustment node serves as the game default values for the weapons. Future updates may save the active values into the player progression file in order to allow for modification in-game, e.g. locating some special item or accomplishing some objective or achievement.

### Achievements

The Achievenents Chunk contains the binary encoded achievement data defined in the [Achievements](../source/GameModification.md#achievements) node.

| Offset In Chunk | Content | Type | Notes |
| :---- | :---- | :---- | :---- |
| 0 | **Ident** | `char[4]` | "ACHV" |
| 4 | **Length** | `uint32` | Size of complete chunk. (Length - 8) / 16 gives record count |
| - | Record [0] | struct { | |
| 8 | - Description Offset | `uint32` | Offset into String Chunk |
| 12 | - Reward Offset | `uint32` | Offset into Reward Chunk, 0 if no Reward |
| 16 | - Rule Type ID | `uint16` | |
| 18 | - Reserved | `uint16` | Set to Zero |
| 20 | - Rule Parameters | `uint8[12]` | Actual interpretation depends on Rule Type ID |
| - | | } |
| ... | ... | ... | Structure repeated per defined Achievement |

Notes:

- Each Achievement record is 32 bytes and the order is important:
    - 12 bytes are reserved for the rule parameters to permit more complex rules in future.
    - Actual interpretation varies according to the rule type.
- The Reserved field is reserved for runtime tagging of the loaded data and must be set to zero in the file.
- The Player Progression file tracks which Achievements have been completed.
- Reordering and regrouping of the Achievements in the source data is permitted provided that their individual Order fields are updated to ensure that the original order is preserved on sorting.
- After loading, the Achievement Chunk is parsed to update the Description and Reward Offsets to their respective locations in memory.

The following Rule Types are enumerated:

| ID | Rule Type |
| :--- | :--- |
| 0x0000 | KillCount |
| 0x0001 | GroupKillCount |
| 0x0002 | ZoneFound |
| 0x0003 | TimeImproved |
| 0x0004 | PlayerDied |
| 0x0005 | Collected |


#### Achievement Rule: KillCount

The `KillCount` rule is checked whenever an alien is killed by the player. This rule defines the following parameters:

| Offset In Record | Content | Type | Notes |
| :---- | :---- | :---- | :---- |
| 8 | Rule Type ID | `uint16` | 0x0000 |
| 10 | Reserved | `uint16` | 0x0000 |
| 12 | Count | `uint32` | |
| 16 | Alien ID | `uint16` | |


#### Achievement Rule: GroupKillCount

| Offset In Record | Content | Type | Notes |
| :---- | :---- | :---- | :---- |
| 8 | Rule Type ID | `uint16` | 0x0001 |
| 10 | Reserved | `uint16` | 0x0000 |
| 12 | Count | `uint32` | |
| 16 | Alien Mask | `uint32` | Bitmask of each Alien Type ID the rule applies to |


#### Achievement Rule: ZoneFound

| Offset In Record | Content | Type | Notes |
| :---- | :---- | :---- | :---- |
| 8 | Rule Type ID | `uint16` | 0x0002 |
| 10 | Reserved | `uint16` | 0x0000 |
| 12 | Level Number | `uint16` | |
| 16 | Zone ID | `uint16` | |


#### Achievement Rule: TimeImproved

| Offset In Record | Content | Type | Notes |
| :---- | :---- | :---- | :---- |
| 8 | Rule Type ID | `uint16` | 0x0000 |
| 10 | Reserved | `uint16` | 0x0003 |
| 12 | Count | `uint32` | |
| 16 | Overall | `uint16` | |
| 18 | Level Mask | `uint16[1]` | Room for future expansion |

Note that the current game is limited to 16 levels and as such only requires uint16 mask. Since this may increase in future, the mask is placed last to allow for growth.


#### Achievement Rule: PlayerDied

| Offset In Record | Content | Type | Notes |
| :---- | :---- | :---- | :---- |
| 8 | Rule Type ID | `uint16` | 0x0004 |
| 10 | Reserved | `uint16` | 0x0000 |
| 12 | Count | `uint32` | |
| 16 | Level Mask | `uint16[1]` | Room for future expansion |


#### Achievement Rule: Collected

| Offset In Record | Content | Type | Notes |
| :---- | :---- | :---- | :---- |
| 8 | Rule Type ID | `uint16` | 0x0005 |
| 10 | Reserved | `uint16` | 0x0000 |
| 12 | Count | `uint32` | |
| 16 | Consumable ID | `uint16` | Index position within InventoryConsumables structure |

### Rewards

The Rewards Chunk contains the binary encoded representation of every defined Reward node encountered in the definition of Special Ammo Bonuses and Achievements. Individual Reward definitions are varying length but always aligned to a 32-bit boundary using padding if necessary.

| Offset In Chunk | Content | Type | Notes |
| :---- | :---- | :---- | :---- |
| 0 | **Ident** | `char[4]` | "RWRD" |
| 4 | **Length** | `uint32` | Size of complete chunk |
| - | Record [0] | struct { | |
| 8 | - Description Offset | `uint32` | Offset into String Chunk |
| 12 | - Carry Offset | `uint16` | Offset from start of this Reward definition, 0 if no Carry Limit update |
| 14 | - Immediate Offset | `uint16` | Offset from start of this Reward definition, 0 if no Immediate update |
| 16 | - Carry Data | `uint16[...]` | Ommitted if no Carry Limit update |
| x | - Carry Termination | `uint16` | 0xFFFF, Ommitted if no Carry Limit update |
| x \+ 2 | Immediate Data | `uint16[...]` | Ommitted if no Immediate update |
| y | Definition Termination | `uint16` | 0xFFFF |
| y \+ 2 | Pad (Optional) | `char[2]` | Only when the the definition size is not a multiple of 4 |
| - | | } | |
| ... | ... | ... | Structure repeated per defined Reward |

The Carry and Immediate Data are varying length arrays of `(u)int16` which is why a termination word is required:

| Offset In Array | Content | Type | Notes |
| :---- | :---- | :---- | :---- |
| 0 | Health Add | `int16` | |
| 2 | Fuel Add | `int16` | |
| 4 | Ammo ID | `uint16[...]` | Per Ammunition class included |
| n | Ammo ID Add | `int16[...]` | Per Ammunition class included |

Notes:

- Add values are signed. This allows for the definition of Rewards that are penalties for the player.
- The values for Health and Fuel are always present, defaulting to zero if no modification is applied.
- The Carry Offset and Immediate Offset fields allow both the presence of each option to be checked as well as jumping directly to the respective data when the offset is non zero.
