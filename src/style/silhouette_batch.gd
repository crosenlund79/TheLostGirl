class_name SilhouetteBatch
extends RefCounted
## Collects many flat-coloured shapes into ONE triangle list, so a whole static
## layer (hundreds of trees, thousands of grass blades) costs a single draw call.
## Fill it, then call commit() from inside the owning CanvasItem's _draw().

var points := PackedVector2Array()
var indices := PackedInt32Array()


func is_empty() -> bool:
	return indices.is_empty()


func triangle(a: Vector2, b: Vector2, c: Vector2) -> void:
	var i := points.size()
	points.append(a)
	points.append(b)
	points.append(c)
	indices.append_array(PackedInt32Array([i, i + 1, i + 2]))


## Convex quad, points in order around the edge.
func quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> void:
	var i := points.size()
	points.append_array(PackedVector2Array([a, b, c, d]))
	indices.append_array(PackedInt32Array([i, i + 1, i + 2, i, i + 2, i + 3]))


## Any simple (non self-intersecting) polygon.
func polygon(pts: PackedVector2Array) -> void:
	var tris := Geometry2D.triangulate_polygon(pts)
	if tris.is_empty():
		return
	var base := points.size()
	points.append_array(pts)
	for k in tris:
		indices.append(base + k)


func disc(center: Vector2, radius: float) -> void:
	var n := clampi(int(radius * 1.5) + 6, 6, 28)
	var base := points.size()
	points.append(center)
	for s in n:
		points.append(center + Vector2.from_angle(TAU * float(s) / float(n)) * radius)
	for s in n:
		indices.append_array(PackedInt32Array([base, base + 1 + s, base + 1 + (s + 1) % n]))


## Tapered limb with round joints (joints skipped when too thin to matter).
func limb(a: Vector2, b: Vector2, width_a: float, width_b: float) -> void:
	var dir := b - a
	if dir.length_squared() < 0.0001:
		return
	var n := dir.normalized().orthogonal()
	var ha := maxf(width_a, 1.2) * 0.5
	var hb := maxf(width_b, 1.2) * 0.5
	quad(a + n * ha, b + n * hb, b - n * hb, a - n * ha)
	if width_a > 2.4:
		disc(a, ha)
	if width_b > 2.4:
		disc(b, hb)


func chain(pts: PackedVector2Array, width_start: float, width_end: float) -> void:
	var count := pts.size()
	for i in count - 1:
		var t0 := float(i) / float(count - 1)
		var t1 := float(i + 1) / float(count - 1)
		limb(pts[i], pts[i + 1], lerpf(width_start, width_end, t0), lerpf(width_start, width_end, t1))


## Pointed leaf from base along dir.
func leaf(base: Vector2, dir: Vector2, length: float, half_width: float) -> void:
	var side := dir.orthogonal() * half_width
	quad(base, base + dir * length * 0.45 + side, base + dir * length, base + dir * length * 0.45 - side)


func commit(ci: CanvasItem, color: Color) -> void:
	if indices.is_empty():
		return
	RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), indices, points, PackedColorArray([color]))
