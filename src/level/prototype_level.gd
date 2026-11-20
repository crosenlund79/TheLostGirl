extends Node2D
## Prototype level flow. Wires the girl, dog and creatures together, tracks
## checkpoints, handles being caught (fade -> respawn, creatures reset) and
## reaching the exit. All tuning lives on the individual nodes.

@export var fade_time := 0.6

var _respawn_point := Vector2.ZERO
var _busy := false
var _finished := false
var _hidden_tween: Tween
var _hidden_amount := 0.0

@onready var _girl: Girl = $Girl
@onready var _dog: Dog = $Dog
@onready var _camera: Camera2D = $Girl/Camera
@onready var _vignette: ColorRect = $Overlay/Vignette
@onready var _fade: ColorRect = $Overlay/Fade
@onready var _message: Label = $Overlay/Message


func _ready() -> void:
	_respawn_point = _girl.global_position
	_dog.set_target(_girl)
	for creature in get_creatures():
		creature.target = _girl
		creature.caught_player.connect(_on_caught)
	for checkpoint in $Checkpoints.get_children():
		checkpoint.body_entered.connect(_on_checkpoint_entered.bind(checkpoint))
	$Exit.body_entered.connect(_on_exit_entered)
	_girl.hidden_changed.connect(_on_hidden_changed)

	$Girl/Camera/Spores.color = Palette.SPORE
	(_vignette.material as ShaderMaterial).set_shader_parameter("tint", Palette.VIGNETTE)
	for hint in $Hints.get_children():
		hint.add_theme_color_override("font_color", Palette.HINT_TEXT)
	_message.add_theme_color_override("font_color", Palette.HINT_TEXT)
	_message.visible = false
	_fade.color = Color(Palette.SILHOUETTE, 1.0)
	create_tween().tween_property(_fade, "modulate:a", 0.0, 1.2).from(1.0)


func get_creatures() -> Array[Creature]:
	var result: Array[Creature] = []
	for node in get_tree().get_nodes_in_group("creature"):
		if is_ancestor_of(node):
			result.append(node)
	return result


func _unhandled_input(event: InputEvent) -> void:
	if _finished and event.is_action_pressed("jump"):
		get_tree().reload_current_scene()


func _on_checkpoint_entered(body: Node2D, checkpoint: Node2D) -> void:
	if body == _girl and not _busy:
		_respawn_point = checkpoint.global_position


func _on_caught(_player: Node2D) -> void:
	if _busy or _finished:
		return
	_busy = true
	_girl.controls_enabled = false
	var tween := create_tween()
	tween.tween_interval(0.35)
	tween.tween_property(_fade, "modulate:a", 1.0, fade_time)
	tween.tween_callback(_respawn)
	tween.tween_interval(0.3)
	tween.tween_property(_fade, "modulate:a", 0.0, fade_time)
	tween.tween_callback(func() -> void: _busy = false)


func _respawn() -> void:
	_girl.respawn(_respawn_point)
	_girl.controls_enabled = true
	for creature in get_creatures():
		creature.reset()
	_dog.snap_to_target()
	_camera.reset_smoothing()


func _on_exit_entered(body: Node2D) -> void:
	if body != _girl or _finished or _busy:
		return
	_finished = true
	_girl.controls_enabled = false
	_message.text = "She slipped out of the dark woods... for now.\n\nPress Jump to walk the woods again."
	_message.visible = true
	_message.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", 0.88, 1.6)
	tween.parallel().tween_property(_message, "modulate:a", 1.0, 2.0)


func _on_hidden_changed(is_hidden: bool) -> void:
	if _hidden_tween:
		_hidden_tween.kill()
	_hidden_tween = create_tween()
	_hidden_tween.tween_method(_set_hidden_amount, _hidden_amount, 1.0 if is_hidden else 0.0, 0.4)


func _set_hidden_amount(value: float) -> void:
	_hidden_amount = value
	(_vignette.material as ShaderMaterial).set_shader_parameter("hidden_amount", value)
