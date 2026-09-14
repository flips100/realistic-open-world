extends Node3D
## Procedural heightmap terrain with grass/dirt/rock coloring and collision.

const TERRAIN_SIZE := 512.0
const RESOLUTION := 128  # vertices per side (129x129 grid)
const HEIGHT_SCALE := 42.0
const NOISE_SEED := 42

var height_noise: FastNoiseLite
var detail_noise: FastNoiseLite
var _heights: PackedFloat32Array = PackedFloat32Array()


func _ready() -> void:
	_setup_noise()
	_generate()


func _setup_noise() -> void:
	height_noise = FastNoiseLite.new()
	height_noise.seed = NOISE_SEED
	height_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	height_noise.frequency = 0.0045
	height_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	height_noise.fractal_octaves = 5
	height_noise.fractal_gain = 0.5
	height_noise.fractal_lacunarity = 2.0

	detail_noise = FastNoiseLite.new()
	detail_noise.seed = NOISE_SEED + 7
	detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	detail_noise.frequency = 0.02
	detail_noise.fractal_octaves = 3


func get_height_at(world_x: float, world_z: float) -> float:
	var n := height_noise.get_noise_2d(world_x, world_z)
	var d := detail_noise.get_noise_2d(world_x, world_z) * 0.15
	# Soft bowl so edges rise into mountains (natural bounds)
	var nx := world_x / (TERRAIN_SIZE * 0.5)
	var nz := world_z / (TERRAIN_SIZE * 0.5)
	var edge := clampf((nx * nx + nz * nz) - 0.55, 0.0, 1.0)
	var mountain := edge * edge * 55.0
	return (n + d) * HEIGHT_SCALE + mountain + 2.0


func _generate() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var step := TERRAIN_SIZE / float(RESOLUTION)
	var half := TERRAIN_SIZE * 0.5
	var verts_per_side := RESOLUTION + 1

	_heights.resize(verts_per_side * verts_per_side)

	# Build height grid
	for z in range(verts_per_side):
		for x in range(verts_per_side):
			var wx := -half + x * step
			var wz := -half + z * step
			var h := get_height_at(wx, wz)
			_heights[z * verts_per_side + x] = h

	# Triangulate with vertex colors by slope/height
	for z in range(RESOLUTION):
		for x in range(RESOLUTION):
			var i00 := z * verts_per_side + x
			var i10 := i00 + 1
			var i01 := i00 + verts_per_side
			var i11 := i01 + 1

			var p00 := _vert(x, z, step, half)
			var p10 := _vert(x + 1, z, step, half)
			var p01 := _vert(x, z + 1, step, half)
			var p11 := _vert(x + 1, z + 1, step, half)

			_add_tri(st, p00, p01, p10)
			_add_tri(st, p10, p01, p11)

	st.generate_normals()
	st.generate_tangents()
	var mesh := st.commit()

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.name = "TerrainMesh"

	# Triplanar-ish look via vertex colors + slight roughness variation
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.92
	mat.metallic = 0.0
	# Subtle noise albedo via procedural NoiseTexture2D (commercial-safe)
	var noise_tex := NoiseTexture2D.new()
	var n := FastNoiseLite.new()
	n.frequency = 0.08
	n.seed = 99
	noise_tex.noise = n
	noise_tex.width = 256
	noise_tex.height = 256
	noise_tex.seamless = true
	mat.albedo_texture = noise_tex
	mat.uv1_scale = Vector3(48, 48, 48)
	mat.uv1_triplanar = true
	mi.material_override = mat
	add_child(mi)

	# Collision
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var col := CollisionShape3D.new()
	col.shape = mesh.create_trimesh_shape()
	body.add_child(col)
	add_child(body)


func _vert(x: int, z: int, step: float, half: float) -> Vector3:
	var wx := -half + x * step
	var wz := -half + z * step
	var h := _heights[z * (RESOLUTION + 1) + x]
	return Vector3(wx, h, wz)


func _add_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.set_color(_color_for(a))
	st.set_uv(Vector2(a.x, a.z) * 0.02)
	st.add_vertex(a)
	st.set_color(_color_for(b))
	st.set_uv(Vector2(b.x, b.z) * 0.02)
	st.add_vertex(b)
	st.set_color(_color_for(c))
	st.set_uv(Vector2(c.x, c.z) * 0.02)
	st.add_vertex(c)


func _color_for(p: Vector3) -> Color:
	# Slope estimate from noise gradient
	var h := p.y
	var dx := get_height_at(p.x + 1.0, p.z) - get_height_at(p.x - 1.0, p.z)
	var dz := get_height_at(p.x, p.z + 1.0) - get_height_at(p.x, p.z - 1.0)
	var slope := sqrt(dx * dx + dz * dz)

	var grass := Color(0.28, 0.48, 0.22)
	var dirt := Color(0.42, 0.32, 0.18)
	var rock := Color(0.45, 0.45, 0.48)
	var snow := Color(0.92, 0.94, 0.96)

	var c: Color
	if slope > 8.0 or h > 38.0:
		c = rock.lerp(snow, clampf((h - 38.0) / 25.0, 0.0, 1.0))
	elif h < 6.0:
		c = dirt.lerp(grass, clampf(h / 6.0, 0.0, 1.0))
	else:
		c = grass.lerp(dirt, clampf(slope / 10.0, 0.0, 0.6))
		if h > 28.0:
			c = c.lerp(rock, clampf((h - 28.0) / 15.0, 0.0, 1.0))
	# Mild brightness variation
	var shade := 0.9 + detail_noise.get_noise_2d(p.x, p.z) * 0.12
	return Color(c.r * shade, c.g * shade, c.b * shade, 1.0)
