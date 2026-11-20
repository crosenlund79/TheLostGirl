class_name SilhouetteDraw
extends RefCounted
## Small drawing helpers shared by the procedural silhouette rigs and props.
## All functions draw into the given CanvasItem from inside its _draw().


## Tapered limb from a to b with round joints (convex quad + two circles).
static func limb(ci: CanvasItem, a: Vector2, b: Vector2, width_a: float, width_b: float, color: Color) -> void:
	var dir := b - a
	if dir.length_squared() < 0.0001:
		ci.draw_circle(a, maxf(width_a, width_b) * 0.5, color, true, -1.0, true)
		return
	var n := dir.normalized().orthogonal()
	var quad := PackedVector2Array([
		a + n * width_a * 0.5, b + n * width_b * 0.5,
		b - n * width_b * 0.5, a - n * width_a * 0.5,
	])
	ci.draw_colored_polygon(quad, color)
	ci.draw_circle(a, width_a * 0.5, color, true, -1.0, true)
	ci.draw_circle(b, width_b * 0.5, color, true, -1.0, true)


## Chain of limbs through points with linearly tapering width.
static func chain(ci: CanvasItem, points: PackedVector2Array, width_start: float, width_end: float, color: Color) -> void:
	var count := points.size()
	if count < 2:
		return
	for i in count - 1:
		var t0 := float(i) / float(count - 1)
		var t1 := float(i + 1) / float(count - 1)
		limb(ci, points[i], points[i + 1], lerpf(width_start, width_end, t0), lerpf(width_start, width_end, t1), color)


## Filled polygon with an antialiased outline to soften jagged silhouette edges.
static func poly(ci: CanvasItem, points: PackedVector2Array, color: Color) -> void:
	if points.size() < 3:
		return
	ci.draw_colored_polygon(points, color)
	var outline := points.duplicate()
	outline.append(points[0])
	ci.draw_polyline(outline, color, 1.0, true)


## Filled antialiased circle.
static func disc(ci: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	ci.draw_circle(center, radius, color, true, -1.0, true)


## Ellipse polygon points (rotation in radians).
static func ellipse_points(center: Vector2, radii: Vector2, rotation: float = 0.0, segments: int = 18) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments:
		var a := TAU * float(i) / float(segments)
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y).rotated(rotation))
	return pts


## Two-bone IK: returns the middle joint between root and end for bone lengths
## len_a/len_b. bend_sign (+1/-1) picks which side the joint bends to.
static func ik_joint(root: Vector2, end: Vector2, len_a: float, len_b: float, bend_sign: float) -> Vector2:
	var to_end := end - root
	var dist := clampf(to_end.length(), 0.001, len_a + len_b - 0.001)
	var cos_angle := clampf((len_a * len_a + dist * dist - len_b * len_b) / (2.0 * len_a * dist), -1.0, 1.0)
	var angle := acos(cos_angle) * bend_sign
	return root + to_end.normalized().rotated(angle) * len_a
