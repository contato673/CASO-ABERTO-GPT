extends Node

const SAVE := "user://campo_grande_survival_v1.json"
const ART := "res://assets/survival_local/"
const CAPACITY := 18
const CHEST_CAPACITY := 60
const LOOT_MIN_SECONDS := 2 * 3600
const LOOT_MAX_SECONDS := 6 * 3600
const ITEM_NAMES := {
	"water": "Água", "food": "Conserva", "med": "Primeiros socorros",
	"fuel": "Galão de combustível", "parts": "Peças", "bat": "Taco", "crowbar": "Pé de cabra"
}
const QUESTS := [
	{"place": "pague_menos_13", "item": "med", "title": "Primeiros socorros", "request": "Busque um kit na Pague Menos da Rua 13 de Maio.", "reward": "water"},
	{"place": "mercado", "item": "food", "title": "Rações para o abrigo", "request": "Busque uma conserva no Mercadão, Rua 7 de Setembro.", "reward": "med"},
	{"place": "patio_central", "item": "parts", "title": "O rádio do abrigo", "request": "Recolha peças no Pátio Central Shopping, Rua Marechal Rondon.", "reward": "fuel"}
]
const NEEDS := ["saude", "fome", "sede", "energia"]
const COLORS := [Color("#f47e80"), Color("#f4bc70"), Color("#73cde7"), Color("#d0dc80")]
# Heart, bread, drop and bolt. A plus marks the highlight pixels.
const METER_PIXELS := [
	["..........", ".++....++.", "+##+..####", "+#########", ".########.", ".########.", "..######..", "...####...", "....##....", ".........."],
	["..........", "...####...", "..##+#++..", ".###++##+.", ".+###++##.", ".-###++##.", ".-######-.", "..------..", "..........", ".........."],
	["....##....", "....##....", "...####...", "...####...", "..#+####..", ".#+######.", ".#+######.", ".##-####-.", "..------..", ".........."],
	[".....###..", "....+##...", "...+##....", "..+######.", ".+#######.", "....###...", "...###....", "...##.....", "..##......", "..#......."],
]

var game
var needs := {"saude":100.0, "fome":92.0, "sede":89.0, "energia":100.0}
var bag := {"water":1, "food":1, "bat":1}
var chest: Dictionary = {}
var containers: Dictionary = {}
var taken: Dictionary = {}
var sites: Dictionary = {}
var infected: Array[Dictionary] = []
var noises: Array[Dictionary] = []
var active_vehicle := -1
var fuel := 0.0
var quest := 0
var supply_found := false
var reputation := 0
var next_contract := 0.0
var safe := Vector2.ZERO
var closest_site: Dictionary = {}
var panel: PanelContainer
var body: VBoxContainer
var window_title: Label
var feedback: Label
var hud: GridContainer
var meter_labels: Array[Label] = []
var meter_cards: Array[PanelContainer] = []
var bars: Array[ProgressBar] = []
var pulse := 0.0
var restock_label: Label
var save_timer := 0.0
var population_timer := 0.0
var swing := 0.0
var noise_timer := 0.0
var menu_kind := ""
var opened: Dictionary = {}
var icons: Dictionary = {}
var down := false
var direction := Vector2(0, 1)

func setup(city_game: Node) -> void:
	game = city_game
	for p in game.pois:
		sites[str(p["id"])] = p
	safe = _entrance(sites["central"])
	_build_hud()
	_load_progress()
	for i in 8:
		icons["zombie_%d" % i] = _texture("zombie_%d" % i)
	for item in ITEM_NAMES:
		icons[item] = _texture(item)
	if active_vehicle < 0:
		game.on_foot = true
	game.walker.visible = game.on_foot
	if not _valid_position(game.walk_pos) or not is_finite(game.walk_pos.x):
		game.walk_pos = safe
	game.walker.position = Vector3(game.walk_pos.x, 0.04, game.walk_pos.y)
	_refresh_vehicle()
	_update_near()


func tick(delta: float) -> void:
	if down:
		return
	var where: Vector2 = game._actor_pos()
	var in_shelter := where.distance_to(safe) < 8.0
	var moving: bool = game.on_foot and direction.length_squared() > 0.02
	swing = maxf(0, swing - delta)
	noise_timer = maxf(0, noise_timer - delta)
	needs["fome"] = maxf(0.0, float(needs["fome"]) - delta * (0.052 if moving else 0.034))
	needs["sede"] = maxf(0.0, float(needs["sede"]) - delta * (0.079 if moving else 0.052))
	if moving:
		needs["energia"] = maxf(0.0, float(needs["energia"]) - delta * 0.33)
	else:
		var recovery := 1.7 if in_shelter else 0.38
		if needs["fome"] < 15.0 or needs["sede"] < 15.0:
			recovery *= 0.25
		needs["energia"] = minf(100.0, float(needs["energia"]) + recovery * delta)
	if needs["fome"] <= 0.0 or needs["sede"] <= 0.0:
		needs["saude"] = maxf(0.0, float(needs["saude"]) - delta * (0.65 if needs["sede"] <= 0.0 else 0.38))
	if not game.on_foot and absf(game.car_speed) > 1.5:
		fuel = maxf(0.0, fuel - delta * absf(game.car_speed) * 0.021)
		if noise_timer == 0.0:
			make_noise(where, 29.0)
			noise_timer = 1.0
	for i in range(noises.size() - 1, -1, -1):
		noises[i]["life"] -= delta
		if noises[i]["life"] <= 0.0:
			noises.remove_at(i)
	population_timer -= delta
	if population_timer <= 0.0:
		population_timer = 2.8
		_population(where)
	_update_infected(where, delta, in_shelter)
	_update_near()
	pulse += delta
	if pulse > 0.15:
		pulse = 0.0
		_update_hud()
		_update_restock_countdown()
	save_timer += delta
	if save_timer > 5.0:
		save_timer = 0.0
		save()
	if needs["saude"] <= 0.0:
		down = true
		game.menu_open = true
		_open_panel("queda", "Você caiu")
		_line("Volte ao abrigo. O equipamento que carregava ficou para trás.")
		_button("Voltar ao abrigo", _revive)


func walking_speed() -> float:
	var stamina := clampf(float(needs["energia"]) / 30.0, 0.35, 1.0)
	var injury := clampf(float(needs["saude"]) / 45.0, 0.55, 1.0)
	return 5.2 * stamina * injury


func objective_id() -> String:
	if quest >= QUESTS.size() or supply_found:
		return "central"
	return str(QUESTS[quest]["place"])


func objective_text() -> String:
	if quest >= QUESTS.size():
		if _now() >= next_contract:
			return "Rede do abrigo\nPasse no abrigo para aceitar outro contrato."
		return "Rede do abrigo · reputação %d\nPróximo contrato em %s." % [reputation, _duration(next_contract - _now())]
	var task: Dictionary = QUESTS[quest]
	if supply_found:
		var item: String = task["item"]
		var name := str(ITEM_NAMES[item]).to_lower()
		if not bag.has(item) and chest.has(item):
			return "%s\nRetire %s do baú para fazer a entrega." % [task["title"], name]
		return "%s\nLeve %s ao abrigo da Rua Barão do Rio Branco." % [task["title"], name]
	return "%s\n%s" % [task["title"], task["request"]]


func layout(available_width: float) -> void:
	var width := minf(400.0, available_width)
	hud.position = Vector2(12, 12)
	for card in meter_cards:
		card.custom_minimum_size.x = (width - 8.0) * 0.5
	hud.size.x = width
	if panel.visible:
		_position_panel()


func available() -> bool:
	return game.on_foot and not closest_site.is_empty()


func walk_location_click(screen: Vector2) -> bool:
	if not available() or game.menu_open:
		return false
	var anchor: Vector2 = _entrance(closest_site)
	var point: Vector2 = game.cam.unproject_position(Vector3(anchor.x, 2.8, anchor.y))
	if screen.distance_to(point) > 115.0:
		return false
	interact()
	return true


func interact() -> void:
	if not game.on_foot or closest_site.is_empty() or down:
		return
	opened = closest_site
	if str(opened["id"]) == "central":
		_shelter_menu()
	else:
		_loot_menu()


func inventory() -> void:
	if down:
		return
	if menu_kind == "inventory":
		close()
		return
	_open_panel("inventory", "Mochila · %d/%d" % [_bag_count(), CAPACITY])
	for item in ITEM_NAMES:
		var count := int(bag.get(item, 0))
		if count == 0:
			continue
		var caption := "%s ×%d" % [ITEM_NAMES[item], count]
		if item in ["food", "water", "med", "fuel"]:
			_button(caption + "   Usar", _use.bind(item), item)
		else:
			_line(caption)
	if _bag_count() == 0:
		_line("Mochila vazia.")


func close() -> void:
	if down:
		return
	panel.hide()
	game.menu_open = false
	menu_kind = ""
	game.joy_vec = Vector2.ZERO
	game.joy_active = false


func vehicle_available() -> bool:
	if not game.on_foot:
		return absf(game.car_speed) <= 2.0
	return _nearest_vehicle() >= 0


func vehicle_caption() -> String:
	if not game.on_foot:
		return "Descer"
	var index := _nearest_vehicle()
	return "Entrar" if index == active_vehicle else "Roubar"


func toggle_vehicle() -> void:
	if game.menu_open or down:
		return
	if not game.on_foot:
		if absf(game.car_speed) > 2.0:
			return
		var side: Vector2 = Vector2(cos(game.car_heading), sin(game.car_heading)).orthogonal()
		for scale in [2.1, -2.1, 2.8, -2.8]:
			var door: Vector2 = game.car_pos + side * float(scale)
			if _valid_position(door):
				game.walk_pos = door
				game.walker.position = Vector3(door.x, 0.04, door.y)
				game.on_foot = true
				game.walker.show()
				game.car_speed = 0.0
				save()
				break
		return
	var index := _nearest_vehicle()
	if index < 0:
		return
	if index != active_vehicle:
		var info: Dictionary = game.parked_vehicles[index]
		var was_stolen := taken.has(str(index))
		if active_vehicle >= 0:
			var previous: Dictionary = game.parked_vehicles[active_vehicle]
			previous["pos"] = game.car_pos
			previous["heading"] = game.car_heading
			previous["fuel"] = fuel
			taken[str(active_vehicle)] = _vehicle_record(previous)
			_set_parked_pose(previous)
			previous["node"].show()
		active_vehicle = index
		game.car_pos = info["pos"]
		game.car_heading = info["heading"]
		fuel = float(info.get("fuel", 16.0 + float(index % 40)))
		taken[str(index)] = _vehicle_record(info)
		info["node"].hide()
		game._swap_car(info["path"])
		if not was_stolen:
			make_noise(game.car_pos, 60.0)
			_notify("Vidro do carro quebrado. Infectados ouviram.")
	game.on_foot = false
	game.walker.hide()
	game.car_root.show()
	game.car_root.position = Vector3(game.car_pos.x, 0, game.car_pos.y)
	game.car_root.rotation.y = atan2(cos(game.car_heading), sin(game.car_heading))
	game.route_target = ""
	save()


func attack() -> void:
	if down or game.menu_open or not game.on_foot or swing > 0.0:
		return
	if needs["energia"] < 6.0:
		_notify("Sem energia para atacar.")
		return
	var reach := 3.05 if bag.has("crowbar") or bag.has("bat") else 1.8
	var damage := 38.0 if bag.has("crowbar") else (30.0 if bag.has("bat") else 14.0)
	swing = 0.64
	needs["energia"] = maxf(0.0, float(needs["energia"]) - 5.0)
	var nearest: Dictionary = {}
	var best := reach
	for zombie in infected:
		if zombie["state"] == "dead":
			continue
		var d: float = game.walk_pos.distance_to(zombie["pos"])
		if d < best and _clear_line(game.walk_pos, zombie["pos"]):
			nearest = zombie
			best = d
	make_noise(game.walk_pos, 13.0)
	if nearest.is_empty():
		_notify("Golpe no ar.")
		return
	_damage_zombie(nearest, damage)


func make_noise(at: Vector2, radius: float) -> void:
	noises.append({"pos":at, "radius":radius, "life":2.6})
	if noises.size() > 12:
		noises.pop_front()


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 8
	add_child(layer)
	hud = GridContainer.new()
	hud.columns = 2
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_theme_constant_override("h_separation", 8)
	hud.add_theme_constant_override("v_separation", 4)
	layer.add_child(hud)
	for i in NEEDS.size():
		var card := PanelContainer.new()
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var plate := StyleBoxFlat.new()
		plate.bg_color = Color(0.09, 0.11, 0.15, 0.94)
		plate.border_color = Color(COLORS[i], 0.38)
		plate.set_border_width_all(1)
		plate.set_corner_radius_all(5)
		plate.content_margin_left = 6
		plate.content_margin_right = 6
		plate.content_margin_top = 3
		plate.content_margin_bottom = 3
		card.add_theme_stylebox_override("panel", plate)
		hud.add_child(card)
		meter_cards.append(card)
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 5)
		card.add_child(row)
		var icon := TextureRect.new()
		icon.texture = _meter_icon(i)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(20, 20)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size.y = 6
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var background := StyleBoxFlat.new()
		background.bg_color = Color("#383d49")
		background.set_corner_radius_all(3)
		var fill := StyleBoxFlat.new()
		fill.bg_color = COLORS[i]
		fill.set_corner_radius_all(3)
		bar.add_theme_stylebox_override("background", background)
		bar.add_theme_stylebox_override("fill", fill)
		row.add_child(bar)
		bars.append(bar)
		var label := Label.new()
		label.custom_minimum_size.x = 25
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", Color("#f7f2e7"))
		row.add_child(label)
		meter_labels.append(label)
	feedback = Label.new()
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(feedback)
	feedback.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	feedback.offset_left = -175
	feedback.offset_right = 175
	feedback.offset_top = -300
	feedback.offset_bottom = -240
	game._label_bg(feedback, 8, 6)
	feedback.hide()
	panel = PanelContainer.new()
	var surface := StyleBoxFlat.new()
	surface.bg_color = Color("#242632")
	surface.border_color = Color("#b99b69")
	surface.set_border_width_all(2)
	surface.content_margin_top = 14
	surface.content_margin_bottom = 14
	surface.content_margin_left = 16
	surface.content_margin_right = 16
	panel.add_theme_stylebox_override("panel", surface)
	layer.add_child(panel)
	var root := VBoxContainer.new()
	panel.add_child(root)
	var row := HBoxContainer.new()
	root.add_child(row)
	window_title = Label.new()
	window_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	window_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	window_title.add_theme_font_size_override("font_size", 24)
	row.add_child(window_title)
	var exit := Button.new()
	exit.text = "Fechar"
	exit.pressed.connect(close)
	row.add_child(exit)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 8)
	scroll.add_child(body)
	panel.hide()
	_update_hud()


func _open_panel(kind: String, title: String) -> void:
	menu_kind = kind
	restock_label = null
	game.menu_open = true
	game.joy_vec = Vector2.ZERO
	game.joy_active = false
	direction = Vector2.ZERO
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	window_title.text = title
	_position_panel()
	panel.show()
	_position_panel.call_deferred()


func _position_panel() -> void:
	var viewport := get_viewport().get_visible_rect().size
	var width := minf(490, viewport.x - 32)
	var height := clampf(body.get_combined_minimum_size().y + 94.0, 160.0, minf(330.0, viewport.y * 0.57))
	panel.size = Vector2(width, height)
	panel.position = (viewport - panel.size) * 0.5


func _line(content: String) -> Label:
	var label := Label.new()
	label.text = content
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 17)
	body.add_child(label)
	return label


func _button(caption: String, action: Callable, item := "") -> void:
	var btn := Button.new()
	btn.text = caption
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.icon = icons.get(item)
	btn.expand_icon = true
	btn.add_theme_constant_override("icon_max_width", 32)
	btn.custom_minimum_size.y = 46
	btn.pressed.connect(action)
	body.add_child(btn)


func _meter_icon(index: int) -> ImageTexture:
	var pixels: Array = METER_PIXELS[index]
	var image := Image.create_empty(10, 10, false, Image.FORMAT_RGBA8)
	var color: Color = COLORS[index]
	var palette := {"#": color, "+": color.lightened(0.46), "-": color.darkened(0.36)}
	for y in pixels.size():
		var line: String = pixels[y]
		for x in line.length():
			if palette.has(line[x]):
				image.set_pixel(x, y, palette[line[x]])
	return ImageTexture.create_from_image(image)


func _update_hud() -> void:
	for i in NEEDS.size():
		var amount := float(needs[NEEDS[i]])
		bars[i].value = amount
		meter_labels[i].text = str(roundi(amount))


func _notify(message: String) -> void:
	feedback.text = message
	feedback.show()
	var expected := message
	get_tree().create_timer(3.5).timeout.connect(func():
		if feedback.text == expected:
			feedback.hide())


func _loot_menu() -> void:
	var id := str(opened["id"])
	var stash := _stash(opened)
	_open_panel("loot", str(opened["name"]))
	var address := str(opened.get("address", ""))
	if not address.is_empty():
		_line(address)
	if not bool(stash["unlocked"]):
		_line("O acesso está trancado. Quebrar o vidro faz barulho e pode atrair infectados próximos.")
		_button("Quebrar o vidro", _break_window)
		return
	var loot: Dictionary = stash["items"]
	if loot.is_empty():
		restock_label = _line("")
		_update_restock_countdown()
		return
	for item in loot:
		_button("Pegar %s ×%d" % [ITEM_NAMES[item], loot[item]], _take.bind(id, item), item)


func _update_restock_countdown() -> void:
	if menu_kind != "loot" or restock_label == null:
		return
	var remaining := float(containers[str(opened["id"])]["ready_at"]) - _now()
	if remaining <= 0.0:
		_loot_menu()
		return
	restock_label.text = "Sem suprimentos. Nova busca em %s." % _duration(remaining)


func _break_window() -> void:
	var stash := _stash(opened)
	if bool(stash["unlocked"]):
		return
	stash["unlocked"] = true
	make_noise(_entrance(opened), 72.0)
	_notify("Vidro quebrado. Escute os passos.")
	save()
	_loot_menu()


func _take(id: String, item: String) -> void:
	if not containers.has(id) or _bag_count() >= CAPACITY:
		_notify("Mochila cheia.")
		return
	var stash: Dictionary = containers[id]
	var items: Dictionary = stash["items"]
	if not items.has(item) or int(items[item]) <= 0:
		return
	bag[item] = int(bag.get(item, 0)) + 1
	items[item] -= 1
	if items[item] <= 0:
		items.erase(item)
	if items.is_empty():
		stash["ready_at"] = _now() + float(stash["delay"])
	if quest < QUESTS.size() and item == QUESTS[quest]["item"]:
		supply_found = true
	save()
	_loot_menu()


func _stash(p: Dictionary) -> Dictionary:
	var id := str(p["id"])
	if containers.has(id):
		var old: Dictionary = containers[id]
		var loot: Dictionary = old["items"]
		if not loot.is_empty() or _now() < float(old["ready_at"]):
			return old
	var random := RandomNumberGenerator.new()
	var cycle := int(containers.get(id, {}).get("cycle", 0)) + 1
	random.seed = int(hash(id)) + cycle * 223
	var type := _kind(p)
	var pool: Array = {
		"pharmacy":["med","med","water","parts"],
		"supermarket":["food","water","food","water","parts"],
		"mall":["parts","crowbar","water","food","bat","fuel"],
		"other":["food","water","parts","fuel","bat","crowbar"]
	}[type]
	var stock := {}
	var count := random.randi_range(0, 2)
	if type != "other":
		count = random.randi_range(1, 3)
	for i in count:
		var item: String = pool[random.randi_range(0, pool.size() - 1)]
		stock[item] = int(stock.get(item, 0)) + 1
	for task in QUESTS:
		if id == task["place"] and (quest < QUESTS.size() and id == QUESTS[quest]["place"]):
			stock[task["item"]] = maxi(1, int(stock.get(task["item"], 0)))
	var delay := random.randi_range(LOOT_MIN_SECONDS, LOOT_MAX_SECONDS)
	var lock := id == "pague_menos_13" or id == "patio_central" or random.randf() < (0.55 if type != "other" else 0.36)
	var entry := {"items":stock, "unlocked":not lock, "delay":delay, "cycle":cycle, "ready_at":(_now() + delay if stock.is_empty() else 0.0)}
	containers[id] = entry
	return entry


func _kind(p: Dictionary) -> String:
	var category := str(p.get("category", ""))
	var name := str(p["name"]).to_lower()
	if category == "pharmacy" or "farmácia" in name or "drogaria" in name:
		return "pharmacy"
	if category in ["supermarket", "market"] or "mercado" in name or "feira" in name:
		return "supermarket"
	if category == "mall" or "shopping" in name or "galeria" in name:
		return "mall"
	return "other"


func _shelter_menu() -> void:
	_open_panel("shelter", "Abrigo · Posto Barão")
	_line("O pátio está protegido. Aqui você pode descansar e entregar suprimentos.")
	if quest < QUESTS.size() and supply_found and int(bag.get(QUESTS[quest]["item"], 0)) > 0:
		_button("Entregar suprimento · " + str(QUESTS[quest]["title"]), _submit)
	elif quest >= QUESTS.size():
		if _now() >= next_contract:
			_button("Aceitar nova rodada de abastecimento", _repeat)
		else:
			_line("Novo contrato em %s." % _duration(next_contract - _now()))
	else:
		_line(objective_text())
	_button("Descansar", _rest)
	_button("Baú pessoal · %d/%d" % [_item_count(chest), CHEST_CAPACITY], _chest_menu.bind(true))


func _chest_menu(deposit: bool) -> void:
	if not _at_shelter():
		return
	_open_panel("chest", "Baú pessoal · %d/%d" % [_item_count(chest), CHEST_CAPACITY])
	_line("Mochila · %d/%d" % [_bag_count(), CAPACITY])
	var tabs := HBoxContainer.new()
	body.add_child(tabs)
	for mode in [true, false]:
		var tab := Button.new()
		tab.text = "Guardar" if mode else "Retirar"
		tab.custom_minimum_size.y = 42
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.disabled = mode == deposit
		tab.pressed.connect(_chest_menu.bind(mode))
		tabs.add_child(tab)
	var contents := bag if deposit else chest
	if contents.is_empty():
		_line("Mochila vazia." if deposit else "Baú vazio.")
	for item in ITEM_NAMES:
		var count := int(contents.get(item, 0))
		if count <= 0:
			continue
		var label := "%s %s ×%d" % ["Guardar" if deposit else "Retirar", ITEM_NAMES[item], count]
		_button(label, _transfer_item.bind(item, deposit, count), item)
		if count > 1:
			_button("Só um · %s" % ITEM_NAMES[item], _transfer_item.bind(item, deposit, 1), item)
	_button("Voltar ao abrigo", _shelter_menu)


func _at_shelter() -> bool:
	return not down and game.on_foot and game.walk_pos.distance_to(safe) <= 8.0


func _transfer_item(item: String, deposit: bool, requested: int) -> void:
	if not _at_shelter() or not ITEM_NAMES.has(item):
		return
	var source := bag if deposit else chest
	var target := chest if deposit else bag
	var limit := CHEST_CAPACITY if deposit else CAPACITY
	var count := int(source.get(item, 0))
	var moved := mini(requested, mini(count, limit - _item_count(target)))
	if moved <= 0:
		if count > 0:
			_notify("Baú cheio." if deposit else "Mochila cheia.")
		return
	if count == moved:
		source.erase(item)
	else:
		source[item] = count - moved
	target[item] = int(target.get(item, 0)) + moved
	save()
	_chest_menu(deposit)


func _submit() -> void:
	var task: Dictionary = QUESTS[quest]
	var item: String = task["item"]
	_remove_item(item)
	var reward: String = task["reward"]
	bag[reward] = int(bag.get(reward, 0)) + 1
	quest += 1
	reputation += 1
	supply_found = false
	if quest == QUESTS.size():
		next_contract = _now() + 1200.0
	save()
	_notify("Entrega concluída. Reputação %d." % reputation)
	_shelter_menu()


func _repeat() -> void:
	quest = 0
	supply_found = false
	save()
	_shelter_menu()


func _rest() -> void:
	needs["energia"] = 100.0
	needs["fome"] = maxf(0, float(needs["fome"]) - 4.5)
	needs["sede"] = maxf(0, float(needs["sede"]) - 6.5)
	_notify("Energia recuperada no abrigo.")
	save()


func _use(item: String) -> void:
	if int(bag.get(item,0)) <= 0:
		return
	if item == "fuel":
		if _nearest_vehicle() != active_vehicle or active_vehicle < 0:
			_notify("Chegue perto do carro em uso para abastecer.")
			return
		fuel = minf(100, fuel + 35.0)
	else:
		var meter: String = {"food":"fome", "water":"sede", "med":"saude"}[item]
		needs[meter] = minf(100, float(needs[meter]) + (35.0 if item == "med" else 42.0))
	_remove_item(item)
	if quest < QUESTS.size() and item == QUESTS[quest]["item"] and not bag.has(item) and not chest.has(item):
		supply_found = false
	save()
	menu_kind = ""
	inventory()


func _remove_item(item: String) -> void:
	bag[item] = int(bag[item]) - 1
	if bag[item] <= 0:
		bag.erase(item)


func _bag_count() -> int:
	return _item_count(bag)


func _item_count(contents: Dictionary) -> int:
	var amount := 0
	for count in contents.values():
		amount += int(count)
	return amount


func _entrance(p: Dictionary) -> Vector2:
	return p.get("npc_pos", Vector2(float(p["x"]), float(p["y"])))


func _update_near() -> void:
	closest_site = {}
	if not game.on_foot:
		return
	var here: Vector2 = game.walk_pos
	var best := 7.5
	for p in game.pois:
		var d := here.distance_to(_entrance(p))
		if d < best:
			closest_site = p
			best = d
	if not closest_site.is_empty():
		return
	best = 5.0
	for b in game._bpolys_at(here):
		var polygon: PackedVector2Array = b["pts"]
		for i in polygon.size():
			var p := Geometry2D.get_closest_point_to_segment(here, polygon[i], polygon[(i + 1) % polygon.size()])
			var d := here.distance_to(p)
			if d < best:
				var center: Vector2 = b["bb"].get_center()
				closest_site = {"id":"b_%d_%d" % [roundi(center.x),roundi(center.y)], "name":"Edificação abandonada", "x":p.x, "y":p.y}
				best = d


func _nearest_vehicle() -> int:
	var here: Vector2 = game.walk_pos
	var best := 4.6
	var found := -1
	if active_vehicle >= 0 and here.distance_to(game.car_pos) < best:
		found = active_vehicle
		best = here.distance_to(game.car_pos)
	for i in game.parked_vehicles.size():
		if i == active_vehicle:
			continue
		var d := here.distance_to(game.parked_vehicles[i]["pos"])
		if d < best:
			best = d
			found = i
	return found


func _vehicle_record(v: Dictionary) -> Dictionary:
	return {"x":v["pos"].x, "y":v["pos"].y, "heading":v["heading"], "fuel":v.get("fuel", float(16 + int(v["index"]) % 40))}


func _set_parked_pose(info: Dictionary) -> void:
	var node: Node3D = info["node"]
	var basis: Basis = info["basis"]
	var yaw: float = info["heading"] - info["original_heading"]
	basis = Basis(Vector3.UP, -yaw) * basis
	var p: Vector2 = info["pos"]
	node.transform = Transform3D(basis, Vector3(p.x, 0, p.y) - basis * (info["offset"] as Vector3))


func _refresh_vehicle() -> void:
	for id in taken:
		var i := int(id)
		if i < 0 or i >= game.parked_vehicles.size():
			continue
		var item: Dictionary = taken[id]
		var info: Dictionary = game.parked_vehicles[i]
		info["pos"] = Vector2(float(item["x"]),float(item["y"]))
		info["heading"] = float(item["heading"])
		info["fuel"] = float(item["fuel"])
		_set_parked_pose(info)
	if active_vehicle < 0 or active_vehicle >= game.parked_vehicles.size():
		active_vehicle = -1
		game.car_root.hide()
		return
	var car: Dictionary = game.parked_vehicles[active_vehicle]
	game._swap_car(car["path"])
	car["node"].hide()
	game.car_root.position = Vector3(game.car_pos.x, 0, game.car_pos.y)
	game.car_root.rotation.y = atan2(cos(game.car_heading), sin(game.car_heading))
	game.car_root.show()


func _population(here: Vector2) -> void:
	for i in range(infected.size() - 1, -1, -1):
		var z: Dictionary = infected[i]
		var d: float = here.distance_to(z["pos"])
		if d > 115.0 or (z["state"] == "dead" and z["timer"] <= 0.0):
			z["node"].queue_free()
			infected.remove_at(i)
	if infected.size() >= 28:
		return
	for tries in 12:
		var at := here + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(30, 76)
		var lane: Array = game._road_near(at, true)
		if lane.is_empty():
			continue
		var start: Vector2 = lane[0]
		var distance := here.distance_to(start)
		if distance < 25.0 or distance > 82.0 or start.distance_to(safe) < 13.0 or not _valid_position(start):
			continue
		var sprite: Sprite3D = game._person_sprite(tries % 6)
		var skin: Texture2D = icons.get("zombie_%d" % (randi() % 8))
		if skin != null:
			sprite.region_enabled = false
			sprite.texture = skin
			sprite.pixel_size = 2.40 / float(skin.get_height())
			sprite.offset.y = float(skin.get_height()) * 0.5 - 1.0
		else:
			sprite.modulate = Color("#a3c292")
		sprite.position = Vector3(start.x, 0.04, start.y)
		var tangent: Vector2 = lane[1]
		infected.append({"node":sprite, "pos":start, "home":start, "patrol":start+tangent*8.0,
			"target":start, "state":"patrol", "timer":0.0, "hp":65.0, "seen":0.0, "bite":0.0,
			"retry":0.0, "path":PackedVector2Array(), "walk":randf() * TAU, "speed":randf_range(1.85, 2.7)})
		break


func _update_infected(here: Vector2, delta: float, protected: bool) -> void:
	for z in infected:
		z["timer"] = float(z["timer"]) - delta
		if z["state"] == "dead":
			continue
		var at: Vector2 = z["pos"]
		var sprite: Sprite3D = z["node"]
		z["bite"] = maxf(0.0, float(z["bite"]) - delta)
		z["retry"] = maxf(0.0, float(z["retry"]) - delta)
		var distance := at.distance_to(here)
		var arrived := at.distance_to(z["target"]) < 1.2
		var detection := 17.0 if game.day_f > 0.35 else 11.0
		if not protected and distance < detection and _clear_line(at, here):
			z["state"] = "chase"
			z["target"] = here
			z["seen"] = 6.0
		elif float(z["seen"]) > 0:
			z["seen"] -= delta
		elif z["state"] == "chase" or arrived or float(z["timer"]) < 0.0:
			z["state"] = "patrol"
			z["target"] = z["home"] if at.distance_to(z["home"]) > 3.0 else z["patrol"]
			z["timer"] = 8.0
		if z["state"] != "chase":
			for n in noises:
				if at.distance_to(n["pos"]) < float(n["radius"]) and (n["pos"] as Vector2).distance_to(safe) >= 8.0:
					z["state"] = "listen"
					z["target"] = n["pos"]
					z["timer"] = 8.5
		if not game.on_foot and distance < 2.1 and absf(game.car_speed) > 5.0:
			_damage_zombie(z, 80.0)
			game.car_speed *= 0.76
			continue
		if not protected and distance < 1.72 and _clear_line(at, here):
			if z["bite"] <= 0.0:
				var hit := 9.5 if game.on_foot else 3.0
				needs["saude"] = maxf(0.0, float(needs["saude"]) - hit)
				z["bite"] = 1.15
				_notify("Infectado atingiu você.")
			continue
		var target: Vector2 = z["target"]
		var path: PackedVector2Array = z["path"]
		if not path.is_empty():
			if at.distance_to(path[0]) < 2.3:
				path.remove_at(0)
				z["path"] = path
			if not path.is_empty():
				target = path[0]
		var forward := at.direction_to(target)
		var speed: float = z["speed"] if z["state"] == "chase" else 1.10
		var next := at.move_toward(target, speed * delta)
		if not _valid_position(next) or next.distance_to(safe) < 8.0:
			var detour := at + forward.orthogonal() * speed * delta
			if _valid_position(detour) and detour.distance_to(safe) >= 8.0:
				next = detour
			else:
				next = at
			if z["retry"] <= 0.0:
				z["path"] = game.road_route.route(at, z["target"])
				z["retry"] = 2.2
		z["pos"] = next
		z["walk"] += delta * (10.0 if z["state"] == "chase" else 6.0)
		var bob := absf(sin(z["walk"])) * 0.09
		sprite.position = Vector3(next.x, 0.05 + bob, next.y)
		sprite.flip_h = Vector3(forward.x, 0, forward.y).dot(game.cam.global_basis.x) < 0.0


func _damage_zombie(z: Dictionary, amount: float) -> void:
	z["hp"] = float(z["hp"]) - amount
	var sprite: Sprite3D = z["node"]
	if z["hp"] <= 0:
		z["state"] = "dead"
		z["timer"] = 14.0
		sprite.rotation_degrees.z = 79.0
		sprite.position.y = -0.02
		sprite.modulate = Color("#98929b")
	else:
		z["bite"] = 0.8
		z["state"] = "chase"
		z["target"] = game._actor_pos()
		z["seen"] = 6.0


func _clear_line(a: Vector2, b: Vector2) -> bool:
	var segments := maxi(2, ceili(a.distance_to(b) / 2.5))
	for i in range(1, segments):
		if game._inside_any_building(a.lerp(b, float(i) / float(segments))):
			return false
	return true


func _valid_position(at: Vector2) -> bool:
	return game._in_area(at) and not game._blocked(at) and not game._in_water(at)


func _revive() -> void:
	bag = {"food":1,"water":1,"bat":1}
	needs = {"saude":100.0,"fome":68.0,"sede":68.0,"energia":72.0}
	for z in infected:
		z["node"].queue_free()
	infected.clear()
	noises.clear()
	supply_found = supply_found and quest < QUESTS.size() and chest.has(QUESTS[quest]["item"])
	game.on_foot = true
	game.walk_pos = safe
	game.walker.position = Vector3(safe.x,0.04,safe.y)
	game.walker.show()
	down = false
	close()
	save()


func _now() -> float:
	return Time.get_unix_time_from_system()


func _duration(seconds: float) -> String:
	var s := maxi(0, ceili(seconds))
	if s >= 3600:
		return "%d h %02d min" % [floori(float(s) / 3600.0), floori(float(s % 3600) / 60.0)]
	return "%d min %02d s" % [floori(float(s) / 60.0), s % 60]


func _texture(key: String) -> Texture2D:
	var path := ART + key + ".png"
	return load(path) if ResourceLoader.exists(path) else null


func save() -> void:
	if active_vehicle >= 0:
		var info: Dictionary = game.parked_vehicles[active_vehicle]
		info["pos"] = game.car_pos
		info["heading"] = game.car_heading
		info["fuel"] = fuel
		taken[str(active_vehicle)] = _vehicle_record(info)
	var player: Vector2 = game._actor_pos()
	var f := FileAccess.open(SAVE, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"on_foot":game.on_foot,"areas":containers,"bag":bag,"chest":chest,"needs":needs,"taken":taken,"vehicle":active_vehicle,
			"fuel":fuel,"quest":quest,"found":supply_found,"reputation":reputation,"next":next_contract,"x":player.x,"y":player.y,
			"cx":game.car_pos.x,"cy":game.car_pos.y,"heading":game.car_heading}))


func _load_progress() -> void:
	game.walk_pos = safe
	if not FileAccess.file_exists(SAVE):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	if not data is Dictionary:
		return
	containers = data.get("areas", {})
	_upgrade_loot_delays()
	bag = data.get("bag", bag)
	chest = data.get("chest", {})
	needs.merge(data.get("needs", {}), true)
	taken = data.get("taken", {})
	active_vehicle = int(data.get("vehicle",-1))
	fuel = float(data.get("fuel",0.0))
	quest = clampi(int(data.get("quest",0)),0,QUESTS.size())
	supply_found = bool(data.get("found",false))
	reputation = int(data.get("reputation",0))
	next_contract = float(data.get("next",0.0))
	game.walk_pos = Vector2(float(data.get("x",safe.x)),float(data.get("y",safe.y)))
	game.car_pos = Vector2(float(data.get("cx",safe.x)),float(data.get("cy",safe.y)))
	game.car_heading = float(data.get("heading",0))
	game.on_foot = bool(data.get("on_foot",true)) or active_vehicle < 0
	if float(needs["saude"]) <= 0.0:
		_revive()


func _upgrade_loot_delays() -> void:
	var current := _now()
	for entry in containers.values():
		var previous := float(entry.get("delay", 0))
		if previous <= 0.0 or previous >= LOOT_MIN_SECONDS:
			continue
		var ratio := clampf(inverse_lerp(420.0, 1180.0, previous), 0.0, 1.0)
		var delay := roundi(lerpf(LOOT_MIN_SECONDS, LOOT_MAX_SECONDS, ratio))
		var ready := float(entry.get("ready_at", 0))
		if ready > current and entry["items"].is_empty():
			entry["ready_at"] = ready - previous + delay
		entry["delay"] = delay
