extends RefCounted

var graph := AStar2D.new()
var ids: Dictionary = {}


func build(roads: Array) -> void:
	for road in roads:
		if str(road["k"]) == "footway":
			continue
		var previous := -1
		for coords in road["p"]:
			var point := Vector2(float(coords[0]), float(coords[1]))
			var key := Vector2i(roundi(point.x * 2.0), roundi(point.y * 2.0))
			if not ids.has(key):
				var id := graph.get_available_point_id()
				ids[key] = id
				graph.add_point(id, point)
			var current: int = ids[key]
			if previous >= 0 and previous != current and not graph.are_points_connected(previous, current):
				graph.connect_points(previous, current)
			previous = current


func route(from: Vector2, to: Vector2) -> PackedVector2Array:
	if graph.get_point_count() == 0:
		return PackedVector2Array()
	var a := graph.get_closest_point(from)
	var b := graph.get_closest_point(to)
	if graph.get_point_position(a).distance_to(from) > 85.0 or graph.get_point_position(b).distance_to(to) > 85.0:
		return PackedVector2Array()
	var path := graph.get_point_path(a, b)
	# A trip can start between junctions. Drop the first junction when it
	# would send the driver backwards along the first route segment.
	if path.size() >= 2:
		var closest := Geometry2D.get_closest_point_to_segment(from, path[0], path[1])
		if from.distance_to(closest) < 10.0 and closest.distance_to(path[0]) > 1.0:
			path.remove_at(0)
	if path.is_empty():
		return path
	path.append(to)
	return path
