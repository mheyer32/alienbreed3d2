= Alien Breed 3D II The Killing Grounds = 

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

In order to be able to cross-compile the code via vasm I had to
* unify filename case to lower cases and edit all include and incbin directives accordingly
* remove absolute volume names from include and incbin
* remove copy protection code/menu
* re-enable the fire effect in the main menu
* turn the default keymapping to AWSD+mouse. Make left mouse button shoot and right mouse button select next weapon

There are MANY ways this game can be improved
* include faster C2P   code just as in legacy patches and WHDLoad slaves
* remove system-takeover
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

