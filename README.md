# SITAR Play Studio — 3D edition

Open `project.godot` in Godot 4.6 and press **F5**. The game library has three independent sections, including real-time 3D adventures. The original hand-tracking experiment is preserved under games/hand_tracking/.

## Cognitive Garden

Memory Meadow, Melody Steps and Focus Finder now play in native 3D with recognizable objects instead of numbered or symbol tiles. Eight original mesh icons include an apple, flower, fish, rocket, mushroom, butterfly, duck and tree. Memory Meadow reveals objects under clouds and celebrates matching pairs with a spin. Melody Steps uses bouncing objects, gold rings and pitched sounds to show the sequence. Focus Finder displays a small target object above the board; click or tap its matching object.

The previous rules, three difficulty levels, scoring, pause/resume, stop, replay and per-game/per-difficulty best scores remain. During play, the HUD shows score, time, a short task cue and essential controls. Reduced motion disables object animation while preserving the sequence highlight. Escape and application focus loss pause gameplay and animation.

## Updated interface and levels

The cognitive setup uses warm ivory panels, dark ink text, and teal Memory, violet Melody and amber Focus cards. Neutral platforms separate the object colors: red apple, yellow flower, turquoise fish, blue/silver rocket, orange mushroom, violet butterfly, ivory duck and green tree. Shapes remain distinct as well as colors.

| Game | Level 1 | Level 2 | Level 3 |
| --- | --- | --- | --- |
| Memory Meadow | 4 pairs, untimed, 1.3s mismatch reveal | 6 pairs, 180s, 0.9s reveal | 8 pairs, 120s, 0.6s reveal |
| Melody Steps | 4-step goal, 0.85s flashes | 6-step goal, 0.65s flashes | 8-step goal, 0.45s flashes |
| Focus Finder | 5 matches, 6 choices, 90s | 8 matches, 9 choices, 60s | 12 matches, 12 choices, 45s; errors cost 3s |
| Seed Quest | 10 seeds, 75s | 14 seeds, 70s | 18 seeds, 65s |
| Sentinel Dash | Survive 60s | Survive 75s | Survive 90s |

Successful completion offers Next level through level 3. Replay repeats the selected level. All levels are available in setup. Adventure scores are saved per game and level; the HUD shows level and remaining hearts.

Adventure levels start with 3 / 4 / 5 enemies, increasing speed, spawn frequency and population caps. Chargers show an orange lane, lock their direction, dash, then recover. Interceptors aim ahead of Nova; flankers approach from changing angles. The dash warning lasts 0.95 / 0.8 / 0.65 seconds. Swept collision detects fast attacks crossing Nova.

Pulse activation uses two staggered cyan shockwaves and six outward sparks, retaining the three-unit hit radius and three-second cooldown. Activation clears the gold ready effect to keep the cues distinct. Warnings, movement, timers and transient animations freeze during pause.

Verification: tests/test_levels_threats.gd covers new level goals, penalties, timeouts, next-level transitions, warnings, dashes, damage and pulse cancellation. tests/capture_refresh.gd renders the refreshed setup, eight icons, charge warning and pulse at 4K.

## Little Adventures — 3D

Both game sections now use three night environments. **Starlight Courtyard (option B)** opens the first session after launching the app. Each subsequent Start or Play again randomly selects one of the other two themes: **Moonlit Robo Garden** or **Lunar Greenhouse**, or returns to Starlight on later sessions. The immediately previous theme never repeats, including when switching between sections. Pausing, resuming and changing difficulty before starting do not change the active theme.

The backgrounds are editable 3D scenes inspired by the approved concepts. They retain an open center, peripheral landmarks and visible floor boundaries. Cyan robot lighting, coral enemy lighting and gold seed rewards stay consistent in every world. Emissive materials, soft radial ground glows and local lights work with the existing Compatibility renderer; no renderer switch or bloom dependency is required. Nature models remain bundled locally from [Kenney Nature Kit](https://kenney.nl/assets/nature-kit).

Play as **Nova**, an original 3D explorer robot, on a continuous floor that fills the display, with hovering drones, glowing golden seeds, shadows and character animations. The playable area is about 59% larger than the previous arena, with clearance for the HUD. The models are actual meshes.

- **Seed Quest:** collect the selected level’s seed goal within its time limit while avoiding pursuing creatures.
- **Sentinel Dash:** survive for the selected level’s duration; collect seeds and repel enemies for points. Enemies spawn more frequently than in Seed Quest.
- **Left-click or tap the arena** to move Nova to a destination, or **drag** to steer continuously. A ring marks the destination. Nova stops on arrival. **Double-click / double-tap the arena**, or click **Pulse**, to repel nearby enemies; recharge takes three seconds. Right-click no longer triggers pulse. Pause, stop and replay clear the destination; clicks on UI controls do not issue movement commands.
- Seeds give 100 points, repelled enemies give 50 points. Three hearts, with 1.8 seconds of protection after taking damage.
- Start, Pause, Resume, Stop, Play again and navigation back to the library are supported. Pause freezes gameplay, enemy movement, animations and timers. Switching away from the window pauses automatically.
- Mute works across both sections for the current app session. Best scores are stored separately for both adventure modes.

## Uncluttered fullscreen play

Starting either section enters native fullscreen on desktop. F11 can return to a window. The adventure play view shows score, time, level, hearts and Pause, Stop, Mute and Pulse controls. Mode selection, instructions, graphics settings and navigation appear before the session; pause/results controls appear when needed. The adventure floor extends to every edge of the 16:9 play view.

Seed pickups award 100 points immediately, with a rising gold effect, warm burst, floating +100 and animated score. Pulse readiness uses a distinct gold halo/spark effect, a glowing Pulse button and a one-time chime. The thin bar inside Pulse shows cooldown progress. Effects use scene-authored animation tracks advanced by gameplay time, so pause freezes them. The tenth pickup has a short celebration before the results appear.

Effect assets: `games/adventure/scenes/3d/collect_effect.tscn` and `games/adventure/scenes/3d/ready_effect.tscn`. Their animation and geometry are editable directly in Godot. UI animation tracks remain in `games/adventure/scenes/adventure.tscn`; `scripts/shared/game_effect.gd` only handles animation playback and cleanup.

## Project folders

All UI, geometry and animation tracks are scene-authored. Scripts contain gameplay and presentation logic.

- games/adventure/scenes and scripts: Nova adventures, actors, effects and HUD.
- games/cognitive/scenes and scripts: memory, melody and focus games, including 3D icons.
- games/hand_tracking/scenes and scripts: preserved original hand-tracking experiment.
- scenes/ui: launcher and shared display controls.
- scenes/environments: the three night worlds and theme host.
- scripts/shared: reusable actors, effects, theme selection and navigation.
- assets/models/nature, audio, fonts, images, shaders and themes: runtime resources and licenses.
- tests: gameplay regression checks and 4K capture scripts.
- docs/ASSET_CREDITS.md: asset sources and license information.

Open project.godot and press F5. Local test output belongs in .test-data (ignored by Godot and Git).
The local .cleanup-backup/unused-files-2026-10-13.zip contains removed files and a migration manifest for recovery; it is excluded from imports and Git. Saved progress was preserved.

## 4K display and graphics

Use **Fullscreen / F11** on a display configured to **3840 × 2160** in the operating system. Fullscreen uses the display's current resolution, so a 1080p monitor remains 1080p. The UI scales to 2× at 4K and text is rasterized at the display resolution. Non-16:9 windows preserve the UI aspect ratio with letterboxing.

- **Performance:** native-resolution 3D with anti-aliasing off.
- **Balanced:** native-resolution 3D with 2× MSAA (default).
- **Ultra:** native-resolution 3D with 4× MSAA.

Graphics controls appear before starting an adventure, in the cognitive section and in the library. F11 returns to windowed mode. Presets change anti-aliasing, not rendering resolution. 4K frame rate depends on the GPU; the successful native 4K render check is not a sustained-frame-rate benchmark.


## Assets and data

Original 3D models are created for this project. Kenney Nature Kit and Interface Sounds remain bundled under CC0 with their license files. Unused 2D prototypes, sprite packs and duplicate model exports were removed. Nunito is bundled under SIL OFL; its semibold file is a static instance of the downloaded variable font. See `docs/ASSET_CREDITS.md` for exact source URLs and usage.

Gameplay works offline. The optional Brain health resources link opens the NIH/NIA website. Scores measure game performance, not clinical improvement; these games are not validated medical treatments.

Best scores live in `user://cognitive_progress.cfg` and `user://adventure_progress.cfg`. No personal or medical data is collected by the new sections. The existing experiment retains its existing behavior and external dependencies; `games/hand_tracking/scenes/main.tscn`, `games/hand_tracking/scenes/sitar_game.tscn`, `games/hand_tracking/scripts/refferance.gd`, and `Player/` are preserved. Its original fixed 1920 × 1080 experiment coordinates still require a matching viewport when run separately.

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
--headless --path D:/sitar --script tests/test_night_themes.gd
--path D:/sitar --script tests/capture_night_themes.gd
```

Tests cover previous cognitive rules, scene controls, adventure movement/collisions, scoring, invincibility, pulse cooldown, frozen pause state, completion/defeat/timeouts, replay, navigation, focus pause and persistence. Headless tests check that audio streams exist but disable mixing to avoid same-frame audio teardown warnings. Rendered Godot screenshots were inspected for the 3D library, cognitive board and adventure view. The 4K capture test uses a real 3840 × 2160 offscreen render with 4× MSAA, asserts camera clearance at both playable depth boundaries, and saves `.test-data/adventure_4k.png`. It requires a graphics-capable Godot process (do not run it headlessly). The 3D test checks mesh assets, animation states, X/Z movement limits, shielding and graphics presets. Physical touchscreen behavior and subjective sound balance still require device testing.


Adventure guidance: orange chevrons preview a drone's charge direction; only drone contact costs a heart. Double-click or double-tap clears drones within three world units (+50 each). Nova's overhead bar refills over three seconds with a countdown, then a breathing PULSE READY cue and sound. Recharge freezes on pause. The start and pause briefings explain Nova's mission, faulty security drones, movement and pulse controls. Presentation is authored in adventure_briefing.tscn, nova_pulse.tscn and enemy.tscn.

Drone-hit feedback: Nova tilts with a brief coral glow; an overhead broken heart and -1 show a life lost. Three persistent HUD heart outlines remain visible while the lost fill enlarges and fades. A cyan shield marks 1.8 seconds of contact immunity. Effects freeze on pause and reset on replay; the final hit has a one-second animation before results. UI and animation tracks are scene-authored.

## Ocean Rescue

Select Ocean Rescue / Set sail in the library. Click, drag or touch the water to steer; collect floating bottles and containers for 100 points each. Pickups arc into the boat basket, with scoop motion, splash, score pop and a brief +100. Orange navigation buoys block movement; choose a route around them. There is no combat or wildlife collection.

Levels: Calm Lagoon collects 8 items in 90 seconds with 2 buoys; Island Trail collects 12 in 80 seconds with 4 buoys; Reef Ranger collects 16 in 70 seconds with 6 buoys. Start, pause/resume, stop, replay, next level, mute and best scores per level are supported. Focus loss pauses. Dolphins jump at milestones and periodically; rigged swimming, wave motion, shoreline foam, boat rocking and pickup effects all freeze during pause.

The boat and buoys use Kenney Watercraft Kit models; palms, bushes and rocks use Kenney Nature Kit. The dolphin uses Quaternius's skinned, animated Fish Pack FBX. A scene material gives the boat the selected coral/yellow palette. Wave and splash recordings come from OpenGameArt. Models and audio are bundled locally for offline play; exact sources and licenses are in docs/ASSET_CREDITS.md.

Scene: games/ocean_rescue/scenes/ocean_rescue.tscn. Logic: games/ocean_rescue/scripts/ocean_rescue.gd. Reusable models and animation tracks are in the game's scenes/3d folder. Imported models are in assets/models/ocean, sounds in assets/audio/ocean, and ocean shaders in assets/shaders. UI lives in scenes, with its theme in assets/themes/ocean_theme.tres.

Rendering uses the native viewport. On a 3840×2160 display select Fullscreen / F11 and Ultra for 4× MSAA. tests/capture_ocean.gd verifies native 4K setup, play and collection frames. This verifies rendering/layout, not sustained 4K frame rate on every GPU. tests/test_ocean_rescue.gd checks progression, collection, animation pause, obstacles, replay and persistence.
