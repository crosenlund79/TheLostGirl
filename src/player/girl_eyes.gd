class_name GirlEyes
extends Node2D
## Two faint eyes that fade in while the girl is hidden. This node sits above
## the cover (higher z_index), so the player can see where she is peeking from
## while her body stays swallowed by the bush. Child of GirlRig (shares its flip).

var _head := Vector2.ZERO
var _amount := 0.0
var _time := 0.0


func update_eyes(head: Vector2, hidden: bool, delta: float) -> void:
	_head = head
	_time += delta
	var target := 1.0 if hidden else 0.0
	var was := _amount
	_amount = move_toward(_amount, target, delta * 2.5)
	if _amount > 0.0 or was > 0.0:
		queue_redraw()


func _draw() -> void:
	if _amount <= 0.0:
		return
	# Slow blink every few seconds.
	var blink := 0.15 if fmod(_time, 3.7) < 0.12 else 1.0
	var col := Color(Palette.GIRL_EYE, Palette.GIRL_EYE.a * _amount)
	for offset in [Vector2(3.0, -0.5), Vector2(7.0, -0.8)]:
		draw_set_transform(_head + offset, 0.0, Vector2(1.0, blink))
		draw_circle(Vector2.ZERO, 1.25, col, true, -1.0, true)
	draw_set_transform(Vector2.ZERO)
