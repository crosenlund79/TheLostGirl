class_name DogRig
extends Node2D
## A Bernese Mountain Dog-like companion drawn as an articulated vector
## silhouette: a smooth torso outline posed along the spine, a neck that stretches
## between body and head, a broad head with a clear stop, a proper muzzle and a
## hinged jaw, a soft hanging ear, a thick bushy tail, feathered legs and "pants",
## and four two-joint legs driven by a real gait (walk at low speed, trot when
## hurrying). Planted paws stay put in the world (no skating); when it stops it
## finishes its steps one paw at a time; turning is a short body turn. Idle life:
## breathing, gentle panting, looking about, sniffing, sitting. It lies down
## beside the girl when she crouches and cowers when a creature is near.
## Drawn facing right with feet at the origin. Purely visual: following is Dog.

const BODY_SCALE := 0.9
const TURN_TIME := 0.2
const STEP_TIME := 0.16

# ---- Rest pose: standing, facing right, world px, ground at y = 0 ----------
# Proportions from the breed: withers ~38.5, body ~1.1x as long as tall, chest
# reaching about half the height, a broad head carried high with a clear stop,
# muzzle about two thirds of the skull, and a bushy tail hanging to the hocks.
const TORSO := [
	Vector2(-18.5, -35), Vector2(-14, -37), Vector2(-7, -37.6), Vector2(2, -37.8),
	Vector2(10, -38.8), Vector2(15, -38), Vector2(21, -33), Vector2(24.2, -28.5),
	Vector2(23.5, -24), Vector2(20, -20.8), Vector2(14, -19.6), Vector2(7, -19.8),
	Vector2(0, -20.4), Vector2(-7, -21.8), Vector2(-12, -22.6), Vector2(-17, -24),
	Vector2(-20.2, -28), Vector2(-20.4, -32),
]
## Neck outline: [point, weight] where weight 0 follows the torso and 1 the head.
const NECK := [
	[Vector2(7, -38.5), 0.0], [Vector2(12, -43.5), 0.5], [Vector2(17, -48.5), 1.0], [Vector2(21.5, -50), 1.0],
	[Vector2(27, -42), 1.0], [Vector2(26.5, -35), 0.4], [Vector2(23.5, -31), 0.0], [Vector2(17, -34), 0.0],
]
const HEAD_PIVOT := Vector2(19.5, -45.5)
const HEAD := [
	Vector2(17.5, -47), Vector2(19, -50.5), Vector2(22.5, -52.6), Vector2(26.5, -52.6),
	Vector2(29.5, -51.2), Vector2(31.2, -49.2), Vector2(33.5, -48.6), Vector2(36.2, -48.2),
	Vector2(38, -47.2), Vector2(38.6, -45.6), Vector2(38.2, -44.0), Vector2(37, -43.4),
	Vector2(34.5, -42.9), Vector2(32, -43.1), Vector2(29, -41.6), Vector2(25.5, -40.6),
	Vector2(21, -41), Vector2(18, -43.5),
]
const JAW_HINGE := Vector2(31.5, -43)
const JAW := [
	Vector2(31, -43.4), Vector2(36.8, -43.2), Vector2(37, -42.0), Vector2(34.5, -41.1),
	Vector2(31, -40.9), Vector2(28.5, -41.6),
]
const EAR_PIVOT := Vector2(22.5, -51.8)
const EAR := [
	Vector2(19.8, -51.6), Vector2(26.4, -52.2), Vector2(28, -48.5), Vector2(27.6, -44.2),
	Vector2(24.6, -39.2), Vector2(20.6, -41.4), Vector2(19.2, -46.5),
]
const TAIL := [Vector2(-19, -33.5), Vector2(-25.5, -29), Vector2(-30, -21.5), Vector2(-30.8, -14.2), Vector2(-29.2, -10)]
const TAIL_WIDTH := [4.5, 6.5, 7.6, 6.6, 2.6]

const SHOULDER := Vector2(13, -29)
const ELBOW := Vector2(10.5, -19.5)
const WRIST := Vector2(12, -5)
const FRONT_PAW := Vector2(13.8, -1.6)
const HIP := Vector2(-13.5, -30)
const STIFLE := Vector2(-7.5, -18)
const HOCK := Vector2(-15, -6.5)
const REAR_PAW := Vector2(-12.5, -1.6)
## Fur hanging behind the thigh ("pants"), skinned to the thigh.
const PANTS := [
	Vector2(-19.6, -27), Vector2(-20.4, -22.5), Vector2(-18.8, -17.5), Vector2(-16.4, -13.5),
	Vector2(-15, -13.5), Vector2(-15, -17.5), Vector2(-16, -23),
]
## Feathering behind the forearm, skinned to the forearm.
const FEATHER := [Vector2(9.4, -18.5), Vector2(8.2, -14.5), Vector2(9.2, -10.5), Vector2(11, -11.5), Vector2(11.2, -16)]
const BELLY_TUFTS := [Vector2(-7, -21.8), Vector2(-2, -20.8), Vector2(3, -20.2), Vector2(8, -19.9), Vector2(13, -19.7)]

## Legs: 0 far hind, 1 far front, 2 near hind, 3 near front.
const LEG_IS_FRONT := [false, true, false, true]
const LEG_DEPTH := [1.5, -2.0, 0.0, 0.0]

var _velocity := Vector2.ZERO
var _facing := 1
var _girl_crouched := false
var _afraid := false

var _time := 0.0
var _phase := 0.0
var _move := 0.0
var _gait := 0.0
var _idle_time := 0.0
var _sit := 0.0
var _lie := 0.0
var _fear := 0.0
var _sniff := 0.0
var _hop := 0.0
var _feet: Array[Vector2] = []
var _lift: Array[float] = [0.0, 0.0, 0.0, 0.0]
var _step_leg := -1
var _step_t := 0.0
var _step_from := Vector2.ZERO
var _resume := 1.0
var _shown_sign := 1.0
var _turn_to := 1.0
var _turn_t := 1.0

# Pose of the current frame.
var _rot := 0.0
var _off := Vector2.ZERO
var _head_rot := 0.0
var _head_off := Vector2.ZERO


func _ready() -> void:
	reset_pose(_facing)


func set_state(velocity: Vector2, facing: int, girl_crouched: bool, afraid: bool) -> void:
	_velocity = velocity
	_facing = facing
	_girl_crouched = girl_crouched
	_afraid = afraid


## Stand still, all four paws home, facing the given way (after a teleport).
func reset_pose(facing: int) -> void:
	_facing = facing
	_feet.clear()
	for i in 4:
		_feet.append(_home(i))
	_lift = [0.0, 0.0, 0.0, 0.0]
	_step_leg = -1
	_move = 0.0
	_shown_sign = float(facing)
	_turn_to = float(facing)
	_turn_t = 1.0
	scale = Vector2(_shown_sign * BODY_SCALE, BODY_SCALE)


func _process(delta: float) -> void:
	_time += delta
	_update_turn(delta)
	var vx := absf(_velocity.x)
	var moving := vx > 8.0
	_move = move_toward(_move, 1.0 if moving else 0.0, delta * 5.0)
	_gait = move_toward(_gait, clampf((vx - 70.0) / 60.0, 0.0, 1.0), delta * 2.0)
	_idle_time = 0.0 if moving else _idle_time + delta
	var sniff_clock := fmod(_idle_time, 7.0)
	var sniffing := sniff_clock >= 2.0 and sniff_clock < 3.6 and not _afraid and not _girl_crouched
	_sit = move_toward(_sit, 1.0 if _idle_time > 5.0 and not _girl_crouched and not _afraid else 0.0, delta * 1.6)
	_lie = move_toward(_lie, 1.0 if _girl_crouched and not moving else 0.0, delta * 1.8)
	_fear = move_toward(_fear, 1.0 if _afraid and not _girl_crouched else 0.0, delta * 2.0)
	_sniff = move_toward(_sniff, 1.0 if sniffing and _sit < 0.1 else 0.0, delta * 2.0)
	_hop = move_toward(_hop, 1.0 if absf(_velocity.y) > 60.0 else 0.0, delta * 8.0)
	_update_feet(delta, vx, moving)
	_update_body()
	queue_redraw()


# ---- Locomotion -------------------------------------------------------------

func _home(leg: int) -> Vector2:
	var paw: Vector2 = FRONT_PAW if LEG_IS_FRONT[leg] else REAR_PAW
	return paw + Vector2(LEG_DEPTH[leg], 0)


func _duty() -> float:
	return lerpf(0.66, 0.5, _gait)


func _stride(vx: float) -> float:
	return clampf(6.0 + 0.12 * vx, 6.0, 24.0)


## Phase offset of each leg: lateral walk (hind, front, hind, front) blending to
## a trot (diagonal pairs move together).
func _leg_offset(leg: int) -> float:
	match leg:
		1:
			return lerpf(0.25, 0.5, _gait)
		2:
			return 0.5
		3:
			return lerpf(0.75, 1.0, _gait)
	return 0.0


## Paw position for a leg at the current gait phase. During stance the paw slides
## back exactly as fast as the body moves forward, so it stays put on the ground.
func _gait_foot(leg: int, stride: float) -> Array:
	var phi := fmod(_phase + _leg_offset(leg), 1.0)
	var duty := _duty()
	var home := _home(leg)
	if phi < duty:
		return [home + Vector2(stride * (0.5 - phi / duty), 0.0), 0.0]
	var s := (phi - duty) / (1.0 - duty)
	var lift := sin(PI * s)
	var height := (2.2 + 1.6 * _gait) * minf(stride / 12.0, 1.0)
	return [home + Vector2(stride * (-0.5 + smoothstep(0.0, 1.0, s)), -height * lift), lift]


func _update_feet(delta: float, vx: float, moving: bool) -> void:
	var stride := _stride(vx)
	if moving:
		# The rig is drawn scaled, so convert the world speed into rig units:
		# then a planted paw slides back exactly as fast as the body moves on.
		var local_speed := vx / BODY_SCALE
		_phase = fmod(_phase + local_speed * _duty() / stride * delta, 1.0)
		_step_leg = -1
		_resume = move_toward(_resume, 1.0, delta / 0.15)
		for leg in 4:
			var g := _gait_foot(leg, stride)
			_feet[leg] = _feet[leg].lerp(g[0], 1.0 if _resume >= 1.0 else clampf(delta * 25.0, 0.0, 1.0))
			_lift[leg] = g[1]
		return
	_resume = 0.0
	# Stopped: finish the steps, one paw at a time (lifted paws first).
	if _step_leg < 0:
		var worst := 1.0
		for leg in 4:
			var off := _feet[leg].distance_to(_home(leg)) + (10.0 if _feet[leg].y < -0.5 else 0.0)
			if off > worst:
				worst = off
				_step_leg = leg
		if _step_leg >= 0:
			_step_t = 0.0
			_step_from = _feet[_step_leg]
	if _step_leg >= 0:
		_step_t = minf(_step_t + delta / STEP_TIME, 1.0)
		var e := smoothstep(0.0, 1.0, _step_t)
		var home := _home(_step_leg)
		var arc := sin(PI * _step_t) * (2.0 if absf(_step_from.x - home.x) > 1.5 else 0.6)
		_feet[_step_leg] = Vector2(lerpf(_step_from.x, home.x, e), lerpf(_step_from.y, home.y, e) - arc)
		_lift[_step_leg] = arc / 2.0
		if _step_t >= 1.0:
			_lift[_step_leg] = 0.0
			_step_leg = -1


## A quick body turn instead of an instant mirror: the silhouette narrows as
## it swings round, then widens facing the other way.
func _update_turn(delta: float) -> void:
	var want := float(_facing)
	if want != _turn_to:
		_turn_to = want
		_turn_t = 0.0
	if _turn_t < 1.0:
		_turn_t = minf(_turn_t + delta / TURN_TIME, 1.0)
		var c := cos(PI * smoothstep(0.0, 1.0, _turn_t)) * -_turn_to
		_shown_sign = (signf(c) if absf(c) > 0.0001 else _turn_to) * maxf(absf(c), 0.6)
	else:
		_shown_sign = _turn_to
	scale = Vector2(_shown_sign * BODY_SCALE, BODY_SCALE)


# ---- Body pose --------------------------------------------------------------

func _update_body() -> void:
	var m := _move * (1.0 - _hop)
	var bob := (0.35 + 0.45 * _gait) * cos(TAU * 2.0 * _phase) * m
	var breathe := sin(_time * 2.3) * 0.35 * (1.0 - m)
	var pitch := 0.012 * sin(TAU * _phase) * m
	_rot = pitch - 0.52 * _sit + 0.02 * _lie - 0.05 * _fear + 0.1 * _sniff
	_off = Vector2(0, bob - breathe) + Vector2(-1.5, 3.0) * _sit + Vector2(0, 15.5) * _lie + Vector2(0, 4.0) * _fear
	var nod := sin(TAU * 2.0 * _phase + 0.6) * m * (1.0 - 0.5 * _gait)
	var look := (sin(_time * 0.45) * 0.05 + sin(_time * 1.27) * 0.025) * (1.0 - m) * (1.0 - _sniff)
	_head_rot = 0.0 + 0.035 * nod + look + 1.1 * _sniff + 0.25 * _fear - 0.1 * _sit - 0.12 * _lie
	_head_off = Vector2(0, 0.6 * nod) + Vector2(3, 18) * _sniff + Vector2(1.5, 4.0) * _fear \
		+ Vector2(0, -1.0) * _sit + Vector2(2.5, 1.5) * _lie
	_head_off.y += sin(_time * 9.0) * 0.7 * _sniff


## Torso space -> rig space.
func _t(p: Vector2) -> Vector2:
	return SHOULDER + (p - SHOULDER).rotated(_rot) + _off


## Head space -> rig space.
func _h(p: Vector2) -> Vector2:
	return _t(HEAD_PIVOT) + _head_off + (p - HEAD_PIVOT).rotated(_rot + _head_rot)


# ---- Drawing ----------------------------------------------------------------

func _draw() -> void:
	if _feet.size() < 4:
		return
	var col := Palette.SILHOUETTE
	var feet := _posed_feet()
	_draw_leg(0, feet[0], col)
	_draw_leg(1, feet[1], col)
	_draw_tail(col)

	var torso := PackedVector2Array()
	for p in TORSO:
		torso.append(_t(p))
	_fill(torso, col)
	for base in BELLY_TUFTS:
		var b := _t(base)
		var down := Vector2(-1.6, 2.4).rotated(_rot)
		draw_colored_polygon(PackedVector2Array([b + Vector2(-1.8, 0), b + down, b + Vector2(1.8, 0)]), col)
	var chest := _t(Vector2(23.4, -25.5))
	draw_colored_polygon(PackedVector2Array([chest + Vector2(0, -2.5), chest + Vector2(2.2, 1.6).rotated(_rot), chest + Vector2(-1, 2)]), col)

	var neck := PackedVector2Array()
	for entry in NECK:
		var p: Vector2 = entry[0]
		neck.append(_t(p).lerp(_h(p), entry[1]))
	SilhouetteDraw.poly(self, Geometry2D.convex_hull(neck), col)

	var head := PackedVector2Array()
	for p in HEAD:
		head.append(_h(p))
	_fill(head, col)
	var pant := (0.08 + 0.05 * sin(_time * 7.0)) * (1.0 - _fear) * (1.0 - _sniff)
	var jaw := PackedVector2Array()
	for p in JAW:
		jaw.append(_h(JAW_HINGE + (p - JAW_HINGE).rotated(pant)))
	_fill(jaw, col, 1)
	# Soft ear: hangs by gravity, swings a little with the gait, pressed back when afraid.
	var ear_angle := 0.08 * _move + 0.06 * sin(TAU * 2.0 * _phase + 1.2) * _move + 0.5 * _fear - 0.75 * (_rot + _head_rot)
	var ear := PackedVector2Array()
	for p in EAR:
		ear.append(_h(EAR_PIVOT + (p - EAR_PIVOT).rotated(ear_angle)))
	_fill(ear, col, 2)

	_draw_leg(2, feet[2], col)
	_draw_leg(3, feet[3], col)


## Paw targets after pose blending (sitting / lying fold the legs, a leap tucks them).
func _posed_feet() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for leg in 4:
		var p := _feet[leg]
		var depth := Vector2(LEG_DEPTH[leg], 0)
		if LEG_IS_FRONT[leg]:
			p = p.lerp(FRONT_PAW + depth + Vector2(1.0, 0), _sit)
			p = p.lerp(Vector2(26.5, -1.6) + depth * 1.5, _lie)
			p = p.lerp(_home(leg) + Vector2(3, -9), _hop)
		else:
			p = p.lerp(Vector2(-7.5, -1.6) + depth, _sit)
			p = p.lerp(Vector2(-6.5, -1.6) + depth, _lie)
			p = p.lerp(_home(leg) + Vector2(-5, -5), _hop)
		out.append(p)
	return out


func _draw_leg(leg: int, paw: Vector2, col: Color) -> void:
	var lift: float = maxf(_lift[leg] * (1.0 - maxf(_sit, _lie)), _hop * 0.6)
	var depth := Vector2(LEG_DEPTH[leg], 0)
	if LEG_IS_FRONT[leg]:
		var shoulder := _t(SHOULDER + depth) + Vector2(0.3 * (paw.x - _home(leg).x), 0)
		# The wrist leads the paw; when the paw lifts it folds back under the wrist.
		var wrist_target := paw + Vector2(-2.0, -3.4).lerp(Vector2(1.6, -3.2), lift)
		var upper := ELBOW.distance_to(SHOULDER)
		var fore := WRIST.distance_to(ELBOW)
		var elbow := SilhouetteDraw.ik_joint(shoulder, wrist_target, upper, fore, 1.0)
		var wrist := elbow + (wrist_target - elbow).limit_length(fore)
		var paw_pos := wrist + (paw - wrist_target)
		SilhouetteDraw.limb(self, shoulder, elbow, 9.0, 6.8, col)
		SilhouetteDraw.limb(self, elbow, wrist, 6.6, 5.4, col)
		SilhouetteDraw.limb(self, wrist, paw_pos + Vector2(-0.6, -0.8), 5.2, 4.8, col)
		var forearm_delta := (wrist - elbow).angle() - (WRIST - ELBOW).angle()
		var feather := PackedVector2Array()
		for p in FEATHER:
			feather.append(elbow + (p - ELBOW).rotated(forearm_delta))
		_fill(feather, col, 2)
		_draw_paw(paw_pos, lift, col)
	else:
		var hip := _t(HIP + depth)
		var hock_target := paw + Vector2(-2.5, -4.9).lerp(Vector2(-4.2, -2.8), lift)
		var thigh := STIFLE.distance_to(HIP)
		var gaskin := HOCK.distance_to(STIFLE)
		var stifle := SilhouetteDraw.ik_joint(hip, hock_target, thigh, gaskin, -1.0)
		var hock := stifle + (hock_target - stifle).limit_length(gaskin)
		var paw_pos := hock + (paw - hock_target)
		var thigh_delta := (stifle - hip).angle() - (STIFLE - HIP).angle()
		var pants := PackedVector2Array()
		for p in PANTS:
			pants.append(hip + (p - HIP).rotated(thigh_delta))
		_fill(pants, col, 2)
		SilhouetteDraw.limb(self, hip, stifle, 12.0, 8.2, col)
		SilhouetteDraw.limb(self, stifle, hock, 7.2, 5.2, col)
		SilhouetteDraw.limb(self, hock, paw_pos + Vector2(-0.6, -0.8), 5.2, 4.8, col)
		_draw_paw(paw_pos, lift, col)


func _draw_paw(paw: Vector2, lift: float, col: Color) -> void:
	var pts := SilhouetteDraw.ellipse_points(paw + Vector2(1.0, 0.3), Vector2(3.4, 1.8), 0.55 * lift, 12)
	SilhouetteDraw.poly(self, pts, col)


func _draw_tail(col: Color) -> void:
	var m := _move * (1.0 - _hop)
	var sway := 0.11 * sin(TAU * _phase) * m + 0.06 * sin(_time * 2.1) * (1.0 - m)
	var tail_rot := _rot + sway - 0.7 * _fear + 0.95 * _sit + 0.5 * _lie + 0.1 * m
	var curl := 0.28 * (1.0 - _fear) - 0.4 * _fear
	var centre: Array[Vector2] = [_t(TAIL[0])]
	for k in range(1, TAIL.size()):
		var seg: Vector2 = TAIL[k] - TAIL[k - 1]
		var extra := curl * float(k - 1) / float(TAIL.size() - 2)
		var next := centre[k - 1] + seg.rotated(tail_rot + extra)
		next.y = minf(next.y, -0.8)
		centre.append(next)
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for k in centre.size():
		var a := centre[maxi(k - 1, 0)]
		var b := centre[mini(k + 1, centre.size() - 1)]
		var n := (b - a).normalized().orthogonal()
		var w: float = TAIL_WIDTH[k] * 0.5
		left.append(centre[k] + n * w)
		right.append(centre[k] - n * w)
	var outline := PackedVector2Array()
	outline.append_array(left)
	var dir := (centre[-1] - centre[-2]).normalized()
	outline.append(centre[-1] + dir * 2.0)
	right.reverse()
	outline.append_array(right)
	_fill(outline, col, 2)


## Fill an outline, smoothed; falls back to the raw outline (or its hull) if a
## pose ever makes the smoothed one impossible to triangulate.
func _fill(points: PackedVector2Array, col: Color, subdivisions: int = 3) -> void:
	var pts := _smooth(points, subdivisions) if subdivisions > 1 else points
	if Geometry2D.triangulate_polygon(pts).is_empty():
		pts = points
		if Geometry2D.triangulate_polygon(pts).is_empty():
			pts = Geometry2D.convex_hull(points)
	SilhouetteDraw.poly(self, pts, col)


## Closed Catmull-Rom smoothing so outlines read as soft fur, not facets.
static func _smooth(points: PackedVector2Array, subdivisions: int = 3) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := points.size()
	for i in n:
		var p0 := points[(i - 1 + n) % n]
		var p1 := points[i]
		var p2 := points[(i + 1) % n]
		var p3 := points[(i + 2) % n]
		for s in subdivisions:
			out.append(p1.cubic_interpolate(p2, p0, p3, float(s) / float(subdivisions)))
	return out
