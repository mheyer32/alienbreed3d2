# Alien Breed 3D II The Killing Grounds 

This repo contains a compileable version of the Alien Breed 3D II source.
It produces executables that can run the original game data or mods created with the
original/compatible tooling.

## Changes

A summary of the changes are listed below:
* Numerous bug fixes and performance improvements.
* No longer takes over the system and can exit back to Workbench.
* Fullscreen is now 320 rather than 288 pixels wide (no side borders)
* RTG cards are supported, provided there is a compatible 256-colour 320x240 or 320x256 screenmode configured.
   * Native chipset is still required as the menus are still rendered in Chip RAM using the blitter.
   * Confirmed working on AGA and ECS systems.
* Player settings and bindings are persisted on exit.
* Player statistics are persisted on exit.
   * This is primarily to support expanded modding by tracking metrics such as things killed, things collected, times killed etc.
   * For the original game, only the best level time on replaying a level is shown.

### Bugfixes

Some annoying bugs have been fixed:
* Damange is no longer inflicted by dangerous floor surfaces when not in contact.
* Liquid pools that have dangerous floor surfaces behave as if the whole volume of the pool is dangerous:
   * Flying above the pool does not result in damage.
   * Swimming in the pool does result in damage.
* Polygon rendering glitches are greatly reduced. 

### Default Input Configuration

When starting the game for the first time, the input defaults to keyboard and mouse. The controls have been modernised since the original Team17 release:
* W/A/S/D for movement and sidestep.
* C for crouch/stand.
* F to use/activate.
* Space to jump/fly.
* Left Shift to walk/run
* Left Mouse to fire

These keys, and more are remain user definable.

### Fixed Keys

Note that these keys may change in subsequent releases as various options are consolidated. The following keys are fixed and not user definable:
* Esc to exit the current level.
* F1 / F2 Adjust automap zoom.
* F3 to cycle audio options.
* F4 toggles dynamic lighting effects.
* F6 toggles wall render quality
* F7 cycles frame rate cap
* F8 toggles between full and simplified shading.
* F9 toggles pixel mode.
   * Presently this is only 1x1 or 1x2.
* F10 toggles between 2/3 and full screen size.
* Tab toggles Automap display.
* K chooses keyboard-only input.
* M chooses keyboard and mouse input.
   * Repeated selection chooses between normal and inverted mouse mode.
* J chooses joystick/joypad input.
* Numeric Pad +/- adjust vertical border size.
* Numeric Pad * exits to the desktop.
   * Note this happens whether in the game or in the menu.

When the Automap is displayed:
* Numeric Pad 5 centres on the player.
* Numeric Pad 1/2/3/4/6/7/8/9 scrolls the map in the implied direction.
* Numeric Pad . (period) toggles green/transparent overlay mode.

When the Automap is not displayed:
* Numeric Pad 7/8/9 adjust display gamma (7 decreases, 8 resets, 9 increases)
* Numeric Pad 4/5/6 adjust display contrast (4 decreases, 5 resets, 6 increases)
* Numeric Pad 1/2/3 adjust display black point (1 decreases, 2 resets, 3 increases)

All options are persisted on clean exist.
* Display options are persisted independently for AGA and RTG screenmodes.  

### Custom Options

The Custom Options menu provides the following additional options:
* Original Mouse:
   * Uses the original Team17 release mouse behaviour, with Right Mouse to move forwards.
* Always run. 

## Modding Improvements

Improvements have been made to allow modders to make more expansive changes to visuals and behaviours:

### New Features
* Each level can redefine the floor texture tile by adding a custome floortile to the level directory.
* Each level can refefine any wall texture by adding a wall_N.256wad, where N is the hex index of the slot (0-F) to override.
* A new properties file, AB3:Includes/game.props can be defined that extends over the original game link file and can add new properties:
   * Inventory carry limits (ammo, things)
   * Special ammo classes that can modify carry limits and be assigned as the ammo given by special items:
      * These make use of the 10 (alien) ammo slots that the player cannot otherwise use.
      * An example might be a bandolier that, once the player has collected an item giving this ammo, increases the amount of bullets that can be carried.
   * Achievements:
      * Achievements can be defined around:
         * Alien kill counts.
         * Group alien kill counts, i.e. any of a group of different alien types.
         * First time entering a Zone, for finding specific secrets.
         * Item collected counts
         * Level time improvements, e.g. beating a previous record.
         * Player died count.
      * Achievements can give rewards:
         * Additional ammunition, health or fuel.
         * Increase carry limits for ammunition, health or fuel.
 * Note that the binary game properties file is compiled from a JSON specification for which no native tooling yet exists.

### Bugfixes
* Doors and lifts are no longer restricted to the leftmost edge of a wall texture.


## Background

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

There are multiple targets that can be built.

| Build | Description | CPU Target | Recipe |
|------|-------------|-----|---------|
|Release | Release, no debug, stripped | 68020+ | make rel |
|||68040| make rel040 |
|||68060| make rel060 | 
|Test|Release mode, full debug, unstripped | 68020+ | make test
|||68040| make test040 |
|||68060| make test060 |
| Developer | Developer mode, full debug, unstripped | 68020+ | make dev |
|||68040| make dev040 |
|||68060| make dev060 |

Each recipe produces two binaries:

- Pure assembler build:
    - AGA only
    - Generall lags behind the mixed assembler/C build featurewise.
- Mixed assembler/C build:
    - AGA and RTG.
    - Older chipsets are supported in RGB mode.

The pure assembler build is under review and may be dropped in future versions. There is generally no performance benefit over the mixed assembler/C builds.


### Tuning

Theere are three main CPU tuning options:

- 68020+
    - Runs on any 68020 or higher CPU, intended for 68030/50MHz.
    - This build may still make use of optimised routines for specific CPUs, e.g. C2P for 030 or 040/060.
- 68040
    - Specifically excludes routines optimised for slower CPUs and any runtime indirections used to select them.
    - May contain 68040-specific optimisations, e.g. cache aware, move16, etc.
- 68060
    - Specifically excludes routines optimised for slower CPUs and runtime indirections used to select them.
    - May contain 68060-specific optimisations, e.g. cache aware, move16 and code rewritten for fast multiplication, zero cycle branches, superscalar execution, etc.


### Release

This is the intended build for end users:

- No devmode features
- No debugging support
- Fully stripped

### Test

This is the same as the release build but full retains debugging support and is unstripped.

### Developer

The developer build, in addition to full debugging support, includes various extras to assist debugging and feature development. This build should be considered unstable and is generally slower. Additional features of the development build include:

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
Note: This section is generally always out of date as several of these improvements have been made and/or are in progress.

There are MANY ways this game can be improved:

* Use Intution for keyboard control.
* Going back to the main menu to change controls makes the level start over.
* Performance improvements (in progress).
* Quality improvements.
   * The rendering code often produces rather wobbly output.
   * Better modding support (in progress)
* More options in the game to enable/disable gouraud shading and bumpmapping as well as glare objects
   * Available in dev build.
   * Option to disable some for regular game as a possible performance improvement. 
* General code cleanups (in progress):
   * Improvements to code organisation, identifier names, etc. (in progress).
   * Refactoring:
      * Extraction of pure data from code (in progress)
      * Deduplication of common code (in progress)  
   * The current code mixes code and data willy-nilly, all in one object file.
      * Using multiple object files and XREF/XDEF may be cleaner.
      * Remove old, unused commented-out cruft (in progress). 


