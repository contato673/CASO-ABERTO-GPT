extends RefCounted

const MODELS := [
	preload("res://assets/survivors_hcg/male_civilian.png"),
	preload("res://assets/survivors_hcg/female_civilian.png"),
	preload("res://assets/survivors_hcg/male_sheriff.png"),
	preload("res://assets/survivors_hcg/female_sheriff.png"),
	preload("res://assets/survivors_hcg/male_fbi.png"),
	preload("res://assets/survivors_hcg/female_fbi.png"),
]
const NAMES := ["Civil 1", "Civil 2", "Patrulha 1", "Patrulha 2", "Agente 1", "Agente 2", "Clássico"]
const FRAME := Vector2(64,80)
const WALK_FRAMES := 7


static func player_atlas(model: int, shirt: Color, skin: Color, pants: Color) -> ImageTexture:
	var source: Image = MODELS[model].get_image()
	var atlas := Image.create_empty(int(FRAME.x * 4),400,false,Image.FORMAT_RGBA8)
	for face in 2:
		for frame in WALK_FRAMES + 1:
			var rect := Rect2i(frame * 64,face * 80,64,80)
			var pose := source.get_region(rect)
			pose.convert(Image.FORMAT_RGBA8)
			pose.resize(32,40,Image.INTERPOLATE_NEAREST)
			_recolor_pose(pose,model,shirt,skin,pants)
			# Broaden the silhouette at the small gameplay scale while keeping its foot position.
			pose.resize(40,40,Image.INTERPOLATE_NEAREST)
			atlas.blit_rect(pose,Rect2i(4,0,32,40),Vector2i(frame * 32,320 + face * 40))
	return ImageTexture.create_from_image(atlas)


static func _recolor_pose(pose: Image, model: int, shirt: Color, skin: Color, pants: Color) -> void:
	for y in range(5,34):
		for x in range(6,26):
			var pixel := pose.get_pixel(x,y)
			if pixel.a < .5:
				continue
			var edge := absf(x-15.5)
			var warm := pixel.r > pixel.g * 1.08 and pixel.r > pixel.b * 1.18
			var tint := Color.TRANSPARENT
			if y < 12 and warm:
				tint = skin
			elif y >= 23 and edge < 5.5 and (not warm or model == 1):
				tint = pants
			elif y in range(13,23) and edge < 5.5:
				tint = shirt
			if tint.a > .5:
				var brightness := pixel.get_luminance()
				pose.set_pixel(x,y,tint.lerp(Color.WHITE,brightness*.24).darkened(.62*(1.0-brightness)))
