class_name TensionCamera
extends Camera2D
## Side-scrolling follow camera (child of the girl). Sits a little closer than
## 1:1 so she reads clearly, glances slightly ahead while she travels, and eases
## in a touch further when a creature investigates near her while she is hidden,
## making the hiding moment more intimate. Her feet keep the same screen height
## while it zooms, so the push-in is towards her, not the sky. Presentation only.

const State := CreatureBrain.State

## Normal framing (1.0 = one world pixel per screen pixel).
@export var base_zoom := 1.35
## Extra closeness while a creature investigates her hiding place (0.14 = 14 % closer).
@export var tension_zoom := 0.14
## How far below the screen centre her feet sit, in screen pixels at any zoom.
@export var feet_below_center := 140.0
## How far the view leans ahead in the direction she faces (world px).
@export var look_ahead := 48.0
## A sniffing or searching creature this close (world px) counts as investigating her.
@export var investigate_radius := 300.0
## Any creature this close counts, while she is hidden.
@export var close_radius := 150.0
## Seconds to ease fully in and back out.
@export var zoom_in_time := 1.4
@export var zoom_out_time := 2.2

var girl: Node2D
var creatures: Array = []
## 0 = normal framing, 1 = fully pushed in (smoothed).
var tension := 0.0

var _look := 0.0


## Called by the level: whose hiding place to watch, and which creatures can investigate it.
func watch(new_girl: Node2D, new_creatures: Array) -> void:
	girl = new_girl
	creatures = new_creatures
	snap()


## Jump straight to normal framing (after a respawn).
func snap() -> void:
	tension = 0.0
	_look = _facing() * look_ahead
	_apply()
	reset_smoothing()


## True when she is hidden and a creature is investigating close by: sniffing or
## searching within investigate_radius, or simply passing within close_radius.
## creature_info: [{position: Vector2, state: CreatureBrain.State}, ...]
static func is_investigated(hidden: bool, girl_position: Vector2, creature_info: Array,
		investigate_radius: float, close_radius: float) -> bool:
	if not hidden:
		return false
	for info in creature_info:
		var distance: float = girl_position.distance_to(info.position)
		var searching: bool = info.state == State.SNIFF or info.state == State.SEARCH
		if (searching and distance <= investigate_radius) or distance <= close_radius:
			return true
	return false


func _ready() -> void:
	_apply()


func _process(delta: float) -> void:
	var target := 1.0 if _investigated() else 0.0
	var duration := zoom_in_time if target > tension else zoom_out_time
	tension = move_toward(tension, target, delta / maxf(duration, 0.01))
	_look = move_toward(_look, _facing() * look_ahead * (1.0 - tension), delta * look_ahead * 1.5)
	_apply()


func _apply() -> void:
	var z := base_zoom * (1.0 + tension_zoom * smoothstep(0.0, 1.0, tension))
	zoom = Vector2(z, z)
	offset = Vector2(_look, -feet_below_center / z)


func _investigated() -> bool:
	if not is_instance_valid(girl) or not girl.has_method("is_hidden"):
		return false
	var info := []
	for creature in creatures:
		if is_instance_valid(creature):
			info.append({"position": creature.global_position, "state": creature.brain.state})
	return is_investigated(girl.is_hidden(), girl.global_position, info, investigate_radius, close_radius)


func _facing() -> float:
	if is_instance_valid(girl) and girl.has_method("get_facing"):
		return float(girl.get_facing())
	return 1.0
