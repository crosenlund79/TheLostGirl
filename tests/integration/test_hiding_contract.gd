extends GutTest
## Contract between Girl (crouch + hidden state), HideCover (zone) and Creature
## (sight + contact): crouched fully under cover she is ignored even when it
## walks right over her; standing, or crouching outside cover, she is caught.

const GirlScene := preload("res://src/player/girl.tscn")
const CreatureScene := preload("res://src/enemy/creature.tscn")

var girl: Girl
var creature: Creature


func before_each() -> void:
	var ground := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4000, 100)
	shape.shape = rect
	shape.position = Vector2(0, 50)
	ground.add_child(shape)
	add_child_autofree(ground)

	var cover := HideCover.new()
	cover.width = 130.0
	add_child_autofree(cover)

	girl = GirlScene.instantiate()
	girl.position = Vector2(0, -1)
	add_child_autofree(girl)

	creature = CreatureScene.instantiate()
	creature.position = Vector2(-250, 0)
	creature.patrol_left = 0.0
	creature.patrol_right = 600.0
	creature.start_facing = 1
	creature.patrol_speed = 220.0
	add_child_autofree(creature)
	creature.target = girl
	watch_signals(creature)


func after_each() -> void:
	Input.action_release("crouch")


func _caught() -> bool:
	return get_signal_emit_count(creature, "caught_player") > 0


func test_crouched_under_cover_the_creature_walks_past() -> void:
	Input.action_press("crouch")
	await wait_physics_frames(5)
	assert_true(girl.is_hidden(), "crouched inside the bush hides her")
	await wait_until(func() -> bool: return creature.global_position.x > girl.global_position.x + 120.0, 8.0)
	assert_gt(creature.global_position.x, girl.global_position.x + 120.0, "it walked right past her")
	assert_signal_not_emitted(creature, "caught_player")


func test_standing_in_the_same_spot_gets_caught() -> void:
	await wait_physics_frames(5)
	assert_false(girl.is_hidden())
	await wait_until(_caught, 8.0)
	assert_signal_emitted(creature, "caught_player")


func test_crouching_outside_cover_gets_caught() -> void:
	girl.position = Vector2(300, -1)
	Input.action_press("crouch")
	await wait_physics_frames(5)
	assert_true(girl.is_crouching())
	assert_false(girl.is_hidden(), "crouching alone does not hide her")
	await wait_until(_caught, 8.0)
	assert_signal_emitted(creature, "caught_player")
