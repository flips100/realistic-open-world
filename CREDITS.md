# Credits

## Engine

- **Godot Engine** — [godotengine.org](https://godotengine.org/) — MIT License  
  Copyright (c) 2014-present Godot Engine contributors; Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.

## This project

- **Realistic Open World** — MIT License (see [LICENSE](LICENSE))  
  Copyright (c) 2026 flips100

## Assets

All gameplay meshes, materials, shaders, lighting, terrain, vegetation, water, UI, procedural audio, and the project icon SVG are **original procedural / code-generated content** created for this repository. No third-party texture packs, 3D models, or audio files were imported.

- Terrain: `FastNoiseLite` heightmap + `terrain_blend.gdshader` + `NoiseTexture2D` (albedo/normals)
- Vegetation: primitive meshes + `bark.gdshader` / `foliage_wind.gdshader`
- Water: subdivided `PlaneMesh` + `water.gdshader`
- Atmosphere: GPU particles (pollen), volumetric fog, procedural sky
- Audio: runtime `AudioStreamGenerator` wind loop + tiny WAV footstep buffers generated in code
- Sky / lighting: `ProceduralSkyMaterial`, DirectionalLight3D (golden-hour), ACES tonemap, SSAO, SSR
- Icon: hand-authored SVG (CC0 / public domain dedication for the icon artwork; project overall remains MIT)

No CC0 external packs are bundled; none are required.
