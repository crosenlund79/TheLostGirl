class_name Creature
extends Node2D
## A tall hunched creature roaming flat ground. CreatureBrain decides where it
## goes; this node feeds it the girl's position/hidden state, moves, and reports
## contact. Touching her is deadly unless she is hidden. Origin at its feet.
## Contact is a direct rectangle overlap (not a physics Area2D), so it can never
## fire on stale overlap data right after a respawn/reset teleport.

signal caught_player(player: Node2D)

## Patrol bounds relative to where the creature is placed.
@export var patrol_left := -220.0
@export var patrol_right := 220.0
@export_range(-1, 1, 2) var start_facing := -1
@export var patrol_speed := 55.0
@export var chase_speed := 165.0
@export var sight_range := 300.0
## Size of the deadly body area (centred on x, rising from the feet).
@export var hurt_size := Vector2(46, 112)

## The girl. Set by the level (or a test).
var target: Node2D
var brain := CreatureBrain.new()

var _home := Vector2.ZERO
var _caught := false

@onready var _rig: CreatureRig = $Rig


func _ready() -> void:
	add_to_group("creature")
	_home = global_position
	reset()


## Back to its starting post (used after the girl is caught).
func reset() -> void:
	brain.patrol_left = _home.x + patrol_left
	brain.patrol_right = _home.x + patrol_right
	brain.patrol_speed = patrol_speed
	brain.chase_speed = chase_speed
	brain.sight_range = sight_range
	brain.reset(_home.x, start_facing)
	global_position = _home
	_caught = false


func _physics_process(delta: float) -> void:
	var has_target := is_instance_valid(target)
	var target_x := 0.0
	var target_dy := 0.0
	var hidden := false
	if has_target:
		target_x = target.global_position.x
		target_dy = target.global_position.y - global_position.y
		hidden = target.has_method("is_hidden") and target.is_hidden()
	brain.tick(delta, has_target, target_x, target_dy, hidden)
	global_position.x = brain.x
	if has_target and not hidden and not _caught and target.has_method("get_body_rect") \
			and get_hurt_rect().intersects(target.get_body_rect()):
		_caught = true
		brain.notify_caught()
		caught_player.emit(target)
	_rig.set_state(brain.state, brain.facing, brain.velocity_x)


func get_hurt_rect() -> Rect2:
	return Rect2(global_position + Vector2(-hurt_size.x * 0.5, -hurt_size.y), hurt_size)
