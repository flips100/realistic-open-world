extends Node3D
## Higher-res procedural heightmap with multi-texture blend shader + dense collision.

const TERRAIN_SIZE := 512.0
const RESOLUTION := 192  # 193x193 vertices — denser mesh matching visuals
const HEIGHT_SCALE := 44.0
const NOISE_SEED := 42

var height_noise: FastNoiseLite
var detail_noise: FastNoiseLite
var ridge_noise: FastNoiseLite
var _heights: PackedFloat32Array = PackedFloat32Array()


func _ready() -> void:
	_setup_noise()
	_generate()


func _setup_noise() -> void:
	height_noise = FastNoiseLite.new()
	height_noise.seed = NOISE_SEED
	height_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	height_noise.frequency = 0.0042
	height_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	height_noise.fractal_octaves = 6
	height_noise.fractal_gain = 0.48
	height_noise.fractal_lacunarity = 2.05

	detail_noise = FastNoiseLite.new()
	detail_noise.seed = NOISE_SEED + 7
	detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	detail_noise.frequency = 0.022
	detail_noise.fractal_octaves = 4
	detail_noise.fractal_gain = 0.45

	ridge_noise = FastNoiseLite.new()
	ridge_noise.seed = NOISE_SEED + 19
	ridge_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	ridge_noise.frequency = 0.008
	ridge_noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	ridge_noise.fractal_octaves = 3


func get_height_at(world_x: float, world_z: float) -> float:
	var n := height_noise.get_noise_2d(world_x, world_z)
	var d := detail_noise.get_noise_2d(world_x, world_z) * 0.14
	var r := absf(ridge_noise.get_noise_2d(world_x, world_z)) * 0.22
	# Soft bowl so edges rise into mountains (natural bounds)
	var nx := world_x / (TERRAIN_SIZE * 0.5)
	var nz := world_z / (TERRAIN_SIZE * 0.5)
	var edge := clampf((nx * nx + nz * nz) - 0.52, 0.0, 1.0)
	var mountain := edge * edge * 58.0
	return (n + d + r) * HEIGHT_SCALE + mountain + 1.5


func get_surface_type(world_x: float, world_z: float) -> String:
	## Used by footsteps: grass / dirt / rock
	var h := get_height_at(world_x, world_z)
	var dx := get_height_at(world_x + 1.0, world_z) - get_height_at(world_x - 1.0, world_z)
	var dz := get_height_at(world_x, world_z + 1.0) - get_height_at(world_x, world_z - 1.0)
	var slope := sqrt(dx * dx + dz * dz)
	if slope > 7.0 or h > 36.0:
		return "rock"
	if h < 7.0:
		return "dirt"
	return "grass"


func _make_noise_tex(seed_v: int, freq: float, w: int = 512, as_normal: bool = false) -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	n.seed = seed_v
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX
	n.frequency = freq
	n.fractal_type = FastNoiseLite.FRACTAL_FBM
	n.fractal_octaves = 5
	var tex := NoiseTexture2D.new()
	tex.noise = n
	tex.width = w
	tex.height = w
	tex.seamless = true
	tex.generate_mipmaps = true
	if as_normal:
		tex.as_normal_map = true
		tex.bump_strength = 8.0
	return tex


func _generate() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var step := TERRAIN_SIZE / float(RESOLUTION)
	var half := TERRAIN_SIZE * 0.5
	var verts_per_side := RESOLUTION + 1

	_heights.resize(verts_per_side * verts_per_side)

	for z in range(verts_per_side):
		for x in range(verts_per_side):
			var wx := -half + x * step
			var wz := -half + z * step
			_heights[z * verts_per_side + x] = get_height_at(wx, wz)

	for z in range(RESOLUTION):
		for x in range(RESOLUTION):
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
	mi.material_override = _build_terrain_material()
	add_child(mi)

	# Dense collision matching visual mesh
	var body := StaticBody3D.new()
	body.name = "TerrainBody"
	body.collision_layer = 1
	body.collision_mask = 0
	var col := CollisionShape3D.new()
	col.shape = mesh.create_trimesh_shape()
	body.add_child(col)
	add_child(body)


func _build_terrain_material() -> ShaderMaterial:
	var shader := load("res://shaders/terrain_blend.gdshader") as Shader
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("grass_albedo", _make_noise_tex(101, 0.06))
	mat.set_shader_parameter("dirt_albedo", _make_noise_tex(202, 0.09))
	mat.set_shader_parameter("rock_albedo", _make_noise_tex(303, 0.05))
	mat.set_shader_parameter("cliff_albedo", _make_noise_tex(404, 0.04))
	mat.set_shader_parameter("detail_normal", _make_noise_tex(505, 0.12, 512, true))
	mat.set_shader_parameter("uv_scale", 42.0)
	mat.set_shader_parameter("normal_strength", 0.9)
	mat.set_shader_parameter("roughness_base", 0.9)
	return mat


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
	var h := p.y
	var dx := get_height_at(p.x + 1.0, p.z) - get_height_at(p.x - 1.0, p.z)
	var dz := get_height_at(p.x, p.z + 1.0) - get_height_at(p.x, p.z - 1.0)
	var slope := sqrt(dx * dx + dz * dz)

	var grass := Color(0.30, 0.50, 0.24)
	var dirt := Color(0.44, 0.33, 0.19)
	var rock := Color(0.46, 0.46, 0.49)
	var snow := Color(0.93, 0.95, 0.97)

	var c: Color
	if slope > 8.0 or h > 40.0:
		c = rock.lerp(snow, clampf((h - 40.0) / 22.0, 0.0, 1.0))
	elif h < 6.5:
		c = dirt.lerp(grass, clampf(h / 6.5, 0.0, 1.0))
	else:
		c = grass.lerp(dirt, clampf(slope / 10.0, 0.0, 0.55))
		if h > 30.0:
			c = c.lerp(rock, clampf((h - 30.0) / 14.0, 0.0, 1.0))
	var shade := 0.88 + detail_noise.get_noise_2d(p.x, p.z) * 0.14
	return Color(c.r * shade, c.g * shade, c.b * shade, 1.0)
