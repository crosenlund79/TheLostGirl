extends GutTest
## The prototype level wires its parts together and handles being caught:
## fade -> girl back at the respawn point -> creatures back on patrol.

const LevelScene := preload("res://src/level/prototype_level.tscn")

var level: Node2D
var girl: Girl
var post_x := 0.0


func before_each() -> void:
	level = LevelScene.instantiate()
	add_child_autofree(level)
	girl = level.get_node("Girl")
	post_x = level.get_creatures()[0].global_position.x


func test_level_wires_dog_creatures_and_cover() -> void:
	await wait_physics_frames(2)
	assert_eq(level.get_node("Dog").target, girl)
	assert_eq(level.get_node("ForestAudio").target, girl, "disturbances happen around the girl")
	var creatures: Array[Creature] = level.get_creatures()
	assert_eq(creatures.size(), 3)
	for creature in creatures:
		assert_eq(creature.target, girl)
	assert_gte(get_tree().get_nodes_in_group("hide_cover").size(), 4)


func test_being_caught_respawns_her_and_resets_creatures() -> void:
	await wait_physics_frames(2)
	var start := girl.global_position
	var creature: Creature = level.get_creatures()[0]
	girl.global_position = Vector2(creature.global_position.x + 30.0, start.y)
	creature.brain.notify_caught()
	creature.caught_player.emit(girl)
	assert_false(girl.controls_enabled, "controls frozen during the fade")
	var respawned := func() -> bool: return girl.global_position.distance_to(start) < 2.0
	assert_true(await wait_until(respawned, level.fade_time * 2.0 + 1.0), "she is back at the respawn point")
	assert_almost_eq(creature.global_position.x, post_x, 3.0, "creature is back at its post")
	assert_eq(creature.brain.state, CreatureBrain.State.PATROL)
	assert_true(girl.controls_enabled)
