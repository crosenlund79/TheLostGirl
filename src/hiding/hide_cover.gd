@tool
class_name HideCover
extends Node2D
## Foreground cover the girl can crouch under: a dense bush or a tree whose low
## branches droop to the ground. Draws itself procedurally (in front of the girl)
## and exposes the rectangle she must be fully inside, while crouched, to hide.
## Its top stays well below a standing girl's head, so standing visibly pokes out.
## Origin sits on the ground at the centre of the cover.

enum Style { BUSH, LOW_BRANCHES }

@export var style: Style = Style.BUSH:
	set(value):
		style = value
		queue_redraw()
@export var width := 130.0:
	set(value):
		width = value
		queue_redraw()
## Height of the hiding zone. Keep it just above the crouched girl (40) and
## well below the standing girl (~69).
@export var cover_height := 42.0:
	set(value):
		cover_height = value
		queue_redraw()
## Zone inset from the visual edges so her whole silhouette is covered when hidden.
@export var edge_margin := 16.0:
	set(value):
		edge_margin = value
		queue_redraw()
@export var shape_seed := 1:
	set(value):
		shape_seed = value
		queue_redraw()

var _rustle := 0.0
var _time := 0.0


func _ready() -> void:
	add_to_group("hide_cover")


## Global-space rectangle the girl's crouched silhouette must be inside.
func get_cover_rect() -> Rect2:
	var local := Rect2(-width * 0.5 + edge_margin, -cover_height, width - edge_margin * 2.0, cover_height + 8.0)
	return Rect2(global_position + local.position, local.size)


## Make the leaves shiver (strength 0..1).
func rustle(strength: float = 1.0) -> void:
	_rustle = clampf(maxf(_rustle, strength), 0.0, 1.0)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var area := Rect2(global_position + Vector2(-width * 0.5, -cover_height - 10.0), Vector2(width, cover_height + 10.0))
	for player in get_tree().get_nodes_in_group("player"):
		var vel: Vector2 = player.get("velocity")
		if player.get_body_rect().intersects(area) and vel.length() > 12.0:
			rustle(0.8)
	var was_rustling := _rustle > 0.0
	_rustle = maxf(_rustle - delta * 1.4, 0.0)
	_time += delta
	if was_rustling:
		queue_redraw()


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = shape_seed
	var batch := SilhouetteBatch.new()
	if style == Style.BUSH:
		_paint_bush(batch, rng)
	else:
		_paint_low_branches(batch, rng)
	batch.commit(self, Palette.SILHOUETTE)
	if Engine.is_editor_hint():
		var r := get_cover_rect()
		draw_rect(Rect2(r.position - global_position, r.size), Color(0.4, 1.0, 0.5, 0.6), false, 1.0)


func _shiver(phase: float, amount: float) -> Vector2:
	return Vector2(sin(_time * 31.0 + phase) * amount * _rustle, cos(_time * 23.0 + phase) * amount * 0.5 * _rustle)


## Rounded but flat-ish profile (0..1) so the zone's top corners are covered too.
func _profile(t: float) -> float:
	return pow(maxf(1.0 - pow(absf(t * 2.0 - 1.0), 4.0), 0.0), 0.25)


func _paint_bush(batch: SilhouetteBatch, rng: RandomNumberGenerator) -> void:
	var body_h := cover_height + 4.0
	var half := width * 0.5
	var body := PackedVector2Array([Vector2(-half - 4.0, 4)])
	var steps := 18
	for i in steps + 1:
		var t := float(i) / float(steps)
		body.append(Vector2(lerpf(-half, half, t), -body_h * _profile(t)))
	body.append(Vector2(half + 4.0, 4))
	batch.polygon(body)
	var centre := Vector2(0, 10)
	# Irregular clumps breaking up the outline.
	for i in int(width / 22.0):
		var t := rng.randf_range(0.08, 0.92)
		var p := Vector2(lerpf(-half, half, t), -body_h * _profile(t))
		var r := rng.randf_range(5.0, 10.0) * (0.5 + 0.5 * _profile(t))
		batch.disc(p + (centre - p).normalized() * r * 0.55 + _shiver(float(i), 1.5), r)
	# Leaves fringing the whole outline, pointing outwards.
	var leaves := int(width / 4.5)
	for i in leaves:
		var t := (float(i) + rng.randf()) / float(leaves)
		var p := Vector2(lerpf(-half, half, t), -body_h * _profile(t))
		var dir := (p - centre).normalized().rotated(rng.randf_range(-0.55, 0.55))
		var tip_shake := _shiver(float(i) * 0.37, 2.0)
		batch.leaf(p - dir * 3.0, (dir + tip_shake * 0.05).normalized(), rng.randf_range(6.0, 10.0), rng.randf_range(1.8, 2.8))
	# A couple of taller sprigs at the shoulders of the bush.
	for k in 2:
		var x := (half * 0.62) * (-1.0 if k == 0 else 1.0) + rng.randf_range(-6.0, 6.0)
		var base := Vector2(x, -body_h * _profile((x + half) / width) + 3.0)
		var tip := base + Vector2((x / half) * 8.0, -rng.randf_range(12.0, 17.0)) + _shiver(9.0 + k, 3.0)
		batch.limb(base, tip, 1.6, 1.4)
		for j in 3:
			var at := base.lerp(tip, 0.45 + 0.25 * float(j))
			batch.leaf(at, Vector2(signf(x) * 0.8, -0.6).normalized().rotated(rng.randf_range(-0.4, 0.4)), 5.0, 1.6)


func _paint_low_branches(batch: SilhouetteBatch, rng: RandomNumberGenerator) -> void:
	var half := width * 0.5
	var trunk_base := Vector2(-half - 10.0, 0)
	# Trunk rising out of view with a sparse crown.
	var trunk_top := trunk_base + Vector2(12, -260)
	batch.limb(trunk_base + Vector2(0, 10), trunk_top, 22.0, 11.0)
	batch.quad(trunk_base + Vector2(-28, 6), trunk_base + Vector2(-8, -26), trunk_base + Vector2(8, -26), trunk_base + Vector2(26, 6))
	var crown_rng := RandomNumberGenerator.new()
	crown_rng.seed = shape_seed + 99
	TreePainter.paint_tree(batch, crown_rng, trunk_top + Vector2(0, 40), 170.0, 10.0)

	# The low bough: leaves the trunk higher up, then sweeps over the hiding spot
	# just above the zone and droops towards the ground at the far end.
	var top_y := -cover_height - 5.0
	var bough := PackedVector2Array([
		trunk_base + Vector2(6, top_y - 30.0), Vector2(-half + 6.0, top_y),
		Vector2(0, top_y + 1.0), Vector2(half * 0.7, top_y + 4.0), Vector2(half + 18.0, top_y + 18.0),
	])
	batch.chain(bough, 10.0, 3.0)

	# Curtain of drooping leaves below the bough, down to the ground.
	var cols := int(width / 7.0) + 3
	for i in cols:
		var x := lerpf(-half - 2.0, half + 10.0, float(i) / float(cols - 1))
		var y := _bough_y(bough, x) + 3.0
		var bottom := -rng.randf_range(0.0, 6.0)
		var phase := float(i) * 0.7
		while y < bottom:
			var r := rng.randf_range(4.5, 6.5)
			batch.disc(Vector2(x + rng.randf_range(-1.5, 1.5), y) + _shiver(phase, 1.8), r)
			y += r * 1.15
		batch.leaf(Vector2(x, bottom) + _shiver(phase, 2.5), Vector2(rng.randf_range(-0.3, 0.3), 1.0).normalized(), 9.0, 2.6)
	# Willow-like strands trailing off the far end of the bough.
	for k in 6:
		var start := Vector2(half + rng.randf_range(0.0, 16.0), _bough_y(bough, half + 8.0) + 2.0)
		var end := Vector2(start.x + rng.randf_range(2.0, 10.0), -rng.randf_range(0.0, 10.0)) + _shiver(float(k), 3.0)
		batch.limb(start, end, 1.4, 1.4)
		batch.leaf(end, Vector2(0.2, 1.0).normalized(), 6.0, 1.8)
	# Small leaves along the top of the bough so it reads as foliage, kept low.
	for k in int(width / 9.0):
		var x := rng.randf_range(-half + 4.0, half + 10.0)
		var base := Vector2(x, _bough_y(bough, x) - 2.0)
		batch.leaf(base, (Vector2(rng.randf_range(-0.7, 0.7), -1.0).normalized() + _shiver(float(k), 0.05)).normalized(), rng.randf_range(4.0, 6.0), 1.6)


func _bough_y(bough: PackedVector2Array, x: float) -> float:
	for i in bough.size() - 1:
		var a := bough[i]
		var b := bough[i + 1]
		if x <= b.x:
			return lerpf(a.y, b.y, clampf((x - a.x) / maxf(b.x - a.x, 0.001), 0.0, 1.0))
	return bough[bough.size() - 1].y
