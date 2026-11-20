class_name CreatureRig
extends Node2D
## Procedural silhouette of an original hunched predator: a tall arched spine
## with writhing tendrils, long knuckle-dragging arms with hooked claws,
## backward-bent legs, a low jutting head with pale slit eyes, and a jagged
## grin that splits open when it spots her. Twitchy head, lurching gait.
## Drawn facing right, feet at the origin; flipped via scale.x.

const State := CreatureBrain.State

var _state: int = State.PATROL
var _facing := 1
var _vx := 0.0

var _time := 0.0
var _phase := 0.0
var _speed := 0.0
var _alert := 0.0
var _sniff := 0.0
var _look := 0.0
var _lunge := 0.0
var _twitch := Vector2.ZERO
var _twitch_timer := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()


func set_state(state: int, facing: int, velocity_x: float) -> void:
	_state = state
	_facing = facing
	_vx = velocity_x


func _process(delta: float) -> void:
	_time += delta
	_speed = clampf(absf(_vx) / 60.0, 0.0, 2.6)
	_phase = fmod(_phase + absf(_vx) * delta * 0.06, TAU * 8.0)
	var alerted := _state == State.ALERT or _state == State.CHASE or _state == State.CAUGHT
	_alert = move_toward(_alert, 1.0 if alerted else 0.0, delta * 5.0)
	_sniff = move_toward(_sniff, 1.0 if _state == State.SNIFF else 0.0, delta * 3.0)
	_look = move_toward(_look, 1.0 if _state == State.LOOK or _state == State.SEARCH else 0.0, delta * 3.0)
	_lunge = move_toward(_lunge, 1.0 if _state == State.CAUGHT else 0.0, delta * 6.0)
	_twitch_timer -= delta
	if _twitch_timer <= 0.0:
		_twitch_timer = _rng.randf_range(0.5, 2.2)
		_twitch = Vector2(_rng.randf_range(-3.5, 3.5), _rng.randf_range(-3.0, 2.0))
	_twitch = _twitch.move_toward(Vector2.ZERO, delta * 18.0)
	scale.x = float(_facing)
	queue_redraw()


func _draw() -> void:
	var col := Palette.SILHOUETTE
	var ms := minf(_speed, 1.3)
	var p := _phase
	var bob := sin(p * 2.0) * 2.0 * minf(_speed, 1.0)
	var breathe := sin(_time * 1.7) * 1.5
	var rear := _alert * (1.0 - _lunge)

	var hip := Vector2(-6, -76 + bob)
	# Alerted, it stays hunched but bristles: hump up, shoulders and head thrust forward.
	var lean := clampf(_speed - 1.0, 0.0, 1.0)
	var hump := Vector2(4, -116 + bob * 1.2 + breathe).lerp(Vector2(8, -125), rear).lerp(Vector2(10, -102), _sniff)
	var shoulder := Vector2(24, -104 + bob).lerp(Vector2(31, -108), rear).lerp(Vector2(30, -86), _sniff) \
		.lerp(Vector2(32, -100), _lunge) + Vector2(5, 5) * lean
	var head := shoulder + Vector2(17, 9).lerp(Vector2(19, 3), rear).lerp(Vector2(16, 26), _sniff) \
		.lerp(Vector2(22, 6), _lunge)
	head += _twitch
	head.x += sin(_time * 2.2) * 5.0 * _look
	head.y += sin(_time * 10.0) * 1.6 * _sniff

	# Legs and arms behind the body first (same colour, but keeps it tidy).
	_draw_leg(hip, p + PI, 0, ms, col)
	_draw_arm(shoulder, p + PI, 0, ms, col)

	# Spine: a chain of discs along a curve through hip -> hump -> shoulder.
	var ctrl := hump * 2.0 - (hip + shoulder) * 0.5
	var samples := 12
	var spine: Array[Vector2] = []
	var radii: Array[float] = []
	for i in samples + 1:
		var t := float(i) / float(samples)
		spine.append(hip * (1.0 - t) * (1.0 - t) + ctrl * 2.0 * (1.0 - t) * t + shoulder * t * t)
		radii.append(lerpf(10.0, 13.0, t) + 8.0 * sin(t * PI))
	for i in samples:
		SilhouetteDraw.limb(self, spine[i], spine[i + 1], radii[i] * 2.0, radii[i + 1] * 2.0, col)

	# Writhing tendrils along the hump.
	for k in 5:
		var idx := 3 + k
		var normal := (spine[idx + 1] - spine[idx - 1]).normalized().orthogonal()
		if normal.y > 0.0:
			normal = -normal
		var base := spine[idx] + normal * radii[idx] * 0.7
		var dir := (normal + Vector2(-0.5, 0)).normalized().rotated(sin(_time * 2.6 + float(k) * 1.3) * 0.35)
		var length := 13.0 + 8.0 * absf(sin(float(k) * 1.7)) + rear * 8.0
		var a := base + dir * length * 0.45
		var b := a + dir.rotated(0.5 * sin(_time * 3.1 + float(k))) * length * 0.55
		SilhouetteDraw.chain(self, PackedVector2Array([base, a, b]), 4.0, 0.8, col)

	# Neck and head: long skull, snout and a jaw that drops open when alerted.
	var open := maxf(_alert, _lunge)
	SilhouetteDraw.limb(self, shoulder, head + Vector2(-6, 2), 14.0, 8.5, col)
	SilhouetteDraw.disc(self, head, 10.0, col)
	SilhouetteDraw.limb(self, head + Vector2(2, 1), head + Vector2(17, 3), 13.0, 6.5, col)
	SilhouetteDraw.limb(self, head + Vector2(0, 5), head + Vector2(14, 8 + open * 7.0), 8.0, 3.8, col)

	_draw_leg(hip, p, 1, ms, col)
	_draw_arm(shoulder, p, 1, ms, col)

	# Pale slit eyes (flare when it spots her) and the jagged grin.
	var eye := Palette.CREATURE_EYE
	var flicker := 0.85 + 0.15 * sin(_time * 13.0)
	var slant := Vector2(1.0, 0.38).normalized()
	for e in [head + Vector2(5, -2.5), head + Vector2(10.5, -1.2)]:
		draw_circle(e, 4.0 + 3.5 * open, Color(eye, (0.08 + 0.16 * open) * flicker), true, -1.0, true)
		draw_line(e - slant * 2.6, e + slant * 2.6, Color(eye, flicker), 1.7 + open * 0.9, true)
	if open > 0.05:
		var grin := PackedVector2Array()
		for z in 7:
			var t := float(z) / 6.0
			var pt := (head + Vector2(3, 5.5)).lerp(head + Vector2(15, 6.5 + open * 3.0), t)
			grin.append(pt + Vector2(0, -1.4 if z % 2 == 0 else 1.4))
		draw_polyline(grin, Color(Palette.CREATURE_GRIN, Palette.CREATURE_GRIN.a * open), 1.2, true)


func _draw_arm(shoulder: Vector2, ph: float, i: int, ms: float, col: Color) -> void:
	var root := shoulder + Vector2(-2.0 + float(i) * 3.0, 4)
	var walk := root + Vector2(12.0 + sin(ph) * 16.0 * ms, 80.0 - maxf(0.0, -cos(ph)) * 8.0 * ms)
	var wrist := walk.lerp(root + Vector2(30.0 + float(i) * 6.0, 52), _alert * (1.0 - _lunge)) \
		.lerp(root + Vector2(10.0 + float(i) * 8.0, 74), _sniff) \
		.lerp(root + Vector2(58.0 + float(i) * 4.0, 6.0 + float(i) * 6.0), _lunge)
	var elbow := SilhouetteDraw.ik_joint(root, wrist, 44.0, 46.0, 1.0)
	SilhouetteDraw.limb(self, root, elbow, 8.5, 5.2, col)
	SilhouetteDraw.limb(self, elbow, wrist, 5.2, 3.4, col)
	var spread := 0.6 * _alert
	for k in 3:
		var ang := lerpf(0.95 - spread, 1.9 + spread, float(k) / 2.0) - 1.1 * _lunge
		var p1 := wrist + Vector2.from_angle(ang) * 9.0
		var p2 := p1 + Vector2.from_angle(ang + 0.7) * 8.0
		SilhouetteDraw.chain(self, PackedVector2Array([wrist, p1, p2]), 3.0, 0.7, col)


func _draw_leg(hip: Vector2, ph: float, i: int, ms: float, col: Color) -> void:
	var root := hip + Vector2(float(i) * 3.0 - 1.0, 2)
	var toe := Vector2(hip.x + 4.0 + sin(ph) * 18.0 * ms + float(i) * 4.0, -maxf(0.0, cos(ph)) * 10.0 * ms)
	toe = toe.lerp(Vector2(hip.x - 12.0 + float(i) * 28.0, 0), _alert * (1.0 - _lunge))
	var ankle := toe + Vector2(-12, -13)
	var knee := SilhouetteDraw.ik_joint(root, ankle, 32.0, 36.0, -1.0)
	SilhouetteDraw.limb(self, root, knee, 12.0, 6.5, col)
	SilhouetteDraw.limb(self, knee, ankle, 6.5, 3.6, col)
	SilhouetteDraw.limb(self, ankle, toe, 3.6, 2.6, col)
	draw_colored_polygon(PackedVector2Array([toe + Vector2(0, -2), toe + Vector2(7, 0.5), toe + Vector2(0, 1.5)]), col)
