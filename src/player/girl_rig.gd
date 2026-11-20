class_name GirlRig
extends Node2D
## Procedural silhouette of the girl: big head, two bowed pigtails on springs,
## an A-line dress, and a teddy bear dangling from one hand on a pendulum so it
## wobbles and lags behind her. Drawn facing right with feet at the origin;
## flipped via scale.x. Purely visual: it never affects gameplay.
## While she is hidden, two faint eyes peek out above the cover (see GirlEyes).

const WALK_SPEED_REF := 150.0
const TEDDY_GRAVITY := Vector2(0, 700)
const PIGTAIL_LENGTH := 15.0
const PIGTAIL_STIFFNESS := 650.0
## Max swing of a pigtail away from its rest angle (radians).
const PIGTAIL_MAX_SWING := 0.85
## Fraction of velocity kept per second (lower = calmer).
const TEDDY_DAMPING := 0.25
const PIGTAIL_DAMPING := 0.01

var _velocity := Vector2.ZERO
var _on_floor := true
var _crouching := false
var _hidden := false
var _facing := 1

var _crouch := 0.0
var _air := 0.0
var _speed := 0.0
var _walk_phase := 0.0

# Secondary motion, simulated in world space (Verlet).
var _teddy := Vector2.ZERO
var _teddy_prev := Vector2.ZERO
var _pig := [Vector2.ZERO, Vector2.ZERO]
var _pig_prev := [Vector2.ZERO, Vector2.ZERO]
var _sim_ready := false
var _pose := {}

@onready var _eyes: GirlEyes = $Eyes


func set_state(velocity: Vector2, on_floor: bool, crouching: bool, facing: int, hidden: bool) -> void:
	_velocity = velocity
	_on_floor = on_floor
	_crouching = crouching
	_hidden = hidden
	if facing != 0:
		_facing = facing


func reset_secondary_motion() -> void:
	_sim_ready = false


func _process(delta: float) -> void:
	_crouch = move_toward(_crouch, 1.0 if _crouching else 0.0, delta * 7.0)
	_air = move_toward(_air, 0.0 if _on_floor else 1.0, delta * 8.0)
	_speed = clampf(absf(_velocity.x) / WALK_SPEED_REF, 0.0, 1.0)
	if _on_floor:
		_walk_phase = fmod(_walk_phase + absf(_velocity.x) * delta * 0.075, TAU * 8.0)
	scale.x = float(_facing)
	_pose = _compute_pose()
	_simulate(delta)
	_eyes.update_eyes(_pose.head, _hidden, delta)
	queue_redraw()


func _compute_pose() -> Dictionary:
	var c := _crouch
	var a := _air * (1.0 - c)
	var s := _speed * (1.0 - _air) * (1.0 - c * 0.5)
	var p := _walk_phase
	var bob := -absf(sin(p)) * 1.6 * s
	var rising := _velocity.y < 0.0

	var hip := Vector2(0, -25).lerp(Vector2(-3, -11), c) + Vector2(0, bob)
	var shoulder := Vector2(0.5, -46).lerp(Vector2(3, -25), c) + Vector2(s * 1.5, bob)
	var head := Vector2(1.5, -59).lerp(Vector2(6.5, -29), c) + Vector2(s * 2.0, bob * 0.8 - a)

	var crouch_feet: Array[Vector2] = [Vector2(-7, 0), Vector2(6, 0)]
	var crouch_knees: Array[Vector2] = [Vector2(3, -11), Vector2(10, -9)]
	var air_feet: Array[Vector2] = [Vector2(-4, -3), Vector2(5, -5)]
	if rising:
		air_feet = [Vector2(-6, -10), Vector2(5, -13)]
	var feet: Array[Vector2] = []
	var knees: Array[Vector2] = []
	for i in 2:
		var ph := p + float(i) * PI
		var stand_foot := Vector2(sin(ph) * 8.0 * s + (1.5 if i == 1 else -1.5), -maxf(0.0, cos(ph)) * 4.5 * s)
		var foot := stand_foot.lerp(crouch_feet[i], c).lerp(air_feet[i], a)
		var stand_knee := (hip + foot) * 0.5 + Vector2(2, 0)
		var air_knee := (hip + air_feet[i]) * 0.5 + Vector2(5, -2)
		feet.append(foot)
		knees.append(stand_knee.lerp(crouch_knees[i], c).lerp(air_knee, a))

	# Teddy arm held a little forward so the bear dangles clear of the dress.
	var teddy_hand := (shoulder + Vector2(10.5 + sin(p) * 2.0 * s, 16.0)) \
		.lerp(shoulder + Vector2(9, 9), c).lerp(shoulder + Vector2(12, 6), a)
	var free_hand := (shoulder + Vector2(-3.0 - sin(p) * 6.0 * s, 16.0)) \
		.lerp(shoulder + Vector2(7, 7), c).lerp(shoulder + Vector2(-10, -6), a)

	var hem_center := Vector2(lerpf(hip.x + 1.0, hip.x + 4.0, c) + sin(p) * 1.5 * s, lerpf(hip.y + 6.0, -3.0, c))
	var hem_half := lerpf(12.0, 14.5, c) + a * 4.0 + s

	return {
		"hip": hip, "shoulder": shoulder, "head": head,
		"feet": feet, "knees": knees,
		"teddy_hand": teddy_hand, "free_hand": free_hand,
		"hem_center": hem_center, "hem_half": hem_half, "hem_lift": a * 3.0,
		"teddy_length": lerpf(13.0, 7.0, c),
		# Pigtails stick out from both sides of the head, drooping ~37 degrees.
		"pig_anchor": [head + Vector2(-8.4, -1.5), head + Vector2(8.0, -2.0)],
		"pig_rest": [Vector2(-0.8, 0.6), Vector2(0.8, 0.6)],
	}


func _simulate(delta: float) -> void:
	var hand_w := to_global(_pose.teddy_hand)
	if not _sim_ready:
		_teddy = hand_w + Vector2(0, _pose.teddy_length)
		_teddy_prev = _teddy
		for i in 2:
			_pig[i] = to_global(_pose.pig_anchor[i] + _pose.pig_rest[i] * PIGTAIL_LENGTH)
			_pig_prev[i] = _pig[i]
		_sim_ready = true
		return
	if delta <= 0.0:
		return

	# Teddy: pendulum hanging from her hand, nudged in rhythm with her steps.
	var keep := pow(TEDDY_DAMPING, delta)
	var vel := (_teddy - _teddy_prev) * keep
	_teddy_prev = _teddy
	_teddy += vel + TEDDY_GRAVITY * delta * delta
	_teddy.x += sin(_walk_phase * 2.0) * 10.0 * _speed * delta * float(_facing)
	var offset := _teddy - hand_w
	if offset.length_squared() < 0.01:
		offset = Vector2.DOWN
	_teddy = hand_w + offset.normalized() * _pose.teddy_length

	# Pigtails: springs pulling each tip back to its rest direction, with the
	# swing clamped so they flap and bounce but never flip over the head.
	var pig_keep := pow(PIGTAIL_DAMPING, delta)
	for i in 2:
		var anchor_w := to_global(_pose.pig_anchor[i])
		var rest_w := to_global(_pose.pig_anchor[i] + _pose.pig_rest[i] * PIGTAIL_LENGTH)
		var v: Vector2 = (_pig[i] - _pig_prev[i]) * pig_keep
		_pig_prev[i] = _pig[i]
		_pig[i] += v + (rest_w - _pig[i]) * PIGTAIL_STIFFNESS * delta * delta
		var rest_dir := (rest_w - anchor_w).normalized()
		var d: Vector2 = _pig[i] - anchor_w
		var swing := clampf(rest_dir.angle_to(d), -PIGTAIL_MAX_SWING, PIGTAIL_MAX_SWING)
		var length := clampf(d.length(), PIGTAIL_LENGTH * 0.8, PIGTAIL_LENGTH * 1.1)
		_pig[i] = anchor_w + rest_dir.rotated(swing) * length


func _draw() -> void:
	if _pose.is_empty():
		return
	var col := Palette.SILHOUETTE
	var shoulder: Vector2 = _pose.shoulder
	var head: Vector2 = _pose.head
	var hip: Vector2 = _pose.hip

	_draw_pigtail(0, col)

	# Free arm (behind the body).
	var free_hand: Vector2 = _pose.free_hand
	var free_elbow := (shoulder + free_hand) * 0.5 + Vector2(-1.5, 0)
	SilhouetteDraw.limb(self, shoulder + Vector2(-3, 1), free_elbow, 2.6, 2.3, col)
	SilhouetteDraw.limb(self, free_elbow, free_hand, 2.3, 2.0, col)
	SilhouetteDraw.disc(self, free_hand, 1.8, col)

	# Legs and little shoes.
	for i in 2:
		var hip_joint := hip + Vector2(-2.5 if i == 0 else 2.5, 0)
		SilhouetteDraw.limb(self, hip_joint, _pose.knees[i], 3.6, 3.1, col)
		SilhouetteDraw.limb(self, _pose.knees[i], _pose.feet[i], 3.1, 2.7, col)
		SilhouetteDraw.limb(self, _pose.feet[i] + Vector2(-1, -1.5), _pose.feet[i] + Vector2(2.5, -1.2), 3.2, 2.8, col)

	# A-line dress with puff sleeves.
	var hc: Vector2 = _pose.hem_center
	var hw: float = _pose.hem_half
	var lift: float = _pose.hem_lift
	var dress := PackedVector2Array([
		shoulder + Vector2(-4.5, -1), shoulder + Vector2(4.5, -1), shoulder + Vector2(6, 7),
		hc + Vector2(hw, -lift), hc + Vector2(hw * 0.5, 1.5), hc + Vector2(0, 0.5),
		hc + Vector2(-hw * 0.5, 1.5), hc + Vector2(-hw, -lift), shoulder + Vector2(-5.5, 7),
	])
	SilhouetteDraw.poly(self, dress, col)
	SilhouetteDraw.disc(self, shoulder + Vector2(-4.5, 1.5), 3.3, col)
	SilhouetteDraw.disc(self, shoulder + Vector2(4.5, 1.5), 3.3, col)

	# Head: round skull, a little fringe bump and a chin.
	SilhouetteDraw.limb(self, shoulder + Vector2(0, -1), head + Vector2(0, 7), 3.6, 3.6, col)
	SilhouetteDraw.disc(self, head, 9.4, col)
	SilhouetteDraw.disc(self, head + Vector2(3.5, -6.0), 4.2, col)
	SilhouetteDraw.disc(self, head + Vector2(4.5, 6.2), 3.6, col)

	# Teddy arm and the teddy itself.
	var hand: Vector2 = _pose.teddy_hand
	var elbow := (shoulder + hand) * 0.5 + Vector2(-0.5, 1.5)
	SilhouetteDraw.limb(self, shoulder + Vector2(3.5, 1), elbow, 2.6, 2.3, col)
	SilhouetteDraw.limb(self, elbow, hand, 2.3, 2.0, col)
	SilhouetteDraw.disc(self, hand, 1.9, col)
	_draw_teddy(hand, to_local(_teddy), col)

	_draw_pigtail(1, col)


func _draw_pigtail(i: int, col: Color) -> void:
	var anchor: Vector2 = _pose.pig_anchor[i]
	var tip := to_local(_pig[i])
	var mid := anchor.lerp(tip, 0.5)
	SilhouetteDraw.limb(self, anchor, mid, 4.5, 8.0, col)
	SilhouetteDraw.limb(self, mid, tip, 8.0, 2.0, col)
	# Bow at the hair tie.
	var along := (tip - anchor).normalized()
	var across := along.orthogonal()
	var knot := anchor + along * 1.5
	draw_colored_polygon(PackedVector2Array([knot, knot + across * 3.8 - along * 2.4, knot + across * 3.8 + along * 1.8]), col)
	draw_colored_polygon(PackedVector2Array([knot, knot - across * 3.8 + along * 1.8, knot - across * 3.8 - along * 2.4]), col)
	SilhouetteDraw.disc(self, knot, 1.8, col)


func _draw_teddy(hand: Vector2, body: Vector2, col: Color) -> void:
	var dir := (body - hand).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.DOWN
	var perp := dir.orthogonal()
	# Held by one raised paw: head beside her hand, round ears, body below.
	SilhouetteDraw.limb(self, hand, hand + dir * 3.5 + perp * 1.5, 2.4, 2.8, col)
	var head := hand + dir * 5.5 + perp * 4.2
	SilhouetteDraw.disc(self, head, 4.6, col)
	SilhouetteDraw.disc(self, head - dir * 3.6 + perp * 3.0, 2.2, col)
	SilhouetteDraw.disc(self, head - dir * 3.6 - perp * 2.6, 2.1, col)
	var center := hand + dir * 12.5 + perp * 2.0
	SilhouetteDraw.poly(self, SilhouetteDraw.ellipse_points(center, Vector2(6.2, 5.0), dir.angle(), 16), col)
	SilhouetteDraw.disc(self, center + dir * 5.4 + perp * 3.0, 2.4, col)
	SilhouetteDraw.disc(self, center + dir * 5.4 - perp * 2.8, 2.4, col)
	SilhouetteDraw.disc(self, center - dir * 1.5 - perp * 5.4, 1.9, col)
