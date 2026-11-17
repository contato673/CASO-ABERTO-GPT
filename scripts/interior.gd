extends Node3D

const ORIGIN := Vector3(120.0, 0.0, 30000.0)
const ART := "res://assets/interiores/"
const LOCAL := "res://assets/interiores_locais/"
const FRAME := Vector2i(32,40)
const PERSON_PIXEL := .052
const REACH := 1.52
const COLOR := Color("#efe3bf")
const ROOM_NAMES := {"home":"Residência", "retail":"Comércio", "pharmacy":"Farmácia",
	"school":"Escola", "industry":"Indústria", "police":"Delegacia", "office":"Escritório",
	"hotel":"Hotel", "civic":"Edifício público"}
# Model, room position, visual height, item groups and optional interaction.
const FURNITURE := {
	"home":[["sofa",2.35,.91,1.0,"cloth","seat"],["coffee",2.3,4.0,.76,"manual"],
		["tv",3.65,4.62,.80,"parts"],["plant",.9,3.6,1.1,""],["vacuum",4.5,4.9,1.02,""],
		["fridge",9.92,.91,1.86,"water"],["cupboard",7.78,.78,1.80,"food"],
		["kitchen_sink",6.08,.91,1.0,"","wash"],["stove",8.79,.89,.94,""],
		["table",8.7,4.5,1.04,"food"],["chair",9.8,4.3,.84,"","seat"],
		["bed",1.65,8.45,1.0,"cloth","bed"],["wardrobe",3.1,6.98,1.87,"clothes"],
		["nightstand",.64,7.62,.56,"manual"],["sink",7.39,6.98,.97,"","wash"],
		["medicine",8.61,6.98,1.58,"med"],["bath",10.46,8.2,.67,""],
		["washer",9.8,6.96,.89,"cloth"],["basket",7.9,9.3,.58,"cloth"],["trash",10.6,6.2,.65,""]],
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
		["drum",7.93,.83,1.12,"fuel"],["drum",9.47,.83,1.18,"fuel"],["generator",1.04,4.33,1.25,"parts"],
		["desk",4.0,5.66,1.0,"manual","survey"],["crate",8.69,4.83,1.10,"tools"],["rubble",10.16,6.1,.31,""],
		["medicine",5.38,7.04,1.56,"med"],["sink",6.55,7.04,.96,"","wash"],["barricade",10.08,8.53,1.02,""]],
	"police":[["reception",2.0,1.7,1.3,"manual","survey"],["office_chair",4.1,1.5,.97,"","seat"],
		["evidence",9.1,1.8,1.8,"tools"],["crate",10.2,3.4,1.04,"tools"],["interrogation",2.4,4.7,1.25,"manual"],
		["radio",3.7,4.1,.55,"parts"],["barricade",8.5,5.0,1.01,""],
		["medicine",2.4,8.2,1.51,"med"],["sink",8.5,8.3,1.22,"","wash"]],
	"office":[["desk",2.2,1.7,1.24,"manual","survey"],["office_chair",4.0,1.6,1.05,"","seat"],
		["shelf",8.2,1.7,1.56,"parts"],["parcel",10.1,2.1,.65,"parts"],["desk",8.4,4.4,1.17,"manual"],
		["plant",.84,2.97,1.13,""],["sofa",2.62,5.72,1.08,"cloth","seat"],["medicine",1.92,7.12,1.55,"med"],
		["fridge",8.2,7.78,1.79,"water"],["sink",9.52,7.78,.98,"","wash"],["office_chair",8.3,5.22,.99,"","seat"]],
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
var home_previous := Vector2.INF
var home_phase := 0.0
var home_facing := 7
var action_until := 0.0
var hud: CanvasLayer
var title: Label
var hint: Button
var focused := {}
var highlighted := {}
var window_built := false
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
	hint = Button.new()
	hint.position = Vector2(12,126)
	hint.custom_minimum_size = Vector2(1,35)
	hint.add_theme_font_size_override("font_size", 15)
	hint.focus_mode = Control.FOCUS_NONE
	hint.pressed.connect(interact)
	var prompt_style := StyleBoxFlat.new()
	prompt_style.bg_color = Color(0.07,.09,.11,.94)
	prompt_style.shadow_color = Color(0,0,0,.55)
	prompt_style.shadow_size = 5
	prompt_style.set_corner_radius_all(6)
	prompt_style.content_margin_left = 12
	prompt_style.content_margin_right = 12
	hint.add_theme_stylebox_override("normal",prompt_style)
	hud.add_child(hint)
	hint.hide()
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
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
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
	window_built = false
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
		if back and not window_built and floor_index == 0 and site.has("footprint") and a.distance_to(b) > 3.8:
			_window_wall(a,b,outside,wall)
			window_built = true
		else:
			_edge(a,b,wall,2.78 if back else .22)
	var upper := _upper_floor()
	for partition in upper.get("walls",PARTITIONS[kind]):
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
	for definition in upper.get("furniture",_furniture_plan()):
		_prop(definition)
	if floor_index == 0 and kind == "police" and ResourceLoader.exists(LOCAL + "lineup.png"):
		_prop(["lineup",8.6,.66,1.6,""])
	if floor_index == 0 and kind == "industry":
		_prop(["fridge",7.70,7.04,1.72,"water"])
		_prop(["evidence",10.48,2.54,1.86,"clothes"])
	if floor_index == 0 and kind in ["home","office"]:
		_prop(["parcel",.7,5.6,.54,"tools"])
	if floor_index == 0:
		_add_action(_mapped(Vector2(5.7,span.y-.55)), "Sair pela porta", "exit")
	if levels > 1:
		if floor_index < levels-1:
			_stair(_mapped(Vector2(span.x-1.2,9.7)),true)
		if floor_index > 0:
			_stair(_mapped(Vector2(span.x-3.1,9.7)),false)
	if str(site["id"]) == "central":
		_add_action(_mapped(Vector2(5.1,5.85)), "Falar com Lia", "shelter")
	_make_actor()
	_refresh_stock()
	exit.visible = floor_index == 0
	title.text = "%s  ·  %s" % [site["name"], "Térreo" if floor_index == 0 else "%dº · %s" % [floor_index,upper["name"]]]

func _window_wall(a: Vector2, b: Vector2, outside: Vector2, wall: Color) -> void:
	var center := a.lerp(b,.54)
	var along := a.direction_to(b)
	var start := center-along*.79
	var finish := center+along*.79
	var dx := 1.58 if absf(along.x) > .5 else .11
	var dz := 1.58 if absf(along.y) > .5 else .11
	_edge(a,start,wall,2.78)
	_edge(finish,b,wall,2.78)
	_edge(start,finish,wall,.95)
	_box(_v(center,2.42),Vector3(dx,.72,dz),wall)
	_box(_v(center,1.92),Vector3(dx+.14,.085,dz+.12),Color("#c9b398"))
	_box(_v(center,.98),Vector3(dx+.21,.075,dz+.21),Color("#c9b398"))
	for shift in [-.75,0.0,.75]:
		_box(_v(center+along*shift,1.46),Vector3(.075,.91,.075),Color("#d4bf9f"))
	_box(_v(center+outside*.055,1.45),Vector3(dx*.96,.81,dz*.56),Color("#739fb4"))
	var approach := center-outside*.98
	_add_action(_put_inside(approach),"Sair pela janela","window")


func _upper_floor() -> Dictionary:
	if floor_index == 0:
		return {}
	var purpose := "Arquivo"
	if kind in ["hotel","home"]:
		purpose = "Quartos" if floor_index % 2 == 1 else "Lavanderia"
	elif kind in ["industry","pharmacy","retail"]:
		purpose = "Estoque" if floor_index % 2 == 1 else "Escritório"
	elif kind == "school":
		purpose = "Biblioteca" if floor_index % 2 == 1 else "Salas de aula"
	elif floor_index % 2 == 0:
		purpose = "Escritório"
	match purpose:
		"Quartos":
			return {"name":purpose,"walls":[[5.65,0,5.65,5.75],[0,6,3.35,6],[7.7,6,11.6,6]],
				"furniture":[["bed",1.75,2.1,1,"cloth","bed"],["wardrobe",3.3,.85,1.8,"clothes"],
					["nightstand",.84,1.35,.59,"parts"],["bed",7.25,2.1,1,"cloth","bed"],
					["wardrobe",9.15,.9,1.8,"clothes"],["sink",.85,8.05,1,"","wash"],["medicine",2.15,8.2,1.4,"med"]]}
		"Lavanderia":
			return {"name":purpose,"walls":[[0,5.6,5,5.6],[8.5,5.6,11.6,5.6]],
				"furniture":[["washer",1.8,1.35,.97,"parts"],["washer",3.15,1.35,.97,""],["washer",4.5,1.35,.97,""],
					["basket",2.2,3.55,.6,"cloth"],["shelf",7.7,1.3,1.45,"clothes"],["sink",9.4,1.25,1,"","wash"]]}
		"Estoque":
			return {"name":purpose,"walls":[[7.05,0,7.05,4],[7.05,6,7.05,8.5]],
				"furniture":[["shelf",1.35,1.35,1.6,"food"],["shelf",3.3,1.35,1.6,"tools"],["shelf",5.5,1.35,1.6,"med"],
					["crate",1.6,4.6,.92,"parts"],["crate",3.35,5.15,.92,"tools"],["drum",9.05,1.3,1,"fuel"],
					["desk",9.4,4.05,1.1,"manual"],["fridge",1.45,8.4,1.76,"water"]]}
		"Biblioteca","Arquivo":
			return {"name":purpose,"walls":[[0,6.1,2.8,6.1],[6.8,0,6.8,4.4]],
				"furniture":[["shelf",1.55,1.45,1.7,"manual"],["shelf",3.4,1.45,1.7,"manual"],
					["shelf",5.25,1.45,1.7,"parts"],["shelf",1.6,4.15,1.7,"manual"],
					["table",8.85,2.65,1.06,"manual"],["chair",10.18,2.73,.82,"","seat"],
					["parcel",1.25,8.5,.65,"clothes"]]}
		"Salas de aula":
			return {"name":purpose,"walls":[[5.9,0,5.9,5.2],[0,6.6,3.3,6.6]],
				"furniture":[["chalk",1.15,1,1.26,""],["teacher",3.6,1.4,1.1,"manual"],
					["student",2.05,3.75,.96,""],["student",4.05,3.75,.96,""],
					["cubbies",8.65,1.7,1.56,"parts"],["table",8.55,4.6,1.08,"tools"]]}
	return {"name":purpose,"walls":[[0,5.1,4.4,5.1],[7.65,5.1,11.6,5.1],[6.1,0,6.1,3.65]],
		"furniture":[["desk",2.25,1.55,1.1,"parts"],["office_chair",3.65,2.55,.96,"","seat"],
			["shelf",7.7,1.45,1.5,"manual"],["desk",9.65,2.75,1.1,"tools"],
			["sofa",2.35,7.2,1.02,"cloth","seat"],["coffee",2.45,8.8,.68,"manual"]]}


func _furniture_plan() -> Array:
	if kind != "home" or layout_id % 3 == 0:
		return FURNITURE[kind]
	if layout_id % 3 == 1:
		return [["bed",2.1,1.76,1,"cloth","bed"],["wardrobe",4.47,.8,1.89,"clothes"],
			["nightstand",.72,1.0,.56,"manual"],["fridge",9.65,.95,1.86,"water"],
			["cupboard",8.3,.84,1.78,"food"],["kitchen_sink",6.77,.89,.98,"","wash"],
			["table",8.9,4.1,1.0,"food"],["chair",10.05,4.12,.82,"","seat"],
			["sofa",2.5,7.14,1.03,"cloth","seat"],["coffee",2.5,8.67,.61,"parts"],
			["tv",.65,9.25,.82,"parts"],["medicine",7.12,6.91,1.44,"med"],["sink",8.26,6.9,.97,"","wash"],
			["washer",10.11,6.92,.9,"cloth"],["bath",9.72,8.83,.7,""],["trash",11.0,8.68,.59,""]]
	return [["sofa",2.35,.86,1.03,"cloth","seat"],["coffee",2.36,2.64,.65,"manual"],
		["tv",.84,4.35,.84,"parts"],["plant",4.1,.74,1.11,""],["bed",8.18,2.12,1,"cloth","bed"],
		["wardrobe",10.61,3.48,1.87,"clothes"],["nightstand",8.96,.83,.58,"parts"],
		["fridge",1.34,7.03,1.86,"water"],["cupboard",2.69,7.01,1.76,"food"],
		["kitchen_sink",.8,8.24,.98,"","wash"],["table",3.09,9.11,1.04,"food"],
		["sink",7.53,6.92,.96,"","wash"],["medicine",8.8,6.93,1.42,"med"],["bath",10.41,8.21,.73,""]]


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
	var model: String = row[0]
	var height: float = row[3]
	var footprint := Vector2(.85,.65)
	if model == "bed":
		footprint = Vector2(1.26,2.07)
		_box(_v(at,.17),Vector3(footprint.x,.30,footprint.y),Color("#695849"))
		_box(_v(at,.38),Vector3(1.20,.19,1.97),Color("#e1d4bd"))
		_box(_v(at+Vector2(0,.25),.486),Vector3(1.19,.055,1.42),Color("#527998"))
		_box(_v(at+Vector2(0,-.68),.513),Vector3(.74,.105,.41),Color("#f3e8d4"))
		_box(_v(at+Vector2(0,-.99),.43),Vector3(1.25,.81,.13),Color("#75634d"))
		height = .52
	elif model == "sofa":
		footprint = Vector2(2.07,.87)
		var fabric := Color("#48708a")
		_box(_v(at,.24),Vector3(2.06,.39,.87),fabric.darkened(.28))
		_box(_v(at+Vector2(0,-.31),.61),Vector3(2.04,.61,.21),fabric)
		_box(_v(at+Vector2(0,.075),.448),Vector3(1.64,.13,.63),fabric.lightened(.12))
		for side in [-.93,.93]:
			_box(_v(at+Vector2(side,.015),.56),Vector3(.22,.28,.76),fabric)
		height = .52
	else:
		var sprite := _sprite(_image(model),at,height)
		var width := clampf(float(sprite.texture.get_width()) * sprite.pixel_size * .69,.43,2.0)
		footprint = Vector2(width,.53 if height < 1.1 else .7)
	if model != "rubble":
		obstacles.append(Rect2(at-footprint*.5,footprint))
	if not str(row[4]).is_empty():
		sockets.append({"pos":at,"zone":row[4],"height":height})
	if row.size() > 5:
		var code := str(row[5])
		var caption: String = {"seat":"Sentar","bed":"Deitar","wash":"Lavar as mãos","survey":"Investigar"}.get(code,"")
		var touch := at + Vector2(0,.40 if code == "seat" else .30)
		if code == "bed":
			touch = at + Vector2(.56,.16)
		_add_action(touch,caption,code,at)


func _add_action(at: Vector2,label: String,code: String, anchor := Vector2.INF) -> void:
	var marker := Marker3D.new()
	marker.position = _v(at,.65)
	scene.add_child(marker)
	actions.append({"pos":at,"caption":label,"code":code,"target":marker,"anchor":anchor})


func _seated_texture(row: int, source: Texture2D) -> Texture2D:
	var key := "%s:%d" % [source.get_instance_id(),row]
	if avatar_art.has(key):
		return avatar_art[key]
	var image := source.get_image()
	image.convert(Image.FORMAT_RGBA8)
	var pose := Image.create_empty(32,40,false,Image.FORMAT_RGBA8)
	pose.blit_rect(image,Rect2i(0,row,32,25),Vector2i(0,9))
	for offset in [11,17]:
		pose.fill_rect(Rect2i(offset,32,5,6),Color("#252b3a"))
		pose.fill_rect(Rect2i(offset+1,32,3,4),Color("#495362"))
		pose.fill_rect(Rect2i(offset+1,37,4,2),Color("#262635"))
	var texture := ImageTexture.create_from_image(pose)
	avatar_art[key] = texture
	return texture


func _make_actor() -> void:
	actor = _sprite(game.walker.texture,pos,1.76)
	actor.region_enabled = true
	actor.pixel_size = PERSON_PIXEL
	actor.no_depth_test = true
	actor.render_priority = 8
	actor.offset.y = 19
	_pose("idle",0.0)


func _pose(action: String, delta: float) -> void:
	if action != anim_key:
		anim_key = action
		phase = 0.0
	phase += delta * (12.0 if action == "running" else 8.0)
	var row := 320 if facing in [0,1,2,3] else 360
	var source: Texture2D = game.walker.texture
	var frame := int(phase)%4 if action in ["walk","running"] else 0
	actor.position = _v(pos)
	actor.region_enabled = posture != "seat"
	actor.texture = source
	actor.region_rect = Rect2(frame*FRAME.x,row,FRAME.x,FRAME.y)
	actor.offset.y = 19
	actor.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	actor.basis = Basis.IDENTITY
	if posture == "seat":
		actor.texture = _seated_texture(row,source)
		actor.position = _v(posture_at+Vector2(0,.17),.23)
	elif posture == "bed":
		actor.position = _v(posture_at,.57)
		actor.offset = Vector2.ZERO
		actor.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		actor.basis = Basis(Vector3.RIGHT,-PI*.5)
	elif action == "carrying":
		actor.offset.y = 17.0 + sin(minf(phase,4.0)*.78)*1.5


func _loot_icon(item: String) -> Texture2D:
	if highlighted.has(item):
		return highlighted[item]
	var texture: Texture2D = life.icons.get(item)
	if texture == null:
		texture = _image({"med":"medical_case","bandage":"medical_case","parts":"electronic_parts",
			"manual":"radio","wood":"crate","cloth":"basket","fuel":"drum"}.get(item,"parcel"))
	var source := texture.get_image()
	source.convert(Image.FORMAT_RGBA8)
	var used := source.get_used_rect()
	source = source.get_region(used)
	var side := 38.0 / maxf(source.get_width(),source.get_height())
	source.resize(maxi(1,roundi(source.get_width()*side)),maxi(1,roundi(source.get_height()*side)),Image.INTERPOLATE_NEAREST)
	var board := Image.create_empty(54,54,false,Image.FORMAT_RGBA8)
	var margin := (Vector2i(54,54)-source.get_size()) / 2
	for y in 54:
		for x in 54:
			var distance := Vector2(x-26.5,y-26.5).length()
			if distance < 25.0:
				board.set_pixel(x,y,Color("#202632") if distance < 22.0 else Color("#ffcd68"))
	for y in source.get_height():
		for x in source.get_width():
			if source.get_pixel(x,y).a < .25:
				continue
			var point := margin + Vector2i(x,y)
			for n in [Vector2i(-2,0),Vector2i(2,0),Vector2i(0,-2),Vector2i(0,2)]:
				board.set_pixelv(point+n,Color("#ffe49c"))
	board.blend_rect(source,Rect2i(Vector2i.ZERO,source.get_size()),margin)
	var result := ImageTexture.create_from_image(board)
	highlighted[item] = result
	return result


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
		var at: Vector2 = slot["pos"] + Vector2((offset%3-1)*.55,-.23 - float(floori(float(offset)/3))*.23)
		var marker := _sprite(_loot_icon(item),at,.88)
		marker.offset.y = 0
		marker.position.y = float(slot["height"]) * .81 + .34
		marker.no_depth_test = true
		marker.render_priority = 10
		pickups.append({"item":item,"pos":at,"target":marker,
			"caption":"Pegar %s ×%d" % [life.ITEM_NAMES[item],stock[item]]})


func focus() -> Vector3:
	return global_position + Vector3(span.x*.5,.05,span.y*.51)

func tick(delta: float,input: Vector2) -> void:
	var viewport := get_viewport().get_visible_rect().size
	exit.position = Vector2(viewport.x - 89, 88)
	var screen: Vector2 = input + Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	screen += Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
	screen = screen.limit_length()
	var walking: bool = screen.length_squared() > .02 and not game.menu_open and life.action_time <= 0.0
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
	focused = _nearest()
	hint.visible = not focused.is_empty() and not game.menu_open
	if hint.visible:
		hint.text = "Levantar" if not posture.is_empty() else focused["caption"]
		hint.reset_size()

func has_nearby_action() -> bool:
	return not posture.is_empty() or not _nearest().is_empty()


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
	var radius := REACH
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
		if not entry.has("item") and pos.distance_to(entry["pos"]) > REACH:
			continue
		var point := node.global_position
		var distance: float = game.cam.unproject_position(point).distance_to(screen)
		if distance < range_px:
			range_px = distance
			chosen = entry
	if chosen.is_empty():
		return false
	if pos.distance_to(chosen["pos"]) > REACH:
		life._notify("Aproxime-se para interagir.")
		return true
	_activate(chosen)
	return true

func interact() -> void:
	if not posture.is_empty():
		posture = ""
	else:
		_activate(_nearest())

func _activate(entry: Dictionary) -> void:
	if entry.is_empty() or game.menu_open or pos.distance_to(entry["pos"]) > REACH:
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
			var going_up: bool = entry["code"] == "up"
			floor_index = clampi(floor_index + (1 if going_up else -1),0,levels-1)
			_build_floor()
			for stair in actions:
				if stair["code"] == ("down" if going_up else "up"):
					pos = _put_inside(stair["pos"] + Vector2(0,-.85))
					break
		"wash":
			life.dirty_hands = false
			life._notify("Mãos lavadas.")
			life.save()
		"seat","bed":
			posture = "" if posture == entry["code"] else str(entry["code"])
			posture_at = entry["anchor"]
		"survey": life._survey(str(site["id"]))
		"shelter": life._shelter_menu()


func _direction(screen: Vector2) -> int:
	return posmod(roundi((screen.angle()-3.0*PI/4.0)/(TAU/8.0)),8)


func update_home_avatar(delta: float) -> void:
	var room: Node3D = game.home
	var original: Node3D = room.avatar["node"]
	original.hide()
	if not is_instance_valid(home_pawn):
		home_pawn = Sprite3D.new()
		home_pawn.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		home_pawn.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		home_pawn.region_enabled = true
		home_pawn.offset.y = 19
		home_pawn.pixel_size = PERSON_PIXEL
		home_pawn.no_depth_test = true
		home_pawn.render_priority = 8
		room.add_child(home_pawn)
	var current: Vector2 = room.pos
	var movement := current-home_previous if home_previous.is_finite() else Vector2.ZERO
	if movement.length_squared() > .000004:
		home_facing = _direction(Vector2(movement.x-movement.y,movement.x+movement.y))
	home_previous = current
	home_pawn.show()
	home_pawn.texture = game.walker.texture
	home_phase += delta * 8.0
	var frame := int(home_phase)%4 if movement.length_squared() > .000004 else 0
	var row := 320 if home_facing in [0,1,2,3] else 360
	home_pawn.region_rect = Rect2(frame*FRAME.x,row,FRAME.x,FRAME.y)
	home_pawn.position = _v(current)


func hide_home_avatar() -> void:
	home_previous = Vector2.INF
	if is_instance_valid(home_pawn):
		home_pawn.hide()
