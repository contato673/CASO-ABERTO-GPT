extends Node

const WORLD_NAME := "Big Field"

var game: Node3D
var endpoint := ""
var account := ""
var token := ""
var live := false
var sent_auth := false
var socket := WebSocketPeer.new()
var request: HTTPRequest
var layer: CanvasLayer
var notice: Label
var login: LineEdit
var password: LineEdit
var invite: LineEdit
var submit: Button
var mode: Button
var registering := false
var outgoing := 0.0
var last_hurt := 0
var people := {}
var zombies := {}


func setup(city: Node3D) -> void:
	game = city
	if OS.has_feature("web"):
		var address = JavaScriptBridge.get_interface("location")
		if address != null and str(address.pathname).begins_with("/alpha/"):
			endpoint = str(address.origin)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--alpha=http://127.0.0.1:") or arg.begins_with("--alpha=https://"):
			endpoint = arg.trim_prefix("--alpha=").trim_suffix("/")
	if endpoint.is_empty():
		return
	if game.ph:
		get_window().content_scale_size = Vector2i(560, 910)
	request = HTTPRequest.new()
	request.timeout = 35.0
	request.request_completed.connect(_credentials)
	add_child(request)
	_build_login()


func _build_login() -> void:
	layer = CanvasLayer.new()
	layer.layer = 25
	add_child(layer)
	var shade := ColorRect.new()
	shade.color = Color(0.04, 0.06, 0.08, 0.96)
	layer.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	shade.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var form := VBoxContainer.new()
	form.custom_minimum_size.x = 310
	form.add_theme_constant_override("separation", 12)
	center.add_child(form)
	var title := Label.new()
	title.text = WORLD_NAME
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Color("#eec477"))
	form.add_child(title)
	notice = Label.new()
	notice.custom_minimum_size.x = 310
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	form.add_child(notice)
	login = _field(form, "Usuário", 24, false)
	password = _field(form, "Senha", 72, true)
	invite = _field(form, "Código de convite", 128, true)
	submit = Button.new()
	submit.custom_minimum_size.y = 52
	submit.pressed.connect(_authenticate)
	form.add_child(submit)
	mode = Button.new()
	mode.custom_minimum_size.y = 46
	mode.pressed.connect(func(): registering = not registering; _refresh_login())
	form.add_child(mode)
	_refresh_login()


func _field(form: VBoxContainer, placeholder: String, maximum: int, secret: bool) -> LineEdit:
	var field := LineEdit.new()
	field.placeholder_text = placeholder
	field.max_length = maximum
	field.secret = secret
	field.custom_minimum_size.y = 50
	form.add_child(field)
	return field


func _refresh_login() -> void:
	notice.text = "Cadastro por convite. A senha deve ter pelo menos 10 caracteres." if registering else "Campo Grande/MS · Alpha fechado para 10 jogadores"
	invite.visible = registering
	submit.text = "Criar conta e entrar" if registering else "Entrar no Big Field"
	mode.text = "Já tenho conta" if registering else "Tenho um convite"


func _authenticate() -> void:
	if login.text.strip_edges().length() < 3 or password.text.length() < 10:
		notice.text = "Revise o usuário e a senha."
		return
	submit.disabled = true
	mode.disabled = true
	notice.text = "Conectando ao servidor…"
	var route := "register" if registering else "login"
	var data := JSON.stringify({"login":login.text, "password":password.text, "invite":invite.text})
	var result := request.request(endpoint + "/api/" + route, PackedStringArray(["Content-Type: application/json"]), HTTPClient.METHOD_POST, data)
	password.clear()
	invite.clear()
	if result != OK:
		_login_error("Falha ao conectar.")


func _login_error(message: String) -> void:
	submit.disabled = false
	mode.disabled = false
	notice.text = message
	layer.show()


func _credentials(result: int, status: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var data = JSON.parse_string(body.get_string_from_utf8())
	if result != HTTPRequest.RESULT_SUCCESS or status != 200 or not data is Dictionary:
		_login_error(str(data.get("detail", "Servidor indisponível.")) if data is Dictionary else "Servidor indisponível. Tente novamente.")
		return
	if not account.is_empty() and account != str(data["id"]):
		_login_error("Recarregue o jogo antes de trocar de conta.")
		return
	account = str(data["id"])
	token = str(data["token"])
	socket = WebSocketPeer.new()
	sent_auth = false
	last_hurt = 0
	var address := endpoint.replace("https://", "wss://").replace("http://", "ws://")
	if socket.connect_to_url(address + "/world") != OK:
		_login_error("Falha ao conectar ao mundo compartilhado.")


func tick(delta: float) -> void:
	if endpoint.is_empty():
		return
	socket.poll()
	if socket.get_ready_state() == WebSocketPeer.STATE_CLOSED:
		if sent_auth or not token.is_empty():
			_disconnect()
		return
	if socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	if not sent_auth:
		socket.send_text(JSON.stringify({"token":token}))
		token = ""
		sent_auth = true
	while socket.get_available_packet_count() > 0:
		var packet = JSON.parse_string(socket.get_packet().get_string_from_utf8())
		if not packet is Dictionary:
			continue
		if packet["kind"] == "ready":
			live = true
			layer.hide()
			if not game.session_ready:
				game._start_session(account)
		elif packet["kind"] == "snapshot" and game.session_ready:
			_snapshot(packet)
	outgoing += delta
	if live and outgoing >= 0.12:
		outgoing = 0.0
		var point: Vector2 = game._actor_pos()
		socket.send_text(JSON.stringify({"kind":"pose", "x":point.x, "y":point.y, "face":game.walk_face,
			"driving":not game.on_foot, "inside":game.in_home or game.interior.active or game.survival.sheltered or game.survival.down}))
	_animate_people(delta)


func attack(weapon: String, direction := Vector2.ZERO, reach := 0.0) -> void:
	if live:
		socket.send_text(JSON.stringify({"kind":"attack","weapon":weapon,"aim_x":direction.x,"aim_y":direction.y,"range":reach}))


func noise(at: Vector2) -> void:
	if live:
		socket.send_text(JSON.stringify({"kind":"noise", "x":at.x, "y":at.y}))


func revive() -> void:
	if live:
		socket.send_text(JSON.stringify({"kind":"revive"}))


func _disconnect() -> void:
	live = false
	sent_auth = false
	token = ""
	for person in people.values():
		person["sprite"].queue_free()
	people.clear()
	zombies.clear()
	if game.session_ready:
		game.survival._clear_infected()
	_login_error("Conexão encerrada. Entre novamente para continuar.")


func _snapshot(packet: Dictionary) -> void:
	var arrivals := {}
	for other in packet["players"]:
		var key: String = other["id"]
		arrivals[key] = true
		if not people.has(key):
			var person: Sprite3D = game._person_sprite(2 + absi(key.hash()) % 4)
			person.position = Vector3(other["x"], 0.04, other["y"])
			var caption := Label3D.new()
			caption.text = str(other["name"])
			caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			caption.font_size = 37
			caption.outline_size = 10
			caption.pixel_size = .016
			caption.modulate = Color("#91eac7")
			caption.position.y = 3.2
			person.add_child(caption)
			people[key] = {"sprite":person, "caption":caption, "walk":0.0}
		people[key]["target"] = Vector3(other["x"], 0.04, other["y"])
		people[key]["face"] = int(other["face"])
		people[key]["moving"] = other["moving"]
		people[key]["driving"] = other.get("driving", false)
	for key in people.keys():
		if not arrivals.has(key):
			people[key]["sprite"].queue_free()
			people.erase(key)
	game.survival._sync_online_infected(packet["infected"], zombies)
	var sequence := int(packet["sequence"])
	if sequence > last_hurt and not game.in_home and not game.survival.down:
		var hit := float(packet["hurt"]) * (sequence - last_hurt)
		game.survival.needs["saude"] = maxf(0, game.survival.needs["saude"] - hit)
		game.survival._notify("Infectado atingiu você.")
	last_hurt = sequence


func _animate_people(delta: float) -> void:
	for key in people:
		var person: Dictionary = people[key]
		var sprite: Sprite3D = person["sprite"]
		var target: Vector3 = person["target"]
		sprite.position = sprite.position.lerp(target, 1.0 - exp(-delta * 13))
		sprite.visible = not game.in_home and not game.interior.active
		person["caption"].visible = sprite.position.distance_squared_to(game.walker.position) < 38.0 * 38.0
		person["walk"] += delta * 8.0
		var frame := int(person["walk"]) % 4 if person["moving"] else 0
		var skin := 2 + absi(key.hash()) % 4
		sprite.region_rect = Rect2(frame * 32, (skin * 2 + int(person["face"])) * 40, 32, 40)
