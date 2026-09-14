# Realistic Open World

A playable **Godot 4.x** 3D open-world prototype: third-person exploration across a large procedural valley, with trees, rocks, fog, shadows, collectible crystals, HUD, and pause menu.

**License: MIT** — free to use, modify, and sell commercially (see [LICENSE](LICENSE)).

## Features

- Third-person controller (WASD, mouse look, sprint, jump, gravity, spring-arm camera)
- Large noise-based terrain (~512×512 units) with grass / dirt / rock vertex coloring
- Soft world bounds via mountain ridges and depth fog
- MultiMesh trees, rocks, and bushes
- Procedural sky, directional sun with shadows, ambient sky light, SSAO, glow
- Game loop: collect **8 glowing crystals** scattered across the valley
- Main menu → world, pause menu (Esc), win state → return to menu
- All art generated in code (meshes, materials, NoiseTexture2D) — commercial-safe

## Requirements

- [Godot 4.3+](https://godotengine.org/download/) (4.2+ should work; project features list `4.3`)
- Desktop platform (Windows, macOS, or Linux)

## How to open and play

1. Install Godot 4.3 or newer.
2. Clone or download this repository.
3. In Godot: **Import** → select `project.godot` in this folder → **Open**.
4. Press **F5** (or Play) to run. The main menu is the startup scene.
5. Click **Start Adventure**.

No external asset packs are required.

## Controls

| Action | Input |
|--------|--------|
| Move | **W A S D** |
| Look | **Mouse** |
| Sprint | **Shift** |
| Jump | **Space** |
| Pause / Resume | **Esc** |

## Goal

Explore the open valley and collect **8 glowing cyan crystals**. Standing stones near the spawn mark a landmark. When all crystals are found, a completion panel appears.

## Exporting downloadable desktop builds

1. In Godot: **Project → Export…**
2. Install export templates if prompted (**Editor → Manage Export Templates**).
3. Add a preset:
   - **Windows Desktop** → `.exe`
   - **Linux/X11** → binary
   - **macOS** → `.app` / `.zip`
4. Choose an output path (e.g. `builds/RealisticOpenWorld`) and click **Export Project**.
5. Distribute the exported binary together with the `.pck` (or one-file export if enabled).

Recommended export tips:

- Enable **Embed PCK** for a single distributable file where supported.
- Use **Release** export mode for players.
- Test the exported build on a clean machine.

## Project structure

```
project.godot          # Engine config, input map, main scene
scenes/
  main_menu.tscn       # Title screen
  world.tscn           # Open outdoor world
  ui/hud.tscn          # Crystal counter + win UI
  ui/pause_menu.tscn   # Pause overlay
scripts/
  game_manager.gd      # Autoload: score, win, scene changes
  player.gd            # Third-person controller
  terrain_generator.gd # Procedural heightmap mesh + collision
  vegetation_spawner.gd
  collectible.gd
  world.gd / hud.gd / pause_menu.gd / main_menu.gd
LICENSE                # MIT
CREDITS.md             # Attribution notes
```

## Commercial use

This project is released under the **MIT License**. You may use it in commercial products, closed-source games, and asset marketplaces, provided you keep the copyright/license notice. Godot Engine itself is MIT-licensed; see [CREDITS.md](CREDITS.md).

## Limitations (prototype scope)

- Indie visuals: solid-color / noise materials, no PBR texture packs or foliage LODs
- Single continuous terrain chunk (not streamed open-world tiles)
- No NPCs, combat, inventory, or save system
- Crystal placements are deterministic per seed but not marked on a minimap

## Contributing

PRs welcome: denser biomes, day/night cycle, animals, quests, or mobile export presets.
