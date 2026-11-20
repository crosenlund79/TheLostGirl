extends GutTest
## GirlMotor: walk / crouch / jump rules (pure logic, no scene).

const DT := 1.0 / 60.0

var motor: GirlMotor


func before_each() -> void:
	motor = GirlMotor.new()


func _run(frames: int, v: Vector2, axis: float, crouch := false, on_floor := true) -> Vector2:
	for i in frames:
		v = motor.step(v, DT, axis, false, false, crouch, on_floor)
	return v


func test_walk_accelerates_to_walk_speed_and_caps() -> void:
	var v := _run(60, Vector2.ZERO, 1.0)
	assert_almost_eq(v.x, motor.walk_speed, 0.01)


func test_releasing_input_on_floor_stops() -> void:
	var v := _run(60, Vector2(motor.walk_speed, 0), 0.0)
	assert_almost_eq(v.x, 0.0, 0.01)


func test_crouch_on_floor_slows_to_crouch_speed() -> void:
	var v := _run(60, Vector2(motor.walk_speed, 0), 1.0, true)
	assert_true(motor.crouching)
	assert_almost_eq(v.x, motor.crouch_speed, 0.01)


func test_crouch_is_ignored_in_the_air() -> void:
	motor.step(Vector2.ZERO, DT, 0.0, false, false, true, false)
	assert_false(motor.crouching)


func test_jump_from_floor() -> void:
	var v := motor.step(Vector2.ZERO, DT, 0.0, true, true, false, true)
	assert_eq(v.y, motor.jump_velocity)


func test_cannot_jump_while_crouching() -> void:
	var v := motor.step(Vector2.ZERO, DT, 0.0, true, true, true, true)
	assert_eq(v.y, 0.0)


func test_coyote_time_allows_a_late_jump() -> void:
	motor.step(Vector2.ZERO, DT, 0.0, false, false, false, true)
	var v := motor.step(Vector2.ZERO, DT, 0.0, false, false, false, false)
	v = motor.step(v, DT, 0.0, true, true, false, false)
	assert_eq(v.y, motor.jump_velocity)


func test_no_jump_once_coyote_time_has_expired() -> void:
	motor.step(Vector2.ZERO, DT, 0.0, false, false, false, true)
	var v := Vector2.ZERO
	for i in 12:
		v = motor.step(v, DT, 0.0, false, false, false, false)
	v = motor.step(v, DT, 0.0, true, true, false, false)
	assert_gt(v.y, 0.0, "still falling: no mid-air jump")


func test_buffered_jump_fires_on_landing() -> void:
	var v := motor.step(Vector2(0, 300), DT, 0.0, true, true, false, false)
	assert_gt(v.y, 0.0, "no jump while airborne")
	v = motor.step(Vector2.ZERO, DT, 0.0, false, true, false, true)
	assert_eq(v.y, motor.jump_velocity)


func test_releasing_jump_early_cuts_the_rise() -> void:
	var v := motor.step(Vector2.ZERO, DT, 0.0, true, true, false, true)
	v = motor.step(v, DT, 0.0, false, false, false, false)
	assert_almost_eq(v.y, motor.jump_velocity * motor.jump_cut, 0.01)


func test_gravity_is_capped_at_max_fall_speed() -> void:
	var v := _run(120, Vector2.ZERO, 0.0, false, false)
	assert_eq(v.y, motor.max_fall_speed)


func test_facing_follows_input_and_persists() -> void:
	motor.step(Vector2.ZERO, DT, -1.0, false, false, false, true)
	assert_eq(motor.facing, -1)
	motor.step(Vector2.ZERO, DT, 0.0, false, false, false, true)
	assert_eq(motor.facing, -1)
