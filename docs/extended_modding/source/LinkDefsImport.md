[Back To Overview](../README.md)

# LinkDefs Import

Please read the [Source Format](./SourceFormat.md) document for further information on the syntax described here.

Since the Game Modification files are an optional modding extension to the original tooling, it is necessary to redefine several key data classes so that the modification files are aligned with the original `test.lnk` data, for example:

- Alien Names
- Weapon Names
- Ammunition Names

These definitions allow the various types to be referred to by name, rather than numerical values. To ensure a single point of definition, these are defined in a common import file:

`common/linkdefs.rson`

```
{
    AlienTypes: {
        // The game link file defines up 20 alien types, enumerated 0-19.
        // This node defines names to each type that are then used in the rest of the file.
        "<name>": <#id>,
    },
    PlayerAmmoTypes: {
        // The game link file defines up to 20 ammunition types, enumerated 0-19. These are
        // shared between aliens and the player and any 10 of these are assignable to
        // the weapons used by the player. This node defines names for those used by player
        // weapons.
        // It is worth noting that a pickup can award any amount of any of the 20 ammunition
        // types.
        "<name>": <#id>,
    },
    SpecialAmmoTypes: {
        // Since the Player can not use the other 10 ammunition types directly and a pickup
        // can give any of the 20 defined types, we can repurpose the other types for special
        // collectables.
        "<name>": <#id>,
    },
    PlayerWeapons: {
        // Assigns names to each of the player weapon slots.
        "<name>": <#slot>
    },
    // Other lookups
}
```
This file is imported into a modification file using the following standard `Import` node definition:

```
{
    Import: {
        LinkDefs: "common/linkdefs.rson",
    },
}
```

