extends RefCounted
## Loads user-supplied reference face textures (jpg / b64 / parts / quarters).

const REF_FACE_PATH := "res://assets/player/reference_person.jpg"
const FACE_CROP := "res://assets/player/reference_person_face.jpg"
const FACE_CROP_B64 := "res://assets/player/reference_person_face.jpg.b64"


static func load_face() -> Texture2D:
	if ResourceLoader.exists(FACE_CROP):
		var cres := load(FACE_CROP)
		if cres is Texture2D:
			return cres as Texture2D
	if FileAccess.file_exists(FACE_CROP):
		var cimg := Image.new()
		if cimg.load(FACE_CROP) == OK:
			return ImageTexture.create_from_image(cimg)
	if FileAccess.file_exists(FACE_CROP_B64):
		var cf := FileAccess.open(FACE_CROP_B64, FileAccess.READ)
		if cf:
			var cb64 := cf.get_as_text().strip_edges()
			cf.close()
			var craw := Marshalls.base64_to_raw(cb64)
			var cimg2 := Image.new()
			if cimg2.load_jpg_from_buffer(craw) == OK:
				return ImageTexture.create_from_image(cimg2)
	if ResourceLoader.exists(REF_FACE_PATH):
		var res := load(REF_FACE_PATH)
		if res is Texture2D:
			return res as Texture2D
		if res is Image:
			return ImageTexture.create_from_image(res as Image)
	if FileAccess.file_exists(REF_FACE_PATH):
		var img := Image.new()
		if img.load(REF_FACE_PATH) == OK:
			return ImageTexture.create_from_image(img)
	var b64 := ""
	var b64_path := "res://assets/player/reference_person.jpg.b64"
	if FileAccess.file_exists(b64_path):
		var f := FileAccess.open(b64_path, FileAccess.READ)
		if f:
			b64 = f.get_as_text().strip_edges()
			f.close()
	elif FileAccess.file_exists("res://assets/player/reference_person.jpg.b64.part1"):
		var f1 := FileAccess.open("res://assets/player/reference_person.jpg.b64.part1", FileAccess.READ)
		var f2 := FileAccess.open("res://assets/player/reference_person.jpg.b64.part2", FileAccess.READ)
		if f1 and f2:
			b64 = f1.get_as_text().strip_edges() + f2.get_as_text().strip_edges()
			f1.close()
			f2.close()
	elif FileAccess.file_exists("res://assets/player/reference_person.jpg.b64.q1"):
		for qi in range(1, 5):
			var qp := "res://assets/player/reference_person.jpg.b64.q%d" % qi
			if not FileAccess.file_exists(qp):
				b64 = ""
				break
			var fq := FileAccess.open(qp, FileAccess.READ)
			if fq == null:
				b64 = ""
				break
			b64 += fq.get_as_text().strip_edges()
			fq.close()
	if b64 != "":
		var raw := Marshalls.base64_to_raw(b64)
		var img2 := Image.new()
		if img2.load_jpg_from_buffer(raw) == OK:
			return ImageTexture.create_from_image(img2)
	push_warning("Player: reference face texture missing at %s" % REF_FACE_PATH)
	return null
