extends GutTest
## HidingRules: hidden only while crouched AND fully inside a cover rectangle.

const COVER := Rect2(0, -42, 100, 50)
const CROUCHED_INSIDE := Rect2(40, -40, 24, 40)


func _covers(list: Array) -> Array[Rect2]:
	var typed: Array[Rect2] = []
	for r in list:
		typed.append(r)
	return typed


func test_crouched_fully_inside_cover_is_hidden() -> void:
	assert_true(HidingRules.is_hidden(true, CROUCHED_INSIDE, _covers([COVER])))


func test_standing_inside_cover_is_not_hidden() -> void:
	assert_false(HidingRules.is_hidden(false, CROUCHED_INSIDE, _covers([COVER])))


func test_crouched_but_poking_out_sideways_is_not_hidden() -> void:
	assert_false(HidingRules.is_hidden(true, Rect2(90, -40, 24, 40), _covers([COVER])))


func test_crouched_but_poking_out_the_top_is_not_hidden() -> void:
	assert_false(HidingRules.is_hidden(true, Rect2(40, -50, 24, 50), _covers([COVER])))


func test_any_one_of_several_covers_is_enough() -> void:
	assert_true(HidingRules.is_hidden(true, CROUCHED_INSIDE, _covers([Rect2(500, -42, 100, 50), COVER])))


func test_no_cover_means_not_hidden() -> void:
	assert_false(HidingRules.is_hidden(true, CROUCHED_INSIDE, _covers([])))
