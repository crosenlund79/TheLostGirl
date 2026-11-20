extends GutTest
## Contract between Girl and Dog: the dog trails behind her at its follow
## distance and tucks in close when she crouches.

const GirlScene := preload("res://src/player/girl.tscn")
const DogScene := preload("res://src/companion/dog.tscn")

var girl: Girl
var dog: Dog


func before_each() -> void:
	var ground := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4000, 100)
	shape.shape = rect
	shape.position = Vector2(0, 50)
	ground.add_child(shape)
	add_child_autofree(ground)

	girl = GirlScene.instantiate()
	girl.position = Vector2(0, -1)
	add_child_autofree(girl)
	dog = DogScene.instantiate()
	add_child_autofree(dog)
	dog.set_target(girl)


func after_each() -> void:
	Input.action_release("move_right")
	Input.action_release("crouch")


func test_dog_starts_behind_her() -> void:
	assert_lt(dog.global_position.x, girl.global_position.x)


func test_dog_trails_behind_while_she_walks() -> void:
	Input.action_press("move_right")
	await wait_seconds(1.5)
	Input.action_release("move_right")
	await wait_seconds(0.8)
	assert_gt(girl.global_position.x, 150.0, "she walked")
	assert_lt(dog.global_position.x, girl.global_position.x, "dog stays behind her")
	assert_almost_eq(girl.global_position.x - dog.global_position.x, dog.follow_distance, 8.0)


func test_dog_tucks_in_when_she_crouches() -> void:
	Input.action_press("move_right")
	await wait_seconds(1.0)
	Input.action_release("move_right")
	Input.action_press("crouch")
	await wait_seconds(0.8)
	assert_almost_eq(girl.global_position.x - dog.global_position.x, dog.crouch_follow_distance, 8.0)
