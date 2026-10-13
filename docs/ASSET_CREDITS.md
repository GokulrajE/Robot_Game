# Asset credits and original 3D assets

## Original 3D assets

Created specifically for this project using Godot mesh geometry and materials:

- Nova: rounded explorer robot, visor, antenna, backpack, articulated legs and shield.
- Sentinel drone: coral body, dark visor, twin rotors and illuminated eyes.
- Golden seed: rounded glowing body, pointed husk, paired leaves and orbiting ring. The scene retains its original `crystal.tscn` filename for gameplay compatibility.
- Night environments: Starlight Courtyard, Moonlit Robo Garden and Lunar Greenhouse; native scene geometry, charging alcoves, lanterns and soft-glow shader inspired by the approved concept previews.
- Cognitive icons: apple, flower, fish, rocket, mushroom, butterfly, duck and tree; native mesh geometry in `games/cognitive/scenes/3d/icons/`.
- Cognitive pedestal and cloud cover, with reveal, bounce and matching-spin animations in `games/cognitive/scenes/3d/cognitive_tile.tscn`.

Editable source scenes are in games/adventure/scenes/3d, games/cognitive/scenes/3d and scenes/environments. Unused GLB snapshots were removed.

## Kenney — Nature Kit 2.1

- Official source: https://kenney.nl/assets/nature-kit
- Download: https://kenney.nl/media/pages/assets/nature-kit/37ac38a37b-1677698939/kenney_nature-kit.zip
- License: Creative Commons Zero (CC0), bundled at `assets/models/nature/License.txt`.
- Downloaded on 12 October 2026. Six original GLB files are bundled locally: `tree_small`, `tree_pineSmallA`, `flower_purpleA`, `flower_yellowA`, `rock_smallA`, and `grass_large`.
- Used as static landmarks in `scenes/environments/moonlit.tscn` and the three night scenes in `scenes/environments/`. Ground, garden beds, edging and pond are original scene geometry. Models use embedded materials and work offline.

## Kenney — Interface Sounds

- Official source: https://kenney.nl/assets/interface-sounds
- Download: https://kenney.nl/media/pages/assets/interface-sounds/fa43c1dd4d-1677589452/kenney_interface-sounds.zip
- License: CC0, included at `assets/audio/License.txt`.
- `click_001.ogg`: session start and cognitive tile taps.
- `confirmation_001.ogg`: correct answers and collecting treasure.
- `error_001.ogg`: taking damage.
- `open_001.ogg`: protective pulse.
- `select_001.ogg`: pulse-ready chime, played once on recharge.

## Nunito

- Source: https://github.com/google/fonts/tree/main/ofl/nunito
- Original variable font: https://raw.githubusercontent.com/google/fonts/main/ofl/nunito/Nunito%5Bwght%5D.ttf
- License: SIL Open Font License 1.1, included at `assets/fonts/Nunito-OFL.txt`.
- `Nunito-SemiBold.ttf` is a locally generated static instance at weight 600, derived with fontTools from the original variable font (unused source font removed). It is used in both UI themes.

Assets were fetched on 12 October 2026 and are bundled for offline use. No third-party attribution logos are used.
## Restored legacy scene dependencies

A small subset of Kenney Tiny Dungeon tiles remains for prototype scenes re-saved by an existing editor session. Source: https://kenney.nl/assets/tiny-dungeon . License: CC0, bundled in assets/kenney-dungeon/License.txt. These do not replace the active 3D game assets.

## Ocean Rescue — downloaded 13 October 2026

- Kenney Watercraft Kit 2.1: https://kenney.nl/assets/watercraft-kit . CC0; fishing boat, navigation buoy and color atlas. License: assets/models/ocean/KENNEY-LICENSE.txt. A custom shader recolors the boat coral/yellow; original GLB retained.
- Kenney Nature Kit: https://kenney.nl/assets/nature-kit . CC0; detailed/bent palms, shoreline rock and bush. License: assets/models/ocean/NATURE-LICENSE.txt.
- Quaternius Animated Fish Pack: https://quaternius.com/packs/animatedfish.html . CC0; Dolphin.fbx, including Armature|Swim skeletal animation. License: assets/models/ocean/QUATERNIUS-LICENSE.txt. The game combines swimming with a scene-authored jump trajectory.
- Ocean splash by Thimras: https://opengameart.org/content/ocean-splash . CC0, original cannon_miss_0.ogg, locally named splash.ogg.
- Beach Ocean Waves by jasinski (submitted by qubodup): https://opengameart.org/content/beach-ocean-waves . CC0; wave_01_cc0-18363__jasinski__alkaibeach.flac converted to OGG with crossfade/fades for ambience. Audio license notes: assets/audio/ocean/LICENSE.txt.
- Original work: litter models, basket and scoop additions, collection effects, ocean/shore/wake shaders, UI and jump tracks.
