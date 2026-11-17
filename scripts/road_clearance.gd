extends RefCounted

const CELL := 48.0
var buckets: Dictionary = {}
var bands: Array[PackedVector2Array] = []
var cut_bands: Array[PackedVector2Array] = []


func add_segment(a: Vector2, b: Vector2, width: float) -> void:
	if a.distance_squared_to(b) < 0.0001:
		return
	var dir := a.direction_to(b)
	var side := dir.orthogonal() * (width * 0.5 + 0.30)
	var end := dir * 0.23
	var corners := PackedVector2Array([a-end-side, a-end+side, b+end+side, b+end-side])
	var padding := dir.orthogonal() * 0.16
	var extension := dir * 0.16
	var cut := PackedVector2Array([corners[0]-padding-extension, corners[1]+padding-extension, corners[2]+padding+extension, corners[3]-padding+extension])
	var span := bounds(cut)
	var index := bands.size()
	bands.append(corners)
	cut_bands.append(cut)
	for y in range(floori(span.position.y / CELL), floori(span.end.y / CELL) + 1):
		for x in range(floori(span.position.x / CELL), floori(span.end.x / CELL) + 1):
			var key := Vector2i(x, y)
			if not buckets.has(key):
				buckets[key] = []
			buckets[key].append(index)


func bounds(shape: PackedVector2Array) -> Rect2:
	var result := Rect2(shape[0], Vector2.ZERO)
	for p in shape:
		result = result.expand(p)
	return result


func candidates(shape: PackedVector2Array) -> Array:
	var span := bounds(shape)
	var found := {}
	for y in range(floori(span.position.y / CELL), floori(span.end.y / CELL) + 1):
		for x in range(floori(span.position.x / CELL), floori(span.end.x / CELL) + 1):
			for index in buckets.get(Vector2i(x,y), []):
				found[index] = true
	return found.keys()


func is_clear(shape: PackedVector2Array) -> bool:
	var span := bounds(shape)
	for index in candidates(shape):
		var band := bands[index]
		if span.intersects(bounds(band)) and not Geometry2D.intersect_polygons(shape, band).is_empty():
			return false
	return true


func clip(shape: PackedVector2Array) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = [shape]
	for index in candidates(shape):
		var road := cut_bands[index]
		var road_span := bounds(road)
		var next: Array[PackedVector2Array] = []
		for part in result:
			if not bounds(part).intersects(road_span) or Geometry2D.intersect_polygons(part, road).is_empty():
				next.append(part)
				continue
			var clipped := Geometry2D.clip_polygons(part, road)
			# A road fully enclosed in a footprint creates a hole. Dropping
			# that anomalous footprint avoids filling the hole with a roof.
			if clipped.any(func(poly): return Geometry2D.is_polygon_clockwise(poly)):
				continue
			next.append_array(clipped)
		result = next
		if result.is_empty():
			break
	return result
