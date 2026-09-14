# Realistic Open World

A playable **Godot 4.x** 3D open-world prototype aimed at a proper **indie game feel** — readable daylight, a humanoid explorer, denser woods, and a clear lake — still fully **procedural / MIT / commercial-friendly**.

**Version 1.3.0** | **License: MIT** (see [LICENSE](LICENSE)).

> **Honest framing:** polished procedural indie look, **not** scanned AAA photogrammetry. Built with shaders, `NoiseTexture2D`, and generated meshes — no proprietary asset packs.

## What's new in v1.3

| Area | What got better |
|------|-----------------|
| **Lighting that always reads** | Switched to reliable **ProceduralSky** (no pure-black sky in normal play). Higher ambient/sky contribution. Fixed exposure (no auto-exposure crush). **Compatibility/OpenGL fallback** path: brighter sun/fill/bounce, disables volumetric fog / SSR / SSIL / SSAO that soft-fail on OpenGL. |
| **Player** | Replaced grey capsule with a **person** matching a user reference photo: dark skin tone, short textured hair + beard, blue **PREFECT** blazer, light-blue shirt, polka-dot tie, dark trousers. Face uses `assets/player/reference_person.jpg`. Over-shoulder camera. |
| **World read** | Brighter grass/dirt/rock tints; denser deciduous (5-blob crowns) + pines; clearer lake colors for daylight/golden hour; visible blue→warm horizon. |
| **HUD / menu** | Crystal badge panel, clearer objective text, main menu with **live 3D valley preview** (not flat grey). |
| **Feel** | Slightly snappier move/camera; same WASD / mouse / Shift / Space / Esc and **8** crystals. |

## Features

- Third-person controller (**WASD**, mouse look, **Shift** sprint, **Space** jump, **Esc** pause)
- Large noise terrain with shader multi-surface blending
- Soft world bounds (mountain ridges + fog)
- MultiMesh trees (2 types), rocks, bushes, grass tufts with distance fade
- Game loop: collect **8** crystals
- Main menu → world (F5), pause, win → menu
- All art generated in code — commercial-safe

## Requirements

- [Godot 4.3+](https://godotengine.org/download/) (`config/features` lists `4.3`)
- Desktop (Windows / macOS / Linux)
- **Recommend Forward+** on a real GPU for best look (SSAO / SSR / SSIL / volumetric fog)
- Compatibility/OpenGL still playable via the automatic brighter fallback path
- Recommended: mid GPU with **4GB+ VRAM** at 1080p with defaults

## How to play

1. Install Godot 4.3+.
2. Clone this repo.
3. **Import** → `project.godot` → **Open**.
4. Prefer **Project → Project Settings → Rendering → Rendering Method = Forward+** when your GPU supports it.
5. Press **F5**. Click **Enter the Valley**.
6. Collect **8** crystals; standing stones mark the spawn landmark.

## Controls

| Action | Input |
|--------|--------|
| Move | **W A S D** |
| Look | **Mouse** |
| Sprint | **Shift** |
| Jump | **Space** |
| Pause | **Esc** |

## Performance knobs (mid GPU)

Defaults target a mid-range GPU. To dial down:

1. **`scripts/world.gd`** (top constants):
   - `ENABLE_VOLUMETRIC_FOG = false`
   - `ENABLE_SSR = false`
   - `ENABLE_SSIL = false`
   - Lower `SHADOW_MAX_DISTANCE` (e.g. `180.0`)
2. **Project → Project Settings → Rendering**:
   - `lights_and_shadows/directional_shadow/size`: `8192` → `4096` or `2048`
   - `anti_aliasing/quality/msaa_3d`: `2` → `1` or `0`
   - Disable TAA if needed (`anti_aliasing/quality/use_taa`)
   - `environment/volumetric_fog/volume_size`: `128` → `64`
3. **Vegetation density** in `scripts/vegetation_spawner.gd`: reduce `GRASS_TUFT_COUNT`, `TREE_COUNT`, etc.

## Compatibility / OpenGL note

If you force **gl_compatibility**, Forward+-only effects are skipped and ambient/sun/fill are boosted so the valley stays visible. You will still get a playable daylight scene with ProceduralSky — just without volumetric fog, SSR, SSIL, or SSAO. Prefer **Forward+** when possible.

## Project structure

```
project.godot
shaders/
  terrain_blend.gdshader   # PBR height/slope/wetness blend
  foliage_wind.gdshader    # Leaves + wind
  bark.gdshader
  water.gdshader
scenes/
  main_menu.tscn           # 3D preview backdrop
  world.tscn
  ui/hud.tscn
  ui/pause_menu.tscn
scripts/
  terrain_generator.gd / vegetation_spawner.gd
  world.gd / player.gd / water_plane.gd / atmosphere_fx.gd
  ...
```

## Commercial use

**MIT License**. Keep the copyright notice. Godot Engine is also MIT — see [CREDITS.md](CREDITS.md).


## Player likeness

The third-person player appearance is based on a **user-supplied reference photograph** (`assets/player/reference_person.jpg`). The mesh is a stylized procedural approximation (assembled primitives + the photo as a face albedo card), not a photogrammetry scan.

**Commercial / publicity rights for any real person's likeness remain the user's responsibility.** This MIT project license covers the code and generated art only — it does not grant rights to commercially exploit a recognizable likeness from the reference photo.

## Honest limitations (remaining)

- Procedural noise materials ≠ scanned PBR photogrammetry
- Primitive mesh foliage (layered crowns, not leaf cards / Nanite trees)
- Player is assembled primitives + reference face card (no skeletal animation / IK); likeness rights are the user's responsibility
- Single terrain chunk (no streaming / virtual texturing)
- Water is a shader plane (no FFT ocean, caustics, or shore foam cards)
- Fixed golden-hour lighting (no full day/night / weather system)
- No GI probes / SDFGI for the whole valley (sky + optional SSIL)
- Grass tufts are capsules, not photo grass atlases

## Contributing

PRs welcome: Terrain3D, day cycle, better leaf cards, skeletal player, animals, quests, or a "Low" graphics preset scene.
