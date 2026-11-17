extends RefCounted

const PEOPLE := [
	["central", "Lia", "Socorrista", "Trabalhava numa ambulância. Agora faço a triagem de quem consegue chegar ao Posto Barão.", "Se ouvir gritos perto da Barão, contorne pela calçada oposta. O pátio do abrigo é seguro."],
	["mercado", "Nivaldo", "Feirante", "Vendia temperos no Mercadão. Minha irmã ficou do outro lado da cidade, então passo aqui à procura de notícias.", "Procure a faca no estoque do Mercadão. Se precisar fugir, não pare para brigar na porta."],
	["pague_menos_13", "Renata", "Farmacêutica", "Deixei os remédios separados por urgência antes de fechar a farmácia. Volto para ver se ainda sobrou algo.", "Leve um kit para o abrigo. Quebrar vidro na rua vazia dá para ouvir de longe."],
	["patio_central", "César", "Vigilante", "Eu fazia a ronda do shopping. Ainda percorro as saídas para saber por onde a gente consegue escapar.", "A munição acaba rápido. Se atirar, mude de rua antes que os infectados cheguem."],
	["comper_centro", "Iara", "Entregadora", "Eu cruzava a cidade de bicicleta. As ruas de serviço ainda são úteis para procurar suprimentos.", "Os quadradinhos verdes do minimapa mostram carros próximos. Procure no acostamento antes de sair a pé."],
	["shopping_cg", "Davi", "Mecânico", "Minha oficina fechou quando faltou luz. Hoje verifico os carros que ainda têm combustível.", "Guarde um galão no abrigo. Para abastecer, estacione e use o galão do lado de fora."],
	["praca", "Márcia", "Professora", "Eu passava pela praça a caminho da escola. Agora uso o caminho aberto para enxergar infectados de longe.", "Quando eles começam a correr, procure uma esquina com saída e mantenha distância."],
	["museu_dom_bosco", "Joel", "Técnico de manutenção", "Conheço as passagens de serviço daqui. À noite me escondo e saio quando a rua esvazia.", "Procure água nas residências. Não vale quebrar todo vidro só por curiosidade."],
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
		var sprite: Sprite3D = game._person_sprite((i + 1) % 7)
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
			"goal": objective, "pos": home, "node": sprite, "title": title, "skin": (i + 1) % 7,
			"state": "patrol", "target": objective, "walk": 0.0, "face": 1,
			"phase": i % 3, "swap_at": 4.0 + i, "calm": 0.0, "route": PackedVector2Array(),
			"last_alarm": -20.0, "context": "survivor"})


func _pick_point(origin: Vector2, along: Vector2, side: Vector2, distance: float) -> Vector2:
	for offset in [along, -along, side, -side, (along + side).normalized()]:
		var candidate: Vector2 = origin + offset * distance
		if life._valid_position(candidate) and life._clear_line(origin, candidate):
			return candidate
	return origin


func near(point: Vector2, limit: float) -> Dictionary:
	var found := {}
	for person in people:
		if person["state"] == "flee":
			continue
		var d: float = point.distance_to(person["pos"])
		if d < limit and life._clear_line(point, person["pos"]):
			found = person
			limit = d
	return found


func tick(here: Vector2, delta: float) -> void:
	review_in -= delta
	var review := review_in <= 0.0
	if review:
		review_in = 0.45
	for person in people:
		var at: Vector2 = person["pos"]
		var sprite: Sprite3D = person["node"]
		var distance := here.distance_squared_to(at)
		sprite.visible = distance < 115.0 * 115.0
		if not sprite.visible:
			continue
		person["title"].visible = distance < 19.0 * 19.0
		if review:
			_decide(person)
		_move(person, sprite, at, delta)


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
	var speed := 5.4 if person["state"] == "flee" else 2.4
	var next := at.move_toward(target, speed * delta)
	if person["state"] == "hide" or not life._valid_position(next):
		next = at
	var step := next - at
	var frame := 0
	if not step.is_zero_approx():
		person["walk"] += delta * (11.0 if person["state"] == "flee" else 6.0)
		frame = int(person["walk"]) % 4
		var right: Vector3 = game.cam.global_basis.x
		person["face"] = 0 if step.dot(Vector2(right.x, right.z)) < 0.0 else 1
	person["pos"] = next
	sprite.position = Vector3(next.x, 0.04, next.y)
	sprite.region_rect = Rect2(frame * 32, (person["skin"] * 2 + person["face"]) * 40, 32, 40)
