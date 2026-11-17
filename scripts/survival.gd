extends Node

const SURVIVORS := preload("res://scripts/survivors.gd")
const INFECTED_SOUNDS := {
	"moan": preload("res://assets/infectados/gemido.wav"),
	"growl": preload("res://assets/infectados/rosnado.wav"),
	"bite": preload("res://assets/infectados/mordida.wav"),
}
const CLOTHES := {
	"jacket": preload("res://assets/equipamento/jacket.png"),
	"shirt": preload("res://assets/equipamento/shirt.png"),
	"coat": preload("res://assets/equipamento/coat.png"),
}
const ART := "res://assets/survival_local/"
const CAPACITY := 18
const INFECTED_HEALTH := 65.0
const CHEST_CAPACITY := 60
const LOOT_MIN_SECONDS := 2 * 3600
const LOOT_MAX_SECONDS := 6 * 3600
const ITEM_NAMES := {
	"water": "Água", "food": "Conserva", "med": "Primeiros socorros",
	"fuel": "Galão de combustível", "parts": "Peças", "bat": "Taco", "crowbar": "Pé de cabra",
	"knife": "Faca", "pistol": "Pistola", "ammo": "Munição",
	"jacket": "Jaqueta verde", "shirt": "Camiseta azul", "coat": "Casaco ocre",
	"cloth":"Retalho", "wood":"Madeira", "dirty_water":"Água turva", "bandage":"Bandagem",
	"noise_maker":"Isca sonora", "manual":"Manual de oficina"
}
const WEAPONS := {
	"fist": {"reach": 1.8, "damage": 14.0, "duration": 0.45, "impact": 0.14, "noise": 10.0},
	"knife": {"reach": 2.25, "damage": 24.0, "duration": 0.43, "impact": 0.15, "noise": 9.0},
	"bat": {"reach": 3.05, "damage": 30.0, "duration": 0.64, "impact": 0.25, "noise": 13.0},
	"crowbar": {"reach": 3.05, "damage": 38.0, "duration": 0.7, "impact": 0.27, "noise": 17.0},
	"pistol": {"reach": 18.0, "damage": 55.0, "duration": 0.55, "impact": 0.18, "noise": 105.0},
}
const EQUIPMENT_ART := {
	"fist": preload("res://assets/equipamento/fist.png"),
	"knife": preload("res://assets/equipamento/knife.png"),
	"bat": preload("res://assets/equipamento/bat.png"),
	"crowbar": preload("res://assets/equipamento/crowbar.png"),
	"pistol": preload("res://assets/equipamento/pistol.png"),
	"ammo": preload("res://assets/equipamento/ammo.png"),
}
const CONSUMABLES := {"food": "fome", "water": "sede", "med": "saude", "bandage": "saude"}
const SKILLS := {"care":"Primeiros socorros", "workshop":"Oficina", "field":"Sobrevivência"}
const RECIPES := [
	{"out":"bandage", "skill":"care", "level":0, "inputs":{"cloth":2}, "tool":"", "home":false},
	{"out":"water", "skill":"field", "level":0, "inputs":{"dirty_water":1, "cloth":1}, "tool":"", "home":true},
	{"out":"noise_maker", "skill":"field", "level":1, "inputs":{"parts":1, "cloth":1}, "tool":"", "home":false},
	{"out":"bat", "skill":"workshop", "level":1, "inputs":{"wood":1, "cloth":1}, "tool":"knife", "home":false},
	{"out":"med", "skill":"care", "level":2, "inputs":{"bandage":2, "water":1}, "tool":"", "home":true},
	{"out":"crowbar", "skill":"workshop", "level":2, "inputs":{"parts":3}, "tool":"bat", "home":true},
]
const QUICK_ITEMS := ["fist", "knife", "bat", "crowbar", "pistol", "water", "food", "med", "bandage", "noise_maker"]
const STORY_QUESTS := 16
const QUESTS := [
	{"place":"pague_menos_13", "item":"med", "title":"Primeiros socorros", "request":"Busque um kit na Pague Menos da Rua 13 de Maio.", "reward":"water", "story":"Lia tem gente ferida no Posto Barão. Bia passou por lá antes de seguir para a estação."},
	{"place":"mercado", "item":"food", "title":"Rações para o abrigo", "request":"Busque uma conserva no Mercadão, Rua 7 de Setembro.", "reward":"med", "story":"Enquanto durarem as buscas, alguém precisa manter o abrigo abastecido."},
	{"place":"patio_central", "item":"parts", "title":"O rádio do abrigo", "request":"Recolha peças no Pátio Central Shopping, Rua Marechal Rondon.", "reward":"fuel", "story":"O rádio pode alcançar os postos que receberam os últimos comboios."},
	{"place":"hotel_gaspar", "item":"", "title":"Quartos de passagem", "request":"Procure o livro de saída no Grande Hotel Gaspar.", "story":"O rádio voltou. Um voluntário disse que os nomes dos passageiros foram anotados no hotel.", "result":"Bia saiu com os voluntários rumo à estação. A lista registra uma segunda saída antes do amanhecer."},
	{"place":"museu", "item":"", "title":"O segundo embarque", "request":"Confira o quadro de partidas junto ao Museu dos Trabalhadores Ferroviários.", "story":"O grupo de Bia levou feridos e dividiu a carga no caminho. O aviso na estação diz para onde.", "result":"O carro dos feridos parou perto da Drogaria São Bento. Há um pedido de curativos anotado no quadro."},
	{"place":"drogaria_sao_bento_centro", "item":"med", "title":"Posto improvisado", "request":"Busque um kit na Drogaria São Bento do Centro.", "reward":"water", "story":"Os feridos da estação devem voltar ao Posto Barão. A farmácia é a última parada do carro."},
	{"place":"centro_comercial", "item":"parts", "title":"Subir o sinal", "request":"Recolha peças no Edifício Centro Comercial.", "reward":"food", "story":"O pessoal do abrigo quer subir uma antena. O sinal precisa chegar aos postos do lado leste."},
	{"place":"morada_bais", "item":"", "title":"Mapa dobrado", "request":"Procure a folha de rotas na Morada dos Baís.", "story":"A rede deixou um mapa em cada ponto de apoio. A cópia do Centro mostra por onde Bia passou.", "result":"Uma rota segue para o Parque das Nações. Na margem, Bia anotou que o carro precisa de combustível."},
	{"place":"shopping_cg", "item":"fuel", "title":"Combustível para a volta", "request":"Busque um galão no Shopping Campo Grande.", "reward":"med", "story":"Lia vai preparar um carro para retirar quem ainda está do outro lado da cidade."},
	{"place":"museu_dom_bosco", "item":"", "title":"Voz do lado leste", "request":"Confira o ponto de encontro no Museu das Culturas Dom Bosco.", "story":"A última coordenada do mapa aponta para o museu. A equipe deixou um recado na entrada.", "result":"Bia está viva. Ela voltou pelo Centro para buscar a lista de desaparecidos, que ficou nos Correios."},
	{"place":"correios_calogeras", "item":"parts", "title":"A lista dos desaparecidos", "request":"Recupere o equipamento de transmissão nos Correios da Calógeras.", "reward":"food", "story":"A lista foi copiada para um transmissor portátil. Leve-o à Lia antes que a bateria acabe."},
	{"place":"prefeitura", "item":"", "title":"A rede volta a falar", "request":"Confira o ponto de transmissão na Prefeitura.", "story":"Lia transmitiu os nomes. Falta confirmar se o ponto de retransmissão recebeu a mensagem de Bia.", "result":"Bia respondeu pelo rádio. A rede tem uma rota de volta e volta a publicar a lista ao anoitecer. Sua casa continua sendo o seu ponto de retorno."},
	{"place":"casa_artesao", "item":"", "title":"Os nomes do mural", "request":"Confira o mural de recados da Casa do Artesão.", "story":"Bia voltou, mas o caderno dos desaparecidos tem uma página arrancada. Lia lembra de famílias que deixavam bilhetes com os artesãos.", "result":"As famílias se reuniam na Feira Central. Uma anotação pede madeira para marcar uma passagem segura."},
	{"place":"feira_central", "item":"wood", "title":"A saída da Feira", "request":"Recupere madeira num depósito da Feira Central.", "reward":"bandage", "story":"Os voluntários querem sinalizar a saída lateral. A entrada principal virou um ponto de aglomeração dos infectados."},
	{"place":"ary_coelho", "item":"", "title":"Debaixo do coreto", "request":"Procure a caixa de recados na Praça Ary Coelho.", "story":"O grupo deixou uma lista de quem saiu pela passagem da feira e para onde cada família foi.", "result":"A lista dá conta da maioria das famílias. Um envelope ficou separado para a Lia com os horários das rondas."},
	{"place":"galeria_afonso", "item":"manual", "title":"Quem fica para o plantão", "request":"Busque o caderno de manutenção na Galeria Afonso Pena.", "reward":"water", "story":"A rede precisa de gente capaz de manter os equipamentos do plantão. O caderno pode salvar a próxima transmissão."},
	{"place":"comper_centro", "item":"water", "title":"Água para a enfermaria", "request":"Busque água no Supermercado Comper do Centro.", "reward":"food", "story":"A enfermaria precisa repor água para quem chega depois da ronda."},
	{"place":"camelódromo", "item":"parts", "title":"Ferragens para a ronda", "request":"Procure peças no Camelódromo de Campo Grande.", "reward":"water", "story":"Os carrinhos e rádios da ronda estão sendo remendados com ferragens recuperadas."},
	{"place":"pague_menos_miraflores", "item":"med", "title":"Kit para o plantão", "request":"Recolha um kit na Pague Menos da Miraflores.", "reward":"food", "story":"O estoque do plantão da noite foi aberto para atender o último comboio."},
	{"place":"carrefour_shopping", "item":"fuel", "title":"Reserva do comboio", "request":"Busque combustível no Carrefour do Shopping Campo Grande.", "reward":"med", "story":"A rede mantém um galão de reserva para trazer feridos quando escurecer."},
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

var save_path := "user://sobrevivencia-%s.json" % ProjectSettings.get_setting("application/config/version", "dev")
var game
var needs := {"saude":100.0, "fome":92.0, "sede":89.0, "energia":100.0}
var bag := {"water":1, "food":1, "bat":1}
var chest: Dictionary = {}
var skill_xp := {"care":0, "workshop":0, "field":0}
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
var equipped := "bat"
var outfit := ""
var dirty_hands := false
var sheltered := false
var resume_at_home := false
var survivor_group = SURVIVORS.new()
var zombie_atlases: Array[Texture2D] = []
var zombie_frame_sizes: Array[Vector2i] = []
var voice_listener: AudioListener3D
var voice_gap := 0.0
var hand: Sprite3D
var sleeve: Sprite3D
var muzzle_flash: Sprite3D
var action_item := ""
var action_time := 0.0
var action_duration := 0.0
var action_face := 1.0
var pending_hit := false
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
	_prepare_infected_walk()
	survivor_group.setup(self, game)
	voice_listener = AudioListener3D.new()
	game.add_child(voice_listener)
	voice_listener.make_current()
	_apply_outfit()
	for item in ITEM_NAMES:
		icons[item] = EQUIPMENT_ART[item] if EQUIPMENT_ART.has(item) else _texture(item)
	if active_vehicle < 0:
		game.on_foot = true
	game.walker.visible = game.on_foot
	if not game.walk_pos.is_finite() or game._walk_blocked(game.walk_pos):
		game.walk_pos = game._recover_walk_position(game.walk_pos)
	game.walker.position = Vector3(game.walk_pos.x, 0.04, game.walk_pos.y)
	hand = Sprite3D.new()
	hand.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	hand.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	hand.shaded = false
	game.walker.add_child(hand)
	sleeve = Sprite3D.new()
	sleeve.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sleeve.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	var pixels := Image.create_empty(4, 3, false, Image.FORMAT_RGBA8)
	pixels.fill(Color("#272432"))
	pixels.fill_rect(Rect2i(0, 1, 3, 1), Color("#777c6c"))
	pixels.set_pixel(3, 1, Color("#e6a47c"))
	sleeve.texture = ImageTexture.create_from_image(pixels)
	game.walker.add_child(sleeve)
	muzzle_flash = Sprite3D.new()
	muzzle_flash.texture = preload("res://assets/equipamento/disparo.png")
	muzzle_flash.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	muzzle_flash.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	muzzle_flash.pixel_size = 0.11
	muzzle_flash.shaded = false
	game.walker.add_child(muzzle_flash)
	_update_hand(0.0)
	_refresh_vehicle()
	_update_near()


func tick(delta: float) -> void:
	if down:
		return
	var where: Vector2 = game._actor_pos()
	var in_shelter := sheltered or where.distance_to(safe) < 8.0
	var camera: Basis = game.cam.global_basis
	var listener_forward := Vector3(camera.z.x, 0, camera.z.z).normalized()
	voice_listener.transform = Transform3D(Basis.looking_at(-listener_forward), Vector3(where.x, 1.4, where.y))
	voice_gap = maxf(0.0, voice_gap - delta)
	var moving: bool = game.on_foot and direction.length_squared() > 0.02
	_update_hand(delta)
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
	if not game.alpha.live:
		population_timer -= delta
		if population_timer <= 0.0:
			population_timer = 2.8
			_population(where)
		_update_infected(where, delta, in_shelter)
	survivor_group.tick(where, delta)
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
		sheltered = false
		_reset_action()
		hand.hide()
		sleeve.hide()
		muzzle_flash.hide()
		game.menu_open = true
		_open_panel("queda", "Você caiu")
		_line("Volte ao abrigo. O equipamento que carregava ficou para trás.")
		_button("Voltar ao abrigo", _revive)


func walking_speed() -> float:
	var stamina := clampf(float(needs["energia"]) / 30.0, 0.35, 1.0)
	var injury := clampf(float(needs["saude"]) / 45.0, 0.55, 1.0)
	return 6.35 * stamina * injury


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
			return "%s\nRetire %s do baú de casa para fazer a entrega." % [task["title"], name]
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
	if not game.on_foot or game.menu_open or closest_site.is_empty() or down or action_time > 0.0:
		return
	opened = closest_site
	if opened.get("context") == "home":
		game._enter_home()
	elif opened.get("context") == "survivor":
		_open_panel("survivor", str(opened["name"]) + " · " + str(opened["job"]))
		_line(opened["bio"])
		_line(opened["advice"])
	elif str(opened["id"]) == "central":
		_shelter_menu()
	else:
		_loot_menu()


func inventory() -> void:
	if down or sheltered or action_time > 0.0:
		return
	if menu_kind == "inventory":
		close()
		return
	_inventory_menu()


func _inventory_menu() -> void:
	_open_panel("inventory", "Mochila · %d/%d" % [_bag_count(), CAPACITY])
	var equipped_name := "Punhos" if equipped == "fist" else str(ITEM_NAMES[equipped])
	if equipped == "pistol":
		equipped_name += " · Munição ×%d" % int(bag.get("ammo", 0))
	_line("Na mão: " + equipped_name)
	_button("Roda de itens", quick_wheel)
	_button("Fabricação e habilidades", _craft_menu.bind(_inventory_menu))
	_button("Diário de missões", _journal.bind(_inventory_menu))
	if equipped != "fist":
		_button("Guardar arma · Usar punhos", _equip.bind("fist"), "fist")
	for item in WEAPONS:
		if item == equipped or not bag.has(item):
			continue
		var caption := "Equipar %s" % ITEM_NAMES[item]
		if item == "pistol":
			caption += " · Munição ×%d" % int(bag.get("ammo", 0))
		_button(caption, _equip.bind(item), item)
	for item in ITEM_NAMES:
		var count := int(bag.get(item, 0))
		if count == 0 or WEAPONS.has(item):
			continue
		var caption := "%s ×%d" % [ITEM_NAMES[item], count]
		if CONSUMABLES.has(item) or item in ["fuel", "noise_maker"]:
			_button("Usar " + caption, _use.bind(item), item)
		elif item == "manual":
			_button("Estudar " + caption, _study_manual)
		elif CLOTHES.has(item):
			var verb := "Vestida · " if item == outfit else "Vestir "
			if item == outfit:
				_line(verb + caption)
			else:
				_button(verb + caption, _change_outfit.bind(item))
		else:
			_line(caption)
	if _bag_count() == 0:
		_line("Mochila vazia.")


func _equip(item: String) -> void:
	if menu_kind != "inventory" or not WEAPONS.has(item):
		return
	if item != "fist" and int(bag.get(item, 0)) <= 0:
		return
	equipped = item
	save()
	_inventory_menu()


func _apply_outfit() -> void:
	var texture: Texture2D = CLOTHES.get(outfit, game.PEDESTRIANS)
	game.walker.texture = game.survivor_texture(texture, outfit.is_empty())


func _change_outfit(item: String) -> void:
	if not item.is_empty() and (not CLOTHES.has(item) or not bag.has(item)):
		return
	outfit = item
	_apply_outfit()
	save()
	if sheltered:
		_clothing_menu()
	else:
		_inventory_menu()


func close() -> void:
	if down:
		return
	sheltered = false
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
	if game.menu_open or down or action_time > 0.0:
		return
	if not game.on_foot:
		if absf(game.car_speed) > 2.0:
			return
		var side: Vector2 = Vector2(cos(game.car_heading), sin(game.car_heading)).orthogonal()
		for scale in [2.1, -2.1, 2.8, -2.8]:
			var door: Vector2 = game.car_pos + side * float(scale)
			if not game._walk_blocked(door):
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
			previous["heading"] = game.car_heading - float(previous["axis_offset"])
			previous["fuel"] = fuel
			taken[str(active_vehicle)] = _vehicle_record(previous)
			_set_parked_pose(previous)
			previous["node"].show()
		active_vehicle = index
		game.car_pos = info["pos"]
		game.car_heading = float(info["heading"]) + float(info["axis_offset"])
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
	if down or game.menu_open or not game.on_foot or action_time > 0.0:
		return
	if needs["energia"] < 6.0:
		_notify("Sem energia para atacar.")
		return
	var stats: Dictionary = WEAPONS[equipped]
	if equipped == "pistol" and not bag.has("ammo"):
		_notify("Pistola sem munição.")
		return
	_start_action(equipped, stats["duration"])
	pending_hit = true
	needs["energia"] = maxf(0.0, float(needs["energia"]) - (2.0 if equipped == "pistol" else 5.0))
	var nearest := _attack_target(stats["reach"])
	if not nearest.is_empty():
		var offset: Vector2 = nearest["pos"] - game.walk_pos
		var right: Vector3 = game.cam.global_basis.x
		if absf(offset.dot(Vector2(right.x, right.z))) > 0.1:
			action_face = signf(offset.dot(Vector2(right.x, right.z)))
			game.walk_face = 0 if action_face < 0.0 else 1


func _attack_target(reach: float) -> Dictionary:
	var nearest: Dictionary = {}
	for zombie in infected:
		if zombie["state"] == "dead":
			continue
		var dist: float = game.walk_pos.distance_to(zombie["pos"])
		if dist <= reach and _clear_line(game.walk_pos, zombie["pos"]):
			nearest = zombie
			reach = dist
	var hostile: Dictionary = survivor_group.combat_target(game.walk_pos, reach)
	return hostile if not hostile.is_empty() else nearest


func _strike(item: String, stats: Dictionary) -> void:
	var firearm := item == "pistol"
	if game.alpha.live:
		game.alpha.attack(item)
		if firearm and bag.has("ammo"):
			_remove_item("ammo")
			if quest < QUESTS.size() and QUESTS[quest]["item"] == "ammo" and not bag.has("ammo"):
				supply_found = false
			save()
		return
	if firearm:
		if int(bag.get("ammo", 0)) <= 0:
			return
		_remove_item("ammo")
	make_noise(game.walk_pos, stats["noise"])
	var nearest := _attack_target(stats["reach"])
	if nearest.is_empty():
		_notify("Disparo sem acerto." if firearm else "Golpe no ar.")
	elif nearest.get("hostile", false):
		survivor_group.take_hit(nearest, stats["damage"])
	else:
		_damage_zombie(nearest, stats["damage"])
	if firearm:
		save()


func _start_action(item: String, duration: float) -> void:
	action_item = item
	action_duration = duration
	action_time = duration
	action_face = -1.0 if game.walk_face == 0 else 1.0


func _reset_action() -> void:
	action_time = 0.0
	action_item = ""
	pending_hit = false
	game.walker.offset = Vector2(0, 19)


func _update_hand(delta: float) -> void:
	var elapsed := 0.0
	if action_time > 0.0:
		action_time = maxf(0.0, action_time - delta)
		elapsed = action_duration - action_time
		if pending_hit:
			var stats: Dictionary = WEAPONS[action_item]
			if elapsed >= float(stats["impact"]):
				pending_hit = false
				_strike(action_item, stats)
		if action_time <= 0.0:
			_reset_action()

	var acting := not action_item.is_empty()
	var item := action_item if acting else equipped
	hand.visible = game.on_foot and not down and (acting or item != "fist")
	muzzle_flash.hide()
	sleeve.visible = hand.visible
	if not hand.visible:
		return
	var texture: Texture2D = EQUIPMENT_ART.get(item, icons.get(item))
	if texture == null and item == "bandage":
		texture = icons.get("med")
	hand.texture = texture
	var face := action_face if acting else (-1.0 if game.walk_face == 0 else 1.0)
	var pose := Vector2(9, 15)
	var tilt := -0.45
	var body_shift := Vector2.ZERO
	var scale_px := 0.078
	var shot_flash := false
	if CONSUMABLES.has(item) or item == "fuel":
		var lift := sin(PI * clampf(elapsed / action_duration, 0.0, 1.0))
		var use_at: Vector2 = {"water": Vector2(4, 28), "food": Vector2(5, 26),
			"med": Vector2(2, 13), "bandage": Vector2(2, 13), "fuel": Vector2(14, 8)}[item]
		pose = pose.lerp(use_at, lift)
		tilt = lift * (0.8 if item == "water" else -0.3)
		body_shift.y = -lift * (2.0 if item == "med" else 1.0)
		if texture != null:
			scale_px = 0.68 / maxf(texture.get_width(), texture.get_height())
	elif acting:
		var impact: float = WEAPONS[item]["impact"]
		if item == "pistol":
			shot_flash = elapsed >= impact and elapsed - impact < 0.085
			var recoil := exp(-maxf(0.0, elapsed - impact) * 22.0) if elapsed >= impact else 0.0
			pose = Vector2(16 - recoil * 5, 20 + recoil * 3)
			tilt = recoil * 0.5
			body_shift.x = -recoil * 2.0
		else:
			var progress := elapsed / impact if elapsed < impact else (action_duration - elapsed) / (action_duration - impact)
			if item == "knife" or item == "fist":
				pose = Vector2(8 + 16 * progress, 15 + 3 * progress)
				tilt = -0.12
			else:
				var arc := lerpf(1.6, -0.65, elapsed / action_duration)
				pose = Vector2(8 + 15 * progress, 15 + 10 * sin(arc))
				tilt = arc
			body_shift = Vector2(4 * progress, -progress)
	hand.flip_h = face < 0.0
	hand.pixel_size = scale_px
	var camera: Basis = game.cam.global_basis
	var origin: Vector3 = game.walker.global_position
	var held := Vector2(pose.x * face, pose.y) * 0.072
	hand.global_transform = Transform3D(camera * Basis(Vector3.BACK, tilt * face),
		origin + camera * Vector3(held.x, held.y, 0.14))
	if shot_flash:
		muzzle_flash.global_transform = hand.global_transform * Transform3D(Basis.IDENTITY, Vector3(0.94 * face, 0.18, 0.03))
		muzzle_flash.show()
	var shoulder := Vector2((5 + body_shift.x) * face, 19 + body_shift.y) * 0.072
	var grip := held - Vector2(0.16 * face, 0)
	var arm := grip - shoulder
	var center := (shoulder + grip) * 0.5
	var arm_basis := Basis(Vector3.BACK, arm.angle()) * Basis.from_scale(Vector3(maxf(0.15, arm.length()) / 0.04, 6, 1))
	sleeve.global_transform = Transform3D(camera * arm_basis, origin + camera * Vector3(center.x, center.y, 0.07))
	game.walker.offset = Vector2(body_shift.x * face, 19 + body_shift.y)


func make_noise(at: Vector2, radius: float) -> void:
	if game.alpha.live:
		game.alpha.noise(at)
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


func _button(caption: String, action: Callable, item := "") -> Button:
	var btn := Button.new()
	btn.text = caption
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.icon = icons.get(item)
	btn.expand_icon = true
	btn.add_theme_constant_override("icon_max_width", 32)
	btn.custom_minimum_size.y = 46
	btn.pressed.connect(action)
	body.add_child(btn)
	return btn


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
	if quest < QUESTS.size() and QUESTS[quest]["place"] == id and str(QUESTS[quest]["item"]).is_empty():
		_button("Investigar · " + str(QUESTS[quest]["title"]), _survey.bind(id))
	if not bool(stash["unlocked"]):
		_line("O acesso está trancado. Quebrar o vidro faz barulho e pode atrair infectados próximos.")
		_button("Quebrar o vidro", _break_window)
		return
	if opened.has("footprint"):
		_button("Usar como esconderijo", _hideout_menu)
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
	dirty_hands = true
	make_noise(_entrance(opened), 72.0)
	_notify("Vidro quebrado. Escute os passos.")
	save()
	_loot_menu()


func _hideout_menu() -> void:
	if not opened.has("footprint") or not bool(_stash(opened)["unlocked"]):
		return
	sheltered = true
	_open_panel("hideout", "Esconderijo · " + str(opened["name"]))
	_line("Mãos sujas" if dirty_hands else "Mãos limpas")
	_button("Descansar", _hideout_rest)
	_button("Lavar as mãos", _wash_hands)
	_button("Trocar de roupa", _clothing_menu)
	if _window_exit().is_finite():
		_button("Sair pela janela", _leave_window)
	_button("Voltar à entrada", close)


func _hideout_rest() -> void:
	if not sheltered or float(needs["energia"]) >= 98.0:
		return
	needs["energia"] = minf(100.0, float(needs["energia"]) + 26.0)
	needs["fome"] = maxf(0.0, float(needs["fome"]) - 5.0)
	needs["sede"] = maxf(0.0, float(needs["sede"]) - 7.0)
	_notify("Você descansou. A fome e a sede aumentaram.")
	save()


func _wash_hands() -> void:
	if sheltered:
		dirty_hands = false
		_notify("Mãos lavadas.")
		save()
		_hideout_menu()


func _clothing_menu() -> void:
	_open_panel("clothing", "Roupas")
	_line("Vestindo: %s" % ("Roupa inicial" if outfit.is_empty() else ITEM_NAMES[outfit]))
	for item in CLOTHES:
		if bag.has(item) and item != outfit:
			_button("Vestir " + str(ITEM_NAMES[item]), _change_outfit.bind(item))
	if not outfit.is_empty():
		_button("Vestir roupa inicial", _change_outfit.bind(""))
	elif not CLOTHES.keys().any(func(item): return bag.has(item)):
		_line("Procure outras roupas nas casas.")
	_button("Voltar ao esconderijo", _hideout_menu)


func _window_exit() -> Vector2:
	var footprint: PackedVector2Array = opened["footprint"]
	var entry := _entrance(opened)
	var best := entry
	var distance := 3.6
	for i in footprint.size():
		var a := footprint[i]
		var b := footprint[(i + 1) % footprint.size()]
		var perpendicular := a.direction_to(b).orthogonal()
		for side in [-1.0, 1.0]:
			var candidate := (a + b) * 0.5 + perpendicular * float(side) * 1.35
			var clear_of_entry := entry.distance_to(candidate)
			if clear_of_entry > distance and not game._walk_blocked(candidate):
				best = candidate
				distance = clear_of_entry
	return best if best != entry else Vector2.INF


func _leave_window() -> void:
	if not sheltered:
		return
	var destination := _window_exit()
	if not destination.is_finite():
		return
	close()
	game.walk_pos = destination
	game.walker.position = Vector3(destination.x, 0.04, destination.y)
	make_noise(destination, 12.0)
	_update_near()
	save()


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
	if quest < QUESTS.size() and item == QUESTS[quest]["item"] and (id == QUESTS[quest]["place"] or quest < 3):
		supply_found = true
	save()
	_loot_menu()


func _stash(p: Dictionary) -> Dictionary:
	var id := str(p["id"])
	if containers.has(id):
		var old: Dictionary = containers[id]
		var loot: Dictionary = old["items"]
		if not loot.is_empty() or _now() < float(old["ready_at"]):
			_reserve_quest_supply(id, loot, float(old["ready_at"]) > _now())
			return old
	var random := RandomNumberGenerator.new()
	var cycle := int(containers.get(id, {}).get("cycle", 0)) + 1
	random.seed = int(hash(id)) + cycle * 223
	var type := _kind(p)
	var pool: Array = {
		"pharmacy":["med","med","water","parts","cloth","bandage"],
		"supermarket":["food","water","food","water","parts","dirty_water"],
		"mall":["parts","crowbar","water","food","bat","fuel","manual","wood"],
		"residence":["water","food","cloth","parts","med","jacket","shirt","coat","dirty_water","wood"],
		"other":["food","water","parts","fuel","bat","crowbar","cloth","wood","manual"]
	}[type]
	var stock := {}
	var count := random.randi_range(0, 2)
	if type != "other":
		count = random.randi_range(1, 3)
	for i in count:
		var item: String = pool[random.randi_range(0, pool.size() - 1)]
		stock[item] = int(stock.get(item, 0)) + 1
	_reserve_quest_supply(id, stock, false)
	var delay := random.randi_range(LOOT_MIN_SECONDS, LOOT_MAX_SECONDS)
	var lock_rate := 0.42 if type == "residence" else (0.55 if type != "other" else 0.36)
	var lock := id == "pague_menos_13" or id == "patio_central" or random.randf() < lock_rate
	var first_equipment := cycle == 1 or bool(containers.get(id, {}).get("arms_pending", false))
	if first_equipment or (id == "mercado" and random.randf() < 0.30) or (id == "patio_central" and random.randf() < 0.16):
		_stock_new_equipment(id, stock)
	if not stock.has("ammo") and type == "mall" and random.randf() < 0.18:
		stock["ammo"] = 2
	var entry := {"items":stock, "unlocked":not lock, "delay":delay, "cycle":cycle, "ready_at":(_now() + delay if stock.is_empty() else 0.0)}
	containers[id] = entry
	return entry


func _reserve_quest_supply(id: String, stock: Dictionary, waiting: bool) -> void:
	if waiting or supply_found or quest >= QUESTS.size() or QUESTS[quest]["place"] != id:
		return
	var item: String = QUESTS[quest]["item"]
	if not item.is_empty() and not stock.has(item):
		stock[item] = 1


func _stock_new_equipment(id: String, stock: Dictionary) -> void:
	if id == "mercado":
		stock["knife"] = 1
	elif id == "patio_central":
		stock["pistol"] = 1
		stock["ammo"] = 3


func _kind(p: Dictionary) -> String:
	var category := str(p.get("category", ""))
	var name := str(p["name"]).to_lower()
	if category == "residence":
		return category
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
	_button("Diário de missões", _journal.bind(_shelter_menu))


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
	_button("Voltar à casa", _personal_home_menu)


func at_personal_home() -> bool:
	return not down and sites.has("personal_home") and game.walk_pos.distance_to(_entrance(sites["personal_home"])) < 7.5


func _at_shelter() -> bool:
	return not down and game.in_home and game.intro_state == 0


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
		if deposit and equipped == item:
			equipped = "fist"
		if deposit and outfit == item:
			outfit = ""
			_apply_outfit()
	else:
		source[item] = count - moved
	target[item] = int(target.get(item, 0)) + moved
	save()
	_chest_menu(deposit)


func _submit() -> void:
	if quest >= QUESTS.size() or not supply_found:
		return
	var task: Dictionary = QUESTS[quest]
	var item: String = task["item"]
	if item.is_empty() or not bag.has(item):
		return
	_remove_item(item)
	var reward: String = task["reward"]
	bag[reward] = int(bag.get(reward, 0)) + 1
	_advance_quest()
	_notify("Entrega concluída. Reputação %d." % reputation)
	_shelter_menu()


func _survey(id: String) -> void:
	if quest >= QUESTS.size():
		return
	var task: Dictionary = QUESTS[quest]
	if task["place"] != id or not str(task["item"]).is_empty():
		return
	_advance_quest()
	_open_panel("report", str(task["title"]))
	_line(task["result"])
	_button("Continuar", close)


func _advance_quest() -> void:
	quest += 1
	reputation += 1
	supply_found = false
	if quest == QUESTS.size():
		next_contract = _now() + 1200.0
	save()


func _journal(back: Callable) -> void:
	_open_panel("journal", "Diário · %d/%d missões" % [quest, QUESTS.size()])
	for index in QUESTS.size():
		if index == 0 or index == STORY_QUESTS:
			_line("Campanha · A última transmissão" if index == 0 else "Contratos da rede")
		var task: Dictionary = QUESTS[index]
		var status := "Concluída" if index < quest else ("Em andamento" if index == quest else "Pendente")
		_line("%02d · %s — %s" % [index + 1, task["title"], status])
		if index == quest:
			_line(task["story"])
			_line(task["request"])
		elif index < quest and task.has("result"):
			_line(task["result"])
	_button("Voltar", back)


func _personal_home_menu() -> void:
	if not _at_shelter():
		return
	_open_panel("personal_home", "Sua casa")
	_line("Casa de " + str(game.home.cfg["nome"]))
	_button("Baú pessoal · %d/%d" % [_item_count(chest), CHEST_CAPACITY], _chest_menu.bind(true))
	_button("Descansar", _home_rest)
	_button("Mobiliar", _furniture_menu)
	_button("Usar a bancada", _craft_menu.bind(_personal_home_menu))
	_button("Diário de missões", _journal.bind(_personal_home_menu))
	_button("Sair de casa", game._exit_home)


func _home_rest() -> void:
	if not _at_shelter():
		return
	if float(needs["energia"]) >= 98.0:
		_notify("Você já está descansado.")
		return
	needs["energia"] = 100.0
	needs["fome"] = maxf(0.0, float(needs["fome"]) - 4.0)
	needs["sede"] = maxf(0.0, float(needs["sede"]) - 5.0)
	_update_hud()
	_notify("Você descansou em casa.")
	save()


func _furniture_menu() -> void:
	if not _at_shelter():
		return
	var room: Node3D = game.home
	_open_panel("furniture", "Móveis")
	_line("Peças disponíveis na mochila · %d" % int(bag.get("parts", 0)))
	_line("Monte móveis com peças ou recoloque os que já guardou.")
	for kind in room.FURN:
		var name := str(room.FURN[kind]["nome"])
		if room._inv(kind) > 0:
			_button("Colocar " + name, _place_furniture.bind(kind))
		else:
			_button("Montar %s · 2 peças" % name, _craft_furniture.bind(kind))
	_button("Voltar à casa", _personal_home_menu)


func _craft_furniture(kind: String) -> void:
	if not _at_shelter() or not game.home.FURN.has(kind):
		return
	if int(bag.get("parts", 0)) < 2:
		_notify("Você precisa de duas peças na mochila.")
		return
	if supply_found and quest < QUESTS.size() and QUESTS[quest]["item"] == "parts" and int(bag["parts"]) <= 2:
		_notify("Separe uma peça para a entrega antes de montar o móvel.")
		return
	_remove_item("parts")
	_remove_item("parts")
	game.home._add_inv(kind, 1)
	game.home._save()
	save()
	_furniture_menu()


func _place_furniture(kind: String) -> void:
	if _at_shelter() and game.home._inv(kind) > 0:
		close()
		game.home._start_inv(kind)


func _repeat() -> void:
	if quest < QUESTS.size() or _now() < next_contract:
		return
	quest = STORY_QUESTS
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
	if not game.on_foot:
		_notify("Desça do carro para usar este item.")
		return
	if down or action_time > 0.0 or int(bag.get(item, 0)) <= 0:
		return
	if item == "fuel":
		if _nearest_vehicle() != active_vehicle or active_vehicle < 0:
			_notify("Chegue perto do carro em uso para abastecer.")
			return
		fuel = minf(100, fuel + 35.0)
	elif item == "noise_maker":
		var right: Vector3 = game.cam.global_basis.x
		var toward := Vector2(right.x, right.z) * (-1.0 if game.walk_face == 0 else 1.0)
		make_noise(game.walk_pos + toward * 16.0, 56.0)
		_gain_skill("field", 1)
	elif CONSUMABLES.has(item):
		var meter: String = CONSUMABLES[item]
		var restored := 42.0
		if meter == "saude":
			restored = (35.0 if item == "med" else 18.0) + 3.0 * _skill_level("care")
			_gain_skill("care", 1)
		needs[meter] = minf(100, float(needs[meter]) + restored)
	else:
		return
	_remove_item(item)
	if quest < QUESTS.size() and item == QUESTS[quest]["item"] and not bag.has(item) and not chest.has(item):
		supply_found = false
	close()
	if item != "noise_maker":
		_start_action(item, 0.85)
	_update_hud()
	save()


func _skill_level(skill: String) -> int:
	return mini(5, floori(float(skill_xp[skill]) / 3.0))


func _gain_skill(skill: String, amount: int) -> void:
	var before := _skill_level(skill)
	skill_xp[skill] += amount
	if _skill_level(skill) > before:
		_notify("%s subiu para o nível %d." % [SKILLS[skill], _skill_level(skill)])


func _study_manual() -> void:
	if not bag.has("manual"):
		return
	if supply_found and quest < QUESTS.size() and QUESTS[quest]["item"] == "manual" and int(bag["manual"]) == 1:
		_notify("Reserve o manual da missão para entregar no Posto Barão.")
		return
	_remove_item("manual")
	_gain_skill("workshop", 3)
	save()
	_craft_menu(_inventory_menu)


func _craft_menu(back: Callable) -> void:
	_open_panel("craft", "Fabricação e habilidades")
	for skill in SKILLS:
		_line("%s · nível %d · %d XP" % [SKILLS[skill], _skill_level(skill), int(skill_xp[skill])])
	for recipe in RECIPES:
		var materials := PackedStringArray()
		for item in recipe["inputs"]:
			materials.append("%s %d/%d" % [ITEM_NAMES[item], int(bag.get(item, 0)), int(recipe["inputs"][item])])
		var where := " · Bancada de casa" if recipe["home"] else ""
		var tool := " · Ferramenta: " + str(ITEM_NAMES[recipe["tool"]]) if not str(recipe["tool"]).is_empty() else ""
		_line("%s · %s nível %d%s%s" % [" + ".join(materials), SKILLS[recipe["skill"]], recipe["level"], where, tool])
		var button := _button("Fabricar " + str(ITEM_NAMES[recipe["out"]]), _craft.bind(recipe, back))
		button.disabled = not _can_craft(recipe)
	_button("Voltar", back)


func _can_craft(recipe: Dictionary) -> bool:
	if down or not game.on_foot or (recipe["home"] and not game.in_home):
		return false
	if _skill_level(recipe["skill"]) < int(recipe["level"]):
		return false
	var tool: String = recipe["tool"]
	if not tool.is_empty() and not bag.has(tool):
		return false
	for item in recipe["inputs"]:
		if int(bag.get(item, 0)) < int(recipe["inputs"][item]):
			return false
	if supply_found and quest < QUESTS.size():
		var reserved: String = QUESTS[quest]["item"]
		if int(recipe["inputs"].get(reserved, 0)) > 0 and int(bag[reserved]) <= int(recipe["inputs"][reserved]):
			return false
	return true


func _craft(recipe: Dictionary, back: Callable) -> void:
	if not _can_craft(recipe):
		return
	for item in recipe["inputs"]:
		for count in int(recipe["inputs"][item]):
			_remove_item(item)
	var result: String = recipe["out"]
	bag[result] = int(bag.get(result, 0)) + 1
	_gain_skill(recipe["skill"], 2)
	save()
	_craft_menu(back)


func quick_wheel() -> void:
	if down or action_time > 0.0 or game.in_home:
		return
	if menu_kind == "wheel":
		close()
		return
	_wheel_page(0)


func _wheel_page(page: int) -> void:
	_open_panel("wheel", "Roda de itens")
	var wheel := Control.new()
	wheel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	wheel.custom_minimum_size = Vector2(262, 223)
	body.add_child(wheel)
	var choices := PackedStringArray()
	for item in QUICK_ITEMS:
		if item == "fist" or bag.has(item):
			choices.append(item)
	var pages := ceili(choices.size() / 8.0)
	var visible_items := choices.slice(page * 8, page * 8 + 8)
	var center := Vector2(131, 108)
	var held := Label.new()
	held.text = "NA MÃO\n" + ("Punhos" if equipped == "fist" else str(ITEM_NAMES[equipped]))
	held.position = center - Vector2(47, 19)
	held.size = Vector2(94, 39)
	held.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	held.add_theme_font_size_override("font_size", 12)
	wheel.add_child(held)
	if pages > 1:
		var more := Button.new()
		more.text = "Mais itens"
		more.position = center + Vector2(-45, 25)
		more.size = Vector2(90, 30)
		more.pressed.connect(_wheel_page.bind((page + 1) % pages))
		wheel.add_child(more)
	for index in visible_items.size():
		var item := visible_items[index]
		var direction := Vector2.from_angle(-PI * 0.5 + TAU * index / visible_items.size())
		var slot := Button.new()
		slot.position = center + Vector2(direction.x * 95, direction.y * 78) - Vector2(32, 25)
		slot.size = Vector2(64, 50)
		slot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		slot.add_theme_font_size_override("font_size", 12)
		var short_names := {"fist":"Punhos", "med":"Kit médico", "noise_maker":"Isca", "bandage":"Curativo", "crowbar":"Alavanca"}
		slot.text = str(short_names.get(item, ITEM_NAMES.get(item, "")))
		slot.pressed.connect(_quick_select.bind(item))
		wheel.add_child(slot)


func _quick_select(item: String) -> void:
	if menu_kind != "wheel":
		return
	if WEAPONS.has(item) and (item == "fist" or bag.has(item)):
		equipped = item
		save()
		close()
	elif bag.has(item):
		_use(item)


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
	if p.get("context") == "survivor":
		return p["pos"]
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
	var person: Dictionary = survivor_group.near(here, minf(4.5, best))
	if not person.is_empty():
		closest_site = person
	if not closest_site.is_empty():
		return
	best = 5.0
	var cell := Vector2i(floori(here.x / 50.0), floori(here.y / 50.0))
	for x in range(-1, 2):
		for y in range(-1, 2):
			for building in game.bpoly_bk.get(cell + Vector2i(x, y), []):
				var bounds: Rect2 = building["bb"]
				if not bounds.grow(best).has_point(here):
					continue
				var polygon: PackedVector2Array = building["pts"]
				for i in polygon.size():
					var edge := Geometry2D.get_closest_point_to_segment(here, polygon[i], polygon[(i + 1) % polygon.size()])
					var d := here.distance_to(edge)
					if d < best:
						var center := bounds.get_center()
						var residence: bool = building["use"] == "residence"
						closest_site = {"id":"b_%d_%d" % [roundi(center.x),roundi(center.y)],
							"name":"Casa abandonada" if residence else "Edificação abandonada",
							"category":"residence" if residence else "", "x":edge.x, "y":edge.y,
							"footprint":polygon, "context":"building"}
						best = d


func _nearest_vehicle() -> int:
	var here: Vector2 = game.walk_pos
	var best := 4.6
	var found := -1
	if active_vehicle >= 0 and here.distance_to(game.car_pos) < best:
		found = active_vehicle
		best = here.distance_to(game.car_pos)
	for i in game._nearby_cars(here, 4.6):
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
	game._index_car(info)
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


func _prepare_infected_walk() -> void:
	for index in 8:
		var skin := _texture("zombie_%d" % index)
		if skin == null:
			continue
		var source := skin.get_image()
		var w := source.get_width()
		var h := source.get_height()
		var frame := Vector2i(w + 4, h + 3)
		var atlas := Image.create_empty(frame.x * 4, frame.y, false, Image.FORMAT_RGBA8)
		var hip := floori(h * 0.72)
		var middle := w / 2
		for step in 4:
			var origin := Vector2i(step * frame.x + 2, 2)
			var stride: int = [0, -1, 0, 1][step]
			var shift: int = [0, -1, 1, 0][step]
			atlas.blend_rect(source, Rect2i(0, 0, w, hip), origin + Vector2i(shift, -absi(stride)))
			atlas.blend_rect(source, Rect2i(0, hip, middle, h - hip), origin + Vector2i(stride, hip - maxi(0, stride) * 2))
			atlas.blend_rect(source, Rect2i(middle, hip, w - middle, h - hip), origin + Vector2i(middle - stride, hip + mini(0, stride) * 2))
		zombie_atlases.append(ImageTexture.create_from_image(atlas))
		zombie_frame_sizes.append(frame)


func _infected_voice(z: Dictionary, cue: String, distance: float) -> void:
	if distance > 34.0 or (voice_gap > 0.0 and cue != "bite"):
		return
	var voice: AudioStreamPlayer3D = z["voice"]
	voice.stream = INFECTED_SOUNDS[cue]
	voice.pitch_scale = float(z["pitch"])
	voice.play()
	voice_gap = 0.62


func _infected_pose(z: Dictionary, at: Vector2, step: Vector2, delta: float, biting: bool) -> void:
	var sprite: Sprite3D = z["node"]
	var moving := not step.is_zero_approx()
	if moving:
		z["walk"] += delta * (11.0 if z["state"] == "chase" else 5.6)
		sprite.flip_h = Vector3(step.x, 0, step.y).dot(game.cam.global_basis.x) < 0.0
	var frame := int(z["walk"]) % 4 if moving else (2 if biting else 0)
	var frame_size: Vector2i = z["frame_size"]
	if frame_size != Vector2i.ZERO:
		sprite.region_rect = Rect2(frame * frame_size.x, 0, frame_size.x, frame_size.y)
	else:
		sprite.region_rect.position.x = frame * 32
	var bob := (0.02 + absf(sin(float(z["walk"]) * PI * 0.5)) * 0.09) if moving else 0.0
	sprite.position = Vector3(at.x, 0.04 + bob, at.y)


func _population(here: Vector2) -> void:
	for i in range(infected.size() - 1, -1, -1):
		var z: Dictionary = infected[i]
		var d: float = here.distance_to(z["pos"])
		if d > 115.0 or (z["state"] == "dead" and z["timer"] <= 0.0):
			_clear_hit_feedback(z)
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
		infected.append(_spawn_infected(start, lane[1]))
		break


func _spawn_infected(start: Vector2, tangent: Vector2) -> Dictionary:
	var sprite: Sprite3D = game._person_sprite(randi() % 6)
	var frame_size := Vector2i.ZERO
	if not zombie_atlases.is_empty():
		var variant := randi() % zombie_atlases.size()
		frame_size = zombie_frame_sizes[variant]
		sprite.texture = zombie_atlases[variant]
		sprite.region_rect = Rect2(0, 0, frame_size.x, frame_size.y)
		sprite.pixel_size = 2.55 / float(frame_size.y)
		sprite.offset.y = float(frame_size.y) * 0.5 - 1.0
	else:
		sprite.modulate = Color("#a3c292")
	var voice := AudioStreamPlayer3D.new()
	voice.max_distance = 38.0
	voice.unit_size = 7.0
	voice.volume_db = -14.0
	sprite.add_child(voice)
	sprite.position = Vector3(start.x, 0.04, start.y)
	return {"node":sprite, "pos":start, "home":start, "patrol":start+tangent*8.0,
		"target":start, "state":"patrol", "timer":0.0, "hp":INFECTED_HEALTH, "seen":0.0, "bite":0.0,
		"retry":0.0, "path":PackedVector2Array(), "walk":randf() * TAU, "speed":randf_range(1.85, 2.7),
		"frame_size":frame_size, "voice":voice, "pitch":randf_range(0.83, 1.16), "voice_in":randf_range(1.0, 5.0)}


func _clear_infected() -> void:
	for z in infected:
		_clear_hit_feedback(z)
		z["node"].queue_free()
	infected.clear()


func _sync_online_infected(list: Array, existing: Dictionary) -> void:
	var present := {}
	for remote in list:
		var id: String = remote["id"]
		present[id] = true
		var spot := Vector2(remote["x"], remote["y"])
		if not existing.has(id):
			var fresh := _spawn_infected(spot, Vector2.RIGHT)
			existing[id] = fresh
			infected.append(fresh)
		var z: Dictionary = existing[id]
		var hp := float(remote["hp"])
		if hp < float(z["hp"]):
			_damage_zombie(z, float(z["hp"]) - hp)
		var previous: Vector2 = z["pos"]
		z["pos"] = spot
		if hp > 0.0:
			_infected_pose(z, spot, spot - previous, 0.12, false)
	for id in existing.keys():
		if not present.has(id):
			var z: Dictionary = existing[id]
			_clear_hit_feedback(z)
			z["node"].queue_free()
			infected.erase(z)
			existing.erase(id)


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
		z["voice_in"] = maxf(0.0, float(z["voice_in"]) - delta)
		if z["voice_in"] <= 0.0 and distance < 24.0:
			_infected_voice(z, "growl" if z["state"] == "chase" else "moan", distance)
			z["voice_in"] = randf_range(3.5, 8.0)
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
				dirty_hands = true
				_infected_voice(z, "bite", distance)
				z["bite"] = 1.15
				_notify("Infectado atingiu você.")
			_infected_pose(z, at, Vector2.ZERO, delta, float(z["bite"]) > 0.85)
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
		_infected_pose(z, next, next - at, delta, false)


func _damage_zombie(z: Dictionary, amount: float) -> void:
	var damage := minf(float(z["hp"]), amount)
	z["hp"] = float(z["hp"]) - damage
	_show_hit_feedback(z, damage)
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


func _show_hit_feedback(z: Dictionary, damage: float) -> void:
	if not z.has("hit_panel"):
		var badge := PanelContainer.new()
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var backdrop := StyleBoxFlat.new()
		backdrop.bg_color = Color(0.08, 0.07, 0.11, 0.92)
		backdrop.set_corner_radius_all(4)
		backdrop.content_margin_left = 5
		backdrop.content_margin_right = 5
		backdrop.content_margin_top = 2
		backdrop.content_margin_bottom = 4
		badge.add_theme_stylebox_override("panel", backdrop)
		var stack := VBoxContainer.new()
		stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack.add_theme_constant_override("separation", 2)
		badge.add_child(stack)
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 13)
		stack.add_child(label)
		var bar := ProgressBar.new()
		bar.max_value = INFECTED_HEALTH
		bar.show_percentage = false
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.custom_minimum_size = Vector2(66, 5)
		var fill := StyleBoxFlat.new()
		fill.bg_color = Color("#ff776e")
		var base := StyleBoxFlat.new()
		base.bg_color = Color("#49333b")
		bar.add_theme_stylebox_override("fill", fill)
		bar.add_theme_stylebox_override("background", base)
		stack.add_child(bar)
		feedback.get_parent().add_child(badge)
		z["hit_panel"] = badge
		z["hit_label"] = label
		z["hit_bar"] = bar
	var hp := int(z["hp"])
	z["hit_label"].text = "ABATIDO" if hp <= 0 else "−%d   %d/%d" % [roundi(damage), hp, int(INFECTED_HEALTH)]
	z["hit_label"].modulate = Color("#ffe5a1") if hp <= 0 else Color.WHITE
	z["hit_bar"].value = hp
	z["hit_bar"].visible = hp > 0
	z["hit_time"] = 2.3 if hp <= 0 else 4.0


func update_hit_feedback(delta: float) -> void:
	for z in infected:
		if not z.has("hit_panel"):
			continue
		z["hit_time"] = float(z["hit_time"]) - delta
		if z["hit_time"] <= 0.0:
			_clear_hit_feedback(z)
			continue
		var badge: PanelContainer = z["hit_panel"]
		var at: Vector2 = z["pos"]
		var anchor := Vector3(at.x, 1.4 if z["state"] == "dead" else 3.1, at.y)
		var point: Vector2 = game.cam.unproject_position(anchor)
		badge.visible = not game.cam.is_position_behind(anchor) and not game.menu_open
		badge.position = (point - Vector2(badge.size.x * 0.5, badge.size.y)).round()


func _clear_hit_feedback(z: Dictionary) -> void:
	if z.has("hit_panel"):
		z["hit_panel"].queue_free()
		z.erase("hit_panel")
		z.erase("hit_label")
		z.erase("hit_bar")
		z.erase("hit_time")


func _clear_line(a: Vector2, b: Vector2) -> bool:
	var segments := maxi(2, ceili(a.distance_to(b) / 2.5))
	for i in range(1, segments):
		if game._inside_any_building(a.lerp(b, float(i) / float(segments))):
			return false
	return true


func _valid_position(at: Vector2) -> bool:
	return not game._walk_blocked(at)


func _revive() -> void:
	if game.alpha.live:
		game.alpha.revive()
	_reset_action()
	equipped = "bat"
	outfit = ""
	dirty_hands = false
	_apply_outfit()
	bag = {"food":1,"water":1,"bat":1}
	needs = {"saude":100.0,"fome":68.0,"sede":68.0,"energia":72.0}
	for z in infected:
		_clear_hit_feedback(z)
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
		info["heading"] = game.car_heading - float(info["axis_offset"])
		info["fuel"] = fuel
		taken[str(active_vehicle)] = _vehicle_record(info)
	var player: Vector2 = game._actor_pos()
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"on_foot":game.on_foot,"in_home":game.in_home and game.intro_state == 0,"areas":containers,"bag":bag,"skills":skill_xp,"equipped":equipped,"outfit":outfit,"dirty_hands":dirty_hands,"chest":chest,"needs":needs,"taken":taken,"parked_heading_v2":true,"vehicle":active_vehicle,
			"fuel":fuel,"quest":quest,"found":supply_found,"reputation":reputation,"next":next_contract,"x":player.x,"y":player.y,
			"cx":game.car_pos.x,"cy":game.car_pos.y,"heading":game.car_heading}))


func _load_progress() -> void:
	game.walk_pos = safe
	if not FileAccess.file_exists(save_path):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not data is Dictionary:
		return
	resume_at_home = bool(data.get("in_home", false))
	containers = data.get("areas", {})
	if not data.has("equipped"):
		for id in ["mercado", "patio_central"]:
			if containers.has(id):
				var entry: Dictionary = containers[id]
				if entry["items"].is_empty():
					entry["arms_pending"] = true
				else:
					_stock_new_equipment(id, entry["items"])
	_upgrade_loot_delays()
	bag = data.get("bag", bag)
	skill_xp.merge(data.get("skills", {}), true)
	var previous := "crowbar" if bag.has("crowbar") else ("bat" if bag.has("bat") else "fist")
	equipped = str(data.get("equipped", previous))
	if not WEAPONS.has(equipped) or (equipped != "fist" and not bag.has(equipped)):
		equipped = "fist"
	outfit = str(data.get("outfit", ""))
	if not CLOTHES.has(outfit) or not bag.has(outfit):
		outfit = ""
	dirty_hands = bool(data.get("dirty_hands", false))
	_apply_outfit()
	chest = data.get("chest", {})
	needs.merge(data.get("needs", {}), true)
	taken = data.get("taken", {})
	if not data.get("parked_heading_v2", false):
		for id in taken:
			var index := int(id)
			if index >= 0 and index < game.parked_vehicles.size():
				taken[id]["heading"] = float(taken[id]["heading"]) - float(game.parked_vehicles[index]["axis_offset"])
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
