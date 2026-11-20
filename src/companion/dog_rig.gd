class_name DogRig
extends Node2D
## Procedural silhouette of a small scruffy dog with perky ears and a wagging tail.
## Small life cues: trots, hops, sniffs and sits when idle, lies down when the
## girl crouches, and cowers (ears back, tail tucked) when a creature is near.
## Drawn facing right, feet at the origin; flipped via scale.x.

var _velocity := Vector2.ZERO
var _facing := 1
var _girl_crouched := false
var _afraid := false

var _time := 0.0
var _phase := 0.0
var _idle_time := 0.0
var _speed := 0.0
var _sit := 0.0
var _lie := 0.0
var _fear := 0.0
var _sniff := 0.0
var _hop := 0.0


func set_state(velocity: Vector2, facing: int, girl_crouched: bool, afraid: bool) -> void:
	_velocity = velocity
	_facing = facing
	_girl_crouched = girl_crouched
	_afraid = afraid


func _process(delta: float) -> void:
	_time += delta
	var moving := absf(_velocity.x) > 12.0
	_idle_time = 0.0 if moving else _idle_time + delta
	_speed = clampf(absf(_velocity.x) / 150.0, 0.0, 1.3)
	_phase = fmod(_phase + absf(_velocity.x) * delta * 0.11, TAU * 8.0)
	var sniffing := _idle_time > 1.0 and fmod(_idle_time, 4.5) < 1.2 and not _afraid
	_sit = move_toward(_sit, 1.0 if _idle_time > 2.5 and not _girl_crouched else 0.0, delta * 3.0)
	_lie = move_toward(_lie, 1.0 if _girl_crouched and not moving else 0.0, delta * 4.0)
	_fear = move_toward(_fear, 1.0 if _afraid else 0.0, delta * 3.0)
	_sniff = move_toward(_sniff, 1.0 if sniffing else 0.0, delta * 4.0)
	_hop = move_toward(_hop, 1.0 if absf(_velocity.y) > 60.0 else 0.0, delta * 10.0)
	scale.x = float(_facing)
	queue_redraw()


func _draw() -> void:
	var col := Palette.SILHOUETTE
	var s := _speed * (1.0 - _hop)
	var low := _fear * 3.0
	var bob := absf(sin(_phase)) * 1.2 * s
	var hip := Vector2(-9, -14 + low + bob).lerp(Vector2(-8, -7), _sit).lerp(Vector2(-9, -6), _lie)
	var chest := Vector2(8, -15 + low * 0.6 + bob).lerp(Vector2(6, -17), _sit).lerp(Vector2(8, -7), _lie)
	var head := chest + Vector2(7, -8).lerp(Vector2(9, 3), _sniff).lerp(Vector2(9, -3), _lie).lerp(Vector2(6, -4), _fear * 0.7)
	head.y += sin(_time * 9.0) * 0.6 * _sniff

	# Legs: diagonal trot pairs.
	var legs := [
		[chest + Vector2(-1, 3), 0.0, Vector2(9, 6)], [chest + Vector2(2, 3), PI, Vector2(11, 6)],
		[hip + Vector2(-2, 3), PI, Vector2(6, 6)], [hip + Vector2(1, 3), 0.0, Vector2(7, 6)],
	]
	for i in legs.size():
		var root: Vector2 = legs[i][0]
		var ph: float = _phase + legs[i][1]
		var stand := Vector2(root.x + sin(ph) * 6.0 * s, -maxf(0.0, cos(ph)) * 3.0 * s)
		if i >= 2:
			stand = stand.lerp(hip + Vector2(5, 7), _sit)
		var hop_foot := root + (Vector2(6, 9) if i < 2 else Vector2(-6, 9))
		var foot := stand.lerp(hop_foot, _hop).lerp(root + legs[i][2] - Vector2(0, 2), _lie)
		SilhouetteDraw.limb(self, root, foot, 3.4, 2.4, col)

	# Body and neck.
	SilhouetteDraw.limb(self, hip, chest, 11.5, 12.5, col)
	SilhouetteDraw.limb(self, chest + Vector2(1, -2), head + Vector2(-1, 2), 6.5, 5.0, col)

	# Round head, short snout and small folded ears (flattened back when afraid).
	SilhouetteDraw.disc(self, head, 5.4, col)
	SilhouetteDraw.limb(self, head + Vector2(2, 1), head + Vector2(7, 2.4), 5.4, 3.4, col)
	SilhouetteDraw.disc(self, head + Vector2(7.6, 1.9), 1.6, col)
	var ear_tip := Vector2(-1.5, -9.5).lerp(Vector2(-8.5, -4.5), _fear)
	var fold := Vector2(2.0, 1.2).lerp(Vector2(-1.2, 1.2), _fear)
	draw_colored_polygon(PackedVector2Array([head + Vector2(-3.5, -2.5), head + ear_tip, head + Vector2(1.5, -4.5)]), col)
	SilhouetteDraw.disc(self, head + ear_tip + fold * 0.6, 1.3, col)

	# Tail: wags up when happy, tucks down when afraid.
	var wag_speed := 7.0 + 9.0 * s
	var angle := lerpf(-2.2, 2.5, _fear) + sin(_time * wag_speed) * lerpf(0.5, 0.15, _fear)
	var base := hip + Vector2(-4, -3)
	var mid := base + Vector2.from_angle(angle) * 6.0
	var tip := mid + Vector2.from_angle(angle + 0.5 * signf(sin(_time * wag_speed) + 0.01)) * 6.0
	SilhouetteDraw.chain(self, PackedVector2Array([base, mid, tip]), 3.0, 1.0, col)
