extends Node3D

# Casa privada do jogador: 5 m x 5 m, instância separada longe da cidade.
# Só o morador e os convidados entram aqui.

signal request_enter
signal request_exit
signal request_actions
signal money_delta(d: int)
signal car_selected(path: String)

const ORIGIN := Vector3(0.0, 0.0, 30000.0)
const ROOM := 5.0
const WALL_H := 2.6
const MODEL_DIR := "res://assets/modelos/"
const WALL_T := 0.15
const WALK_SPEED := 2.2
const VISITOR_SPEED := 1.4
const WORK_PAY := 40
const WORK_COOLDOWN := 45.0
const VISIT_TIME := 60.0
const MAX_VISITORS := 2
const DEFAULT_CAR := "res://assets/pack/Vehicles/Car_Coral.glb"
const SKIN := [Color(0.96, 0.82, 0.68), Color(0.88, 0.7, 0.55), Color(0.72, 0.52, 0.38), Color(0.5, 0.34, 0.25), Color(0.32, 0.22, 0.16)]
const HAIR_COL := [Color(0.1, 0.08, 0.06), Color(0.35, 0.22, 0.12), Color(0.8, 0.62, 0.3), Color(0.55, 0.55, 0.58), Color(0.7, 0.2, 0.15)]
const HAIR_STYLES := ["curto", "longo", "coque", "careca"]
const SHIRT := [Color(0.2, 0.35, 0.6), Color(0.7, 0.2, 0.2), Color(0.2, 0.5, 0.3), Color(0.85, 0.85, 0.82), Color(0.25, 0.25, 0.28), Color(0.85, 0.6, 0.2)]
const PANTS := [Color(0.18, 0.18, 0.22), Color(0.35, 0.28, 0.2), Color(0.2, 0.3, 0.45), Color(0.6, 0.55, 0.45)]
const HEIGHTS := [0.92, 1.0, 1.08]
const CAT_ROWS := [
	["pele", "Tom da pele", 5],
	["cabelo", "Estilo do cabelo", 4],
	["cor_cabelo", "Cor do cabelo", 5],
	["altura", "Altura", 3],
	["camisa", "Camisa", 6],
	["calca", "Calça", 4],
	["oculos", "Óculos", 2],
]
# Roupas à venda. Camisa/calça padrão (índices 0 e 1 / 0 e 1) já são do jogador.
const CLOTHES := {
	"camisa": [
		{"idx": 2, "nome": "Verde", "preco": 60},
		{"idx": 3, "nome": "Branca", "preco": 60},
		{"idx": 4, "nome": "Grafite", "preco": 80},
		{"idx": 5, "nome": "Mostarda", "preco": 80},
	],
	"calca": [
		{"idx": 2, "nome": "Azul", "preco": 50},
		{"idx": 3, "nome": "Bege", "preco": 70},
	],
}
const CLOTHES_NAME := {"camisa": "Camisa", "calca": "Calça"}
# Carros: o padrão é o Coral (já é do jogador).
const CARS := [
	{"path": "res://assets/pack/Vehicles/Car_Coral.glb", "nome": "Coral", "preco": 0},
	{"path": "res://assets/pack/Vehicles/Car_Blue.glb", "nome": "Azul", "preco": 2500},
	{"path": "res://assets/pack/Vehicles/Police_Car.glb", "nome": "Viatura", "preco": 6000},
]
const FURN := {
	"cama": {"size": Vector3(1.0, 0.5, 2.0), "color": Color(0.7, 0.3, 0.3), "nome": "Cama", "preco": 300},
	"sofa": {"size": Vector3(2.0, 0.6, 0.9), "color": Color(0.35, 0.45, 0.55), "nome": "Sofá", "preco": 450},
	"mesa": {"size": Vector3(1.2, 0.75, 0.8), "color": Color(0.55, 0.4, 0.25), "nome": "Mesa", "preco": 180},
	"cadeira": {"size": Vector3(0.5, 0.9, 0.5), "color": Color(0.5, 0.35, 0.2), "nome": "Cadeira", "preco": 80},
	"estante": {"size": Vector3(1.0, 1.8, 0.35), "color": Color(0.45, 0.32, 0.2), "nome": "Estante", "preco": 220},
	"planta": {"size": Vector3(0.4, 1.0, 0.4), "color": Color(0.25, 0.55, 0.3), "nome": "Planta", "preco": 40},
	"luminaria": {"size": Vector3(0.3, 1.6, 0.3), "color": Color(0.9, 0.85, 0.5), "nome": "Luminária", "preco": 60},
	"tv": {"size": Vector3(1.2, 0.7, 0.1), "color": Color(0.1, 0.1, 0.12), "nome": "TV", "preco": 500},
}
const TAB_NAMES := ["Avatar", "Loja", "Móveis", "Garagem", "Convidados"]

var save_path := "user://casa-%s.json" % ProjectSettings.get_setting("application/config/save_version", ProjectSettings.get_setting("application/config/version", "dev"))
var cfg: Dictionary = {}
var owned: Dictionary = {}
var inventory: Dictionary = {}
var furniture: Array = []
var neighbors: Array = []
var money_now := 500
var cam: Camera3D
var pos := Vector2(2.5, 2.5)
var walk_t := 0.0
var active := false
var survival_mode := false
var menu_open := false
var work_cd := 0.0
var notice_t := 0.0
var avatar: Dictionary = {}
var visitors: Array = []
var ghost: Dictionary = {}
var ghost_node: Node3D = null
var furn_root: Node3D
var hud: CanvasLayer
var btn_menu: Button
var btn_enter: Button
var btn_exit: Button
var panel: PanelContainer
var tabs: TabContainer
var money_lbl: Label
var notice_lbl: Label
var ghost_bar: HBoxContainer
var name_edit: LineEdit
var row_labels: Dictionary = {}
var tab_vbs: Dictionary = {}
var work_btn: Button


func _ready() -> void:
	position = ORIGIN
	_load()
	if survival_mode and not cfg.has("survival_house_seeded"):
		owned["camisa"] = range(SHIRT.size())
		owned["calca"] = range(PANTS.size())
		cfg["survival_house_seeded"] = true
		if furniture.is_empty():
			furniture.append({"kind":"cama", "x":0.82, "z":3.5, "rot":0.0})
		_save()
	_build_room()
	avatar = _make_avatar(cfg, self)
	(avatar["node"] as Node3D).position = Vector3(pos.x, 0.0, pos.y)
	_rebuild_furniture()
	_build_hud()
	visible = false


func enter() -> void:
	active = true
	visible = true
	pos = Vector2(2.5, 2.5)
	(avatar["node"] as Node3D).rotation.y = PI * 0.25
	menu_open = false
	panel.visible = false
	_update_hud()


func leave() -> void:
	_cancel_ghost()
	for v in visitors:
		((v["av"] as Dictionary)["node"] as Node3D).queue_free()
	visitors.clear()
	active = false
	visible = false
	menu_open = false
	panel.visible = false
	_save()
	_update_hud()


func focus_point() -> Vector3:
	return global_position + Vector3(ROOM * 0.5, 0.9, ROOM * 0.5)


func get_car_path() -> String:
	return str(cfg.get("carro", DEFAULT_CAR))


func update(delta: float, jv: Vector2) -> void:
	if not active:
		return
	if work_cd > 0.0:
		work_cd = maxf(0.0, work_cd - delta)
	if notice_t > 0.0:
		notice_t -= delta
		if notice_t <= 0.0:
			notice_lbl.text = ""
	money_lbl.text = "Saldo: R$ %d" % money_now
	if is_instance_valid(work_btn):
		work_btn.text = ("Fazer bico (+R$ %d)" % WORK_PAY) if work_cd <= 0.0 else ("Próximo bico em %ds" % ceili(work_cd))
		work_btn.disabled = work_cd > 0.0
	_update_visitors(delta)
	if menu_open:
		return
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if jv.length() > 0.15:
		dir += jv
	if dir.length() > 1.0:
		dir = dir.normalized()
	var moving := dir.length() > 0.05
	if moving:
		pos += dir * WALK_SPEED * delta
		pos.x = clampf(pos.x, 0.45, ROOM - 0.45)
		pos.y = clampf(pos.y, 0.45, ROOM - 0.45)
		(avatar["node"] as Node3D).rotation.y = atan2(dir.x, dir.y)
	(avatar["node"] as Node3D).position = Vector3(pos.x, 0.0, pos.y)
	walk_t += delta * 9.0
	_swing(avatar, walk_t, moving)


func _unhandled_input(ev: InputEvent) -> void:
	if not active or menu_open or (survival_mode and (get_parent().intro_state != 0 or get_parent().menu_open)):
		return
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
		_on_click(ev.position)
	elif ev is InputEventMouseMotion and not ghost.is_empty() and (ev.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		var p2 := _floor_point(ev.position)
		if p2.x > -999.0:
			ghost["pos"] = _clamp_pos(p2, str(ghost["kind"]))
			_update_ghost_node()


# ---------- sala ----------

func _mat(col: Color) -> StandardMaterial3D:
	var s := StandardMaterial3D.new()
	s.albedo_color = Color(col.r * 0.8, col.g * 0.8, col.b * 0.8, col.a)
	return s


func _box(size: Vector3, at: Vector3, col: Color, parent: Node3D) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	m.material_override = _mat(col)
	m.position = at
	parent.add_child(m)
	return m


func _build_room() -> void:
	var room := Node3D.new()
	room.name = "Sala"
	add_child(room)
	# piso em xadrez, estilo isométrico
	var tc1 := Color(0.66, 0.60, 0.50)
	var tc2 := Color(0.52, 0.46, 0.38)
	for ix in range(int(ROOM)):
		for iz in range(int(ROOM)):
			var col := tc1 if (ix + iz) % 2 == 0 else tc2
			_box(Vector3(1.0, 0.1, 1.0), Vector3(ix + 0.5, -0.05, iz + 0.5), col, room)
	var h := WALL_H * 0.5
	var wc := Color(0.74, 0.60, 0.44)
	var wf := WALL_T * 0.5
	var sk := Color(0.45, 0.30, 0.20)
	# só as duas paredes de trás (a câmera fica do lado de fora da frente)
	_box(Vector3(ROOM + WALL_T, WALL_H, WALL_T), Vector3(ROOM * 0.5, h, 0.0), wc, room)
	_box(Vector3(WALL_T, WALL_H, ROOM + WALL_T), Vector3(0.0, h, ROOM * 0.5), wc, room)
	# rodapé
	_box(Vector3(ROOM, 0.12, 0.04), Vector3(ROOM * 0.5, 0.06, wf + 0.02), sk, room)
	_box(Vector3(0.04, 0.12, ROOM), Vector3(wf + 0.02, 0.06, ROOM * 0.5), sk, room)
	# quadro-negro com moldura na parede do fundo esquerda
	_box(Vector3(1.9, 1.1, 0.05), Vector3(1.6, 1.5, wf + 0.03), Color(0.14, 0.2, 0.17), room)
	_box(Vector3(2.0, 1.2, 0.03), Vector3(1.6, 1.5, wf + 0.015), Color(0.35, 0.22, 0.12), room)
	# quadro colorido na parede direita
	_box(Vector3(0.05, 0.9, 1.3), Vector3(wf + 0.015, 1.6, 3.4), Color(0.75, 0.42, 0.2), room)
	_box(Vector3(0.03, 0.7, 1.1), Vector3(wf + 0.03, 1.6, 3.4), Color(0.25, 0.5, 0.65), room)
	# janela e tomada
	_box(Vector3(0.05, 0.9, 0.9), Vector3(4.2, 1.7, wf + 0.015), Color(0.4, 0.62, 0.75), room)
	_box(Vector3(2.2, 0.02, 1.5), Vector3(2.6, 0.01, 2.8), Color(0.45, 0.2, 0.2), room)
	_box(Vector3(1.9, 0.022, 1.2), Vector3(2.6, 0.012, 2.8), Color(0.6, 0.5, 0.36), room)
	furn_root = Node3D.new()
	furn_root.name = "Moveis"
	add_child(furn_root)


# ---------- avatar (procedural, só código) ----------

func _pm(mesh: Mesh, at: Vector3, col: Color, parent: Node3D, sc := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = at
	mi.scale = sc
	var mt := StandardMaterial3D.new()
	mt.albedo_color = col
	mt.roughness = 0.8
	mi.material_override = mt
	parent.add_child(mi)
	return mi


func _sph(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 16
	s.rings = 8
	return s


func _cap(r: float, hh: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = hh
	c.radial_segments = 12
	c.rings = 4
	return c


func _cyl(rt: float, rb: float, hh: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = rt
	c.bottom_radius = rb
	c.height = hh
	c.radial_segments = 16
	return c


func _bx(x: float, y: float, z: float) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3(x, y, z)
	return b


func _make_avatar(c: Dictionary, parent: Node3D) -> Dictionary:
	var node := Node3D.new()
	parent.add_child(node)
	var s: float = HEIGHTS[int(c["altura"])]
	var skin: Color = SKIN[int(c["pele"])]
	var shirt: Color = SHIRT[int(c["camisa"])]
	var pants: Color = PANTS[int(c["calca"])]
	var hair: Color = HAIR_COL[int(c["cor_cabelo"])]
	var style: String = HAIR_STYLES[int(c["cabelo"])]
	var shoe := Color(0.12, 0.09, 0.08)
	var legs: Array = []
	var arms: Array = []
	var root := Node3D.new()
	root.scale = Vector3(s, s, s)
	node.add_child(root)
	# pernas e sapatos
	for side in [-1.0, 1.0]:
		var leg := Node3D.new()
		leg.position = Vector3(0.1 * side, 0.84, 0.0)
		root.add_child(leg)
		_pm(_cap(0.085, 0.84), Vector3(0.0, -0.4, 0.0), pants, leg)
		_pm(_sph(0.1), Vector3(0.0, -0.8, 0.05), shoe, leg, Vector3(0.95, 0.62, 1.7))
		legs.append(leg)
		# braços: manga, mão
		var arm := Node3D.new()
		arm.position = Vector3(0.285 * side, 1.43, 0.0)
		root.add_child(arm)
		_pm(_cap(0.068, 0.6), Vector3(0.0, -0.27, 0.0), shirt, arm)
		_pm(_sph(0.065), Vector3(0.0, -0.6, 0.0), skin, arm)
		arms.append(arm)
		# ombros arredondados
		_pm(_sph(0.085), Vector3(0.255 * side, 1.43, 0.0), shirt, root)
	# quadril, cinto e fivela
	_pm(_cyl(0.195, 0.2, 0.2), Vector3(0.0, 0.88, 0.0), pants, root, Vector3(1.0, 1.0, 0.72))
	_pm(_cyl(0.205, 0.205, 0.05), Vector3(0.0, 0.97, 0.0), Color(0.14, 0.1, 0.08), root, Vector3(1.0, 1.0, 0.74))
	_pm(_bx(0.06, 0.045, 0.02), Vector3(0.0, 0.97, 0.155), Color(0.85, 0.7, 0.3), root)
	# tronco afunilado + camisa
	_pm(_cyl(0.235, 0.2, 0.52), Vector3(0.0, 1.22, 0.0), shirt, root, Vector3(1.0, 1.0, 0.72))
	# gola, gravata e distintivo
	_pm(_bx(0.1, 0.045, 0.035), Vector3(-0.055, 1.47, 0.115), shirt.lightened(0.35), root).rotation.z = 0.7
	_pm(_bx(0.1, 0.045, 0.035), Vector3(0.055, 1.47, 0.115), shirt.lightened(0.35), root).rotation.z = -0.7
	_pm(_bx(0.055, 0.3, 0.022), Vector3(0.0, 1.3, 0.152), Color(0.45, 0.1, 0.12), root)
	_pm(_sph(0.032), Vector3(-0.13, 1.33, 0.15), Color(0.9, 0.75, 0.3), root, Vector3(1.0, 1.0, 0.35))
	# pescoço e cabeça
	_pm(_cyl(0.06, 0.07, 0.12), Vector3(0.0, 1.52, 0.0), skin, root)
	_pm(_sph(0.17), Vector3(0.0, 1.72, 0.0), skin, root, Vector3(1.0, 1.1, 1.0))
	_pm(_sph(0.036), Vector3(-0.17, 1.71, 0.0), skin, root, Vector3(0.6, 1.0, 0.9))
	_pm(_sph(0.036), Vector3(0.17, 1.71, 0.0), skin, root, Vector3(0.6, 1.0, 0.9))
	_pm(_sph(0.032), Vector3(0.0, 1.69, 0.168), skin.darkened(0.06), root)
	# olhos, sobrancelhas, boca
	for sx in [-1.0, 1.0]:
		_pm(_sph(0.032), Vector3(0.065 * sx, 1.74, 0.148), Color(0.97, 0.97, 0.95), root, Vector3(1.0, 1.15, 0.5))
		_pm(_sph(0.017), Vector3(0.065 * sx, 1.74, 0.162), Color(0.08, 0.06, 0.05), root, Vector3(1.0, 1.0, 0.5))
		_pm(_bx(0.07, 0.016, 0.02), Vector3(0.065 * sx, 1.795, 0.152), hair.darkened(0.1), root)
	_pm(_bx(0.07, 0.014, 0.012), Vector3(0.0, 1.635, 0.16), Color(0.55, 0.24, 0.24), root)
	# cabelo
	if style != "careca":
		_pm(_sph(0.185), Vector3(0.0, 1.775, -0.02), hair, root, Vector3(1.0, 0.78, 1.08))
		_pm(_bx(0.3, 0.05, 0.04), Vector3(0.0, 1.855, 0.125), hair, root).rotation.x = -0.35
		_pm(_bx(0.03, 0.09, 0.05), Vector3(-0.17, 1.72, 0.04), hair, root)
		_pm(_bx(0.03, 0.09, 0.05), Vector3(0.17, 1.72, 0.04), hair, root)
	match style:
		"longo":
			_pm(_cap(0.14, 0.52), Vector3(0.0, 1.58, -0.1), hair, root, Vector3(1.05, 1.0, 0.6))
			_pm(_cap(0.045, 0.36), Vector3(-0.16, 1.6, -0.01), hair, root)
			_pm(_cap(0.045, 0.36), Vector3(0.16, 1.6, -0.01), hair, root)
		"coque":
			_pm(_sph(0.085), Vector3(0.0, 1.97, -0.07), hair, root)
	# óculos
	if int(c["oculos"]) == 1:
		var dk := Color(0.08, 0.08, 0.1)
		for sx in [-1.0, 1.0]:
			var tm := TorusMesh.new()
			tm.inner_radius = 0.026
			tm.outer_radius = 0.046
			var ring := _pm(tm, Vector3(0.068 * sx, 1.74, 0.172), dk, root)
			ring.rotation.x = PI * 0.5
		_pm(_bx(0.04, 0.01, 0.01), Vector3(0.0, 1.745, 0.175), dk, root)
		_pm(_bx(0.01, 0.01, 0.16), Vector3(-0.115, 1.74, 0.09), dk, root)
		_pm(_bx(0.01, 0.01, 0.16), Vector3(0.115, 1.74, 0.09), dk, root)
	var lab := Label3D.new()
	lab.text = str(c["nome"])
	lab.position = Vector3(0.0, 2.2, 0.0)
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.pixel_size = 0.004
	lab.font_size = 36
	lab.outline_size = 8
	node.add_child(lab)
	return {"node": node, "legs": legs, "arms": arms}


func _glb(path: String, parent: Node3D) -> Node3D:
	var full := MODEL_DIR + path
	if not ResourceLoader.exists(full):
		return null
	var ps := load(full) as PackedScene
	if ps == null:
		return null
	var n := ps.instantiate() as Node3D
	parent.add_child(n)
	return n


func _tint(n: Node, cols: Dictionary) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh != null:
			for i in range(mi.mesh.get_surface_count()):
				var m: Material = mi.mesh.surface_get_material(i)
				if m is StandardMaterial3D and cols.has(str(m.resource_name)):
					var d := m.duplicate() as StandardMaterial3D
					var tc: Color = cols[str(m.resource_name)]
					d.albedo_color = Color(tc.r * 0.8, tc.g * 0.8, tc.b * 0.8)
					mi.set_surface_override_material(i, d)
	for ch in n.get_children():
		_tint(ch, cols)


func _make_avatar_glb(c: Dictionary, node: Node3D, root: Node3D, cols: Dictionary) -> Dictionary:
	var legs: Array = []
	var arms: Array = []
	_glb("avatar/torso.glb", root)
	_glb("avatar/cabelo_" + str(HAIR_STYLES[int(c["cabelo"])]) + ".glb", root)
	if int(c["oculos"]) == 1:
		_glb("avatar/oculos.glb", root)
	for side in [-1.0, 1.0]:
		var leg := Node3D.new()
		leg.position = Vector3(0.11 * side, 0.8, 0.0)
		root.add_child(leg)
		_glb("avatar/perna.glb", leg)
		legs.append(leg)
		var arm := Node3D.new()
		arm.position = Vector3(0.3 * side, 1.44, 0.0)
		root.add_child(arm)
		_glb("avatar/braco.glb", arm)
		arms.append(arm)
	_tint(root, cols)
	var lab := Label3D.new()
	lab.text = str(c["nome"])
	lab.position = Vector3(0.0, 2.25, 0.0)
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.pixel_size = 0.004
	lab.font_size = 36
	node.add_child(lab)
	return {"node": node, "legs": legs, "arms": arms}


func _swing(av: Dictionary, t: float, moving: bool) -> void:
	var sw: float = (sin(t) * 0.6) if moving else 0.0
	var legs: Array = av["legs"]
	var arms: Array = av["arms"]
	(legs[0] as Node3D).rotation.x = sw
	(legs[1] as Node3D).rotation.x = -sw
	(arms[0] as Node3D).rotation.x = -sw * 0.7
	(arms[1] as Node3D).rotation.x = sw * 0.7


func _refresh_avatar() -> void:
	if not avatar.is_empty():
		(avatar["node"] as Node3D).queue_free()
	avatar = _make_avatar(cfg, self)
	(avatar["node"] as Node3D).position = Vector3(pos.x, 0.0, pos.y)


# ---------- visitas com convite ----------

func _invite(nm: String) -> void:
	if visitors.size() >= MAX_VISITORS:
		_notice("Já tem visita na casa.")
		return
	var c := {
		"pele": randi() % SKIN.size(), "cabelo": randi() % HAIR_STYLES.size(),
		"cor_cabelo": randi() % HAIR_COL.size(), "altura": randi() % HEIGHTS.size(),
		"camisa": randi() % SHIRT.size(), "calca": randi() % PANTS.size(),
		"oculos": randi() % 2, "nome": nm,
	}
	var av := _make_avatar(c, self)
	var start := Vector2(randf_range(1.5, 3.5), ROOM - 0.4)
	(av["node"] as Node3D).position = Vector3(start.x, 0.0, start.y)
	visitors.append({"av": av, "t": VISIT_TIME, "wander": 0.0, "pos": start, "tgt": Vector2(2.5, 3.0), "walk": 0.0})
	_notice("%s entrou na casa." % nm)


func _update_visitors(delta: float) -> void:
	for i in range(visitors.size() - 1, -1, -1):
		var v: Dictionary = visitors[i]
		v["t"] = float(v["t"]) - delta
		v["wander"] = float(v["wander"]) - delta
		if float(v["wander"]) <= 0.0:
			v["wander"] = randf_range(3.0, 6.0)
			v["tgt"] = Vector2(randf_range(0.6, ROOM - 0.6), randf_range(0.6, ROOM - 0.6))
		var p: Vector2 = v["pos"]
		var tg: Vector2 = v["tgt"]
		var d: Vector2 = tg - p
		var moving := d.length() > 0.05
		var node := (v["av"] as Dictionary)["node"] as Node3D
		if moving:
			p += d.normalized() * minf(VISITOR_SPEED * delta, d.length())
			v["pos"] = p
			node.rotation.y = atan2(d.x, d.y)
			v["walk"] = float(v["walk"]) + delta * 9.0
		node.position = Vector3(p.x, 0.0, p.y)
		_swing(v["av"], float(v["walk"]), moving)
		if float(v["t"]) <= 0.0:
			node.queue_free()
			visitors.remove_at(i)
			_notice("Visita foi embora.")


# ---------- móveis: posicionar arrastando no chão ----------

func _rot2(v: Vector2, a: float) -> Vector2:
	return Vector2(v.x * cos(a) + v.y * sin(a), -v.x * sin(a) + v.y * cos(a))


func _floor_point(sp: Vector2) -> Vector2:
	if cam == null:
		return Vector2(-9999.0, -9999.0)
	var o := cam.project_ray_origin(sp)
	var d := cam.project_ray_normal(sp)
	if absf(d.y) < 0.0001:
		return Vector2(-9999.0, -9999.0)
	var w := o + d * (-o.y / d.y)
	var l := to_local(w)
	return Vector2(l.x, l.z)


func _clamp_pos(p: Vector2, kind: String) -> Vector2:
	var sz: Vector3 = (FURN[kind] as Dictionary)["size"]
	var m := maxf(sz.x, sz.z) * 0.5
	return Vector2(clampf(p.x, m, ROOM - m), clampf(p.y, m, ROOM - m))


func _pick_screen(sp: Vector2) -> int:
	if cam == null:
		return -1
	var best := -1
	var best_d := 90.0
	for i in furniture.size():
		var it: Dictionary = furniture[i]
		var d: Dictionary = FURN.get(str(it["kind"]), {})
		if d.is_empty():
			continue
		var sz: Vector3 = d["size"]
		var wp := global_position + Vector3(float(it["x"]), sz.y * 0.5, float(it["z"]))
		if cam.is_position_behind(wp):
			continue
		var dd := cam.unproject_position(wp).distance_to(sp)
		if dd < best_d:
			best_d = dd
			best = i
	return best


func _on_click(sp: Vector2) -> void:
	if not ghost.is_empty():
		var p := _floor_point(sp)
		if p.x > -999.0:
			ghost["pos"] = _clamp_pos(p, str(ghost["kind"]))
			_update_ghost_node()
		return
	var idx := _pick_screen(sp)
	if idx < 0:
		return
	var it: Dictionary = furniture[idx]
	furniture.remove_at(idx)
	_start_ghost(str(it["kind"]), false, it)
	_rebuild_furniture()
	if not survival_mode:
		_save()


func _start_inv(kind: String) -> void:
	if _inv(kind) <= 0:
		return
	_add_inv(kind, -1)
	_start_ghost(kind, true, {})
	if not survival_mode:
		_save()


func _start_ghost(kind: String, from_inv: bool, old: Dictionary) -> void:
	_end_ghost()
	var gp := pos
	if old.has("x"):
		gp = Vector2(float(old["x"]), float(old["z"]))
	ghost = {"kind": kind, "rot": float(old.get("rot", 0.0)), "pos": gp, "from_inv": from_inv, "old": old}
	var d: Dictionary = FURN[kind]
	var sz: Vector3 = d["size"]
	var base: Color = d["color"]
	ghost_node = Node3D.new()
	add_child(ghost_node)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(base.r, base.g, base.b, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat
	mi.position = Vector3(0.0, sz.y * 0.5, 0.0)
	ghost_node.add_child(mi)
	_update_ghost_node()
	ghost_bar.visible = true
	panel.visible = false
	menu_open = false
	_notice("Arraste no chão para mover. Confirme com Colocar.")


func _update_ghost_node() -> void:
	if ghost_node == null or ghost.is_empty():
		return
	var gp: Vector2 = ghost["pos"]
	ghost_node.position = Vector3(gp.x, 0.0, gp.y)
	ghost_node.rotation.y = float(ghost["rot"])


func _end_ghost() -> void:
	ghost = {}
	if ghost_node != null:
		ghost_node.queue_free()
		ghost_node = null
	ghost_bar.visible = false


func _confirm_ghost() -> void:
	if ghost.is_empty():
		return
	var gp: Vector2 = ghost["pos"]
	furniture.append({"kind": ghost["kind"], "x": gp.x, "z": gp.y, "rot": ghost["rot"]})
	_end_ghost()
	_rebuild_furniture()
	_save()
	if survival_mode:
		_notice("Móvel colocado.")
	else:
		_fill_all()


func _cancel_ghost() -> void:
	if ghost.is_empty():
		return
	if bool(ghost["from_inv"]):
		_add_inv(str(ghost["kind"]), 1)
	else:
		furniture.append(ghost["old"])
	_end_ghost()
	_rebuild_furniture()
	_save()


func _rotate_ghost() -> void:
	if ghost.is_empty():
		return
	ghost["rot"] = float(ghost["rot"]) + PI * 0.5
	_update_ghost_node()


func _rebuild_furniture() -> void:
	for c in furn_root.get_children():
		c.queue_free()
	for it in furniture:
		var d: Dictionary = FURN.get(str(it["kind"]), {})
		if d.is_empty():
			continue
		var sz: Vector3 = d["size"]
		var holder := Node3D.new()
		holder.position = Vector3(float(it["x"]), 0.0, float(it["z"]))
		holder.rotation.y = float(it["rot"])
		furn_root.add_child(holder)
		if _glb("moveis/" + str(it["kind"]) + ".glb", holder) == null:
			_box(sz, Vector3(0.0, sz.y * 0.5, 0.0), d["color"], holder)


func _inv(kind: String) -> int:
	return int(inventory.get(kind, 0))


func _add_inv(kind: String, n: int) -> void:
	inventory[kind] = _inv(kind) + n


# ---------- compras, dinheiro e bico ----------

func _pay(price: int) -> bool:
	if money_now < price:
		_notice("Dinheiro insuficiente.")
		return false
	money_delta.emit(-price)
	_save()
	return true


func _buy_furniture(kind: String) -> void:
	if not _pay(int(FURN[kind]["preco"])):
		return
	_add_inv(kind, 1)
	_save()
	_fill_all()
	_notice("Comprou %s." % FURN[kind]["nome"])


func _buy_cloth(cat: String, item: Dictionary) -> void:
	if not _pay(int(item["preco"])):
		return
	var lst: Array = owned[cat]
	lst.append(int(item["idx"]))
	lst.sort()
	_save()
	_fill_all()
	_notice("Comprou %s %s." % [CLOTHES_NAME[cat], item["nome"]])


func _buy_car(c: Dictionary) -> void:
	if not _pay(int(c["preco"])):
		return
	(owned["carros"] as Array).append(str(c["path"]))
	_save()
	_fill_all()
	_notice("Comprou o carro %s." % c["nome"])


func _use_car(path: String) -> void:
	cfg["carro"] = path
	car_selected.emit(path)
	_save()
	_fill_all()


func _work() -> void:
	if work_cd > 0.0:
		return
	money_delta.emit(WORK_PAY)
	work_cd = WORK_COOLDOWN
	_save()
	_notice("Bico feito: +R$ %d." % WORK_PAY)


# ---------- interface ----------

func _build_hud() -> void:
	hud = CanvasLayer.new()
	hud.layer = 11
	add_child(hud)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(root)
	btn_enter = _btn("Voltar para casa", 160.0)
	btn_enter.pressed.connect(func(): request_enter.emit())
	root.add_child(btn_enter)
	btn_menu = _btn("Menu da casa", 160.0)
	if survival_mode:
		btn_menu.pressed.connect(func(): request_actions.emit())
	else:
		btn_menu.pressed.connect(_toggle_menu)
	root.add_child(btn_menu)
	btn_exit = _btn("Sair de casa", 206.0)
	btn_exit.pressed.connect(func(): request_exit.emit())
	root.add_child(btn_exit)
	notice_lbl = Label.new()
	notice_lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	notice_lbl.offset_left = -300.0
	notice_lbl.offset_right = 300.0
	notice_lbl.offset_top = 14.0
	notice_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(notice_lbl)
	ghost_bar = HBoxContainer.new()
	ghost_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	ghost_bar.offset_left = -190.0
	ghost_bar.offset_right = 190.0
	ghost_bar.offset_top = -90.0
	ghost_bar.offset_bottom = -40.0
	ghost_bar.visible = false
	root.add_child(ghost_bar)
	var bg := Button.new()
	bg.text = "Girar"
	bg.pressed.connect(_rotate_ghost)
	ghost_bar.add_child(bg)
	var bc := Button.new()
	bc.text = "Colocar"
	bc.pressed.connect(_confirm_ghost)
	ghost_bar.add_child(bc)
	var bx := Button.new()
	bx.text = "Cancelar"
	bx.pressed.connect(_cancel_ghost)
	ghost_bar.add_child(bx)
	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	panel.offset_left = -500.0
	panel.offset_right = -20.0
	panel.offset_top = -270.0
	panel.offset_bottom = 270.0
	panel.visible = false
	root.add_child(panel)
	var vb := VBoxContainer.new()
	panel.add_child(vb)
	var head := HBoxContainer.new()
	vb.add_child(head)
	var t := Label.new()
	t.text = "Casa"
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	money_lbl = Label.new()
	head.add_child(money_lbl)
	var fx := Button.new()
	fx.text = "Fechar"
	fx.pressed.connect(_toggle_menu)
	head.add_child(fx)
	tabs = TabContainer.new()
	tabs.custom_minimum_size = Vector2(470.0, 480.0)
	vb.add_child(tabs)
	for nm in TAB_NAMES:
		var sc := ScrollContainer.new()
		sc.name = nm
		sc.custom_minimum_size = Vector2(460.0, 440.0)
		var inner := VBoxContainer.new()
		inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sc.add_child(inner)
		tabs.add_child(sc)
		tab_vbs[nm] = inner
	_build_avatar_tab()
	_fill_all()
	_update_hud()


func _btn(text: String, top: float) -> Button:
	var b := Button.new()
	b.text = text
	b.position = Vector2(20.0, top)
	b.custom_minimum_size = Vector2(220.0, 36.0)
	return b


func _label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	return l


func _head(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", Color(1.0, 0.92, 0.7))
	return l


func _row_action(title: String, btn_text: String, disabled: bool, cb: Callable) -> HBoxContainer:
	var hb := HBoxContainer.new()
	var lab := Label.new()
	lab.text = title
	lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(lab)
	var b := Button.new()
	b.text = btn_text
	b.disabled = disabled
	b.pressed.connect(cb)
	hb.add_child(b)
	return hb


func _build_avatar_tab() -> void:
	var vb: VBoxContainer = tab_vbs["Avatar"]
	for r in CAT_ROWS:
		_add_row(vb, str(r[0]), str(r[1]), int(r[2]))
	name_edit = LineEdit.new()
	name_edit.placeholder_text = "Nome do avatar"
	name_edit.max_length = 16
	name_edit.text = str(cfg["nome"])
	name_edit.text_changed.connect(_on_name_changed)
	if OS.has_feature("web"):
		name_edit.editable = false
		name_edit.placeholder_text = "Toque para digitar o nome"
		name_edit.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed:
				ask_name())
	vb.add_child(name_edit)
	_refresh_rows()


func _add_row(vb: VBoxContainer, key: String, text: String, count: int) -> void:
	var hb := HBoxContainer.new()
	vb.add_child(hb)
	var lab := Label.new()
	lab.custom_minimum_size = Vector2(230.0, 0.0)
	hb.add_child(lab)
	var prev := Button.new()
	prev.text = "<"
	prev.pressed.connect(_cycle.bind(key, -1, count))
	hb.add_child(prev)
	var nxt := Button.new()
	nxt.text = ">"
	nxt.pressed.connect(_cycle.bind(key, 1, count))
	hb.add_child(nxt)
	row_labels[key] = {"label": lab, "text": text, "count": count}


func _refresh_rows() -> void:
	for key in row_labels.keys():
		var r: Dictionary = row_labels[key]
		var lab: Label = r["label"]
		var cur := 0
		var total := 0
		if owned.has(key):
			var lst: Array = owned[key]
			cur = lst.find(int(cfg[key])) + 1
			total = lst.size()
		else:
			cur = int(cfg[key]) + 1
			total = int(r["count"])
		lab.text = "%s: %d/%d" % [r["text"], cur, total]


func _cycle(key: String, step: int, count: int) -> void:
	if owned.has(key):
		var lst: Array = owned[key]
		var i := lst.find(int(cfg[key]))
		if i < 0:
			i = 0
		cfg[key] = int(lst[posmod(i + step, lst.size())])
	else:
		cfg[key] = posmod(int(cfg[key]) + step, count)
	_refresh_avatar()
	_refresh_rows()
	_save()


func reset_all() -> void:
	cfg = {"pele": 0, "cabelo": 0, "cor_cabelo": 0, "altura": 1, "camisa": 0, "calca": 0, "oculos": 0, "nome": "Você", "carro": DEFAULT_CAR}
	owned = {"camisa": [0, 1], "calca": [0, 1], "carros": [DEFAULT_CAR]}
	furniture = []
	inventory = {}
	money_now = 500
	_refresh_avatar()
	_rebuild_furniture()
	_refresh_rows()
	if name_edit != null:
		name_edit.text = ""


func ask_name() -> void:
	# no navegador/celular o teclado do canvas não é confiável: usa a caixa nativa do navegador
	var cur := str(cfg.get("nome", ""))
	if cur == "Você":
		cur = ""
	var r: Variant = JavaScriptBridge.eval("window.prompt('Digite o nome do seu sobrevivente (até 14 letras):', %s)" % JSON.stringify(cur))
	if r != null:
		var s := str(r).strip_edges()
		if s.length() > 14:
			s = s.substr(0, 14)
		if s != "":
			_on_name_changed(s)
			if name_edit != null:
				name_edit.text = s


func _on_name_changed(t: String) -> void:
	cfg["nome"] = t
	_refresh_avatar()
	_save()


func _clear(vb: VBoxContainer) -> void:
	for c in vb.get_children():
		c.queue_free()


func _fill_all() -> void:
	_fill_loja()
	_fill_moveis()
	_fill_garagem()
	_fill_convidados()
	_refresh_rows()
	money_lbl.text = "Saldo: R$ %d" % money_now


func _fill_loja() -> void:
	var vb: VBoxContainer = tab_vbs["Loja"]
	_clear(vb)
	vb.add_child(_head("Trabalho"))
	work_btn = Button.new()
	work_btn.pressed.connect(_work)
	vb.add_child(work_btn)
	vb.add_child(_head("Roupas"))
	for cat in CLOTHES.keys():
		for item in CLOTHES[cat]:
			var have: bool = (owned[cat] as Array).has(int(item["idx"]))
			var title := "%s %s" % [CLOTHES_NAME[cat], item["nome"]]
			var btxt := "Já tem" if have else ("R$ %d" % int(item["preco"]))
			vb.add_child(_row_action(title, btxt, have, _buy_cloth.bind(cat, item)))
	vb.add_child(_head("Móveis"))
	for kind in FURN.keys():
		var f: Dictionary = FURN[kind]
		vb.add_child(_row_action(str(f["nome"]), "R$ %d" % int(f["preco"]), false, _buy_furniture.bind(kind)))


func _fill_moveis() -> void:
	var vb: VBoxContainer = tab_vbs["Móveis"]
	_clear(vb)
	vb.add_child(_head("Inventário"))
	var any := false
	for kind in FURN.keys():
		var n := _inv(kind)
		if n > 0:
			any = true
			vb.add_child(_row_action("%s x%d" % [FURN[kind]["nome"], n], "Colocar", not ghost.is_empty(), _start_inv.bind(kind)))
	if not any:
		vb.add_child(_label("Nenhum móvel. Compre na Loja."))
	vb.add_child(_head("Na casa: %d peças. Toque numa peça no chão para pegá-la." % furniture.size()))


func _fill_garagem() -> void:
	var vb: VBoxContainer = tab_vbs["Garagem"]
	_clear(vb)
	vb.add_child(_head("Seus carros"))
	for c in CARS:
		var path := str(c["path"])
		var has: bool = (owned["carros"] as Array).has(path)
		var in_use := get_car_path() == path
		if not has:
			vb.add_child(_row_action(str(c["nome"]), "R$ %d" % int(c["preco"]), false, _buy_car.bind(c)))
		elif in_use:
			vb.add_child(_row_action(str(c["nome"]), "Em uso", true, _use_car.bind(path)))
		else:
			vb.add_child(_row_action(str(c["nome"]), "Usar", false, _use_car.bind(path)))


func _fill_convidados() -> void:
	var vb: VBoxContainer = tab_vbs["Convidados"]
	_clear(vb)
	vb.add_child(_head("Quem pode entrar"))
	vb.add_child(_label("Só entra quem você convidar. A visita fica 1 minuto."))
	if neighbors.is_empty():
		vb.add_child(_label("Ninguém por perto."))
	for nm in neighbors:
		vb.add_child(_row_action(str(nm), "Convidar", false, _invite.bind(str(nm))))


func _toggle_menu() -> void:
	if not active:
		return
	panel.visible = not panel.visible
	menu_open = panel.visible
	if menu_open:
		_fill_all()
	else:
		_save()


func _notice(t: String) -> void:
	notice_lbl.text = t
	notice_t = 2.5


func _update_hud() -> void:
	btn_enter.visible = not active and not survival_mode
	btn_menu.visible = active
	btn_exit.visible = active
	notice_lbl.visible = active
	if not active:
		notice_lbl.text = ""
		panel.visible = false
		ghost_bar.visible = false


# ---------- salvamento ----------

func _ints(arr) -> Array:
	var out: Array = []
	for v in arr:
		out.append(int(v))
	return out


func _load() -> void:
	cfg = {"pele": 0, "cabelo": 0, "cor_cabelo": 0, "altura": 1, "camisa": 0, "calca": 0, "oculos": 0, "nome": "Você", "carro": DEFAULT_CAR}
	owned = {"camisa": [0, 1], "calca": [0, 1], "carros": [DEFAULT_CAR]}
	if not FileAccess.file_exists(save_path):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if typeof(data) != TYPE_DICTIONARY:
		return
	var c = data.get("cfg", {})
	if typeof(c) == TYPE_DICTIONARY:
		for k in c.keys():
			cfg[k] = c[k]
	var ow = data.get("owned", {})
	if typeof(ow) == TYPE_DICTIONARY:
		for k in ow.keys():
			owned[k] = ow[k]
		owned["camisa"] = _ints(owned.get("camisa", [0, 1]))
		owned["calca"] = _ints(owned.get("calca", [0, 1]))
	var fl = data.get("furniture", [])
	if typeof(fl) == TYPE_ARRAY:
		furniture = fl
	var inv = data.get("inventory", {})
	if typeof(inv) == TYPE_DICTIONARY:
		inventory = inv
	money_now = int(data.get("dinheiro", 500))


func _save() -> void:
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"cfg": cfg, "owned": owned, "furniture": furniture, "inventory": inventory, "dinheiro": money_now}))
