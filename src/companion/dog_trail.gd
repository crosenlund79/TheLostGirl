class_name DogTrail
extends RefCounted
## Breadcrumb trail of where the girl has been (newest point last). The dog walks
## to the point a given distance *along the path* behind her, so it naturally
## follows her over logs and hops where she jumped.

var min_step := 4.0
var max_length := 700.0

var _points: Array[Vector2] = []


## Start a fresh trail. `behind` lets the dog start a little way behind her.
func reset(point: Vector2, behind: Vector2 = point) -> void:
	_points.clear()
	if behind != point:
		_points.append(behind)
	_points.append(point)


func record(point: Vector2) -> void:
	if _points.is_empty():
		_points.append(point)
		return
	if _points[-1].distance_to(point) < min_step:
		return
	_points.append(point)
	_prune()


func point_behind(distance: float) -> Vector2:
	if _points.is_empty():
		return Vector2.ZERO
	var remaining := maxf(distance, 0.0)
	for i in range(_points.size() - 1, 0, -1):
		var a := _points[i]
		var b := _points[i - 1]
		var seg := a.distance_to(b)
		if remaining <= seg:
			return a.lerp(b, remaining / seg) if seg > 0.0 else a
		remaining -= seg
	return _points[0]


func length() -> float:
	var total := 0.0
	for i in range(1, _points.size()):
		total += _points[i - 1].distance_to(_points[i])
	return total


func point_count() -> int:
	return _points.size()


func _prune() -> void:
	var total := 0.0
	for i in range(_points.size() - 1, 0, -1):
		total += _points[i].distance_to(_points[i - 1])
		if total > max_length:
			_points = _points.slice(i - 1)
			return
