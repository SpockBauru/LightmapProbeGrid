# LightmapProbeGrid
> ### Create a grid of Lightmap Probes and cut unwanted ones!

<p align="center" width="100%">
  <img width="600px" src="https://github.com/user-attachments/assets/8d94f78a-b288-44a5-9050-fc3e8c266bb0">
</p>


## What is it?
LightmapProbeGrid is an extension for [Godot Engine](https://godotengine.org/) that helps on the demanding task of placing [Lightmap Probes](https://docs.godotengine.org/en/stable/classes/class_lightmapprobe.html) where [LightmapGI](https://docs.godotengine.org/en/stable/tutorials/3d/global_illumination/using_lightmap_gi.html#dynamic-objects) fails to do it.

**Video Tutorial:** https://www.youtube.com/watch?v=HzZSQ0BPpuk


## How to install
1) Download the file `LightmapProbeGrid_v2.2.1.zip` from the [Download Page](https://github.com/SpockBauru/LightmapProbeGrid/releases)
2) Extract the `addons` folder on the root of your project (`res://`). Other files/folders are optional.
3) Go to Godot's "Project" menu -> "Project Settings" -> "Plugins" tab -> enable "LightmapProbeGrid".
4) Restart Godot.

You can also open the `DemoScene` to see how it works.


## Making a grid of Light Probes
- Place the LightmapProbeGrid Node in the scene. It's located at "Add Node" -> Node3D -> LightmapProbeGrid.
- Use the handles (red dots) to resize the grid.
- In the LightmapProbeGrid Inspector you can set the number of Light Probes on each axis with the minimum of 2. Press "Generate Probes" to apply the settings and place your grid of Light Probes in the Scene.

Now you can cut unwanted probes with the methods bellow.


### Cut Obstructed Probes
<p align="center" width="100%">
  <img width="600px" src="https://github.com/user-attachments/assets/c03287bc-630e-48ce-ab58-8aacbe6f44ac">
</p>

This method is designed to cut probes that are placed beyond visual limits such as the ground or the walls of a cave. 

On LightmapProbeGrid Inscpector click on "Cut Obstructed Probes". It will test each Light Probe from the center of the grid to the probe and see if the line intercepts an object. The probe will be cut if there's something blocking the line.


### Cut probes inside objects
<p align="center" width="100%">
  <img width="450px" src="https://github.com/user-attachments/assets/4d11293d-a129-4f4f-af84-75552cdc113a">
</p>

This method is designed to delete probes that are inside objects. It will test all 6 axis of each Light Probe: Up, Down, Left, Right, Forward and Backward by the distance indicated in `Max Object Size`. 

If at least 4 of these lines hit something the probe will be cut. It considers only 4 hits to cut probes on long objects like pillars and trees.


### Cut probes far from objects
<p align="center" width="100%">
  <img width="600px" src="https://github.com/user-attachments/assets/c2195e0c-efcc-4965-80fc-0b393231e2e5">
</p>

This method is designed to delete probes that are far away from any object. Normally these probes don't contain any relevant light information but use with care in places that have a high usage of spotlights.

When you click the button the area around the Light Probe is tested on various directions by the distance indicated in `Max Distance`. The probe will be cut if none of the rays intercept an object.


### Using masks
You can select which 3D render layers LightmapProbeGrid will interact on the section Visual Cull Mask. Only selected layers will be used on detection for the Cut methods above.

Use masks to filter out objects to not interact with the rays, like characters or moving objects.


## Limitations
LightmapProbeGrid is not designed to work with a huge number of Light Probes at once covering a vast area. It is designed to be placed multiple times in a scene with relatively small grids (less than 1,000 probes).


## Compatibility
LightmapProbeGrid is compatible with Godot 4.2 and there are plans to continue supporting onward.


## Ending notes
This tool was entirely made on my free time. If you want to support me, please make an awesome asset and publish for free to the community!


## Changelog
v2.2.1
- Fixed bug in "Cut Obstructed Probes"

v2.2:
- Support for Godot 4.4

v2.1:
- Support for Godot 4.3

v2.0:
- Major changes: now uses GPU Raycast instead of Physics raycast
- This means that colliders are not needed anymore!
- The Cull Mask from v1.0 is not compatible with v2.0

v1.0:
- First release.
