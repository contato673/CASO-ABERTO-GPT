extends Node3D

const ORIGIN := Vector3(120.0, 0.0, 30000.0)
const ART := "res://assets/interiores/"
const LOCAL := "res://assets/interiores_locais/"
const FRAME := Vector2i(96, 112)
const COLOR := Color("#efe3bf")
const ROOM_NAMES := {"home":"Residência", "retail":"Comércio", "pharmacy":"Farmácia",
	"school":"Escola", "industry":"Indústria", "police":"Delegacia", "office":"Escritório",
	"hotel":"Hotel", "civic":"Edifício público"}
# Model, room position, visual height, item groups and optional interaction.
const FURNITURE := {
	"home":[["sofa",2.2,2.0,1.28,"cloth","seat"],["coffee",2.3,4.0,.76,"manual"],
		["tv",4.2,1.8,.92,"parts"],["plant",.9,3.6,1.1,""],["vacuum",4.5,4.9,1.02,""],
		["fridge",8.6,1.3,1.75,"water"],["cupboard",6.8,1.3,1.59,"food"],
		["kitchen_sink",10.0,2.7,1.19,"","wash"],["stove",7.0,3.0,1.05,""],
		["table",8.7,4.5,1.04,"food"],["chair",9.8,4.3,.84,"","seat"],
		["bed",2.1,8.2,1.0,"cloth","bed"],["wardrobe",4.0,7.4,1.62,"clothes"],
		["nightstand",.9,8.0,.85,"manual"],["sink",7.1,7.1,1.11,"","wash"],
		["medicine",8.7,7.1,1.35,"med"],["bath",9.7,8.7,1.02,""],
		["washer",6.9,8.9,1.0,"cloth"],["basket",7.9,9.3,.58,"cloth"],["trash",10.6,6.2,.65,""]],
	"retail":[["fridge",1.4,1.6,1.7,"water"],["shelf",3.5,1.6,1.42,"food"],
		["shelf",6.1,1.6,1.42,"food"],["shelf",8.9,1.6,1.42,"tools"],["desk",1.5,4.7,1.12,"manual","survey"],
		["fridge",10.3,3.9,1.65,"water"],["shelf",4.0,5.1,1.36,"clothes"],["parcel",7.8,5.1,.62,"parts"],
		["sink",1.4,8.0,1.18,"","wash"],["medicine",3.1,8.1,1.48,"med"],["crate",9.5,8.0,1.04,"tools"],["trash",10.6,6.5,.8,""]],
	"pharmacy":[["medicine",1.5,1.4,1.7,"med"],["medicine",3.6,1.4,1.7,"med"],["medicine",7.4,1.4,1.6,"med"],
		["fridge",9.8,1.5,1.68,"water"],["desk",2.1,4.0,1.12,"manual","survey"],["shelf",5.3,4.2,1.34,"med"],
		["shelf",8.4,4.6,1.42,"med"],["sink",1.5,8.1,1.23,"","wash"],
		["medical_case",3.1,8.3,.81,"med"],["bed",8.1,8.4,1.13,"cloth","bed"]],
	"school":[["chalk",1.5,1.2,1.24,""],["teacher",3.5,1.5,1.12,"manual","survey"],
		["student",1.8,3.3,.95,""],["student",3.8,3.3,.95,""],["student",1.8,5.1,.95,""],["student",3.8,5.1,.95,""],
		["cubbies",8.6,1.8,1.58,"manual"],["table",8.3,4.4,1.28,"food"],
		["fridge",10.5,3.3,1.62,"water"],["medicine",2.5,8.4,1.6,"med"],["sink",7.9,8.2,1.16,"","wash"]],
	"industry":[["crate",1.4,1.6,1.16,"tools"],["crate",3.5,1.5,1.22,"parts"],
		["drum",8.1,1.6,1.12,"fuel"],["drum",10.2,2.6,1.18,"fuel"],["generator",1.6,5.0,1.32,"parts"],
		["desk",4.0,5.2,1.2,"manual","survey"],["crate",8.3,5.0,1.25,"tools"],["rubble",9.6,6.6,.32,""],
		["medicine",1.5,8.4,1.56,"med"],["sink",3.2,8.4,1.16,"","wash"],["barricade",9.5,8.3,1.06,""]],
	"police":[["reception",2.0,1.7,1.3,"manual","survey"],["office_chair",4.1,1.5,.97,"","seat"],
		["evidence",9.1,1.8,1.8,"tools"],["crate",10.2,3.4,1.04,"tools"],["interrogation",2.4,4.7,1.25,"manual"],
		["radio",3.7,4.1,.55,"parts"],["barricade",8.5,5.0,1.01,""],
		["medicine",2.4,8.2,1.51,"med"],["sink",8.5,8.3,1.22,"","wash"]],
	"office":[["desk",2.2,1.7,1.24,"manual","survey"],["office_chair",4.0,1.6,1.05,"","seat"],
		["shelf",8.2,1.7,1.56,"parts"],["parcel",10.1,2.1,.65,"parts"],["desk",8.4,4.4,1.17,"manual"],
		["plant",1.2,4.6,1.13,""],["sofa",3.0,4.6,1.13,"cloth","seat"],["medicine",2.5,8.4,1.43,"med"],
		["fridge",8.0,8.1,1.62,"water"],["sink",10.0,8.1,1.25,"","wash"]],
	"hotel":[["desk",2.2,1.7,1.25,"manual","survey"],["sofa",3.6,4.4,1.19,"cloth","seat"],
		["bed",8.4,2.5,1.1,"cloth","bed"],["nightstand",10.2,1.6,.88,"manual"],
		["wardrobe",1.7,8.3,1.73,"clothes"],["bed",3.8,8.3,1.06,"cloth","bed"],
		["medicine",8.7,8.3,1.42,"med"],["sink",10.4,8.0,1.18,"","wash"]],
	"civic":[["desk",2.0,1.6,1.21,"manual","survey"],["shelf",3.7,1.6,1.4,"manual"],
		["table",8.7,2.6,1.01,"parts"],["shelf",10.2,1.8,1.57,"parts"],
		["sofa",2.3,4.7,1.17,"cloth","seat"],["parcel",9.8,5.2,.72,"parts"],
		["medicine",2.4,8.4,1.5,"med"],["fridge",8.2,8.5,1.67,"water"],["sink",10.2,8.2,1.18,"","wash"]],
}
const PARTITIONS := {
	"home":[[5.43,0,5.43,2.4],[5.43,4.04,5.43,5.5],[0,6.35,3.55,6.35],[6.85,6.35,11.6,6.35]],
	"hotel":[[5.43,0,5.43,2.35],[5.43,4.04,5.43,5.5],[0,6.35,3.55,6.35],[6.85,6.35,11.6,6.35]],
	"retail":[[0,6.36,3.3,6.36],[7.8,6.9,11.6,6.9],[3.8,6.36,3.8,7.65]],
	"pharmacy":[[0,6.35,3.55,6.35],[6.85,6.35,11.6,6.35],[5.42,0,5.42,2.7]],
	"school":[[5.35,0,5.35,2.35],[5.35,4.05,5.35,5.65],[0,6.55,3.9,6.55],[7.1,6.55,11.6,6.55]],
	"industry":[[0,6.52,4.62,6.52],[8.1,7.1,11.6,7.1]],
	"police":[[5.51,0,5.51,2.5],[5.51,4.1,5.51,5.6],[0,6.4,3.5,6.4],[7.0,6.4,11.6,6.4]],
	"office":[[5.5,0,5.5,2.45],[5.5,4.1,5.5,5.65],[0,6.3,3.3,6.3],[7.1,7.15,11.6,7.15]],
	"civic":[[5.5,0,5.5,2.45],[0,6.6,3.65,6.6],[7.5,6.6,11.6,6.6]],
}
const FALLBACK := {"student":"table", "teacher":"desk", "chalk":"tv","cubbies":"shelf","evidence":"wardrobe",
	"reception":"desk","interrogation":"table","generator":"washer","drum":"basket","crate":"parcel",
	"rubble":"trash","medical_case":"medicine","barricade":"coffee"}
const ITEM_ZONE := {"water":"water","dirty_water":"water","food":"food","med":"med","bandage":"med",
	"cloth":"cloth","parts":"parts","manual":"manual","ammo":"tools","pistol":"tools","knife":"tools",
	"bat":"tools","crowbar":"tools","fuel":"fuel","wood":"parts","jacket":"clothes","coat":"clothes","shirt":"clothes"}

var game
var life
var active := false
var site := {}
var kind := ""
var floor_index := 0
var levels := 1
var layout_id := 0
var mirrored := false
var span := Vector2(11.6,10.6)
var pos := Vector2(5.6, 9.75)
var scene: Node3D
var actor: Sprite3D
var held: Sprite3D
var obstacles: Array[Rect2] = []
var floor_shape := PackedVector2Array()
var sockets: Array[Dictionary] = []
var actions: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var art := {}
var avatar_art := {}
var phase := 0.0
var facing := 7
var anim_key := ""
var posture := ""
var posture_at := Vector2.ZERO
var home_pawn: Sprite3D
var home_hand: Sprite3D
var home_previous := Vector2.INF
var home_phase := 0.0
var home_facing := 7
var action_until := 0.0
var hud: CanvasLayer
var title: Label
var hint: Label
var exit: Button

func setup(city: Node, survival: Node) -> void:
	game = city
	life = survival
	position = ORIGIN
	hud = CanvasLayer.new()
	hud.layer = 6
	add_child(hud)
	title = Label.new()
	title.position = Vector2(12,86)
	title.add_theme_font_size_override("font_size",21)
	game._label_bg(title, 10, 6)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(title)
	hint = Label.new()
	hint.position = Vector2(12,128)
	hint.add_theme_font_size_override("font_size",16)
	game._label_bg(hint, 9, 5)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(hint)
	exit = Button.new()
	exit.text = "Sair"
	exit.custom_minimum_size = Vector2(76,52)
	exit.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	hud.add_child(exit)
	exit.pressed.connect(game._exit_interior)
	hud.hide()

func classify(place: Dictionary) -> String:
	var name := (str(place.get("name","")) + " " + str(place.get("building_use",""))).to_lower()
	if str(place["id"]) == "central" or "delegacia" in name or "polícia" in name or "police" in name:
		return "police"
	if "escola" in name or "colégio" in name or "school" in name:
		return "school"
	if "indústria" in name or "industrial" in name or "warehouse" in name or "galpão" in name:
		return "industry"
	if "hotel" in name:
		return "hotel"
	var category: String = life._kind(place)
	if category == "residence" or str(place["id"]) == "grand_park" or "residencial" in name:
		return "home"
	if category == "pharmacy":
		return "pharmacy"
	if category in ["supermarket","mall"] or "shop" in str(place["id"]):
		return "retail"
	if "correios" in name or "comercial" in name or float(place.get("height",0)) > 18.0:
		return "office"
	return "civic"

func enter(place: Dictionary) -> void:
	active = true
	site = place.duplicate()
	kind = classify(site)
	layout_id = int(hash(str(site["id"])))
	mirrored = layout_id % 2 == 0
	span = Vector2(11.6 + float(layout_id % 3) * .6, 10.6 + float((layout_id / 7) as int % 3) * .5)
	var height := float(site.get("height", 3.0))
	levels = 1 if height < 6.2 or site["id"] == "mercado" or (kind == "industry" and height < 9.0) else clampi(floori(height / 3.0), 2, 32)
	floor_index = 0
	pos = _mapped(Vector2(5.7,span.y-.86))
	hud.show()
	_build_floor()

func leave() -> void:
	active = false
	hud.hide()
	if is_instance_valid(scene):
		scene.queue_free()
	scene = null
	actor = null
	held = null
	pickups.clear()
	actions.clear()
	sockets.clear()
	obstacles.clear()
	if avatar_art.size() > 12:
		avatar_art.clear()
	art.clear()

func _mapped(at: Vector2) -> Vector2:
	return Vector2(span.x-at.x,at.y) if mirrored else at

func _v(at: Vector2, height := 0.0) -> Vector3:
	return Vector3(at.x,height,at.y)

func _box(at: Vector3, size: Vector3, tint: Color, wall_finish := false) -> void:
	var part := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 1
	if wall_finish and ResourceLoader.exists(LOCAL + "wall_panels.png"):
		material.albedo_texture = load(LOCAL + "wall_panels.png")
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		material.uv1_triplanar = true
		material.uv1_scale = Vector3(1.35,1.35,1.35)
		material.albedo_color = tint.lightened(.4)
	mesh.material = material
	part.mesh = mesh
	part.position = at
	scene.add_child(part)

func _wall(x1: float,z1: float,x2: float,z2: float, color: Color, high: float) -> void:
	var trace := PackedVector2Array([_mapped(Vector2(x1,z1)),_mapped(Vector2(x2,z2))])
	for part in Geometry2D.intersect_polyline_with_polygon(trace,floor_shape):
		if part.size() >= 2:
			_edge(part[0],part[-1],color,high)


func _edge(a: Vector2, b: Vector2, color: Color, high: float) -> void:
	var width := maxf(.13,absf(b.x-a.x))
	var depth := maxf(.13,absf(b.y-a.y))
	var center := (a+b)*.5
	var size := Vector2(width,depth)
	obstacles.append(Rect2(center-size*.5,size))
	_box(_v(center,high*.5),Vector3(width,high,depth),color,high > 1.5 and kind in ["police","office","civic"])
	_box(_v(center,high+.035),Vector3(width+.045,.07,depth+.045),color.lightened(.15))


func _outline() -> PackedVector2Array:
	var outline := PackedVector2Array([Vector2.ZERO,Vector2(span.x,0),span,Vector2(0,span.y)])
	var cuts: Array[Rect2] = []
	var variant := layout_id % 3
	match kind:
		"home":
			if variant != 1:
				cuts.append(Rect2(span.x-(2.2 if variant == 0 else 3.15),-.2,3.35,2.6))
		"school":
			cuts.append(Rect2(span.x-2.45,7.2,3.0,span.y-6.9))
			if variant == 2:
				cuts.append(Rect2(-.2,-.2,1.85,2.1))
		"industry":
			cuts.append(Rect2(-.3,7.2,3.3,span.y-6.9))
		"hotel","civic":
			cuts.append(Rect2(-.3,-.2,2.85,2.8))
			if floor_index == 0:
				cuts.append(Rect2(span.x-2.05,6.8,2.5,2.02))
		"retail":
			cuts.append(Rect2(span.x-2.25,-.2,2.55,2.32))
		"pharmacy":
			cuts.append(Rect2(-.2,span.y-1.9,2.31,2.2))
		"police":
			cuts.append(Rect2(-.2,span.y-2.3,2.62,2.55))
		"office":
			cuts.append(Rect2(-.3,4.65,1.88,2.05))
			cuts.append(Rect2(span.x-2.45,-.2,2.8,1.72))
	for cut in cuts:
		var start := cut.position
		var end := cut.end
		var gutter := PackedVector2Array([start,Vector2(end.x,start.y),end,Vector2(start.x,end.y)])
		var result := Geometry2D.clip_polygons(outline,gutter)
		if result.size() == 1:
			outline = result[0]
	for i in outline.size():
		outline[i] = _mapped(outline[i])
	if Geometry2D.is_polygon_clockwise(outline):
		outline.reverse()
	return outline


func _surface(tint: Color) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	game._roof(st,floor_shape,.0,tint)
	for x in range(1,int(span.x)):
		_floor_strip(st,Rect2(float(x)-.011,0,.022,span.y),.007,tint.darkened(.13))
	for z in range(1,int(span.y)):
		_floor_strip(st,Rect2(0,float(z)-.011,span.x,.022),.007,tint.darkened(.13))
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.mesh = st.commit()
	floor_mesh.material_override = game._mat(Color.WHITE,true)
	scene.add_child(floor_mesh)


func _floor_strip(surface: SurfaceTool, area: Rect2, height: float, tint: Color) -> void:
	var a := area.position
	var b := area.end
	var quad := PackedVector2Array([a,Vector2(b.x,a.y),b,Vector2(a.x,b.y)])
	for part in Geometry2D.intersect_polygons(quad,floor_shape):
		game._roof(surface,part,height,tint)


func _space_for(at: Vector2) -> bool:
	for offset in [Vector2(-.32,-.32),Vector2(.32,-.32),Vector2(-.32,.32),Vector2(.32,.32)]:
		if not Geometry2D.is_point_in_polygon(at+offset,floor_shape):
			return false
	return true


func _put_inside(at: Vector2) -> Vector2:
	if _space_for(at):
		return at
	var best := Vector2.INF
	var score := INF
	for x in range(1,int(span.x)):
		for z in range(1,int(span.y)):
			var candidate := Vector2(x,z)
			var distance := at.distance_squared_to(candidate)
			if distance >= score or not _space_for(candidate):
				continue
			if obstacles.any(func(shape: Rect2): return shape.grow(.45).has_point(candidate)):
				continue
			best = candidate
			score = distance
	return best


func _build_floor() -> void:
	if is_instance_valid(scene):
		scene.hide()
		scene.queue_free()
	scene = Node3D.new()
	add_child(scene)
	obstacles.clear()
	sockets.clear()
	actions.clear()
	pickups.clear()
	posture = ""
	var hue := float((layout_id + floor_index*31) % 100) / 100.0
	var palette := {"home":"#a58a77","hotel":"#8a7864","retail":"#6d8187","pharmacy":"#759889",
		"school":"#8a969b","industry":"#77796e","police":"#667a88","office":"#7d8288","civic":"#8b867e"}
	var wall := Color(palette[kind]).lerp(Color.from_hsv(hue,.25,.48),.22)
	var floor_color := Color("#98795c") if kind in ["home","hotel"] else Color("#61696b")
	floor_shape = _outline()
	_surface(floor_color)
	for i in floor_shape.size():
		var a := floor_shape[i]
		var b := floor_shape[(i+1)%floor_shape.size()]
		var middle := (a+b)*.5
		var outside := a.direction_to(b).orthogonal()
		if Geometry2D.is_point_in_polygon(middle+outside*.18,floor_shape):
			outside = -outside
		var back := outside.x + outside.y < -.5 and (middle.x < 4.1 or middle.y < 4.1)
		_edge(a,b,wall,2.78 if back else .22)
	for partition in PARTITIONS[kind]:
		var far: float = span.x if float(partition[2]) == 11.6 else partition[2]
		_wall(partition[0],partition[1],far,partition[3],wall,.86)
	var rug := Color("#795048") if kind == "home" else Color("#47595e")
	var patches := SurfaceTool.new()
	patches.begin(Mesh.PRIMITIVE_TRIANGLES)
	_floor_strip(patches,Rect2(_mapped(Vector2(2.65,3.7))-Vector2(1.92,1.95),Vector2(3.85,3.9)),.012,rug)
	_floor_strip(patches,Rect2(_mapped(Vector2(8.35,8.1))-Vector2(2.0,1.32),Vector2(4.0,2.65)),.012,floor_color.lightened(.19))
	var carpet := MeshInstance3D.new()
	carpet.mesh = patches.commit()
	carpet.material_override = game._mat(Color.WHITE,true)
	scene.add_child(carpet)
	for definition in FURNITURE[kind]:
		if floor_index > 0 and kind == "hotel" and str(definition[0]) == "desk":
			_prop(["bed",definition[1],definition[2],1.08,"cloth","bed"])
		else:
			_prop(definition)
	if kind == "police" and ResourceLoader.exists(LOCAL + "lineup.png"):
		_prop(["lineup",8.6,.66,1.6,""])
	if kind == "industry":
		_prop(["fridge",4.1,8.8,1.50,"water"])
		_prop(["wardrobe",10.15,4.1,1.61,"clothes"])
	if kind in ["home","office"]:
		_prop(["parcel",.7,5.6,.54,"tools"])
	_add_action(_mapped(Vector2(5.7,span.y-.55)), "Sair pela porta", "exit")
	if site.has("footprint") and floor_index == 0:
		_add_action(_mapped(Vector2(1.0,5.5)), "Sair pela janela", "window")
	if levels > 1:
		if floor_index < levels-1:
			_stair(_mapped(Vector2(span.x-1.2,9.7)),true)
		if floor_index > 0:
			_stair(_mapped(Vector2(span.x-3.1,9.7)),false)
	if str(site["id"]) == "central":
		_add_action(_mapped(Vector2(5.1,5.85)), "Falar com Lia", "shelter")
	_make_actor()
	_refresh_stock()
	title.text = "%s  ·  %s" % [site["name"], "Térreo" if floor_index == 0 else "%dº andar" % floor_index]

func _stair(at: Vector2, up: bool) -> void:
	at = _put_inside(at)
	for i in range(4):
		var height := .10 + .12 * (i if up else 3-i)
		_box(_v(at+Vector2(0,(i-1.5)*.24), height*.5), Vector3(1.17,height,.24),Color("#6e7777").lightened(i*.055))
	_add_action(at,"Subir escada" if up else "Descer escada","up" if up else "down")

func _image(name: String) -> Texture2D:
	if art.has(name):
		return art[name]
	var path := ART + name + ".png"
	if not ResourceLoader.exists(path):
		path = LOCAL + name + ".png"
	if not ResourceLoader.exists(path):
		path = ART + str(FALLBACK.get(name, "parcel")) + ".png"
	var loaded := load(path) as Texture2D
	art[name] = loaded
	return loaded

func _sprite(texture: Texture2D, at: Vector2, height: float) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.texture = texture
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	if texture != null:
		sprite.pixel_size = height / texture.get_height()
		sprite.offset.y = texture.get_height() * .5
	sprite.position = _v(at,.018)
	scene.add_child(sprite)
	return sprite

func _prop(row: Array) -> void:
	var at := _put_inside(_mapped(Vector2(row[1], row[2])))
	if not at.is_finite():
		return
	var height: float = row[3]
	var sprite := _sprite(_image(row[0]),at,height)
	# A billboard's projected face is wider than its footprint.
	var width := clampf(float(sprite.texture.get_width()) * sprite.pixel_size * .65,.43,2.0)
	if row[0] != "rubble":
		var footprint := Vector2(width,.53 if height < 1.1 else .7)
		obstacles.append(Rect2(at-footprint*.5,footprint))
	if not str(row[4]).is_empty():
		sockets.append({"pos":at,"zone":row[4],"height":height})
	if row.size() > 5:
		var code := str(row[5])
		var caption: String = {"seat":"Sentar","bed":"Deitar","wash":"Lavar as mãos","survey":"Investigar"}.get(code,"")
		_add_action(at,caption,code)

func _add_action(at: Vector2,label: String,code: String) -> void:
	var sign := Label3D.new()
	sign.text = label
	sign.font_size = 37
	sign.outline_size = 11
	sign.pixel_size = .013
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.modulate = COLOR
	sign.no_depth_test = true
	sign.position = _v(at,1.45)
	scene.add_child(sign)
	actions.append({"pos":at,"caption":label,"code":code,"target":sign})

func _actor_texture(action: String) -> Texture2D:
	var key: String = "%s:%s:%s" % [action, life.outfit, game.home.cfg.get("camisa",0)]
	if avatar_art.has(key):
		return avatar_art[key]
	var source := _image("actor_" + action)
	var profile: Dictionary = game.home.cfg
	var image := source.get_image()
	var color: Color = game.home.SHIRT[clampi(int(profile.get("camisa",0)),0,game.home.SHIRT.size()-1)]
	if life.outfit == "jacket":
		color = Color("#459678")
	elif life.outfit == "shirt":
		color = Color("#5b8fce")
	elif life.outfit == "coat":
		color = Color("#cb953d")
	for y in image.get_height():
		for x in image.get_width():
			var texel := image.get_pixel(x,y)
			if texel.a > .6 and texel.b > texel.r * 1.22 and texel.b > texel.g * 1.04:
				var tinted := color * clampf(texel.v * 1.43,.42,1.38)
				tinted.a = texel.a
				image.set_pixel(x,y,tinted)
	var result := ImageTexture.create_from_image(image)
	avatar_art[key] = result
	return result

func _make_actor() -> void:
	actor = _sprite(_actor_texture("idle"),pos,2.55)
	actor.region_enabled = true
	actor.pixel_size = .038
	actor.offset.y = FRAME.y * .5 - 3
	held = _sprite(null,pos,.5)
	_pose("idle",0.0)

func _pose(action: String, delta: float) -> void:
	if action != anim_key:
		anim_key = action
		phase = 0.0
	phase += delta * (12.0 if action == "walk" else 8.0)
	actor.texture = _actor_texture(action)
	var count := maxi(1, floori(float(actor.texture.get_width()) / FRAME.x))
	actor.region_rect = Rect2((int(phase)%count)*FRAME.x,facing*FRAME.y,FRAME.x,FRAME.y)
	actor.position = _v(pos if posture.is_empty() else posture_at, -.48 if not posture.is_empty() else .0)
	actor.billboard = BaseMaterial3D.BILLBOARD_DISABLED if posture == "bed" else BaseMaterial3D.BILLBOARD_ENABLED
	actor.basis = game.cam.global_basis * Basis(Vector3.BACK,-1.12) if posture == "bed" else Basis.IDENTITY
	var icon: Texture2D = life.icons.get(life.equipped)
	held.texture = icon
	held.visible = icon != null and posture.is_empty()
	if held.visible:
		held.pixel_size = .42 / maxf(icon.get_width(),icon.get_height())
		var offset: Vector3 = game.cam.global_basis.x * .36 + game.cam.global_basis.z * .11
		held.position = actor.position + offset + Vector3.UP * .91

func _refresh_stock() -> void:
	for entry in pickups:
		entry["target"].queue_free()
	pickups.clear()
	var stock: Dictionary = life._stash(site)["items"]
	var used := {}
	var keys := stock.keys()
	keys.sort()
	for item in keys:
		var zone := str(ITEM_ZONE.get(item,""))
		var possible: Array[int] = []
		for i in sockets.size():
			if sockets[i]["zone"] == zone:
				possible.append(i)
		if possible.is_empty():
			for i in sockets.size():
				possible.append(i)
		if possible.is_empty():
			continue
		var level := 0
		if levels > 1 and zone in ["manual","parts","tools","clothes"]:
			level = int(hash(str(site["id"]) + str(item))) % mini(levels,4)
		if life.quest < life.QUESTS.size() and life.QUESTS[life.quest]["place"] == site["id"] and life.QUESTS[life.quest]["item"] == item:
			level = 0
		if level != floor_index:
			continue
		var socket_id: int = possible[int(hash(str(site["id"]) + str(item))) % possible.size()]
		var slot: Dictionary = sockets[socket_id]
		var offset := int(used.get(socket_id,0))
		used[socket_id] = offset + 1
		var at: Vector2 = slot["pos"] + Vector2((offset%3-1)*.29,-.23 - float(floori(float(offset)/3))*.23)
		var texture: Texture2D = life.icons.get(item)
		if texture == null:
			texture = _image({"med":"medical_case","bandage":"medical_case","parts":"electronic_parts",
				"manual":"radio","water":"fridge","dirty_water":"fridge","wood":"crate",
				"cloth":"basket","fuel":"drum"}.get(item,"parcel"))
		var marker := _sprite(texture,at,.30)
		marker.position.y = float(slot["height"]) * .69 + .14
		marker.no_depth_test = true
		var label := Label3D.new()
		label.text = "%s ×%d" % [life.ITEM_NAMES[item], stock[item]]
		label.font_size = 35
		label.outline_size = 10
		label.pixel_size = .011
		label.no_depth_test = true
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = Color("#ffe499")
		label.position.y = .52
		marker.add_child(label)
		pickups.append({"item":item,"pos":at,"target":marker,"label":label,"caption":label.text})

func focus() -> Vector3:
	return global_position + Vector3(span.x*.5,.05,span.y*.51)

func tick(delta: float,input: Vector2) -> void:
	var viewport := get_viewport().get_visible_rect().size
	exit.position = Vector2(viewport.x - 89, 88)
	var screen: Vector2 = input + Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	screen += Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
	screen = screen.limit_length()
	var walking: bool = screen.length_squared() > .02 and not game.menu_open
	var running: bool = walking and Input.is_physical_key_pressed(KEY_SHIFT) and life.needs["energia"] > 8.0
	if walking:
		posture = ""
		facing = _direction(screen)
		var world: Vector2 = game._joy_home(screen)
		var step := world * minf(delta,.08) * minf(life.walking_speed(),4.6 if running else 3.5)
		if running:
			life.needs["energia"] = maxf(0.0,float(life.needs["energia"])-delta*.6)
			life._update_hud()
		for portion in [Vector2(step.x,0),Vector2(0,step.y)]:
			if _can_walk(pos+portion):
				pos += portion
	if not posture.is_empty():
		life.needs["energia"] = minf(100.0,float(life.needs["energia"]) + delta * (3.0 if posture == "bed" else 1.25))
		life._update_hud()
	action_until = maxf(0,action_until-delta)
	_pose("carrying" if action_until > 0 else ("running" if running else ("walk" if walking else "idle")), delta)
	for entry in actions:
		entry["target"].visible = pos.distance_to(entry["pos"]) < 3.1 and _available(entry)
	for entry in pickups:
		entry["label"].visible = pos.distance_to(entry["pos"]) < 3.0
	var nearest := _nearest()
	hint.text = str(nearest.get("caption","Toque em um item para coletar."))

func _available(entry: Dictionary) -> bool:
	return entry["code"] != "survey" or (life.quest < life.QUESTS.size() and life.QUESTS[life.quest]["place"] == site["id"] and str(life.QUESTS[life.quest]["item"]).is_empty())

func _can_walk(point: Vector2) -> bool:
	if not _space_for(point):
		return false
	for footprint in obstacles:
		if footprint.grow(.22).has_point(point):
			return false
	return true

func _nearest() -> Dictionary:
	var nearest := {}
	var radius := 2.0
	for entry in pickups + actions:
		if entry.has("code") and not _available(entry):
			continue
		var distance := pos.distance_to(entry["pos"])
		if distance < radius:
			nearest = entry
			radius = distance
	return nearest

func tap(screen: Vector2) -> bool:
	if game.menu_open:
		return false
	var chosen := {}
	var range_px := 29.0
	for entry in pickups + actions:
		if entry.has("code") and not _available(entry):
			continue
		var node: Node3D = entry["target"]
		if not node.visible:
			continue
		var point := node.global_position + Vector3.UP * (.16 if entry.has("item") else 0.0)
		var distance: float = game.cam.unproject_position(point).distance_to(screen)
		if distance < range_px:
			range_px = distance
			chosen = entry
	if chosen.is_empty():
		return false
	if pos.distance_to(chosen["pos"]) > 2.1:
		life._notify("Aproxime-se para interagir.")
		return true
	_activate(chosen)
	return true

func interact() -> void:
	_activate(_nearest())

func _activate(entry: Dictionary) -> void:
	if entry.is_empty() or game.menu_open or pos.distance_to(entry["pos"]) > 2.1:
		return
	if entry.has("item"):
		if life.take_interior(str(site["id"]),entry["item"]):
			action_until = .48
			_refresh_stock()
		return
	match entry["code"]:
		"exit": game._exit_interior()
		"window": game._exit_interior(true)
		"up","down":
			floor_index = clampi(floor_index + (1 if entry["code"] == "up" else -1),0,levels-1)
			_build_floor()
		"wash":
			life.dirty_hands = false
			life._notify("Mãos lavadas.")
			life.save()
		"seat","bed":
			posture = "" if posture == entry["code"] else str(entry["code"])
			posture_at = entry["pos"] + Vector2(.07,.24)
		"survey": life._survey(str(site["id"]))
		"shelter": life._shelter_menu()


func _direction(screen: Vector2) -> int:
	return posmod(roundi((screen.angle()-3.0*PI/4.0)/(TAU/8.0)),8)


func update_home_avatar(delta: float) -> void:
	var room: Node3D = game.home
	var original: Node3D = room.avatar["node"]
	if game.intro_state != 0:
		original.show()
		if is_instance_valid(home_pawn):
			home_pawn.hide()
			home_hand.hide()
		return
	original.hide()
	if not is_instance_valid(home_pawn):
		home_pawn = Sprite3D.new()
		home_pawn.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		home_pawn.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		home_pawn.region_enabled = true
		home_pawn.offset.y = FRAME.y*.5-3
		home_pawn.pixel_size = .033
		room.add_child(home_pawn)
		home_hand = Sprite3D.new()
		home_hand.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		home_hand.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		room.add_child(home_hand)
	var current: Vector2 = room.pos
	var movement := current-home_previous if home_previous.is_finite() else Vector2.ZERO
	if movement.length_squared() > .000004:
		home_facing = _direction(Vector2(movement.x-movement.y,movement.x+movement.y))
	home_previous = current
	home_pawn.show()
	home_pawn.texture = _actor_texture("walk" if movement.length_squared() > .000004 else "idle")
	home_phase += delta * 10.0
	var frames := maxi(1,floori(float(home_pawn.texture.get_width()) / FRAME.x))
	home_pawn.region_rect = Rect2((int(home_phase)%frames)*FRAME.x,home_facing*FRAME.y,FRAME.x,FRAME.y)
	home_pawn.position = _v(current)
	var icon: Texture2D = life.icons.get(life.equipped)
	home_hand.texture = icon
	home_hand.visible = icon != null
	if icon != null:
		home_hand.pixel_size = .33 / maxf(icon.get_width(),icon.get_height())
		home_hand.position = home_pawn.position + game.cam.global_basis.x*.29 + Vector3.UP*.78


func hide_home_avatar() -> void:
	home_previous = Vector2.INF
	if is_instance_valid(home_pawn):
		home_pawn.hide()
		home_hand.hide()
