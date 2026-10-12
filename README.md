# SITAR Play Studio — 3D edition

Open `project.godot` in Godot 4.6 and press **F5**. The game library has two independent sections, including real-time 3D adventures. The original hand-tracking experiment is preserved in its original files.

## Cognitive Garden

Memory Meadow, Melody Steps and Focus Finder now play in native 3D with recognizable objects instead of numbered or symbol tiles. Eight original mesh icons include an apple, flower, fish, rocket, mushroom, butterfly, duck and tree. Memory Meadow reveals objects under clouds and celebrates matching pairs with a spin. Melody Steps uses bouncing objects, gold rings and pitched sounds to show the sequence. Focus Finder displays a small target object above the board; click or tap its matching object.

The previous rules, three difficulty levels, scoring, pause/resume, stop, replay and per-game/per-difficulty best scores remain. During play, the HUD shows score, time, a short task cue and essential controls. Reduced motion disables object animation while preserving the sequence highlight. Escape and application focus loss pause gameplay and animation.

## Little Adventures — 3D

The current background is a quiet garden, using locally bundled CC0 models from [Kenney Nature Kit](https://kenney.nl/assets/nature-kit). Sage ground, a simple border and a still pond replace the industrial grid. Trees, flowers and stones sit outside the movement bounds. Distinct fixed landmarks help players orient themselves; the open center and static scenery keep visual attention on moving enemies and collectible crystals. This is a readability and orientation design choice, not a claim of measured cognitive benefit.

Play as **Nova**, an original 3D explorer robot, on a continuous floor that fills the display, with hovering drones, faceted crystals, shadows and character animations. The playable area is about 59% larger than the previous arena, with clearance for the HUD. The models are actual meshes.

- **Crystal Quest:** collect 10 crystals within 75 seconds while avoiding pursuing creatures.
- **Sentinel Dash:** survive for 60 seconds; collect crystals and repel enemies for points. Enemies spawn more frequently than in Crystal Quest.
- **Left-click or tap the arena** to move Nova to a destination, or **drag** to steer continuously. A ring marks the destination. Nova stops on arrival. **Double-click / double-tap the arena**, or click **Pulse**, to repel nearby enemies; recharge takes three seconds. Right-click no longer triggers pulse. Pause, stop and replay clear the destination; clicks on UI controls do not issue movement commands.
- Crystals give 100 points, repelled enemies give 50 points. Three hearts, with 1.8 seconds of protection after taking damage.
- Start, Pause, Resume, Stop, Play again and navigation back to the library are supported. Pause freezes gameplay, enemy movement, animations and timers. Switching away from the window pauses automatically.
- Mute works across both sections for the current app session. Best scores are stored separately for both adventure modes.

## Uncluttered fullscreen play

Starting either section enters native fullscreen on desktop. F11 can return to a window. The adventure play view shows only score, time and Pause, Stop, Mute and Pulse controls. Mode selection, instructions, graphics settings and navigation appear before the session; pause/results controls appear when needed. The adventure floor extends to every edge of the 16:9 play view.

Crystal pickups award 100 points immediately, with a rising crystal, teal burst, floating +100 and animated score. Pulse readiness uses a distinct gold halo/spark effect, a glowing Pulse button and a one-time chime. The thin bar inside Pulse shows cooldown progress. Effects use scene-authored animation tracks advanced by gameplay time, so pause freezes them. The tenth pickup has a short celebration before the results appear.

Effect assets: `scenes/3d/collect_effect.tscn` and `scenes/3d/ready_effect.tscn`. Their animation and geometry are editable directly in Godot. UI animation tracks remain in `scenes/adventure.tscn`; `scripts/game_effect.gd` only handles animation playback and cleanup.

## Editing the project

All new and refactored UI is stored in `.tscn` scenes. Colors, typography and button states are stored in scene resources and `.tres` themes. Gameplay scripts connect signals, update state/text, handle input and instantiate reusable scenes; they do not construct UI nodes or styles.

| File | Purpose |
| --- | --- |
| `scenes/launcher.tscn` | Main library, credits and section navigation |
| `cognitive_hub.tscn` | Cognitive 3D stage, lighting, camera, setup, HUD, results and audio |
| `scenes/3d/cognitive_tile.tscn`, `scenes/3d/icons/*.tscn` | Pedestals, cloud covers, object models and reveal/bounce/match animation tracks |
| `scenes/adventure.tscn` | Adventure HUD, controls, world, results and audio |
| `scenes/3d/arena.tscn` | Original floating arena geometry and decoration |
| `scenes/3d/expanded_arena.tscn` | Enlarged arena platform with tiles, illuminated edges, lamps and plants, plus surrounding floor |
| `scenes/3d/garden_arena.tscn` | Active garden background, imported nature landmarks, open clearing and still pond |
| `assets/kenney-nature/` | Six downloaded CC0 3D models and their license |
| `scenes/3d/expanse.tscn` | Continuous screen-filling adventure floor |
| `scenes/3d/player.tscn`, `enemy.tscn`, `crystal.tscn` | Original mesh assets, materials, idle/walk animations and shield effect |
| `scenes/3d/studio.tscn`, `adventure_studio.tscn` | Orthographic cameras, lighting, shadows and environment |
| `scenes/display_controls.tscn` | Fullscreen and anti-aliasing controls shared by all sections |
| `assets/3d/*.glb` | Exported reusable copies of the player, enemy, crystal and arena |
| `scenes/garden_theme.tres`, `adventure_theme.tres` | Shared typography, buttons and focus styling |
| `cognitive_hub.gd`, `scripts/*.gd` | Game and navigation logic |

The project uses a 1920 × 1080 logical UI with canvas scaling and a 1280 × 720 default window. The 3D world renders in the main viewport at native window resolution; it is not enlarged from a low-resolution texture. UI is editable and visible in Godot's scene editor. No scene generation step is required to run or edit the project.

## 4K display and graphics

Use **Fullscreen / F11** on a display configured to **3840 × 2160** in the operating system. Fullscreen uses the display's current resolution, so a 1080p monitor remains 1080p. The UI scales to 2× at 4K and text is rasterized at the display resolution. Non-16:9 windows preserve the UI aspect ratio with letterboxing.

- **Performance:** native-resolution 3D with anti-aliasing off.
- **Balanced:** native-resolution 3D with 2× MSAA (default).
- **Ultra:** native-resolution 3D with 4× MSAA.

Graphics controls appear before starting an adventure, in the cognitive section and in the library. F11 returns to windowed mode. Presets change anti-aliasing, not rendering resolution. 4K frame rate depends on the GPU; the successful native 4K render check is not a sustained-frame-rate benchmark.

The original 3D assets are editable in `scenes/3d/`. GLB exports in `assets/3d/` are reusable snapshots; the game uses the native scene versions, so editing a GLB does not change the game until you explicitly replace the scene asset.

## Assets and data

Original 3D models are created for this project. The earlier downloaded Kenney Tiny Dungeon art is retained for the legacy 2D assets; Interface Sounds remain in use. Both packs are bundled locally under CC0, with their license files. Nunito is bundled under SIL OFL; its semibold file is a static instance of the downloaded variable font. See `ASSET_CREDITS.md` for exact source URLs and usage.

Gameplay works offline. The optional Brain health resources link opens the NIH/NIA website. Scores measure game performance, not clinical improvement; these games are not validated medical treatments.

Best scores live in `user://cognitive_progress.cfg` and `user://adventure_progress.cfg`. No personal or medical data is collected by the new sections. The existing experiment retains its existing behavior and external dependencies; `main.tscn`, `sitar_game.tscn`, `refferance.gd`, and `Player/` are preserved. Its original fixed 1920 × 1080 experiment coordinates still require a matching viewport when run separately.

## Verification

Run each with your Godot executable:

```
--headless --path D:/sitar --script tests/test_cognitive_hub.gd
--headless --path D:/sitar --script tests/test_adventure.gd
--headless --path D:/sitar --script tests/test_navigation.gd
--headless --path D:/sitar --script tests/test_3d.gd
--headless --path D:/sitar --script tests/test_mouse_movement.gd
--headless --path D:/sitar --script tests/test_effects.gd
--headless --path D:/sitar --script tests/test_cognitive_3d.gd
--path D:/sitar --script tests/capture_4k.gd
--path D:/sitar --script tests/capture_cognitive_4k.gd
```

Tests cover previous cognitive rules, scene controls, adventure movement/collisions, scoring, invincibility, pulse cooldown, frozen pause state, completion/defeat/timeouts, replay, navigation, focus pause and persistence. Headless tests check that audio streams exist but disable mixing to avoid same-frame audio teardown warnings. Rendered Godot screenshots were inspected for the 3D library, cognitive board and adventure view. The 4K capture test uses a real 3840 × 2160 offscreen render with 4× MSAA, asserts camera clearance at both playable depth boundaries, and saves `.test-data/adventure_4k.png`. It requires a graphics-capable Godot process (do not run it headlessly). The 3D test checks mesh assets, animation states, X/Z movement limits, shielding and graphics presets. Physical touchscreen behavior and subjective sound balance still require device testing.
