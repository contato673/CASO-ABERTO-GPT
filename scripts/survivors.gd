extends RefCounted

const PEOPLE_ART := preload("res://scripts/people_art.gd")
const MODEL_BY_PROFILE := [1,0,1,4,1,0,1,0,2,5,3,2,4]

const HOSTILE_SITES := ["correios_calogeras", "museu"]
const PEOPLE := [
	["central", "Lia", "Socorrista", "Trabalhava numa ambulância. Agora faço a triagem de quem consegue chegar ao Posto Barão.", "Se ouvir gritos perto da Barão, contorne pela calçada oposta. O pátio do abrigo é seguro."],
	["mercado", "Nivaldo", "Feirante", "Vendia temperos no Mercadão. Minha irmã ficou do outro lado da cidade, então passo aqui à procura de notícias.", "Procure a faca no estoque do Mercadão. Se precisar fugir, não pare para brigar na porta."],
	["pague_menos_13", "Renata", "Farmacêutica", "Deixei os remédios separados por urgência antes de fechar a farmácia. Volto para ver se ainda sobrou algo.", "Leve um kit para o abrigo. Quebrar vidro na rua vazia dá para ouvir de longe."],
	["patio_central", "César", "Vigilante", "Eu fazia a ronda do shopping. Ainda percorro as saídas para saber por onde a gente consegue escapar.", "A munição acaba rápido. Se atirar, mude de rua antes que os infectados cheguem."],
	["comper_centro", "Iara", "Entregadora", "Eu cruzava a cidade de bicicleta. As ruas de serviço ainda são úteis para procurar suprimentos.", "Os quadradinhos verdes do minimapa mostram carros próximos. Procure no acostamento antes de sair a pé."],
	["shopping_cg", "Davi", "Mecânico", "Minha oficina fechou quando faltou luz. Hoje verifico os carros que ainda têm combustível.", "Guarde um galão no abrigo. Para abastecer, estacione e use o galão do lado de fora."],
	["praca", "Márcia", "Professora", "Eu passava pela praça a caminho da escola. Agora uso o caminho aberto para enxergar infectados de longe.", "Quando eles começam a correr, procure uma esquina com saída e mantenha distância."],
	["museu_dom_bosco", "Joel", "Técnico de manutenção", "Conheço as passagens de serviço daqui. À noite me escondo e saio quando a rua esvazia.", "Procure água nas residências. Não vale quebrar todo vidro só por curiosidade."],
	["correios_calogeras", "Breno", "Ex-segurança", "Controlava a portaria de um depósito. Depois do apagão passou a tomar suprimentos de quem cruza a Calógeras.", ""],
	["museu", "Marta", "Ex-transportadora", "Perdeu a carga e o carro na estação. Agora defende o que conseguiu reunir perto dos trilhos.", ""],
	["prefeitura", "Sônia", "Guarda municipal", "A equipe se dividiu quando o rádio apagou. Volto à Prefeitura para procurar o livro de ocorrências.", "Se perder a rota, use as avenidas largas para sair do Centro."],
	["morada_bais", "Hélio", "Agente de trânsito", "Antes do apagão eu orientava o trânsito na Calógeras. Faço a ronda para ver quais acessos ainda estão livres.", "Um carro encostado pode precisar de peças, mesmo com combustível."],
	["hotel_gaspar", "Vicente", "Agente de resgate", "Ajudei a tirar hóspedes do Gaspar. Agora confiro se alguém voltou à recepção à procura de abrigo.", "Mantenha a saída livre antes de subir aos quartos."],
]

var life: Node
var game: Node
var people: Array[Dictionary] = []
var review_in := 0.0


func setup(survival: Node, city: Node) -> void:
	life = survival
	game = city
	for i in PEOPLE.size():
		var profile: Array = PEOPLE[i]
		if not life.sites.has(profile[0]):
			continue
		var site: Dictionary = life.sites[profile[0]]
		var entrance: Vector2 = life._entrance(site)
		var lane: Array = game._road_near(entrance, true)
		if lane.is_empty():
			continue
		var tangent: Vector2 = lane[1]
		var away := tangent.orthogonal()
		var lane_pos: Vector2 = lane[0]
		if (entrance - lane_pos).dot(away) < 0.0:
			away = -away
		var home := _pick_point(entrance, tangent, away, 18.0)
		var objective := _pick_point(home, tangent, away, 13.0)
		if objective == home:
			objective = _pick_point(home, -tangent, -away, 13.0)
		var sprite: Sprite3D = game._person_sprite(0)
		sprite.texture = PEOPLE_ART.MODELS[MODEL_BY_PROFILE[i]]
		sprite.region_rect = Rect2(Vector2.ZERO,PEOPLE_ART.FRAME)
		sprite.pixel_size = .042
		sprite.offset.y = 31
		sprite.hide()
		var title := Label3D.new()
		title.text = profile[1]
		title.font_size = 34
		title.outline_size = 10
		title.pixel_size = 0.016
		title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		title.position = Vector3(0, 3.25, 0)
		title.modulate = Color("#a9f4d7")
		sprite.add_child(title)
		people.append({"id": "person_" + str(profile[0]), "name": profile[1],
			"job": profile[2], "bio": profile[3], "advice": profile[4], "home": home,
			"goal": objective, "pos": home, "node": sprite, "title": title,
			"state": "patrol", "target": objective, "walk": 0.0, "face": 1,
			"phase": i % 3, "swap_at": 4.0 + i, "calm": 0.0, "route": PackedVector2Array(),
			"last_alarm": -20.0, "rest_until":0.0,"warning_until":0.0, "context": "survivor", "hostile": HOSTILE_SITES.has(profile[0]),
			"slot": (i * 5 + 2) % 7, "active": false, "hp": 55.0, "strike_at": 0.0, "defeated_until": 0.0})


func _pick_point(origin: Vector2, along: Vector2, side: Vector2, distance: float) -> Vector2:
	for offset in [along, -along, side, -side, (along + side).normalized()]:
		var candidate: Vector2 = origin + offset * distance
		if life._valid_position(candidate) and life._clear_line(origin, candidate):
			return candidate
	return origin


func near(point: Vector2, limit: float) -> Dictionary:
	var found := {}
	for person in people:
		if not person["active"] or person["state"] not in ["patrol","search","warn"]:
			continue
		var d: float = point.distance_to(person["pos"])
		if d < limit and life._clear_line(point, person["pos"]):
			found = person
			limit = d
	return found


func memory(person: Dictionary) -> Dictionary:
	var id: String = person["id"]
	if not life.npc_memory.has(id):
		life.npc_memory[id] = {"visits":0,"trust":0,"supply":absi(id.hash())%3,
			"angry_until":0.0,"danger_until":0.0,"danger_x":0.0,"danger_y":0.0,"search_at":0.0}
	return life.npc_memory[id]


func reaction(person: Dictionary) -> String:
	var record := memory(person)
	if float(record["angry_until"]) > life._now():
		return "Eu lembro do que você fez. Fique longe."
	if int(record["trust"]) > 0:
		return "Eu lembro da sua ajuda. Pode baixar a guarda."
	if person["hostile"]:
		return "Não chegue mais perto. Preciso de suprimentos e estou defendendo esta rota."
	if int(record["visits"]) > 1:
		return "Já nos cruzamos por aqui. Ainda estou procurando um caminho seguro."
	return "Estou tentando sobreviver. O que você precisa?"


func _encounter_window(person: Dictionary, now: float) -> bool:
	return posmod(floori(now / 180.0), 7) == int(person["slot"])


func tick(here: Vector2, delta: float) -> void:
	review_in -= delta
	var review := review_in <= 0.0
	if review:
		review_in = 0.45
	var now: float = life._now()
	for person in people:
		var home: Vector2 = person["home"]
		var at: Vector2 = person["pos"]
		var sprite: Sprite3D = person["node"]
		if person["active"] and here.distance_squared_to(at) > 110.0 * 110.0:
			person["active"] = false
		if not person["active"] and now >= float(person["defeated_until"]) and _encounter_window(person, now):
			if here.distance_squared_to(home) <= 100.0 * 100.0:
				at = home
				person["active"] = true
				person["pos"] = home
				person["target"] = person["goal"]
				person["route"] = PackedVector2Array()
				person["state"] = "patrol"
				person["hp"] = 55.0
		sprite.visible = person["active"]
		if not sprite.visible:
			continue
		var title: Label3D = person["title"]
		title.visible = here.distance_squared_to(at) < 13.0 * 13.0
		if review:
			_decide(person)
		if person["hostile"]:
			_hostility(person, here, now)
			title.text = person["name"] + " · Hostil" if person["state"] == "attack" else "Desconhecido"
			title.modulate = Color("#f59c87") if person["state"] == "attack" else Color("#eacbb0")
		_move(person, sprite, at, delta)


func _hostility(person: Dictionary, player: Vector2, now: float) -> void:
	var record := memory(person)
	var trusted := int(record["trust"]) >= 2 and float(record["angry_until"]) <= now
	if life.sheltered or life.down or not game.on_foot or player.distance_to(life.safe) < 8.0 or trusted:
		if person["state"] == "warn":
			person["state"] = "patrol"
		person["warning_until"] = 0.0
		if person["state"] == "attack":
			person["state"] = "patrol"
			person["target"] = person["home"]
		return
	if person["state"] in ["flee","hide","recover"]:
		return
	if life.menu_kind == "survivor" and life.opened.get("id") == person["id"]:
		return
	var at: Vector2 = person["pos"]
	var distance: float = at.distance_to(player)
	if distance > (16.0 if person["state"] == "attack" else 9.0) or not life._clear_line(at, player):
		if person["state"] in ["attack","warn"]:
			person["state"] = "patrol"
			person["target"] = person["home"]
		return
	if person["state"] != "attack":
		if person["state"] != "warn":
			person["state"] = "warn"
			person["warning_until"] = now + (1.0 if float(record["angry_until"]) > now else 5.0)
			person["target"] = at
			person["route"] = PackedVector2Array()
			life._notify("Um sobrevivente mandou você parar.")
		if now < float(person["warning_until"]):
			return
		person["strike_at"] = now + 1.1
		life._notify("Sobrevivente hostil por perto.")
	person["state"] = "attack"
	person["target"] = player
	person["route"] = PackedVector2Array()
	if distance < 1.35 and now >= float(person["strike_at"]):
		life.needs["saude"] = maxf(0.0, float(life.needs["saude"]) - 12.0)
		life.dirty_hands = true
		life._notify("O sobrevivente atacou você.")
		person["strike_at"] = now + 1.55


func combat_target(point: Vector2, reach: float) -> Dictionary:
	var found := {}
	for person in people:
		if not person["active"] or not person["hostile"]:
			continue
		var distance := point.distance_to(person["pos"])
		if distance <= reach and life._clear_line(point, person["pos"]):
			found = person
			reach = distance
	return found


func take_hit(person: Dictionary, amount: float) -> void:
	var record := memory(person)
	record["trust"] = -3
	record["angry_until"] = life._now() + 1800.0
	person["hp"] = float(person["hp"]) - amount
	person["strike_at"] = life._now() + 0.8
	if person["hp"] <= 0.0:
		person["active"] = false
		person["node"].hide()
		person["defeated_until"] = life._now() + 1800.0
		life._notify("O sobrevivente hostil caiu.")


func _decide(person: Dictionary) -> void:
	var at: Vector2 = person["pos"]
	var threat := {}
	var limit := 19.0
	for zombie in life.infected:
		if zombie["state"] == "dead":
			continue
		var d: float = at.distance_to(zombie["pos"])
		if d < limit and life._clear_line(at, zombie["pos"]):
			threat = zombie
			limit = d
	var now := life._now() as float
	if not threat.is_empty():
		var record := memory(person)
		record["danger_until"] = now + 135.0
		record["danger_x"] = threat["pos"].x
		record["danger_y"] = threat["pos"].y
		var away: Vector2 = (threat["pos"] as Vector2).direction_to(at)
		if person["state"] != "flee" or at.distance_to(person["target"]) < 4.0:
			person["state"] = "flee"
			person["target"] = _escape_point(at, away, threat["pos"], person["home"])
			person["route"] = PackedVector2Array()
		person["calm"] = now + 7.0
		if now - float(person["last_alarm"]) > 10.0:
			life.make_noise(at, 24.0)
			person["last_alarm"] = now
		return
	if now < float(person["calm"]):
		if at.distance_to(person["target"]) < 2.0:
			person["state"] = "hide"
		return
	if person["state"] in ["attack","warn"]:
		return
	var record := memory(person)
	if float(person["hp"]) < 19.0:
		person["state"] = "recover"
		person["target"] = person["home"]
		if at.distance_to(person["home"]) < 2.0:
			if float(person["rest_until"]) == 0.0:
				person["rest_until"] = now + 18.0
			elif now >= float(person["rest_until"]):
				person["hp"] = 38.0
				person["rest_until"] = 0.0
		return
	if int(record["supply"]) <= 0 and now >= float(record["search_at"]):
		var goal: Vector2 = person["goal"]
		var danger := Vector2(float(record["danger_x"]),float(record["danger_y"]))
		if now < float(record["danger_until"]) and goal.distance_to(danger) < 12.0:
			person["state"] = "hide"
			person["target"] = at
			return
		person["state"] = "search"
		person["target"] = goal
		if at.distance_to(goal) < 2.0:
			record["supply"] = 1
			record["search_at"] = now + 180.0
			person["state"] = "patrol"
		return
	if now > float(record["search_at"]) and int(record["supply"]) > 0:
		record["search_at"] = now + 240.0
		record["supply"] = int(record["supply"]) - 1
	if person["state"] != "patrol":
		person["state"] = "patrol"
		person["target"] = person["home"]
		person["route"] = PackedVector2Array()
		person["swap_at"] = now + 5.0
	elif at.distance_to(person["target"]) < 2.0 and now >= float(person["swap_at"]):
		var hour := fposmod(now / 3600.0 - 4.0, 24.0)
		var resting := hour < 6.0 or hour >= 20.0
		if not resting or int(person["phase"]) == 0:
			person["target"] = person["home"] if person["target"] == person["goal"] else person["goal"]
		else:
			person["target"] = person["home"]
		person["swap_at"] = now + 12.0 + float(person["phase"]) * 5.0
	if not life._clear_line(at, person["target"]) and person["route"].is_empty():
		person["route"] = game.road_route.route(at, person["target"])


func _escape_point(at: Vector2, away: Vector2, threat: Vector2, home: Vector2) -> Vector2:
	if home.distance_to(threat) > at.distance_to(threat) + 7.0 and life._clear_line(at, home):
		return home
	for angle in [0.0, 0.6, -0.6, 1.2, -1.2]:
		var end := at + away.rotated(angle) * 17.0
		if life._valid_position(end) and life._clear_line(at, end):
			return end
	return at


func _move(person: Dictionary, sprite: Sprite3D, at: Vector2, delta: float) -> void:
	var target: Vector2 = person["target"]
	var route: PackedVector2Array = person["route"]
	if not route.is_empty():
		if at.distance_to(route[0]) < 2.2:
			route.remove_at(0)
			person["route"] = route
		if not route.is_empty():
			target = route[0]
	var rushing: bool = person["state"] in ["flee", "attack"]
	var speed := 5.4 if rushing else 2.4
	var next := at.move_toward(target, speed * delta)
	if person["state"] == "hide" or not life._valid_position(next) or game._pedestrian_blocks(at, next, sprite):
		next = at
	var step := next - at
	var frame := 0
	if not step.is_zero_approx():
		person["walk"] += delta * (17.0 if rushing else 10.0)
		frame = 1 + int(person["walk"]) % PEOPLE_ART.WALK_FRAMES
		var right: Vector3 = game.cam.global_basis.x
		var up: Vector3 = game.cam.global_basis.y
		var toward_left := step.dot(Vector2(right.x,right.z)) < 0.0
		var moving_away := step.dot(Vector2(up.x,up.z)) > .015 * step.length()
		person["face"] = (2 if moving_away else 0) + (0 if toward_left else 1)
	person["pos"] = next
	sprite.position = Vector3(next.x, 0.04, next.y)
	sprite.region_rect = Rect2(Vector2(frame,person["face"])*PEOPLE_ART.FRAME,PEOPLE_ART.FRAME)
