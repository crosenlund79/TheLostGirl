extends GutTest
## CreatureBrain: patrol, sight, chase, losing her when she hides, leash.

const DT := 1.0 / 60.0
const State := CreatureBrain.State

var brain: CreatureBrain


func before_each() -> void:
	brain = CreatureBrain.new()
	brain.patrol_left = 0.0
	brain.patrol_right = 200.0
	brain.reset(100.0, 1)


func _tick(seconds: float, has_target: bool, target_x: float, hidden: bool, target_dy := 0.0) -> void:
	for i in int(round(seconds / DT)):
		brain.tick(DT, has_target, target_x, target_dy, hidden)


func test_sees_a_visible_girl_in_front_within_range() -> void:
	assert_true(brain.can_see(150.0, 0.0, false))


func test_never_sees_a_hidden_girl() -> void:
	assert_false(brain.can_see(20.0, 0.0, true))


func test_cannot_see_beyond_range_or_height() -> void:
	assert_false(brain.can_see(brain.sight_range + 1.0, 0.0, false))
	assert_false(brain.can_see(50.0, brain.sight_height + 1.0, false))


func test_only_senses_very_close_behind() -> void:
	assert_true(brain.can_see(-20.0, 0.0, false))
	assert_false(brain.can_see(-80.0, 0.0, false))


func test_patrol_turns_around_at_the_end() -> void:
	var reached := false
	for i in 600:
		brain.tick(DT, false, 0.0, 0.0, false)
		if brain.state == State.LOOK:
			reached = true
			break
	assert_true(reached, "reached the patrol end")
	assert_almost_eq(brain.x, brain.patrol_right, 0.01)
	_tick(brain.look_time + 0.1, false, 0.0, false)
	assert_eq(brain.facing, -1)
	assert_eq(brain.state, State.PATROL)
	_tick(1.0, false, 0.0, false)
	assert_lt(brain.x, brain.patrol_right)


func test_spots_a_visible_girl_then_chases_her() -> void:
	_tick(DT, true, 250.0, false)
	assert_eq(brain.state, State.ALERT)
	_tick(brain.alert_time + 0.05, true, 250.0, false)
	assert_eq(brain.state, State.CHASE)
	var before := brain.x
	_tick(0.5, true, 300.0, false)
	assert_gt(brain.x, before)


func test_walks_right_past_a_hidden_girl() -> void:
	var passed := false
	var noticed := false
	for i in 400:
		brain.tick(DT, true, 150.0, 0.0, true)
		if brain.state == State.ALERT or brain.state == State.CHASE:
			noticed = true
		if brain.x > 170.0:
			passed = true
	assert_false(noticed, "never alerted by a hidden girl")
	assert_true(passed, "kept patrolling past her")


func test_sniffs_only_once_per_pass_near_a_hidden_girl() -> void:
	var sniffs := 0
	var was_sniffing := false
	for i in 300:
		brain.tick(DT, true, 150.0, 0.0, true)
		var sniffing := brain.state == State.SNIFF
		if sniffing and not was_sniffing:
			sniffs += 1
		was_sniffing = sniffing
		if brain.state == State.LOOK:
			break
	assert_eq(sniffs, 1)


func test_hiding_during_a_chase_loses_her_then_resumes_patrol() -> void:
	_tick(DT, true, 250.0, false)
	_tick(brain.alert_time + 0.05, true, 250.0, false)
	assert_eq(brain.state, State.CHASE)
	_tick(DT, true, 250.0, true)
	assert_eq(brain.state, State.SEARCH)
	_tick(brain.search_time + 0.1, true, 250.0, true)
	# Back on patrol (it may first sniff where she vanished), never re-acquiring her.
	assert_has([State.PATROL, State.SNIFF], brain.state)
	var reacquired := false
	for i in 300:
		brain.tick(DT, true, 250.0, 0.0, true)
		reacquired = reacquired or brain.state == State.ALERT or brain.state == State.CHASE
	assert_false(reacquired)


func test_hiding_during_the_alert_cancels_the_chase() -> void:
	_tick(DT, true, 250.0, false)
	assert_eq(brain.state, State.ALERT)
	_tick(DT, true, 250.0, true)
	assert_eq(brain.state, State.SEARCH)


func test_chase_stops_at_the_leash() -> void:
	brain.leash = 50.0
	_tick(DT, true, 300.0, false)
	_tick(brain.alert_time + 0.05, true, 300.0, false)
	_tick(5.0, true, 600.0, false)
	assert_lte(brain.x, brain.patrol_right + brain.leash + 0.01)


func test_caught_freezes_until_reset() -> void:
	brain.notify_caught()
	var x := brain.x
	_tick(1.0, true, brain.x + 10.0, false)
	assert_eq(brain.state, State.CAUGHT)
	assert_eq(brain.x, x)
	brain.reset(50.0, -1)
	assert_eq(brain.state, State.PATROL)
	assert_eq(brain.x, 50.0)
	assert_eq(brain.facing, -1)
