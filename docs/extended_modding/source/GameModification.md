[Back To Overview](../README.md)

# Game Modification File

Please read the [Source Format](./SourceFormat.md) document for further information on the syntax described here.

The main game modification file lays out various game-wide rules that modify game behaviour. As a primary asset, this must include the correct header and must import the [`LinkDefs`](./LinkDefsImport.md) node.

The resulting binary format for this asset is desribed [here](../binary/GameModification.md).

**Example:**

```
{
    Header: {
        Type: "Game",
        Description: "Example Game Modification",
        Version: "1.0",
        Requires: "1.13",
    },
    Import: {
        LinkDefs: "common/linkdefs.rson",
    },

    // Remaining definitions
}
```

## Common Types

The following data structures are used in multiple definitions:

### LevelList

The `LevelList` type is a string literal that is used to specify a set of Levels. The following conventions are used:

- Each distinct level is denoted by a single uppercase character A-P.
    - Level letter codes can occur in any order.
    - Level letter codes must occur only once each.

- Spaces and commas are permitted as separators for readability and are ignored.
- Asterisk is accepted as shorthand for every level.
    - If included, an asterisk must occur only once.
    - When an asterisk is used in conjuction with any letter code, the specific letters are considered as exclusions from the full set.

- Any other character classes are illegal.

**Examples:**

```
    // Below are valid definitions for the set of levels A, C and E:

    "ACE"
    "CEA"    // Order is irrelevent.
    "A C E"  // Spaces are ignored.
    "A,C,E," // Commas are ignored.
    "A CE, " // Any combination of spaces and commas are ignored.

    // Below are valid definitions for all levels:

    "ABCDEFGHIJKLMNOP"           // Including any permutation, spaces or commas.
    "*"                          // Preferred

    // Below are a valid examples of all levels except A, C and E:

    "BDFGHIJKLMNOP"              // Including any permutation, spaces or commas.
    "*ACE"                       // Including any permutation. Preferred.

    // Illegal examples:

    ""                           // Must not be empty.
    "ACEA"                       // Cannot specify a level code twice.
    "ACE1"                       // Illegal character class
    "**"                         // Asterisk may occur only once.
```

**Notes:**

- When dealing with the complete set of levels, or all levels excluding some specific subset, the asterisk notion is preferred as it ensures that any future expansion to the set of levels is accounted for.

### SupplyQuantity

The `SupplyQuantity` structure defines an amount of health, fuel and ammunition. These structures are used wherever something modifies the player inventory/limits.

**Structure:**

```
    {
        // All fields optional but at least one value is required.
        Health: <#count>,
        Fuel: <#count>,
        Ammo: {
            // Any of the LinkDefs enumerated PlayerAmmoTypes
            "<ammo type name>": <#count>,
        }
    }
```

**Notes:**

- Each field is optional, but the structure as a whole should not be empty.
- The interpretation of the values is context-specific.
    - Count values can be negative, the intention is to support incidents that might deplete some player inventory.

- The interpretation of a missing value is context-specific.

### Reward

The `Reward` structure defines a set of inventory modifications that can be applied as a bonus for completing certain objectives, achievements or collecting specific items.

**Structure:**

```
    {
        Description: "<text>",

        // Both the following are optional, but at least one must be present.
        ImmediateAdd: { SupplyQuantity },
        CarryLimitAdd: { SupplyQuantity }
    }
```

**Notes:**

- The `SupplyQuantity` values are added to the existing player totals:
    - `ImmediateAdd` is added to the current carry.
    - `CarryLimitAdd` is added to the current carry capacity.

- If both are included, `CarryLimitAdd` is processed before `ImmediateAdd`.

## Main Node Types

The following nodes define the major behavioural modificatons. Generally, each one will be compiled into a distinct chunk within the generated asset binary.

### DefaultInventoryLimits

The `DefaultInventoryLimits` node is a `SupplyQuantity` that sets the initial limits for player comsumables and ammunition when starting a new game:

**Structure:**

```
    DefaultInventoryLimits: { SupplyQuantity }
```

The initial limits defined here can be raised via rewards for completing objectives or finding special bonus items. The actual limits are saved in the player progress data when exiting the game.

**Notes:**

- Where the `SupplyQuantity` does not define a specific limit for some value, the internal default for that type is used:
    - Health: 32767
    - Fuel: 255
    - Any ammuition type: 32767

### SpecialAmmoBonuses

The optional `SpecialAmmoBonuses` node defines a set of `Reward` definitions that pertain to the collection of items that give any of the ammunition types enumerated in the `SpecialAmmoTypes` node imported from `LinkDefs`. This allows for the definition of one-off collectable objects in game, that can give the special ammo type on collection, triggering the associated `Reward` as a consequence.

**Structure:**

```
    SpecialAmmoBonuses: {
        // One per special ammo type
        "<special ammo type name>": { Reward },
    }
```

### WeaponAdjustment

The optional `WeaponAdjustment` node defines per-weapon behavioural changes for the player arsenal:

**Structure:**

```
    WeaponAdjustment: {
        "<weapon name>": {
            // All fields are optional but at least one must be specified.
            SpawnOffset: [<#x>, <#y>],
            Recoil: <#amount>,
            Spray: <#amount>,
            BurstLimit: <#duration>,
            Cooldown: <#duration>,
            NoRun: <bool>,
            NoCrouch: <bool>,
            NoFly: <bool>,
            NoFireSubmerged: <bool>
        },
    }
```

**Notes:**

If all values are zero/false, the definition is considered empty and will be discarded. The values defined within these definitions are considered _default_ values for the weapons they apply to. Future updates will record the active values for eahc weapon in the player progression file. This is intended to allow for in-game modification to these values e.g. as a consequence of locating some special item or via achievements or other objectives.

Fields:

- `SpawnOffset`
    - Adjusts the on-screen location that the visible projectile launched from the weapon appears from.
    - Has no effect for hitscanned ammunition types.
    - Signed values are allowed.

- `Recoil`
    - Sets the force with which firing the weapon will knock the player backwards.
    - Larger values should only be used for heavier weapons, e.g. Rocket Launcher.

- `Spray`
    - Sets the degree to which firing the weapon disturbs the player forwards direction.
    - Random values within +/- the spray value are added to the player yaw and pitch.
    - Should be restricted to rapid fire automatic weapons, potentially starting off small and rising with the duration of fire up to the spray limit.

- `BurstLimit`
    - Sets the number of shots a weapon can fire continuously before forcing a cooldown.
    - Should be reserved for rapid automatic and plasma weapons.

- `Cooldown`
    - Sets the length of time in game ticks before a weapon can be fired after a cooldown is triggered.
    - Switching weapons might be faster.

The following options define how a given weapon encumbers the player.

- `NoRun`
    - When true, prevents running while the weapon is equipped.
    - Should be reserved for heavy/bulky weapons, e.g. Rocked Laucher, Chain Cannon.
    - Run state is disabled when the weapon is equipped, forcing the player to walk.

- `NoCrouch`
    - When true, prevents the player from crouching while the weapon is equipped.
    - Should be reserved for heavy/bulky weapons, e.g. Rocked Laucher, Chain Cannon.
    - Crouch state is disabled when the weapon is euipped, forcing the player to stand.
    - If the player is in a zone that prevents standing, the weapon cannot be equipped.

- `NoFly`
    - When true, prevents the player flying while the weapon is equipped.
    - Should be reserved for heavy/bulky weapons, e.g. Rocked Laucher, Chain Cannon.
    - Fly state is disabled when the weapon is equipped.
    - Weapon cannot be equipped while the player is actively flying but can be equipped while falling.

- `NoFireSubmerged`
    - When true, prevents the weapon being fired while the player is submerged in liquid.

**Example:**

```
    // Values shown here are illustrative until properly defined.

    WeaponAdjustment: {
        "RocketLauncher": {
            SpawnOffset: [50, 10],   // Shift to the right and up slightly
            Recoil: 10,              // Fairly big kick

            // Weapon is too slow firing to have any spray or cooldown
            // and too chonky to use just anywhere.

            NoRun: true,             // Too big to run with.
            NoCrouch: true,          // Too big to crouch with.
            NoFly: true,             // Too big to fly with.
            NoFireSubmerged: true    // You'd be suicidal to try.
        },
        "AssaultRifle": {
            // Hitscanned projectile doesn't have visible spawn offset.
            // Small enough not to be encumbered.

            Recoil: 1,               // Small recoil
            Spray: 5,                // Modest interference with aim per shot.
            BurstLimit: 40,          // That's a full magazine anyway...
            Cooldown: 100,           // 2 seconds in game ticks.
        },
    }
```

### Achievements

The optional `Achievements` node defines an array of achievement defintions that may optionally include a `Reward` definition for completion of the achievement.

**Structure:**

```
    Achievements: [
        {
            Order: <#value>,
            Description: "<text>",
            Rule: "<enumerated rule name>",

            // Parameters are key-value pairs that depend on Rule type
            Params: {
                "<key>": <value>,
            },

            // Reward is optional, only included for achievements that have bonuses for completion.
            Reward: { Reward }
        },
    ]
```

**Notes:**

- The order that achievements are defined in is important as the game maintains a basic bitmap of the achieved ones in the player progress file.
- New achievements must be added at the end of the list if the the definitions are to remain congruent with the existing progression data.
- The `Order` field allows the definitions to be reorganised within the source file without impacting the final order they are written to the asset binary.
    - All Achievement data are first sorted by ascending `Order` value, followed by their initial position wherever two `Order` values are the same.
    - The `Order` value is optional and only used by the data compilation. Ommitting the field is equivalent to setting it to zero.

The following `Rule` types are defined:

#### Achievement Rule: Collected

The `Collected` rule is checked when the player collects some inventory consumable such as health, fuel or ammunition. This rule defines the following parameters:

```
    Params: {
        Type: "<consumable name>",
        Count: <#count>
    }
```

Valid values for the consumable name are any of the `LinkDefs` enumerated `PlayerAmmoTypes`, `SpecialAmmoTypes`, `Health` and `Fuel`.

**Example:**

```
    {
        // Triggered once the player has collected at least 800 bullets
        // increase the carry limit by 40.

        Description: "Items: Top Brass (800/800)",
        Rule: "Collected",
        Params: {
            Type: "Bullet",
            Count: 800
        },
        Reward: {
            // Carry limit upgrades are always applied first
            Description: "Bullets +40, Carry +40",
            ImmediateAdd: {
                Ammo: {
                    "Bullet": 40,
                }
            },
            CarryLimitAdd: {
                Ammo: {
                    "Bullet": 40,
                }
            }
        }
    }
```

#### Achievement Rule: KillCount

The `KillCount` rule is checked whenever an alien is killed by the player. This rule defines the following parameters:

```
    Params: {
        Alien: "<alien name>",
        Count: <#count>
    }
```

Valid values for the alien name are any of the `LinkDefs` enumerated `AlienTypes`. There are no restrictions to the number of `KillCount` achievements for a specific alien type.

**Example:**

```
    {
        Description: "Kills: Endangered Species (Pest control 100/200)",
        Rule: "KillCount",
        Params: {
            Alien: "Beast",
            Count: 100
        },
        Reward: {
            Description: "Blaster +40, Carry +40",
            ImmediateAdd: {
                Ammo: {
                    "Blaster": 40,
                }
            },
            CarryLimitAdd: {
                Ammo: {
                    "Blaster": 40,
                }
            }
        }
    }
```

#### Achievement Rule: GroupKillCount

The `GroupKillCount` rule is checked whenever an alien is killed by the player. This rule defines the following parameters:

```
    Params: {
        Aliens: [
            // Multiple entries
            "<alien name>",
        ],
        Count: <#count>
    }
```

Valid values for the alien name are any of the `LinkDefs` enumerated `AlienTypes`. There are no restrictions to the number of `GroupKillCount` achievements for a specific alien type.

Killing any of the specified aliens counts towards the achievement.

**Example:**

```
    {
        Description: "Kills: Red's Dead, Baby (Other red things, 25/50)",
        Rule: "GroupKillCount",
        Params: {
            Aliens: [
                "ShotgunGuard",
                "RedDemon",
                "InsectBoss"
            ],
            Count: 25
        }
        // No particular reward for this one.
    },
```

#### Achievement Rule: PlayerDied

The `PlayerDied` rule is checked whenever the player dies. This rule defines the following parameters:

```
    Params: {
        Levels: "<LevelList>",
        Count: <#count>,
        Overall: <bool>
    }
```

The game separately tracks the number of times the player died in each level. The `Levels` field is a `LevelList` string specifies which levels the rule applies to. This allows the definition of specific achievements for dying in a particular level or set of levels.

The `Overall` flag specifies whether or not the required `Count` limit is tested against the death count any single level in the set or the sum total death count for all of the levels in the set.

**Example:**

```
    {
        // First time killed, any level.
        Description: "Died: 'Tis but a scratch!",
        Rule: "PlayerDied",
        Params: {
            Levels: "*",
            Count: 1,
            Overall: false
        }
        // No reward defined here, just shame :)
    },
```

#### Achievement Rule: TimeImproved

The `TimeImproved` rule is checked whenever the player completes a level. This rule defines the following parameters:

```
    Params: {
        Levels: "<LevelList>",
        Count: <#count>,
        Overall: <bool>
    }
```

The game separately tracks the shortest time the player has completed each level and the number of times it has been improved. This allows the definition of specific achievements for beating a past time in a particular level or set of levels.

The `Overall` flag specifies whether or not the required `Count` limit is tested against the improvement count of any single level in the mask or the sum total improvement count for all of the levels in the mask.

**Example:**

```
    {
        Description: "Again: Action Replay (Beat any previous level time)",
        Rule: "TimeImproved",
        Params: {
            Levels: "*",
            Count: 1,
            Overall: true
        }
    },
```

#### Achievement Rule: ZoneFound

The `ZoneFound` rule is checked whenever the player enters a given Zone in a particular Level for the first time. This rule defines the following parameters:

```
    Params: {
        Level: "<level code>",
        Zone: <#zone>
    }
```

The Level field refers to a single specific level and must contain only a single letter A-P.

**Example:**

```
    {
        // Yeah good luck triggering this one.

        Description: "Overflow!",
        Rule: "ZoneFound",
        Params: {
            Level: "A",
            Zone: 256
        }
    }
```
