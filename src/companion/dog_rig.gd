class_name DogRig
extends Node2D
## Procedural silhouette of a big, round, fluffy companion dog in the spirit of a
## Bernese Mountain Dog: barrel body, deep chest, sturdy legs with big paws, a
## broad head with soft hanging ears, and a bushy tail carried low that curls up
## when it is happy. Small life cues: ambles, breathes, sniffs and sits when idle,
## lies down when the girl crouches, and cowers (ears back, tail tucked) when a
## creature is near. Drawn facing right, feet at the origin; flipped via scale.x.

## Overall size relative to the drawing below (tunes presence next to the girl).
const BODY_SCALE := 0.88

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
	_phase = fmod(_phase + absf(_velocity.x) * delta * 0.085, TAU * 8.0)
	var sniffing := _idle_time > 1.0 and fmod(_idle_time, 4.5) < 1.2 and not _afraid
	_sit = move_toward(_sit, 1.0 if _idle_time > 2.5 and not _girl_crouched else 0.0, delta * 2.5)
	_lie = move_toward(_lie, 1.0 if _girl_crouched and not moving else 0.0, delta * 3.0)
	_fear = move_toward(_fear, 1.0 if _afraid else 0.0, delta * 3.0)
	_sniff = move_toward(_sniff, 1.0 if sniffing else 0.0, delta * 3.0)
	_hop = move_toward(_hop, 1.0 if absf(_velocity.y) > 60.0 else 0.0, delta * 10.0)
	scale = Vector2(float(_facing) * BODY_SCALE, BODY_SCALE)
	queue_redraw()


func _draw() -> void:
	var col := Palette.SILHOUETTE
	var s := _speed * (1.0 - _hop)
	var low := _fear * 4.0
	var bob := absf(sin(_phase)) * 1.5 * s
	var breathe := sin(_time * 2.2) * 0.7 * (1.0 - s)
	var hip := Vector2(-17, -26 + low + bob).lerp(Vector2(-14, -11), _sit).lerp(Vector2(-17, -10), _lie)
	var chest := Vector2(13, -28 + low * 0.6 + bob - breathe).lerp(Vector2(11, -28), _sit).lerp(Vector2(13, -11), _lie)
	var head := chest + Vector2(14, -13).lerp(Vector2(17, 0), _sniff).lerp(Vector2(16, -7), _lie).lerp(Vector2(12, -7), _fear * 0.8)
	head.y += sin(_time * 9.0) * 0.6 * _sniff + sin(_time * 0.8) * 0.6 * (1.0 - s)

	# Sturdy legs (diagonal amble pairs) with big round paws.
	var legs := [
		[chest + Vector2(-3, 9), 0.0, Vector2(13, 8)], [chest + Vector2(3, 9), PI, Vector2(16, 8)],
		[hip + Vector2(-4, 9), PI, Vector2(9, 8)], [hip + Vector2(2, 9), 0.0, Vector2(11, 8)],
	]
	for i in legs.size():
		var root: Vector2 = legs[i][0]
		var ph: float = _phase + legs[i][1]
		var stand := Vector2(root.x + sin(ph) * 7.0 * s, -maxf(0.0, cos(ph)) * 3.5 * s)
		if i >= 2:
			stand = stand.lerp(hip + Vector2(9, 11), _sit)
		var hop_foot := root + (Vector2(7, 10) if i < 2 else Vector2(-7, 10))
		var foot := stand.lerp(hop_foot, _hop).lerp(root + legs[i][2] - Vector2(0, 2), _lie)
		SilhouetteDraw.limb(self, root, foot, 7.0, 5.5, col)
		SilhouetteDraw.disc(self, foot + Vector2(1.8, -2.4), 3.4, col)

	# Barrel body, deep rounded chest and a fluffy rump.
	SilhouetteDraw.limb(self, hip, chest, 22.0, 24.0, col)
	SilhouetteDraw.disc(self, chest + Vector2(3, 4), 11.5, col)
	SilhouetteDraw.disc(self, hip + Vector2(-3, -1), 11.5, col)

	# Thick neck, broad head with full cheeks, a defined muzzle.
	SilhouetteDraw.limb(self, chest + Vector2(3, -7), head + Vector2(-3, 5), 15.0, 12.0, col)
	SilhouetteDraw.disc(self, head, 8.5, col)
	SilhouetteDraw.disc(self, head + Vector2(-2, 4), 7.0, col)
	SilhouetteDraw.limb(self, head + Vector2(4, 2.5), head + Vector2(14, 5), 9.0, 7.0, col)
	SilhouetteDraw.disc(self, head + Vector2(14.6, 4), 2.4, col)

	# Soft ear hanging beside the head (pressed back when afraid).
	var ear_end := Vector2(-6.5, 5.0).lerp(Vector2(-11.0, 0.5), _fear)
	SilhouetteDraw.limb(self, head + Vector2(-3, -5), head + ear_end, 7.0, 4.5, col)

	# Bushy tail carried low: curls up and sways when content, tucks under when afraid.
	var wag_speed := 4.0 + 6.0 * s
	var sway := sin(_time * wag_speed) * lerpf(0.28, 0.08, _fear)
	var base := hip + Vector2(-12, -4)
	var mid := base + Vector2.from_angle(lerpf(2.05, 1.75, _fear) + sway) * 11.0
	var tip := mid + Vector2.from_angle(lerpf(2.85, 1.1, _fear) + sway * 1.6) * 9.0
	SilhouetteDraw.chain(self, PackedVector2Array([base, mid, tip]), 9.0, 4.5, col)
