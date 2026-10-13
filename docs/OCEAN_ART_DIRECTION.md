# Ocean Rescue menu artwork
Generated with the built-in imagegen tool. Asset: assets/images/ocean/lagoon_menu.png.
Prompt: Premium stylized 3D tropical lagoon, turquoise transparent water and coral, palm islands, yellow/coral rescue boat with collection net on the right, friendly leaping dolphin, a few plastic bottles, cinematic sunlight. Calm left side for menu controls. Widescreen, no text, interface, borders, logos or split panels.
The artwork is a menu illustration, not a screenshot of the playable 3D environment. Existing interactive models remain in gameplay. Original vector HUD icons are authored locally in SVG. UI nodes remain in the Ocean Rescue scene; script changes only format the live count.

## Playable 3D upgrade
The runtime scene now uses authored rounded boat geometry, feathered palm meshes, an animated dolphin with eyes and moving tail/flippers, and shaped bottles and containers. These are actual meshes, saved in games/ocean_rescue/scenes/3d/*_detailed.tscn. The offline authoring tool tools/build_ocean_assets.gd rebuilds those resources; gameplay never runs a mesh builder.
Static boat and palm parts are merged by material to reduce draw calls. The dolphin animation uses the existing manual game clock so pausing freezes it.
The generated reef-floor bitmap is applied to a submerged 3D plane beneath translucent, lit water. New splash spray is authored in the effect scene.
Imagegen built-in prompt: Seamless top-down tropical seabed albedo texture, pale rippled sand with scattered reef rock, sage seagrass, peach and lavender coral, diffuse lighting, broad sandy channels, no water surface, horizon, text or interface.
Asset: assets/images/ocean/reef_floor.png. The texture is generated artwork, not a 3D coral scan. These improvements do not claim to exactly reproduce the cinematic menu illustration.

## Calm reef life
Gameplay dolphin jumps are replaced by two schools of five decorative fish: turquoise/yellow and coral/orange. The scene reef_life.tscn owns 48-second curved routes, tail animations and sparse rising bubbles. Six seagrass clumps sway using the same manually advanced session clock. Pause, stop and completion freeze reef life; replay resets its animation. Fish remain submerged and never affect collision or scoring. The original menu illustration remains decorative artwork.
