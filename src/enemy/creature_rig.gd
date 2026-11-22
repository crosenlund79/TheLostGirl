class_name CreatureRig
extends Node2D
## Procedural silhouette of an original hunched predator: very tall and gangly,
## its arched upper body hanging out ahead of its feet so it always looks about
## to tip over. Long dangling arms with hooked fingers, backward-bent legs with
## a slightly limping long stride, writhing tendrils on the hump, a low jutting
## head with pale slit eyes and a jagged grin that splits open when it spots her.
## Reaching for her is slow and trembling; sniffing stretches its neck down to
## the ground, one hand braced. Drawn facing right, feet at the origin; flipped
## via scale.x. Purely visual: speeds, sight and contact live in CreatureBrain.

const State := CreatureBrain.State
const THIGH := 44.0
const SHIN := 50.0
const UPPER_ARM := 58.0
const FOREARM := 62.0

var _state: int = State.PATROL
var _facing := 1
var _vx := 0.0

var _time := 0.0
var _phase := 0.0
var _speed := 0.0
var _reach := 0.0
var _sniff := 0.0
var _look := 0.0
var _lunge := 0.0
var _twitch := Vector2.ZERO
var _twitch_timer := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_time = _rng.randf_range(0.0, 20.0)  # creatures teeter out of sync


func set_state(state: int, facing: int, velocity_x: float) -> void:
	_state = state
	_facing = facing
	_vx = velocity_x


func _process(delta: float) -> void:
	_time += delta
	_speed = clampf(absf(_vx) / 60.0, 0.0, 2.6)
	_phase = fmod(_phase + absf(_vx) * delta * 0.05, TAU * 8.0)
	var reaching := _state == State.ALERT or _state == State.CHASE or _state == State.CAUGHT
	# Reaching out is slow (about a second): it visibly takes effort.
	_reach = move_toward(_reach, 1.0 if reaching else 0.0, delta * (1.0 if reaching else 1.8))
	_sniff = move_toward(_sniff, 1.0 if _state == State.SNIFF else 0.0, delta * 1.6)
	_look = move_toward(_look, 1.0 if _state == State.LOOK or _state == State.SEARCH else 0.0, delta * 2.0)
	_lunge = move_toward(_lunge, 1.0 if _state == State.CAUGHT else 0.0, delta * 5.0)
	_twitch_timer -= delta
	if _twitch_timer <= 0.0:
		_twitch_timer = _rng.randf_range(0.6, 2.4)
		_twitch = Vector2(_rng.randf_range(-4.0, 4.0), _rng.randf_range(-3.5, 2.5))
	_twitch = _twitch.move_toward(Vector2.ZERO, delta * 16.0)
	scale.x = float(_facing)
	queue_redraw()


func _draw() -> void:
	var col := Palette.SILHOUETTE
	var ms := minf(_speed, 1.3)
	var reach := smoothstep(0.0, 1.0, _reach) * (1.0 - _lunge)
	var sniff := smoothstep(0.0, 1.0, _sniff)
	var strain := maxf(reach, sniff)
	var tremble := Vector2(sin(_time * 41.0), cos(_time * 37.0)) * strain
	var bob := (absf(sin(_phase)) - 0.5) * 4.0 * minf(_speed, 1.0)
	var breathe := sin(_time * 1.5) * 2.0

	# Slow, irregular teeter; bigger while it searches. Positive tips it forward.
	var teeter := (sin(_time * 0.9) * 0.7 + sin(_time * 2.3 + 1.1) * 0.3) * lerpf(1.0, 1.7, _look)
	# The whole upper body pivots forward at the hips: reaching down for her and
	# sniffing are deep, strained bends; the teeter keeps it never quite balanced.
	var tip := 0.08 * teeter + 0.22 * reach + 0.04 * ms + 0.18 * sniff + 0.25 * _lunge

	# Tall question-mark stance: the spine rises steeply from the hips, arches
	# over, and hangs the shoulders and head out ahead of the feet.
	var hip := Vector2(-6, -110 + bob)
	var hump_rel := Vector2(10, -64).lerp(Vector2(16, -60), reach).lerp(Vector2(22, -52), sniff) + Vector2(0, -breathe * 0.5)
	var shoulder_rel := Vector2(46, -48).lerp(Vector2(52, -40), reach).lerp(Vector2(54, -26), sniff) \
		.lerp(Vector2(60, -34), _lunge)
	var hump := hip + hump_rel.rotated(tip)
	var shoulder := hip + shoulder_rel.rotated(tip)

	# Head hangs low and forward; stretched to the ground when sniffing, scanning when searching.
	var head_rel := Vector2(24, 22).lerp(Vector2(26, 16), reach).lerp(Vector2(18, 56), sniff).lerp(Vector2(30, 10), _lunge)
	head_rel += Vector2(sin(_time * 1.6) * 8.0, -7.0 - absf(sin(_time * 1.6)) * 3.0) * _look
	var head := shoulder + head_rel.rotated(tip * 0.5) + _twitch + tremble * 0.8
	var sniff_pulse := pow(maxf(0.0, sin(_time * 8.0)), 6.0)
	head += Vector2(2.5, 3.5) * sniff_pulse * sniff
	var head_angle := lerpf(0.35, 1.1, sniff) - 0.15 * reach + 0.12 * sin(_time * 1.6) * _look

	_draw_leg(hip, 0, ms, strain, col)
	_draw_arm(shoulder, 0, ms, teeter, reach, sniff, tremble, col)

	# Spine: a chain of discs along a curve through hip -> hump -> shoulder.
	var ctrl := hump * 2.0 - (hip + shoulder) * 0.5
	var samples := 12
	var spine: Array[Vector2] = []
	var radii: Array[float] = []
	for i in samples + 1:
		var t := float(i) / float(samples)
		spine.append(hip * (1.0 - t) * (1.0 - t) + ctrl * 2.0 * (1.0 - t) * t + shoulder * t * t)
		radii.append(lerpf(7.0, 9.0, t) + 5.5 * sin(t * PI))
	for i in samples:
		SilhouetteDraw.limb(self, spine[i], spine[i + 1], radii[i] * 2.0, radii[i + 1] * 2.0, col)

	# Writhing tendrils along the hump.
	for k in 5:
		var idx := 3 + k
		var normal := (spine[idx + 1] - spine[idx - 1]).normalized().orthogonal()
		if normal.y > 0.0:
			normal = -normal
		var base := spine[idx] + normal * radii[idx] * 0.7
		var dir := (normal + Vector2(-0.5, 0)).normalized().rotated(sin(_time * 2.4 + float(k) * 1.3) * 0.35)
		var length := 16.0 + 10.0 * absf(sin(float(k) * 1.7)) + reach * 8.0
		var a := base + dir * length * 0.45
		var b := a + dir.rotated(0.5 * sin(_time * 2.9 + float(k))) * length * 0.55
		SilhouetteDraw.chain(self, PackedVector2Array([base, a, b]), 3.2, 0.6, col)

	# Long neck (slight S-curve), narrow skull, snout and a jaw that drops open.
	var open := maxf(reach, _lunge)
	var neck_mid := shoulder.lerp(head, 0.5) + (head - shoulder).orthogonal().normalized() * 5.0
	SilhouetteDraw.chain(self, PackedVector2Array([shoulder, neck_mid, head + _hp(Vector2(-6, 2), head_angle)]), 12.0, 7.0, col)
	SilhouetteDraw.disc(self, head, 9.0, col)
	SilhouetteDraw.limb(self, head + _hp(Vector2(2, 1), head_angle), head + _hp(Vector2(19, 4), head_angle), 12.0, 5.5, col)
	SilhouetteDraw.limb(self, head + _hp(Vector2(0, 5), head_angle), head + _hp(Vector2(16, 9 + open * 8.0), head_angle), 7.0, 3.5, col)

	_draw_leg(hip, 1, ms, strain, col)
	_draw_arm(shoulder, 1, ms, teeter, reach, sniff, tremble, col)

	# Pale slit eyes (flare when it spots her) and the jagged grin.
	var eye := Palette.CREATURE_EYE
	var flicker := 0.85 + 0.15 * sin(_time * 13.0)
	var slant := Vector2(1.0, 0.38).normalized().rotated(head_angle - 0.2)
	for e in [head + _hp(Vector2(6, -2.5), head_angle), head + _hp(Vector2(12, -1.2), head_angle)]:
		draw_circle(e, 4.0 + 3.5 * open, Color(eye, (0.08 + 0.16 * open) * flicker), true, -1.0, true)
		draw_line(e - slant * 2.6, e + slant * 2.6, Color(eye, flicker), 1.7 + open * 0.9, true)
	if open > 0.05:
		var grin := PackedVector2Array()
		for z in 7:
			var t := float(z) / 6.0
			var pt := _hp(Vector2(3, 5.5), head_angle).lerp(_hp(Vector2(17, 7.0 + open * 3.0), head_angle), t)
			grin.append(head + pt + Vector2(0, -1.4 if z % 2 == 0 else 1.4))
		draw_polyline(grin, Color(Palette.CREATURE_GRIN, Palette.CREATURE_GRIN.a * open), 1.2, true)


## A head-local offset rotated by the head's pitch.
func _hp(v: Vector2, angle: float) -> Vector2:
	return v.rotated(angle)


func _draw_arm(shoulder: Vector2, i: int, ms: float, teeter: float, reach: float, sniff: float,
		tremble: Vector2, col: Color) -> void:
	var root := shoulder + Vector2(-3.0 + float(i) * 4.0, 6)
	# Walking: long arms dangle to knee height and swing loosely, lagging the teeter.
	var swing := sin(_phase + (PI if i == 0 else 0.0)) * 18.0 * ms
	var dangle := root + Vector2(10.0 + swing - teeter * 8.0, 108.0 - absf(swing) * 0.3)
	# Reaching: stretched forward and down towards her, one arm further, trembling.
	var reach_to := root + Vector2(90.0 - float(i) * 16.0, 70.0 + float(i) * 8.0) + tremble * 2.0
	# Sniffing: the near hand braces on the ground ahead, the far arm hangs.
	var brace := Vector2(shoulder.x + 30.0, 0) if i == 1 else dangle + Vector2(-10, -10)
	var lunge_to := root + Vector2(110.0 - float(i) * 10.0, 4.0 + float(i) * 8.0)
	var wrist := dangle.lerp(reach_to, reach).lerp(brace, sniff).lerp(lunge_to, _lunge)
	var elbow := SilhouetteDraw.ik_joint(root, wrist, UPPER_ARM, FOREARM, 1.0)
	wrist = elbow + (wrist - elbow).limit_length(FOREARM)
	SilhouetteDraw.limb(self, root, elbow, 6.5, 4.0, col)
	SilhouetteDraw.limb(self, elbow, wrist, 4.0, 2.8, col)
	# Long hooked fingers that slowly curl and uncurl, spreading as it reaches.
	var along := (wrist - elbow).normalized()
	var curl := 0.55 + 0.3 * sin(_time * 1.9 + float(i) * 2.0)
	var spread := 0.45 + 0.35 * reach
	for k in 3:
		var base_dir := along.rotated(lerpf(-spread, spread, float(k) / 2.0))
		var p1 := wrist + base_dir * 11.0
		var p2 := p1 + base_dir.rotated(curl) * 9.0
		SilhouetteDraw.chain(self, PackedVector2Array([wrist, p1, p2]), 2.6, 0.6, col)


func _draw_leg(hip: Vector2, i: int, ms: float, strain: float, col: Color) -> void:
	var root := hip + Vector2(float(i) * 4.0 - 2.0, 3)
	# Long, high-kneed stride with a slight limp (one leg off the beat).
	var ph := _phase + (PI if i == 1 else 0.0) + 0.35 * sin(_phase)
	var toe := Vector2(hip.x + 10.0 + sin(ph) * 30.0 * ms + float(i) * 6.0, -maxf(0.0, cos(ph)) * 16.0 * ms)
	# Bracing: feet planted wide, the back leg pushed far behind as it strains forward.
	toe = toe.lerp(Vector2(hip.x - 24.0 + float(i) * 48.0, 0), strain * (1.0 - _lunge))
	var ankle := toe + Vector2(-16, -20)
	var knee := SilhouetteDraw.ik_joint(root, ankle, THIGH, SHIN, -1.0)
	SilhouetteDraw.limb(self, root, knee, 10.0, 5.5, col)
	SilhouetteDraw.limb(self, knee, ankle, 5.5, 3.2, col)
	SilhouetteDraw.limb(self, ankle, toe, 3.2, 2.4, col)
	draw_colored_polygon(PackedVector2Array([toe + Vector2(0, -2), toe + Vector2(8, 0.5), toe + Vector2(0, 1.5)]), col)
