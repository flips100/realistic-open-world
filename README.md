# Realistic Open World

A playable **Godot 4.x** 3D open-world prototype — a cohesive **v2.0 full indie upgrade** with cinematic daylight, a prefect humanoid explorer, denser valley, stamina, compass, shrine checkpoint, and side pickups. Still fully **procedural / MIT / commercial-friendly**.

**Version 2.0.0** | **License: MIT** (see [LICENSE](LICENSE)).

> **Honest framing:** polished procedural indie look, **not** scanned AAA photogrammetry. Built with shaders, `NoiseTexture2D`, and generated meshes — no proprietary asset packs.

## What's new in v2.0

| Pillar | What got better |
|--------|-----------------|
| **Rendering & lighting** | Brighter cinematic ProceduralSky, tuned ambient/fill/bounce, SSAO/SSR/SSIL/glow/fog refined. Fixed exposure (no auto-exposure crush on llvmpipe). Compatibility/OpenGL still gets a brighter fallback path. |
| **Player** | Prefect humanoid (blue blazer + face from `assets/player`) with better proportions, idle breathe/sway, stronger walk/sprint cycle, torso lean, over-shoulder camera polish. |
| **World** | Denser terrain mesh (112²), more trees/pines/rocks/bushes/grass, lakeside shrine, watchtower ruin landmark, soft world bounds with push-back. |
| **Gameplay** | Stamina sprint drain + regen, crystal compass (direction + distance), **E** interact shrine checkpoint (restores stamina), 5 optional valley flowers, dynamic quest text, polished win state. Core: **8** crystals. |
| **Audio / UI** | Richer procedural wind, crystal pickup chime, shrine chime, flower SFX, footsteps. HUD with stamina bar, compass, flowers, quest line. Main menu / pause framed as v2.0. |
| **Stability** | All scripts present; main scene `main_menu.tscn` → world F5; README perf knobs + export notes. |

## Features

- Third-person controller (**WASD**, mouse look, **Shift** sprint + stamina, **Space** jump, **E** interact, **Esc** pause)
- Large noise terrain with shader multi-surface blending (grass / dirt / rock / cliff / snow + wetness)
- Soft world bounds (mountain ridges + fog + soft push)
- MultiMesh trees (deciduous + pines), rocks, bushes, grass tufts
- Game loop: collect **8** crystals; optional **5** flowers; shrine checkpoint
- Compass to nearest crystal; quest text updates as you progress
- Main menu live 3D valley preview → world (F5), pause, win → menu
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
6. Collect **8** crystals (compass points to the nearest). Visit the **lakeside shrine** (**E**) for a checkpoint + stamina restore. Optional: pick **5** valley flowers. Standing stones mark spawn; a ruin arch sits on a far ridge.

## Controls

| Action | Input |
|--------|--------|
| Move | **W A S D** |
| Look | **Mouse** |
| Sprint (drains stamina) | **Shift** |
| Jump | **Space** |
| Interact (shrine) | **E** |
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
4. **Terrain resolution** in `scripts/terrain_generator.gd`: `RESOLUTION` `112` → `80` for weaker CPUs.

## Compatibility / OpenGL note

If you force **gl_compatibility**, Forward+-only effects are skipped and ambient/sun/fill/bounce are boosted so the valley stays visible. You will still get a playable daylight scene with ProceduralSky — just without volumetric fog, SSR, SSIL, or SSAO. Prefer **Forward+** when possible.

## Export

Use **Project → Export** with the included `export_presets.cfg` as a starting point (or create a desktop preset). Export templates for Godot 4.3+ required. Keep `assets/player/*.b64*` if you strip `.import` caches — the face loader reconstructs from base64 when needed.

## Project structure

```
project.godot
shaders/     terrain_blend, foliage_wind, bark, water
scenes/      main_menu, world, ui/hud, ui/pause_menu
scripts/     terrain, vegetation, world, player, shrine, side_pickup, ...
assets/player/  reference face (+ .b64 fallbacks)
```

## Commercial use

**MIT License**. Keep the copyright notice. Godot Engine is also MIT — see [CREDITS.md](CREDITS.md).

## Player likeness

The third-person player appearance is based on a **user-supplied reference photograph** (`assets/player/reference_person.jpg`). The mesh is a stylized procedural approximation (assembled primitives + the photo as a face albedo card), not a photogrammetry scan.

**Commercial / publicity rights for any real person's likeness remain the user's responsibility.** This MIT project license covers the code and generated art only — it does not grant rights to commercially exploit a recognizable likeness from the reference photo.

## Honest limitations (remaining)

- Procedural noise materials ≠ scanned PBR photogrammetry
- Primitive mesh foliage (layered crowns, not leaf cards / Nanite trees)
- Player is assembled primitives + reference face card (procedural walk/idle, no skeletal IK); likeness rights are the user's responsibility
- Single terrain chunk (no streaming / virtual texturing)
- Water is a shader plane (no FFT ocean, caustics, or shore foam cards)
- Fixed golden-hour lighting (no full day/night / weather system)
- No GI probes / SDFGI for the whole valley (sky + optional SSIL)
- Compass is a simple HUD bearing (not a full minimap)
- Shrine checkpoint stores position for quest/state (no full save-game system yet)

## Contributing

PRs welcome: Terrain3D, day cycle, better leaf cards, skeletal player, animals, fuller quests, minimap, or a "Low" graphics preset scene.
