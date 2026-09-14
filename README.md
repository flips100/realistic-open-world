# Realistic Open World

A playable **Godot 4.x** 3D open-world prototype with a **realism-focused upgrade**: cinematic golden-hour lighting, multi-texture terrain blending, wind-shaded vegetation, water, volumetric haze, and tighter player feel — still fully procedural / MIT / commercial-friendly.

**License: MIT** — free to use, modify, and sell commercially (see [LICENSE](LICENSE)).

> Not photoreal AAA. Aimed at the strongest look/feel achievable with code-generated assets and Godot 4 Forward+ features.

## Realism upgrade (v1.1)

| Area | What changed |
|------|----------------|
| **Rendering** | Forward+ preferred; ACES tonemap; SSAO + SSR; glow; soft 8K directional shadows; volumetric fog; warm golden-hour sun + sky fill |
| **Terrain** | 192² mesh (~512×512 units); custom blend shader (grass/dirt/rock/cliff/snow by height & slope); NoiseTexture2D albedo + normals; denser trimesh collision |
| **Vegetation** | Deciduous + pine trees, denser rocks/bushes; bark & foliage shaders; light wind sway; visibility-range culling |
| **Atmosphere** | Horizon haze matching sky; volumetric fog; water plane with animated normals / fresnel; pollen motes |
| **Player** | Camera smoothing; sprint FOV kick; landing punch; head bob; procedural footsteps by surface (grass/dirt/rock) |
| **Audio** | Procedural looping wind ambience + footstep one-shots (no third-party audio files) |
| **Polish** | Quieter HUD, subtler crystal glow + sparkles, refined menus |

## Features

- Third-person controller (WASD, mouse look, sprint, jump, gravity, spring-arm camera)
- Large noise-based terrain with shader-based multi-surface blending
- Soft world bounds via mountain ridges and depth fog
- MultiMesh trees (2 types), rocks, and bushes with LODish distance fade
- Game loop: collect **8** crystals scattered across the valley
- Main menu → world, pause menu (Esc), win state → return to menu
- All art generated in code (meshes, materials, shaders, NoiseTexture2D) — commercial-safe

## Requirements

- [Godot 4.3+](https://godotengine.org/download/) (project features list `4.3`)
- **Desktop** (Windows, macOS, or Linux)
- **Forward+** renderer (default) for SSAO / SSR / volumetric fog quality  
  - Mobile/Compatibility will run but with reduced fidelity; disable volumetric fog if needed on low-end GPUs
- Recommended: GPU with 4GB+ VRAM for 8K shadows + volumetric fog at 1080p

## How to open and play

1. Install Godot 4.3 or newer.
2. Clone or download this repository.
3. In Godot: **Import** → select `project.godot` → **Open**.
4. Confirm **Project → Project Settings → Rendering → Renderer** is **Forward+** (or open as-is; `project.godot` sets `forward_plus`).
5. Press **F5** (or Play). Main menu is the startup scene.
6. Click **Enter the Valley**.

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

Explore the open valley and collect **8** crystals. Standing stones near the spawn mark a landmark. When all are found, a completion panel appears.

## Exporting desktop builds

1. **Project → Export…**
2. Install export templates if prompted.
3. Add **Windows / Linux / macOS** preset → Export Project.
4. Prefer **Release** mode; embed PCK where supported.

## Project structure

```
project.godot
shaders/
  terrain_blend.gdshader   # Height/slope multi-texture terrain
  foliage_wind.gdshader    # Leaf/bush wind
  bark.gdshader
  water.gdshader
scenes/
  main_menu.tscn
  world.tscn
  ui/hud.tscn
  ui/pause_menu.tscn
scripts/
  terrain_generator.gd
  vegetation_spawner.gd
  world.gd / player.gd / collectible.gd
  ambient_audio.gd / water_plane.gd / atmosphere_fx.gd
  game_manager.gd / hud.gd / pause_menu.gd / main_menu.gd
```

## Commercial use

**MIT License**. You may use this in commercial products provided you keep the copyright notice. Godot Engine is also MIT — see [CREDITS.md](CREDITS.md).

## Honest limitations

- Still indie/procedural: primitive meshes + noise materials, not scanned PBR foliage
- Single terrain chunk (not streamed open-world tiles)
- Volumetric fog + 8K shadows are GPU-heavy; lower shadow size if needed
- No day/night cycle (fixed photographic golden-hour)
- Water is a single stylized plane (no full fluid sim / caustics)
- No NPCs, combat, inventory, or save system

## Contributing

PRs welcome: Terrain3D integration, true day cycle, animals, quests, or mobile presets.
