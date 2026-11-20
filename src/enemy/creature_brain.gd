class_name CreatureBrain
extends RefCounted
## Pure patrol / sense / chase rules for a roaming creature (no Nodes, unit-testable).
## Creatures walk flat ground along one axis between two patrol points.
##
## PATROL -> (sees her) ALERT -> CHASE -> (loses her) SEARCH -> PATROL
## PATROL -> (hidden girl right under its nose) SNIFF -> PATROL   (she stays safe)
## PATROL -> (patrol end) LOOK -> turn around -> PATROL

enum State { PATROL, LOOK, SNIFF, ALERT, CHASE, SEARCH, CAUGHT }

var patrol_left := 0.0
var patrol_right := 300.0
var patrol_speed := 55.0
var chase_speed := 165.0
var sight_range := 300.0
var sight_height := 90.0
## Notices a visible girl this close even behind it.
var rear_sense := 30.0
## How far beyond its patrol range it will chase.
var leash := 150.0
var look_time := 1.3
var sniff_time := 1.6
var sniff_range := 70.0
var alert_time := 0.45
var search_time := 1.8
## Period of the lurching speed surge while patrolling.
var stride_period := 1.6

var state := State.PATROL
var facing := 1
var x := 0.0
var velocity_x := 0.0

var _timer := 0.0
var _clock := 0.0
var _sniffed := false
var _last_seen_x := 0.0


func reset(start_x: float, start_facing: int = 1) -> void:
	x = start_x
	facing = 1 if start_facing >= 0 else -1
	state = State.PATROL
	velocity_x = 0.0
	_timer = 0.0
	_clock = 0.0
	_sniffed = false


## Sight check. dx/dy are target minus creature. A hidden girl is never seen.
func can_see(dx: float, dy: float, target_hidden: bool) -> bool:
	if target_hidden or absf(dy) > sight_height:
		return false
	var ahead := dx * float(facing)
	if ahead >= 0.0:
		return ahead <= sight_range
	return -ahead <= rear_sense


func notify_caught() -> void:
	state = State.CAUGHT
	velocity_x = 0.0


func tick(delta: float, has_target: bool, target_x: float, target_dy: float, target_hidden: bool) -> void:
	_clock += delta
	var dx := target_x - x
	var sees := has_target and can_see(dx, target_dy, target_hidden)
	var start_x := x
	match state:
		State.PATROL:
			if sees:
				_spot(target_x)
			elif has_target and target_hidden and not _sniffed and absf(dx) < sniff_range and absf(target_dy) < sight_height:
				_sniffed = true
				_enter(State.SNIFF, sniff_time)
			else:
				_patrol_step(delta)
		State.LOOK, State.SNIFF:
			if sees:
				_spot(target_x)
			else:
				_timer -= delta
				if _timer <= 0.0:
					if state == State.LOOK:
						facing = -facing
						_sniffed = false
					state = State.PATROL
		State.ALERT:
			if has_target and target_hidden:
				_enter(State.SEARCH, search_time)
			else:
				_timer -= delta
				if _timer <= 0.0:
					state = State.CHASE
		State.CHASE:
			var still_visible := has_target and not target_hidden and absf(target_dy) <= sight_height \
				and absf(dx) <= sight_range * 1.5
			if still_visible:
				_last_seen_x = target_x
				_face(dx)
				var goal := clampf(target_x, patrol_left - leash, patrol_right + leash)
				x = move_toward(x, goal, chase_speed * delta)
			else:
				_enter(State.SEARCH, search_time)
		State.SEARCH:
			if sees:
				state = State.CHASE
				_last_seen_x = target_x
			else:
				var goal := clampf(_last_seen_x, patrol_left - leash, patrol_right + leash)
				if absf(goal - x) > 1.0:
					_face(goal - x)
				x = move_toward(x, goal, patrol_speed * delta)
				_timer -= delta
				if _timer <= 0.0:
					state = State.PATROL
					_sniffed = false
		State.CAUGHT:
			pass
	velocity_x = (x - start_x) / delta if delta > 0.0 else 0.0


func _patrol_step(delta: float) -> void:
	if x < patrol_left:
		facing = 1
	elif x > patrol_right:
		facing = -1
	var goal := patrol_right if facing > 0 else patrol_left
	var surge := pow(sin(_clock * PI / stride_period), 2.0)
	x = move_toward(x, goal, patrol_speed * (0.55 + 0.45 * surge) * delta)
	if is_equal_approx(x, goal):
		_enter(State.LOOK, look_time)


func _spot(target_x: float) -> void:
	_last_seen_x = target_x
	_face(target_x - x)
	_enter(State.ALERT, alert_time)


func _enter(new_state: State, duration: float) -> void:
	state = new_state
	_timer = duration


func _face(dx: float) -> void:
	if absf(dx) > 0.5:
		facing = 1 if dx > 0.0 else -1
