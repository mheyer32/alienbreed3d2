# Alien Breed 3D II The Killing Grounds 

This repo contains a compileable version of the Alien Breed 3D II source.
It produces executables that can run the original game's data.

This repo is based on and still contains the original source release of TKG. The
original code is very messy, apparently containing multiple versions of the
source (the was code base handled by one man without source control).
It looks like as if TKG was grown out of the AB3D source. In fact, the original
AB3D source is contained here, albeit I couldn't get it to compile as there are
some media files missing that the executable needs.
A big difference between the AB3D and TKG code is that AB3D includes many data
files directly in the executable, while TKG is more data driven by "outsourcing"
much of its game data control into test.lnk

The way the code is "structured" is to have one main assembly source file which
includes everything else (recursivly). No makefiles or project setup is needed -
just point the assembler at the main file. There are actually many 'main' files
in the original source, pointing at different milestones, demos or renderer
experiments.

I have been able to get the code in source_4000/hires.s and
cheesesauce/cheesey.s to compile, but only the hires executable really works.
The 'distilled' version of this source is under ab3d2_source. 
Some of the older render experiments also compile, albeit rarely produce a working executable.

In order to be able to cross-compile the code via vasm I had to:

* unify filename case to lower cases and edit all include and incbin directives accordingly
* remove absolute volume names from include and incbin
* remove copy protection code/menu
* re-enable the fire effect in the main menu
* turn the default keymapping to AWSD+mouse. Make left mouse button shoot and right mouse button select next weapon

## Building
The currently maintained and buildable source code is located within the `ab3d2_source/` directory. The original game sources are retained in the `ab3d2_old_source/` directory.

A standard GNU make compatible Makefile is included. This can be used with Bebbo's cross compiler suite for Linux. See: https://github.com/bebbo/amiga-gcc for details on installation.

There are two targets that can be built.

### Release

This is the standard game engine. When build, this produces an AmigaOS executable `hires` that can be copied to your game directory. Example for cross compiling under linux:
```
$ git clone https://github.com/mheyer32/alienbreed3d2.git
... snip output ...
$ cd alienbreed3d2/ab3d2_source
$ make
vasmm68k_mot -Fhunk -m68060 -linedebug -chklabels -align -L listing.txt -Dmnu_nocode=1 -I../ -I/home/commander_reynolds/misc/amiga/m68k-amigaos/ndk-include -I../media -I../media/includes -o hires.o hires.s
vasm 1.8k (c) in 2002-2021 Volker Barthelmann
vasm M68k/CPU32/ColdFire cpu backend 2.4 (c) 2002-2021 Frank Wille
vasm motorola syntax module 3.15a (c) 2002-2021 Frank Wille
vasm hunk format output module 2.13 (c) 2002-2020 Frank Wille

bss(aurw16):	      242340 bytes
data(adrw16):	      144098 bytes
code(acrx64):	      196568 bytes
bss_c(aurw256):	      128416 bytes
data_c(adrw2):	       58362 bytes
vlink -b amigahunk -sc -l amiga -L /home/commander_reynolds/misc/amiga/m68k-amigaos/ndk/lib/libs hires.o -o hires

```
The optimisation level is set for 68060, however at this time there are no specific requirements for 68060, 68040 or FPU.

Please note the following limitations of the present build:

* There is no hires text mode, so level blurb is missing.
* There is no message display in game, as this used a hires slice at the foot of the view.
* There is no palette animation, e.g. pain flashes.

The game supports double buffered vertical sync and frame rate capping. These can be cycled through using the F7 key.


### Developer
The developer build includes various extras to assist debugging and feature development.
```
$ cd alienbreed3d2/ab3d2_source
$ make dev
vasmm68k_mot -Fhunk -m68060 -linedebug -chklabels -align -L listing.txt -Dmnu_nocode=1 -I../ -I/home/commander_reynolds/misc/amiga/m68k-amigaos/ndk-include -I../media -I../media/includes -DDEV=1 -o hires.o hires.s
vasm 1.8k (c) in 2002-2021 Volker Barthelmann
vasm M68k/CPU32/ColdFire cpu backend 2.4 (c) 2002-2021 Frank Wille
vasm motorola syntax module 3.15a (c) 2002-2021 Frank Wille
vasm hunk format output module 2.13 (c) 2002-2020 Frank Wille

bss(aurw16):	      242650 bytes
data(adrw16):	      144098 bytes
code(acrx64):	      197976 bytes
bss_c(aurw256):	      128416 bytes
data_c(adrw2):	       58362 bytes
vlink -b amigahunk -sc -l amiga -L /home/commander_reynolds/misc/amiga/m68k-amigaos/ndk/lib/libs hires.o -o hires
```

Please note that the development build may be less stable and also slower. Features of the development build include:

* Performance metrics overlay:
    * Draw time
    * FPS (averaged over last 8 frames)
    * Object count, including breakdown in 2/3 window mode
    * Wall count, including breakdown in 2/3 window mode
    * Flat count
    * On-screen history graph for draw time and object count
* Developer toggles to enable/disable specific features statically bound to specific keys:
    * Flat shaded walls (E)
    * Shaded walls (R)
    * Basic sprites (T)
    * Glare sprites (Y)
    * Additive transparency sprites (U)
    * Lightsourced sprites (I)
    * Polygon Models (O)
    * Flats (floors/ceilings) (G)
    * Fast buffer clear (when hiding walls/floors) (Q)
    * AI attack (N)



## Considerations
Note: This section is out of date as several of these improvements have been made.

There are MANY ways this game can be improved:

* include faster C2P   code just as in legacy patches and WHDLoad slaves
* remove system-takeover, in partcular writing to DMACON and INTENA
** open regular screen, support RTG
** use intution for keyboard control
** allow exiting the game
* something is badly screwed up in level C
* going back to the main menu to change controls makes the level start over
* performance improvements?
* quality improvements?
** the rendering code often produces rather wobbly output
* more options in the game to enable/disable gouraud shading and bumpmapping as well as glare objects
* general code cleanups
** cleaner startup/shutdown
** the current code mixes code and data willy-nilly, all in one object file. Using multiple object files and XREF/XDEF may be cleaner.
** remove old, unused commented-out cruft 


