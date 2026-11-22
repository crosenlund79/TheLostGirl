class_name Dog
extends Node2D
## The girl's pet dog. Walks along the exact path she took (so it hops where she
## jumped), keeps a little behind her, lies down close behind her when she
## crouches, and never collides with anything, so it can't block gameplay.
## It speeds up and slows down smoothly like an animal instead of snapping to a
## point, never walks backwards, and if she doubles back past it, it waits and
## then follows her the other way. Enemies ignore it.

@export var follow_distance := 60.0
@export var crouch_follow_distance := 50.0
@export var max_speed := 240.0
## How quickly it gets up to speed and slows down (px/s²).
@export var acceleration := 520.0
## How eagerly it closes the gap (1/s); it lags a little further while walking.
@export var arrive_gain := 5.0
## Teleport instead of running if the gap ever gets this large (e.g. respawn).
@export var snap_distance := 420.0
## A creature this close makes the dog cower.
@export var fear_radius := 380.0

var target: Node2D
var trail := DogTrail.new()
var facing := 1
var velocity := Vector2.ZERO

## How far behind her the dog is, measured along her path.
var _behind := 0.0
## The dog's own speed along that path (px/s).
var _path_speed := 0.0
## 1 = follows her path exactly (hops her jump arcs), 0 = walks on the ground below it.
var _on_path := 1.0

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
	_behind = follow_distance
	_path_speed = 0.0
	_on_path = 1.0
	velocity = Vector2.ZERO
	global_position = behind
	facing = girl_facing
	if is_node_ready():
		_rig.reset_pose(facing)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target) or delta <= 0.0:
		return
	_behind += trail.record(target.global_position)
	var crouched: bool = target.has_method("is_crouching") and target.is_crouching()
	var wanted := crouch_follow_distance if crouched else follow_distance

	# She doubled back past the dog: restart the path from where it stands, so
	# it waits for her instead of retracing her steps to the turning point.
	var straight := global_position.distance_to(target.global_position)
	if straight < follow_distance * 0.8 and _behind > straight * 1.5 + 8.0:
		trail.reset(target.global_position, global_position)
		_behind = straight

	if _behind - wanted > snap_distance:
		snap_to_target()
		return

	var desired := clampf((_behind - wanted) * arrive_gain, 0.0, max_speed)
	_path_speed = move_toward(_path_speed, desired, acceleration * delta)
	var previous := global_position
	_behind = clampf(_behind - _path_speed * delta, 0.0, trail.length())
	var spot := trail.point_behind(_behind)
	# Moving briskly it hops along her jump arcs; slowing down or stopping on one,
	# it settles onto the ground below instead of hanging in mid-air.
	_on_path = move_toward(_on_path, 1.0 if _path_speed > 80.0 else 0.0, delta * 5.0)
	var ground := _ground_below(spot)
	var y := lerpf(ground, spot.y, _on_path)
	spot.y = move_toward(previous.y, y, 420.0 * delta) if _on_path < 1.0 else y
	global_position = spot
	velocity = (global_position - previous) / delta

	if absf(velocity.x) > 15.0:
		facing = 1 if velocity.x > 0.0 else -1
	elif absf(target.global_position.x - global_position.x) > 14.0:
		facing = 1 if target.global_position.x > global_position.x else -1
	_rig.set_state(velocity, facing, crouched, _creature_nearby())


## Height of the walkable ground under a point (or the point itself if none).
func _ground_below(point: Vector2) -> float:
	var query := PhysicsRayQueryParameters2D.create(point + Vector2(0, -6), point + Vector2(0, 260), 1)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return hit.position.y if not hit.is_empty() else point.y


func _creature_nearby() -> bool:
	for creature in get_tree().get_nodes_in_group("creature"):
		if creature.global_position.distance_to(global_position) < fear_radius:
			return true
	return false
