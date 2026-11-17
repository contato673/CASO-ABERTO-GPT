extends Node

var game: Node3D
var life: Node
var overlay: Control
var aiming := false
var direction := Vector2.RIGHT
var trace := {}
var fired := {}
var remaining := 0.0


func setup(city: Node3D, survival: Node) -> void:
	game = city
	life = survival
	var layer := CanvasLayer.new()
	layer.layer = 3
	add_child(layer)
	overlay = Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(overlay)
	overlay.draw.connect(_draw)


func enabled() -> bool:
	return game.on_foot and not game.in_home and not life.down and not game.menu_open and life.FIREARMS.has(life.equipped)


func toggle() -> void:
	if not enabled():
		return
	aiming = not aiming
	if aiming:
		var reach: float = life.WEAPONS[life.equipped]["reach"]
		var nearest: Dictionary = life._attack_target(reach)
		direction = game.walk_heading
		if not nearest.is_empty() and not game.interior.active:
			direction = game.walk_pos.direction_to(nearest["pos"])
		if direction.is_zero_approx():
			direction = Vector2.RIGHT
		orient_actor()


func aim_at(screen: Vector2) -> bool:
	if not aiming or not enabled():
		return false
	var actor: Sprite3D = game.interior.actor if game.interior.active else game.walker
	var start: Vector3 = actor.global_position
	var ray_start: Vector3 = game.cam.project_ray_origin(screen)
	var ray_dir: Vector3 = game.cam.project_ray_normal(screen)
	var projected: Variant = Plane(Vector3.UP,start.y+1.1).intersects_ray(ray_start,ray_dir)
	if projected is Vector3:
		var offset: Vector3 = projected-start
		var candidate := Vector2(offset.x,offset.z)
		if candidate.length() > .35:
			direction = candidate.normalized()
	orient_actor()
	return true


func orient_actor() -> void:
	var right: Vector3 = game.cam.global_basis.x
	game.walk_face = int(direction.dot(Vector2(right.x,right.z)) >= 0.0)
	if game.interior.active:
		game.interior.facing = 0 if game.walk_face == 0 else 4


func update(delta: float) -> void:
	if aiming and not enabled():
		aiming = false
		trace = {}
	if aiming:
		orient_actor()
		trace = cast(life.equipped,direction)
	remaining = maxf(0,remaining-delta)
	overlay.queue_redraw()


func cast(weapon: String, heading: Vector2) -> Dictionary:
	var inside: bool = game.interior.active
	var actor: Sprite3D = game.interior.actor if inside else game.walker
	var start: Vector3 = actor.global_position + Vector3.UP * 1.1
	var from := Vector2(start.x,start.z)
	var length: float = life.WEAPONS[weapon]["reach"]
	var wall := false
	var step := .55
	while step < length:
		var at := from + heading*step
		var blocked: bool = not game.interior._can_walk(game.interior.pos+heading*step) if inside else game._inside_any_building(at)
		if blocked:
			length = step
			wall = true
			break
		step += .32
	var target := {}
	if not inside and not game.in_home:
		for zombie in life.infected:
			if zombie["state"] == "dead":
				continue
			var offset: Vector2 = zombie["pos"] - from
			var distance := offset.dot(heading)
			if distance > .25 and distance < length and absf(offset.cross(heading)) < .96:
				target = zombie
				length = distance
				wall = false
		for person in life.survivor_group.people:
			if not person["active"] or not person["hostile"]:
				continue
			var offset: Vector2 = person["pos"] - from
			var distance := offset.dot(heading)
			if distance > .25 and distance < length and absf(offset.cross(heading)) < .86:
				target = person
				length = distance
				wall = false
	var finish := start + Vector3(heading.x,0,heading.y)*length
	return {"start":start,"finish":finish,"target":target,"wall":wall,"range":length}


func fire(weapon: String) -> Dictionary:
	var heading: Vector2 = direction if aiming else game.walk_heading
	if not aiming and not game.interior.active and not game.in_home:
		var target: Dictionary = life._attack_target(life.WEAPONS[weapon]["reach"])
		if not target.is_empty():
			heading = game.walk_pos.direction_to(target["pos"])
	if heading.is_zero_approx():
		heading = Vector2.RIGHT
	fired = cast(weapon,heading)
	fired["direction"] = heading
	remaining = .26
	overlay.queue_redraw()
	return fired


func _draw() -> void:
	if aiming and not trace.is_empty():
		var end: Vector2 = game.cam.unproject_position(trace["finish"])
		overlay.draw_line(game.cam.unproject_position(trace["start"]),end,Color("#a4efeb"),2.0,true)
		overlay.draw_arc(end,5,0,TAU,16,Color("#d7ffff"),1.5,true)
	if remaining <= 0 or fired.is_empty():
		return
	var start: Vector2 = game.cam.unproject_position(fired["start"])
	var end: Vector2 = game.cam.unproject_position(fired["finish"])
	var fade := remaining/.26
	overlay.draw_line(start,end,Color(1,.76,.32,fade),4.0,true)
	overlay.draw_line(start,end,Color(1,.96,.76,fade),1.7,true)
	if fired["wall"] or not fired["target"].is_empty():
		var ink := Color(1,.43,.28,fade) if not fired["target"].is_empty() else Color(1,.86,.55,fade)
		for spoke in 6:
			var ray := Vector2.from_angle(spoke*TAU/6.0)
			overlay.draw_line(end+ray*3,end+ray*(8+10*(1-fade)),ink,2.5,true)
