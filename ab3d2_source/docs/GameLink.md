# Development / Game Link File

## Overview

This document describes the data format used in the `test.lnk` file that is exported by the Game Linker. This file is a binary database containing the definitions for all standard aliens, objects and assets used by the game.

## File Structure

The file is a raw binary with no specific header data.

| Offset | Content | Format | Notes |
| :---- | :---- | :---- | :---- |
| 0x00000000 | Level Names | `char[16][40]` | |
| 0x000002C0 | Object Graphic Paths | `char[30][64]`| Location of bitmapped graphics |
| 0x00000A40 | Sound Effect Paths | `char[64][60]` | Location of sound effects |
| 0x00001940 | Floor Path | `char[64]` | Location of floor texture atlas |
| 0x00001980 | Texture Path | `char[192] ` | Location of vector texture atlas |
| 0x00001A40 | Gun Graphics Path | `char[64]` | Not Used |
| 0x00001A80 | Story Path | `char[64]` | |
| 0x00001AC0 | Bullet Defs | `BulletDef[20]` | Bullet behaviours |
| 0x00003230 | Bullet Names | `char[20][20]` | |
| 0x000033C0 | Gun Names | `char[10][20]` | |
| 0x00003488 | Shoot Defs | `ShootDef[10]` | Gun behaviours |
| 0x000034D8 | Alien Names | `char[20][20]` | |
| 0x00003668 | Alien Defs | `AlienDef[20]` | |
| 0x000039B0 | Frame Data | `uint8[7680]` | Format TBC |
| 0x000057B0 | Object Names | `char[30][20]` | |
| 0x00005A08 | Object Defs | `ObjectDef[30]` | |
| 0x00005EB8 | Object Default Anims | `ObjectAnim[30]` | |
| 0x00006CC8 | Object Active Anims | `ObjectAnim[30]` | |
| 0x00007AD8 | Consumables Given | `Consumables[30]` | |
| 0x00008000 | Items Given | `Items[30]` | |
| 0x000082D0 | Alien Anims | `AlienAnimFrame[20][11][20]` | Packed frame definitions, no padding |
| 0x00013FE0 | Vector Paths | `char[30][64]` | |
| 0x00014760 | Wall Texture Paths | `char[16][64]` | |
| 0x00014B60 | Wall Heights | `uint16[16]` | |
| 0x00014B80 | Alien Brights | `uint16[20]` | |
| 0x00014BA8 | Gun Object IDs | `uint16[10]` | |
| 0x00014BBC | Player 1 Graphic ID | `uint16` | |
| 0x00014BBE | Player 2 Graphic ID | `uint16` | |
| 0x00014BC0 | Floor Data | `FloorDef[16]` | |
| 0x00014C00 | Alien Shoot Defs | `ShootDef[20]` | |
| 0x00014CA0 | Ambient Sounds | `uint16[16]`| |
| 0x00014CC0 | Level Music Paths | `char[16][64]` | |
| 0x000150C0 | Echo Table | `uint8[60]` | |


See: [defs/gamelink.i](../defs/gamelink.i)

## Data Structures

The data structures presented here are in pseudo C structure format. Each structure is packed, with no padding or holes. The structure names are illustrative and do not necessarily exactly match the structure names used in the sourceode.

### AlienAnimFrame

Defines a single frame of animation for an Alien. This is more than just the basic graphical properties and can include sound effects, next action types and specific instructions.

```
struct AlienAnimFrame {
    uint8 GraphicFile;
    uint8 FrameNumber;
    uint8 ScaledWidth;
    uint8 ScaledHeight;
    int8  VerticalOffset;
    uint8 SoundEffect;
    uint8 Action;
    uint8 AnimationInstruction;
    uint8 AuxObjectFrame;
    int8  AuxObjectXOffset;
    int8  AuxObjectYOffset;
};

```

### AlienDef

Defines the basic properties and behaviours of a given alien.

```
struct AlienDef {
    uint16 GraphicsType;
    uint16 DefaultBehaviour;
    uint16 ReactionTime;
    uint16 DefaultSpeed;
    uint16 ResponseBehaviour;
    uint16 ResponseSpeed;
    uint16 ResponseTimeout;
    uint16 DamageToRetreat;
    uint16 DamageToFollowup;
    uint16 FollowupBehaviour;
    uint16 FollowupSpeed;
    uint16 FollowupTimeout;
    uint16 RetreatBehaviour;
    uint16 RetreatSpeed;
    uint16 RetreatTimeout;
    uint16 BulletType;
    uint16 HitPoints;
    uint16 Height;
    uint16 Girth;
    uint16 SplatType; // either the projectile class, or spanwed alien class
    uint16 Auxilliary;
};
```

See: [defs/alien.i](../defs/alien.i)

### BulletDef

Defines the behaviour of a particular bullet/projectile type. Note that this structure comprises primarily of 32-bit fields that contain only 8 or 16-bit data. These fields may be split in future so that runtime-injected additional properties can be added by game modifications.

```
struct BulletDef {
    uint32 IsHitScan;
    uint32 Gravity;
    uint32 Lifetime;
    uint32 AmmoInClip;
    uint32 BounceHoriz;
    uint32 BounceVert;
    uint32 HitDamage;
    uint32 ExplosiveForce;
    uint32 Speed;
    uint32 AnimFrames;
    uint32 ImpactFrames;
    uint32 BounceSoundEffect;
    uint32 ImpactSoundEffect;
    uint32 GraphicType;
    uint32 ImpactGraphicType;
    uint8  AnimData[120];   // Substructure TBC
    uint8  ImpactAnim[120]; // Substructure TBC
};
```

See: [defs/bullet.i](../defs/bullet.i)

### FloorDef

Defines floor tile behaviours.
```
struct FloorDef {
    int16 DamageGiven;
    uint16 SoundEffect;
};

```

### ShootDef

Defines the specific behaviours associated with firing a given bullet/projectile.

```
struct ShootDef {
    uint16 BulletType;
    uint16 Delay;
    uint16 BulletCount;
    uint16 SountEffect;
};
```

See: [defs/bullet.i](../defs/bullet.i)
