# Realistic Open World

A playable **Godot 4.x** 3D open-world prototype pushed toward **photoreal-leaning** ("pic realism") visuals: photographic lighting & post, PBR terrain blending, a reflective lake, denser foliage/ground cover, and filmic camera feel -- still fully **procedural / MIT / commercial-friendly**.

**Version 1.2.0** | **License: MIT** (see [LICENSE](LICENSE)).

> **Honest framing:** photoreal-**leaning** procedural look, **not** scanned AAA and **not** indistinguishable from a photograph. Built with shaders, `NoiseTexture2D`, and primitive meshes -- no proprietary asset packs.

## Photoreal upgrade (v1.2)

| Area | What changed |
|------|----------------|
| **Lighting & post** | `PhysicalSkyMaterial`; ACES tonemap; stable auto-exposure (`CameraAttributesPractical`); strong SSAO + SSIL; SSR; careful softlight glow; camera-like contrast/saturation; ~5200K sun + cool fill; soft 4-split shadows; volumetric + depth fog haze |
| **Terrain PBR** | Denser 224^2 mesh; dual-scale triplanar albedo/normal/roughness; grass->dirt->rock->cliff->snow by height/slope/noise; shoreline **wetness** (darker + glossier); macro noise to break tiling |
| **Water** | Larger subdivided lake; dual-scroll normals; fresnel; specular boost for SSR; shore darkening; subtler multi-frequency waves |
| **Foliage** | 4-blob deciduous crowns (less "lollipop"); 4-layer pines; bark vertical normals + roughness; translucent-ish leaf emission; **2200** grass-tuft MultiMesh; clumped scatter; gust+flutter wind |
| **Atmosphere** | Pollen motes + soft ground haze near the lake |
| **Camera** | Filmic FOV (~62 deg); subtle head bob + strafe roll; grounded walk/sprint |
| **Perf knobs** | Constants in `scripts/world.gd` + Project Settings (documented below) |

## Features

- Third-person controller (**WASD**, mouse look, **Shift** sprint, **Space** jump, **Esc** pause)
- Large noise terrain with shader multi-surface blending
- Soft world bounds (mountain ridges + fog)
- MultiMesh trees (2 types), rocks, bushes, grass tufts with distance fade
- Game loop: collect **8** crystals
- Main menu -> world (F5), pause, win -> menu
- All art generated in code -- commercial-safe

## Requirements

- [Godot 4.3+](https://godotengine.org/download/) (`config/features` lists `4.3`)
- Desktop (Windows / macOS / Linux)
- **Forward+** renderer (default) for SSAO / SSR / SSIL / volumetric fog
- Recommended: mid GPU with **4GB+ VRAM** at 1080p with defaults

## How to play

1. Install Godot 4.3+.
2. Clone this repo.
3. **Import** -> `project.godot` -> **Open**.
4. Press **F5**. Click **Enter the Valley**.
5. Collect **8** crystals; standing stones mark the spawn landmark.

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
2. **Project -> Project Settings -> Rendering**:
   - `lights_and_shadows/directional_shadow/size`: `8192` -> `4096` or `2048`
   - `anti_aliasing/quality/msaa_3d`: `2` -> `1` or `0`
   - Disable TAA if needed (`anti_aliasing/quality/use_taa`)
   - `environment/volumetric_fog/volume_size`: `128` -> `64`
3. **Vegetation density** in `scripts/vegetation_spawner.gd`: reduce `GRASS_TUFT_COUNT`, `TREE_COUNT`, etc.

## Project structure

```
project.godot
shaders/
  terrain_blend.gdshader   # PBR height/slope/wetness blend
  foliage_wind.gdshader    # Translucent-ish leaves + wind
  bark.gdshader
  water.gdshader
scenes/
  main_menu.tscn
  world.tscn
  ui/hud.tscn
  ui/pause_menu.tscn
scripts/
  terrain_generator.gd / vegetation_spawner.gd
  world.gd / player.gd / water_plane.gd / atmosphere_fx.gd
  ...
```

## Commercial use

**MIT License**. Keep the copyright notice. Godot Engine is also MIT -- see [CREDITS.md](CREDITS.md).

## Honest limitations (gaps vs true photoreal)

- Procedural noise materials != scanned PBR photogrammetry
- Primitive mesh foliage (multi-blob crowns, not leaf cards / Nanite trees)
- Single terrain chunk (no streaming / virtual texturing)
- Water is a shader plane (no FFT ocean, caustics, or shore foam cards)
- Fixed golden-hour lighting (no full day/night / weather system)
- No GI probes / SDFGI baked for the whole valley (relies on sky + SSIL)
- Grass tufts are capsules, not photo grass atlases
- Player is a simple capsule avatar

## Contributing

PRs welcome: Terrain3D, day cycle, better leaf cards, animals, quests, or a "Low" graphics preset scene.
