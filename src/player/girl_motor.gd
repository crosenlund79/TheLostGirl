class_name GirlMotor
extends RefCounted
## Pure movement rules for the girl: walk, crouch, jump (with coyote time,
## jump buffering and variable height). No Nodes or Input, so it is unit-testable.

var walk_speed := 150.0
var crouch_speed := 55.0
var ground_accel := 1100.0
var ground_decel := 1500.0
var air_accel := 750.0
var gravity := 1500.0
var jump_velocity := -540.0
## Upward speed is capped to jump_velocity * jump_cut once jump is released.
var jump_cut := 0.45
var max_fall_speed := 900.0
var coyote_time := 0.1
var jump_buffer_time := 0.12

var crouching := false
var facing := 1

var _coyote := 0.0
var _buffer := 0.0


func reset() -> void:
	crouching = false
	_coyote = 0.0
	_buffer = 0.0


## Returns the new velocity for one physics step.
func step(velocity: Vector2, delta: float, move_axis: float, jump_pressed: bool,
		jump_held: bool, crouch_held: bool, on_floor: bool) -> Vector2:
	move_axis = clampf(move_axis, -1.0, 1.0)
	crouching = crouch_held and on_floor
	if absf(move_axis) > 0.01:
		facing = 1 if move_axis > 0.0 else -1

	var max_speed := crouch_speed if crouching else walk_speed
	var target_x := move_axis * max_speed
	var rate := air_accel
	if on_floor:
		var speeding_up := absf(target_x) > absf(velocity.x) and signf(target_x) == signf(velocity.x)
		rate = ground_accel if (speeding_up or is_zero_approx(velocity.x)) else ground_decel
	velocity.x = move_toward(velocity.x, target_x, rate * delta)

	_coyote = coyote_time if on_floor else maxf(_coyote - delta, 0.0)
	_buffer = jump_buffer_time if jump_pressed else maxf(_buffer - delta, 0.0)

	if not on_floor:
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)

	if _buffer > 0.0 and _coyote > 0.0 and not crouching:
		velocity.y = jump_velocity
		_buffer = 0.0
		_coyote = 0.0
	elif not jump_held and velocity.y < jump_velocity * jump_cut:
		velocity.y = jump_velocity * jump_cut

	return velocity
