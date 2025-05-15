#Potentially Visible Set Rendering

##Map Structure Overview

TKG is a 2.5D game engine. Each level is a 2D map. Points are connected in clockwise order to define convex polygons with 3-10 sides. This polygon, together with height data forms a Zone, which is the fundamental primitive the map is built from. The example image below shows a section of a level map, clearly showing the points and edges that together define the Zones the map is built from.

![Example](img/map_example.png)

Notes:

- Solid dark lines indicate a solid "outer" wall edge.
- Lighter grey lines indicate an adjoining edge between Zones.
- Blue lines indicate door or lift zone edges
- Green lines indicate the edges of a zone that has an upper and lower space.

While Zones are required to be convex, it is permitted to have adjacent edges that are completely colinear, i.e. their points fall in a straight line.

What the player thinks of as a "room" may have a more complex, concave shape, such as the left-centre area adjacent Door A in the above map. Neither the engine or the editor has any such concept of a room. Rather this is just a space defined by a set of adjacent Zones that have been given consistent graphical styling.

A Level may have up to 256 Zones defined by up to 800 points (values subject to change). 

##Potentially Visible Sets

It is not possible to see the entire map from any one location. When a map is built, the editor steps through each Zone and compiles a list of every other Zone in the map that has an unblocked line of sight to a point in the Zone. This list forms the Potentially Visible Set or (PVS).

- The PVS also contains the indexes of the Points those Zones are defiend from which allows the runtime to transform and project only the points that matter.
- Information about the edge through which a Zone is seen in is also stored. This allows the renderer to "clip" the maximum rendering extents at runtime.

At runtime, the engine takes note of which Zone the player is in and is then able to test and render only the subset of Zones that are in that Zone's PVS. This saves a lot of computational effort.

##Rendering

Rendering is very simple. Zones are sorted by their centre weighted distance from the observer and are then rendered from the furthest to the nearest, ensuring that rendering is restricted to any clips that are relevant.

The net result is somewhere between a BSP (Convex spaces, precomputed PVS) and Portal renderer.

##Issues

There are some issues and defects with the original solution:

- The PVS determination does not seem to take into account that adjacent Zones can be disconnected due to non-overlapping height ranges.
- The PVS list for a Zone may contain entries that are spatially connected but not visibly connected.
- Runtime application of PVS has to test every Zone in the PVS for rendering. These tests are not comletely reliable and frequently glitch.
- The state of Doors and Lift zones are not taken into consideration.

Invariably, these issues and limitations tend to result in overdraw, where a more distant Zone is rendered, only to be completely drawn over.