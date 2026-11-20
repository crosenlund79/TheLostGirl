class_name Dog
extends Node2D
## The girl's pet dog. Trails her along the path she walked, keeps a little
## behind her (closer when she crouches, so it hides with her), and never
## collides with anything, so it can't block gameplay. Enemies ignore it.

@export var follow_distance := 46.0
@export var crouch_follow_distance := 14.0
@export var max_speed := 240.0
## Teleport instead of running if the gap ever gets this large (e.g. respawn).
@export var snap_distance := 420.0
## A creature this close makes the dog cower.
@export var fear_radius := 380.0

var target: Node2D
var trail := DogTrail.new()
var facing := 1

@onready var _rig: DogRig = $Rig


func set_target(new_target: Node2D) -> void:
	target = new_target
	snap_to_target()


## Place the dog just behind the girl and restart its trail.
func snap_to_target() -> void:
	if not is_instance_valid(target):
		return
	var girl_facing := 1
	if target.has_method("get_facing"):
		girl_facing = target.get_facing()
	var behind := target.global_position - Vector2(follow_distance * girl_facing, 0)
	trail.reset(target.global_position, behind)
	global_position = behind
	facing = girl_facing


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target) or delta <= 0.0:
		return
	trail.record(target.global_position)
	var crouched: bool = target.has_method("is_crouching") and target.is_crouching()
	var goal := trail.point_behind(crouch_follow_distance if crouched else follow_distance)
	var previous := global_position
	if global_position.distance_to(goal) > snap_distance:
		global_position = goal
	else:
		global_position = global_position.move_toward(goal, max_speed * delta)
	var velocity := (global_position - previous) / delta
	if absf(velocity.x) > 8.0:
		facing = 1 if velocity.x > 0.0 else -1
	elif absf(target.global_position.x - global_position.x) > 6.0:
		facing = 1 if target.global_position.x > global_position.x else -1
	_rig.set_state(velocity, facing, crouched, _creature_nearby())


func _creature_nearby() -> bool:
	for creature in get_tree().get_nodes_in_group("creature"):
		if creature.global_position.distance_to(global_position) < fear_radius:
			return true
	return false
