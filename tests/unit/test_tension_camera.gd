extends GutTest
## TensionCamera.is_investigated: when the camera should push in on the hidden girl.

const State := CreatureBrain.State
const GIRL := Vector2(1000, 0)
const INVESTIGATE := 300.0
const CLOSE := 150.0


func _check(hidden: bool, creatures: Array) -> bool:
	return TensionCamera.is_investigated(hidden, GIRL, creatures, INVESTIGATE, CLOSE)


func _at(dx: float, state: int) -> Dictionary:
	return {"position": GIRL + Vector2(dx, 0), "state": state}


func test_sniffing_creature_near_her_hiding_place() -> void:
	assert_true(_check(true, [_at(60, State.SNIFF)]))


func test_searching_creature_near_her_hiding_place() -> void:
	assert_true(_check(true, [_at(-250, State.SEARCH)]))


func test_any_creature_passing_very_close_while_she_hides() -> void:
	assert_true(_check(true, [_at(120, State.PATROL)]))


func test_patrolling_creature_further_away_does_not_count() -> void:
	assert_false(_check(true, [_at(220, State.PATROL)]))


func test_investigating_too_far_away_does_not_count() -> void:
	assert_false(_check(true, [_at(400, State.SNIFF)]))


func test_never_while_she_is_visible() -> void:
	assert_false(_check(false, [_at(30, State.SNIFF)]))


func test_no_creatures() -> void:
	assert_false(_check(true, []))
