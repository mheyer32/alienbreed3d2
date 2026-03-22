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

| Offset In Chunk | Content |
| :---- | :---- |
| 0 | **Ident** `"INVL"` |
| 4 | **Length** `uint32` |
| 8 | **Max Health** `int16` |
| 10 | **Max Fuel** `int16` |
| 12 | **Max Ammo \[0\]** `int16` |
| 14 | **Max Ammo \[1\]** `int16` |
| ... | ... |
| 48 | **Max Ammo \[19\]** `int16` |

Notes:

- The default maximum value for Ammunition is 32767
- The default maximum value for Health is 32767
- The default maximum value for Fuel is 255
- The values in this chunk represent the initial limits for a new game. Player progression files are saved that include the impact of any bonuses added to these limits due to locating special bonuses or completing achievements.

### Special Ammo Bonuses

The Special Ammo Bonuses Chunk contains the binary encoded values defined in the [Special Ammo Bonuses](../source/GameModification.md#specialammobonuses) node. If the node is omitted, no Chunk is generated.

| Offset In Chunk | Content |
| :---- | :---- |
| 0 | **Ident** `"SPAB"` |
| 4 | **Length** `uint32` |
| 8 | **Reserved \[0\]** `uint16` |
| 10 | **Ammo Type ID \[0\]** `uint16` |
| 12 | **Reward Offset \[0\]** `uint32` Offset into Reward Chunk |
| ... | ... |
| N \+ 0 | **Reserved \[N\]** `uint16` |
| N \+ 2 | **Ammo Type ID \[N\]** `uint16` |
| N \+ 4 | **Reward Offset \[N\]** `uint32` |
| N \+ 8 | **End Marker** `uint16` 0xFFFF |
| N \+ 10 | **Pad** `uint8[2]` |

Notes:

- Since each special bonus defines a corresponding Reward, the Reward Chunk must also be present.
- The Ammo Type values can only be those defined in the SpecialAmmoTypes list.
- After loading, the Special Ammo Bonuses Chunk is parsed to update teh Reward Offset to the corresponding in-memory location of the Reward data.

### Weapon Adjustment

The Weapon Adjusment Chunk contains the binary encoded data defined in the  [Weapon Adjustment](../source/GameModification.md#weaponadjustment) node. If the node is ommited, no Chunk is generated.

| Offset In Chunk | Content |
| :---- | :---- |
| 0 | **Ident** `"WADJ"` |
| 4 | **Length** `uint32` |
| 8 | **Slot ID \[0\]** `uint16` Which weapon slot the adjustment is for |
| 10 | **XOffset \[0\]** `int16` |
| 12 | **YOffset \[0\]** `int16` |
| 14 | **Recoil \[0\]** `int16` |
| 16 | **Spray \[0\]** `int16` |
| 18 | **Burst Limit \[0\]** `uint16`, Zero implies no limit |
| 20 | **Cooldown \[0\]** `uint16`, Zero implies no cooldown |
| 22 | **Flags \[0\]** `uint16` Flags |
| 24 | **Slot ID \[1\]** `uint16` |
| ... | ... |

Notes:

- The Flags field contains the boolean options defined in the source node:
    - NoRun `0x0001`
    - NoCrouch `0x0002`
    - NoFly `0x0004`
    - NoFireSubmerged `0x0008`
    - All other bits are reserved.

The data in the Weapon Adjustment node serves as the game default values for the weapons. Future updates may save the active values into the player progression file in order to allow for modification in-game, e.g. locating some special item or accomplishing some objective or achievement.

### Achievements

The Achievenents Chunk contanns the binary encoded achievement data defined in the [Achievements](../source/GameModification.md#achievements) node.

| Offset In Chunk | Content |
| :---- | :---- |
| 0 | **Ident** `"ACHV"` |
| 4 | **Length** `uint32` |
| 8 | **Description Offset \[0\]** `uint32` Offset into String Chunk |
| 12 | **Reward Offset \[0\]** `uint32` Offset into Reward Chunk, 0 if no Reward |
| 16 | **Rule Type ID \[0\]** `uint16` |
| 18 | **Rule Parameters \[0\]** `uint16[3]` |
| 20 | **Description Offset \[1\]** `uint32` Offset into String Chunk |
| ... | ... |

Notes:

- Each Achievement is 16 bytes and the order is important.
- The Player Progression file allocates a bitmap to track which Achievements have been completed.
- Reordering and regrouping of the Achievements in the source data is permitted provided that their individual Order fields are updated to ensure that the original order is preserved on sorting.
- After loading, the Achievement Chunk is parsed to update the Description and Reward Offsets to their respective locations in memory.

### Rewards

The Rewards Chunk contains the binary encoded representation of every defined Reward node encountered in the definition of Special Ammo Bonuses and Achievements. Individual Reward definitions are varying length but always aligned to a 32-bit boundary using padding if necessary.

| Offset In Chunk | Content |
| :---- | :---- |
| 0 | **Ident** `"RWRD"` |
| 4 | **Length** `uint32` |
| 8 | **Description Offset \[0\]** `uint32` Offset into String Chunk` |
| 12 | **Carry Offset \[0\]** `uint16` Offset from start of this Reward definition, 0 if no Carry Limit update |
| 14 | **Immediate Offset \[0\]** `uint16` Offset from start of this Reward definition, 0 if no Immediate update |
| 16 | **Carry Data \[0\]** `uint16[]` Ommitted if no Carry Limit update |
| x | **Carry Termination \[0\]** `uint16` 0xFFFF, Ommitted if no Carry Limit update |
| x \+ 2 | **Immediate Data \[0\]** `uint16[]` Ommitted if no Immediate update |
| y | **Definition Termination \[0\]** `uint16` 0xFFFF |
| y \+ 2 | **Pad \[0\]** `char[2]` Only when the the definition size is not a multiple of 4 |
| ... | ... |

The Carry and Immediate Data are varying length arrays of `(u)int16` which is why a termination word is required:

| Offset In Array | Content |
| :---- | :---- |
| 0 | **Health Add** `int16` |
| 2 | **Fuel Add** `int16` |
| 4 | **Ammo ID \[0\]** `uint16` Only present if there is a modification for this value |
| 6 | **Ammo ID Add \[0\]** `int16` Only present if there is a modification for this value |

Notes:

- Add values are signed. This allows for the definition of Rewards that are penalties for the player.
- The values for Health and Fuel are always present, defaulting to zero if no modification is applied.
- The Carry Offset and Immediate Offset fields allow both the presence of each option to be checked as well as jumping directly to the respective data when the offset is non zero.
