class_name Girl
extends CharacterBody2D
## Player body: reads input, applies GirlMotor, keeps the collision shape in sync
## with crouching, and decides whether she is hidden (crouched fully inside cover).
## Origin is at her feet.

signal hidden_changed(is_hidden: bool)

const STAND_SIZE := Vector2(16, 58)
const CROUCH_SIZE := Vector2(18, 36)
## Core of the crouched silhouette (feet origin) that must sit fully inside cover.
const HIDE_RECT := Rect2(-12, -40, 24, 40)
## Rough body silhouettes (feet origin) used for creature contact and rustling.
const BODY_RECT := Rect2(-12, -69, 24, 69)
const CROUCH_BODY_RECT := Rect2(-13, -40, 26, 40)

@export var controls_enabled := true

var motor := GirlMotor.new()
var _hidden := false
var _shape_rect: RectangleShape2D

@onready var _shape: CollisionShape2D = $Shape
@onready var _rig: GirlRig = $Rig


func _ready() -> void:
	add_to_group("player")
	_shape_rect = RectangleShape2D.new()
	_shape.shape = _shape_rect
	_apply_shape()


func _physics_process(delta: float) -> void:
	var axis := 0.0
	var jump_pressed := false
	var jump_held := false
	var crouch_held := false
	if controls_enabled:
		axis = Input.get_axis("move_left", "move_right")
		jump_pressed = Input.is_action_just_pressed("jump")
		jump_held = Input.is_action_pressed("jump")
		crouch_held = Input.is_action_pressed("crouch")
	velocity = motor.step(velocity, delta, axis, jump_pressed, jump_held, crouch_held, is_on_floor())
	_apply_shape()
	move_and_slide()
	_update_hidden()
	_rig.set_state(velocity, is_on_floor(), motor.crouching, motor.facing, _hidden)


func is_crouching() -> bool:
	return motor.crouching


func get_facing() -> int:
	return motor.facing


func is_hidden() -> bool:
	return _hidden


func get_hide_rect() -> Rect2:
	return Rect2(global_position + HIDE_RECT.position, HIDE_RECT.size)


func get_body_rect() -> Rect2:
	var rect := CROUCH_BODY_RECT if motor.crouching else BODY_RECT
	return Rect2(global_position + rect.position, rect.size)


## Teleport (used after being caught). Clears motion and secondary animation.
func respawn(at: Vector2) -> void:
	global_position = at
	velocity = Vector2.ZERO
	motor.reset()
	_apply_shape()
	_update_hidden()
	_rig.reset_secondary_motion()


func _apply_shape() -> void:
	var size := CROUCH_SIZE if motor.crouching else STAND_SIZE
	if _shape_rect.size != size:
		_shape_rect.size = size
		_shape.position = Vector2(0, -size.y * 0.5)


func _update_hidden() -> void:
	var covers: Array[Rect2] = []
	for cover in get_tree().get_nodes_in_group("hide_cover"):
		covers.append(cover.get_cover_rect())
	var now_hidden := HidingRules.is_hidden(motor.crouching, get_hide_rect(), covers)
	if now_hidden != _hidden:
		_hidden = now_hidden
		hidden_changed.emit(_hidden)
