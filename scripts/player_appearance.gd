extends RefCounted
## Builds prefect-blazer humanoid meshes matching assets/player/reference_person.jpg

const SKIN := Color(0.28, 0.16, 0.10)
const SKIN_DARK := Color(0.18, 0.10, 0.06)
const HAIR := Color(0.06, 0.04, 0.03)
const BLAZER := Color(0.22, 0.38, 0.62)
const BLAZER_SHADOW := Color(0.14, 0.26, 0.45)
const SHIRT := Color(0.72, 0.82, 0.92)
const TIE_BASE := Color(0.08, 0.08, 0.10)
const TROUSERS := Color(0.12, 0.12, 0.14)
const SHOES := Color(0.05, 0.04, 0.04)


static func mat(color: Color, rough: float = 0.78, metallic: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metallic
	return m


static func add_part(parent: Node3D, mesh: Mesh, material: Material, pos: Vector3, name_s: String = "", scale_v: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	if name_s != "":
		mi.name = name_s
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	mi.scale = scale_v
	parent.add_child(mi)
	return mi


static func polka_tie_texture() -> ImageTexture:
	var img := Image.create(64, 128, false, Image.FORMAT_RGBA8)
	img.fill(TIE_BASE)
	for y in range(128):
		for x in range(64):
			var cx := (x % 16) - 8
			var cy := (y % 16) - 8
			if cx * cx + cy * cy < 9:
				img.set_pixel(x, y, Color(0.92, 0.92, 0.94, 1))
	return ImageTexture.create_from_image(img)


static func crest_texture() -> ImageTexture:
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(128):
		for x in range(128):
			var nx := (float(x) - 64.0) / 52.0
			var ny := (float(y) - 58.0) / 58.0
			var in_top := ny > -0.85 and ny < 0.15 and absf(nx) < 0.72
			var in_bot := ny >= 0.15 and ny < 0.95 and absf(nx) < (0.72 - (ny - 0.15) * 0.85)
			if not (in_top or in_bot):
				continue
			var edge := absf(nx) > 0.62 or ny < -0.78 or ny > 0.88
			if edge:
				img.set_pixel(x, y, Color(0.12, 0.12, 0.14, 1))
			else:
				img.set_pixel(x, y, Color(0.94, 0.94, 0.96, 1))
			if absf(nx) < 0.12 or (ny > -0.15 and ny < 0.08):
				if absf(nx) < 0.55 and ny > -0.55 and ny < 0.55:
					img.set_pixel(x, y, Color(0.75, 0.12, 0.14, 1))
			if ny > -0.78 and ny < -0.52 and absf(nx) < 0.58:
				img.set_pixel(x, y, Color(0.95, 0.95, 0.97, 1))
				var lx := int((nx + 0.55) * 10.0)
				if lx % 2 == 0 and ny > -0.72 and ny < -0.58:
					img.set_pixel(x, y, Color(0.08, 0.08, 0.1, 1))
	return ImageTexture.create_from_image(img)


## Returns {visual, left_arm, right_arm, left_leg, right_leg}
static func build_body(host: Node3D, face_tex: Texture2D) -> Dictionary:
	var visual := Node3D.new()
	visual.name = "Visual"
	host.add_child(visual)

	var skin_mat := mat(SKIN, 0.68)
	var skin_dark_mat := mat(SKIN_DARK, 0.72)
	var hair_mat := mat(HAIR, 0.92)
	var blazer_mat := mat(BLAZER, 0.82)
	var blazer_dark := mat(BLAZER_SHADOW, 0.85)
	var shirt_mat := mat(SHIRT, 0.75)
	var pants_mat := mat(TROUSERS, 0.88)
	var shoe_mat := mat(SHOES, 0.55, 0.15)

	var torso := BoxMesh.new()
	torso.size = Vector3(0.62, 0.78, 0.36)
	add_part(visual, torso, blazer_mat, Vector3(0, 1.18, 0), "Blazer")

	var lapel_l := BoxMesh.new()
	lapel_l.size = Vector3(0.12, 0.42, 0.04)
	add_part(visual, lapel_l, blazer_dark, Vector3(-0.14, 1.35, -0.18), "LapelL")
	var lapel_r := BoxMesh.new()
	lapel_r.size = Vector3(0.12, 0.42, 0.04)
	add_part(visual, lapel_r, blazer_dark, Vector3(0.14, 1.35, -0.18), "LapelR")

	var shirt := BoxMesh.new()
	shirt.size = Vector3(0.28, 0.35, 0.08)
	add_part(visual, shirt, shirt_mat, Vector3(0, 1.38, -0.16), "ShirtFront")
	var col_l := BoxMesh.new()
	col_l.size = Vector3(0.14, 0.06, 0.1)
	add_part(visual, col_l, shirt_mat, Vector3(-0.1, 1.55, -0.14), "CollarL")
	var col_r := BoxMesh.new()
	col_r.size = Vector3(0.14, 0.06, 0.1)
	add_part(visual, col_r, shirt_mat, Vector3(0.1, 1.55, -0.14), "CollarR")

	var tie_mat := StandardMaterial3D.new()
	tie_mat.albedo_texture = polka_tie_texture()
	tie_mat.albedo_color = Color(1, 1, 1)
	tie_mat.roughness = 0.7
	tie_mat.uv1_scale = Vector3(1, 2, 1)
	var tie_knot := BoxMesh.new()
	tie_knot.size = Vector3(0.1, 0.1, 0.06)
	add_part(visual, tie_knot, tie_mat, Vector3(0, 1.48, -0.2), "TieKnot")
	var tie_blade := BoxMesh.new()
	tie_blade.size = Vector3(0.09, 0.42, 0.04)
	add_part(visual, tie_blade, tie_mat, Vector3(0, 1.22, -0.2), "TieBlade")

	var crest_mat := StandardMaterial3D.new()
	crest_mat.albedo_texture = crest_texture()
	crest_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	crest_mat.roughness = 0.65
	crest_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var crest := PlaneMesh.new()
	crest.size = Vector2(0.16, 0.18)
	var crest_mi := add_part(visual, crest, crest_mat, Vector3(0.22, 1.28, -0.19), "PrefectCrest")
	crest_mi.rotation_degrees = Vector3(90, 0, 0)

	var hem := BoxMesh.new()
	hem.size = Vector3(0.64, 0.08, 0.38)
	add_part(visual, hem, blazer_dark, Vector3(0, 0.8, 0), "BlazerHem")

	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.17
	head_mesh.height = 0.34
	add_part(visual, head_mesh, skin_mat, Vector3(0, 1.72, 0), "Head")

	var face_mat := StandardMaterial3D.new()
	if face_tex:
		face_mat.albedo_texture = face_tex
		face_mat.albedo_color = Color(1, 1, 1)
	else:
		face_mat.albedo_color = SKIN
	face_mat.roughness = 0.7
	face_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	face_mat.uv1_scale = Vector3(1.15, 0.85, 1)
	face_mat.uv1_offset = Vector3(-0.08, 0.02, 0)
	var face_plane := PlaneMesh.new()
	face_plane.size = Vector2(0.26, 0.3)
	var face_mi := add_part(visual, face_plane, face_mat, Vector3(0, 1.72, -0.155), "FaceCard")
	face_mi.rotation_degrees = Vector3(90, 0, 0)

	var ear := SphereMesh.new()
	ear.radius = 0.045
	ear.height = 0.08
	add_part(visual, ear, skin_dark_mat, Vector3(-0.17, 1.72, 0.02), "EarL", Vector3(0.6, 1.0, 0.8))
	var ear_r := SphereMesh.new()
	ear_r.radius = 0.045
	ear_r.height = 0.08
	add_part(visual, ear_r, skin_dark_mat, Vector3(0.17, 1.72, 0.02), "EarR", Vector3(0.6, 1.0, 0.8))

	var hair_cap := SphereMesh.new()
	hair_cap.radius = 0.185
	hair_cap.height = 0.28
	var hair_mi := add_part(visual, hair_cap, hair_mat, Vector3(0, 1.82, 0.02), "HairCap")
	hair_mi.scale = Vector3(1.08, 0.72, 1.1)
	for i in range(6):
		var nub := SphereMesh.new()
		nub.radius = 0.055
		nub.height = 0.09
		var a := float(i) / 6.0 * TAU
		add_part(visual, nub, hair_mat, Vector3(cos(a) * 0.1, 1.88 + sin(a * 2.0) * 0.02, 0.04 + sin(a) * 0.08), "HairNub%d" % i)

	var beard := SphereMesh.new()
	beard.radius = 0.12
	beard.height = 0.14
	var beard_mi := add_part(visual, beard, hair_mat, Vector3(0, 1.58, -0.1), "Beard")
	beard_mi.scale = Vector3(1.05, 0.55, 0.75)
	var stash := BoxMesh.new()
	stash.size = Vector3(0.12, 0.035, 0.04)
	add_part(visual, stash, hair_mat, Vector3(0, 1.64, -0.17), "Mustache")

	var neck := CylinderMesh.new()
	neck.top_radius = 0.07
	neck.bottom_radius = 0.09
	neck.height = 0.12
	add_part(visual, neck, skin_mat, Vector3(0, 1.58, 0), "Neck")

	var left_arm := Node3D.new()
	left_arm.name = "LeftArm"
	left_arm.position = Vector3(-0.4, 1.42, 0)
	visual.add_child(left_arm)
	var la := CapsuleMesh.new()
	la.radius = 0.08
	la.height = 0.58
	add_part(left_arm, la, blazer_mat, Vector3(0, -0.3, 0), "LSleeve")
	var lh := SphereMesh.new()
	lh.radius = 0.07
	add_part(left_arm, lh, skin_mat, Vector3(0, -0.58, 0), "LHand")

	var right_arm := Node3D.new()
	right_arm.name = "RightArm"
	right_arm.position = Vector3(0.4, 1.42, 0)
	visual.add_child(right_arm)
	var ra := CapsuleMesh.new()
	ra.radius = 0.08
	ra.height = 0.58
	add_part(right_arm, ra, blazer_mat, Vector3(0, -0.3, 0), "RSleeve")
	var rh := SphereMesh.new()
	rh.radius = 0.07
	add_part(right_arm, rh, skin_mat, Vector3(0, -0.58, 0), "RHand")

	var left_leg := Node3D.new()
	left_leg.name = "LeftLeg"
	left_leg.position = Vector3(-0.14, 0.78, 0)
	visual.add_child(left_leg)
	var ll := CapsuleMesh.new()
	ll.radius = 0.095
	ll.height = 0.72
	add_part(left_leg, ll, pants_mat, Vector3(0, -0.36, 0), "LTrouser")
	var lb := BoxMesh.new()
	lb.size = Vector3(0.17, 0.1, 0.3)
	add_part(left_leg, lb, shoe_mat, Vector3(0, -0.74, -0.04), "LShoe")

	var right_leg := Node3D.new()
	right_leg.name = "RightLeg"
	right_leg.position = Vector3(0.14, 0.78, 0)
	visual.add_child(right_leg)
	var rl := CapsuleMesh.new()
	rl.radius = 0.095
	rl.height = 0.72
	add_part(right_leg, rl, pants_mat, Vector3(0, -0.36, 0), "RTrouser")
	var rb := BoxMesh.new()
	rb.size = Vector3(0.17, 0.1, 0.3)
	add_part(right_leg, rb, shoe_mat, Vector3(0, -0.74, -0.04), "RShoe")

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.32
	shape.height = 1.55
	collision.shape = shape
	collision.position.y = 0.88
	host.add_child(collision)

	return {
		"visual": visual,
		"left_arm": left_arm,
		"right_arm": right_arm,
		"left_leg": left_leg,
		"right_leg": right_leg,
	}
