# Credits

## Engine

- **Godot Engine** -- [godotengine.org](https://godotengine.org/) -- MIT License  
  Copyright (c) 2014-present Godot Engine contributors; Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.

## This project

- **Realistic Open World** -- MIT License (see [LICENSE](LICENSE))  
  Copyright (c) 2026 flips100

## Assets (commercial-safe)

All gameplay meshes, materials, shaders, lighting, terrain, vegetation, water, UI, procedural audio, and the project icon SVG are **original procedural / code-generated content** created for this repository. **No proprietary asset packs.** No third-party texture packs, 3D models, or audio files were imported.

| System | Source / license |
|--------|------------------|
| Terrain | `FastNoiseLite` heightmap + `terrain_blend.gdshader` + `NoiseTexture2D` (albedo / normal / roughness / macro) -- original, MIT with project |
| Vegetation | Primitive meshes + `bark.gdshader` / `foliage_wind.gdshader` + MultiMesh grass tufts -- original |
| Water | Subdivided `PlaneMesh` + `water.gdshader` -- original |
| Atmosphere | GPU particles (pollen, ground haze), volumetric fog -- original |
| Sky / lighting | `PhysicalSkyMaterial`, DirectionalLight3D (~5200K), ACES, SSAO, SSIL, SSR, auto-exposure -- Godot built-ins (MIT) |
| Audio | Runtime `AudioStreamGenerator` wind + code-generated WAV footsteps -- original |
| Icon | Hand-authored SVG (CC0 / public domain dedication for the icon artwork; project overall remains MIT) |

No external CC0 packs are bundled; none are required to build or ship commercially under MIT.
