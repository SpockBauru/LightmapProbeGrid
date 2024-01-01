# LightmapProbeGrid
Create a grid of Lightmap Probes and cut unwanted ones!

LightmapProbeGrid is an extension for [Godot Engine](https://godotengine.org/) that helps on the demanding task of placing Lightmap Probes where LightmapGI fails to do it.

**Disclaimer:** If you are getting the error `scene/3d/lightmap_gi.cpp:529 - Inconsistency found in triangulation...` is because [Godot Issue 82642](https://github.com/godotengine/godot/issues/82642) which cause probes to not be connected correctly and inconsistencies on character lighting.

# Index
 * [How to install](#how-to-install)
 * [Making a grid of Light Probes](#making-a-grid-of-light-probes)
 * [Cut Probes Based on Colliders](#cut-probes-based-on-colliders)
   * [Cut Obstructed](#cut-obstructed)
   * [Cut probes inside objects](#cut-probes-inside-objects)
   * [Cut probes far from objects](#cut-probes-far-from-objects)
 * [Limitations](#limitations)
 * [Compatibility](#compatibility)
 * [Ending notes](#ending-notes)
 * [Changelog](#changelog)

# How to install
1) Extract the `addons` folder on the root of your project (`res://`). Other files/folders are optional.
2) Go to "Project" menu -> "Project Settings" -> "Plugins" tab -> enable "LightmapProbeGrid".
3) Restart Godot.

You can also open the `DemoScene` to see how it works.

# Making a grid of Light Probes
Place the LightmapProbeGrid Node in the scene. It's located at "Add Node" -> Node3D -> LightmapProbeGrid.

Use the handles (red dots) to resize the grid.

In the LightmapProbeGrid Inspector you can set the number of Light Probes on each axis with the minimum of 2. Press "Generate Probes" to apply the settings and place your grid of Light Probes in the Scene.

Now you can cut unwanted probes with the methods bellow.

# Cut Probes Based on Colliders
You can only cut probes based on objects that have colliders attached. This is because the tool relies on Raycast.

## Cut Obstructed
This method is designed to cut probes that are placed beyond collider limits such as the ground or the walls of a cave. 

On LightmapProbeGrid Inscpector click on "Cut Obstructed Probes". It will test each Light Probe from the center of the grid to the probe and see if the line intercepts an collision object. The probe will be cut if there's something blocking the line.

## Cut probes inside objects
This method is designed to delete probes that are inside objects with colliders. It will test all 6 axis of each Light Probes: Up, Down, Left, Right, Forward and Backward by the distance indicated in `Max Object Size`. 

If at least 4 of these hit the same object the probe will be cut. It considers only 4 hits to cut probes on long objects like pillars and trees.

## Cut probes far from objects
This method is designed to delete probes that are far away from any collider. Normally these probes don't contain any relevant light information but use with care in places that have a high usage of spotlights.

When you click the button the area around the Light Probe is tested on various directions by the distance indicated in `Max Distance`. The probe will be cut if none of the rays intercept an object.

## Using masks
You can select which layers the rays will interact on the Collision Mask section. Only selected layers will be used on detection for the Cut methods above.

Use masks to filter out objects to not interact with the rays, like characters or moving objects.

# Limitations
LightmapProbeGrid is not designed to work with a huge number of Light Probes at once covering a vast area. It is designed to be placed multiple times in a scene with relatively small grids (less than 1,000 probes).

Cutting probes relies on raycast which only works on object that have a collider. If the object doesn’t have a collider, it will not be tested for the cut.

# Compatibility
LightmapProbeGrid is compatible with Godot 4.2 and there are plans to continue supporting onward.

# Ending notes
This tool was entirely made on my free time. If you want to support me, please make an awesome asset and publish for free to the community!

# Changelog
v1.0:
- First release.
