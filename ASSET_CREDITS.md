# Asset credits and original 3D assets

## Original 3D assets

Created specifically for this project using Godot mesh geometry and materials:

- Nova: rounded explorer robot, visor, antenna, backpack, articulated legs and shield.
- Sentinel drone: coral body, dark visor, twin rotors and illuminated eyes.
- Golden seed: rounded glowing body, pointed husk, paired leaves and orbiting ring. The scene retains its original `crystal.tscn` filename for gameplay compatibility.
- Night environments: Starlight Courtyard, Moonlit Robo Garden and Lunar Greenhouse; native scene geometry, charging alcoves, lanterns and soft-glow shader inspired by the approved concept previews.
- Floating arena: tiled platform, edge lighting, lamps, planters and landing marker.
- Continuous adventure floor: grid surface extending beyond the viewport.
- Cognitive icons: apple, flower, fish, rocket, mushroom, butterfly, duck and tree; native mesh geometry in `scenes/3d/icons/`.
- Cognitive pedestal and cloud cover, with reveal, bounce and matching-spin animations in `scenes/3d/cognitive_tile.tscn`.

Editable source scenes: `scenes/3d/`. Reusable GLB exports: `assets/3d/`. The exports contain geometry/materials/animations supported by GLTF; gameplay scripts stay in the native Godot project. The characters and cognitive icons are original; the garden background also uses the downloaded nature models below.

## Kenney — Nature Kit 2.1

- Official source: https://kenney.nl/assets/nature-kit
- Download: https://kenney.nl/media/pages/assets/nature-kit/37ac38a37b-1677698939/kenney_nature-kit.zip
- License: Creative Commons Zero (CC0), bundled at `assets/kenney-nature/License.txt`.
- Downloaded on 12 October 2026. Six original GLB files are bundled locally: `tree_small`, `tree_pineSmallA`, `flower_purpleA`, `flower_yellowA`, `rock_smallA`, and `grass_large`.
- Used as static landmarks in `scenes/3d/garden_arena.tscn` and the three night scenes in `scenes/3d/themes/`. Ground, garden beds, edging and pond are original scene geometry. Models use embedded materials and work offline.

## Kenney — Tiny Dungeon 1.0

- Official source: https://kenney.nl/assets/tiny-dungeon
- Download: https://kenney.nl/media/pages/assets/tiny-dungeon/f8422efb44-1674742415/kenney_tiny-dungeon.zip
- License: Creative Commons Zero (CC0), included at `assets/kenney-dungeon/License.txt`.
- Retained for the earlier 2D hero, enemy creatures, cyan-tinted collectible, floor, walls and courtyard props. Current adventures use the new original 3D assets instead. Original pack files remain in `assets/kenney-dungeon/`.

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
- License: SIL Open Font License 1.1, included at `assets/Nunito-OFL.txt`.
- `Nunito-SemiBold.ttf` is a locally generated static instance at weight 600, derived with fontTools from the bundled variable font. It is used in both UI themes.

Assets were fetched on 12 October 2026 and are bundled for offline use. No third-party attribution logos are used.
