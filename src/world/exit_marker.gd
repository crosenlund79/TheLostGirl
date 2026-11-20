@tool
class_name ExitMarker
extends Node2D
## The level's end point: a crooked lantern post with a faint, breathing glow
## seen through the trees. Purely visual; the level's Exit area does the logic.
## The glow is drawn additively on an internal child so it lifts the pale sky.

var _time := 0.0
var _glow: Node2D


func _ready() -> void:
	_glow = Node2D.new()
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = mat
	_glow.show_behind_parent = true
	_glow.draw.connect(_draw_glow)
	add_child(_glow, false, Node.INTERNAL_MODE_FRONT)


func _process(delta: float) -> void:
	_time += delta
	if _glow:
		_glow.queue_redraw()


func _lamp_position() -> Vector2:
	return Vector2(6, -118)


func _draw_glow() -> void:
	var pulse := 0.85 + 0.15 * sin(_time * 1.3)
	var lamp := _lamp_position()
	for i in 12:
		var t := float(i) / 11.0
		_glow.draw_circle(lamp, lerpf(300.0, 10.0, t), Color(Palette.EXIT_GLOW, 0.028 * pulse), true, -1.0, true)
	_glow.draw_circle(lamp, 5.5, Color(Palette.EXIT_GLOW, 0.8 * pulse), true, -1.0, true)


func _draw() -> void:
	var col := Palette.SILHOUETTE
	var lamp := _lamp_position()
	# Crooked post, hook and lantern cage.
	SilhouetteDraw.chain(self, PackedVector2Array([Vector2(0, 10), Vector2(-3, -60), Vector2(2, -130), Vector2(-2, -140)]), 7.0, 4.0, col)
	SilhouetteDraw.chain(self, PackedVector2Array([Vector2(-1, -134), Vector2(9, -138), Vector2(8, -129)]), 2.5, 1.5, col)
	draw_rect(Rect2(lamp + Vector2(-7, -10), Vector2(14, 2.5)), col)
	draw_rect(Rect2(lamp + Vector2(-6, 8), Vector2(12, 2.5)), col)
	for x in [-6.0, 0.0, 6.0]:
		draw_line(lamp + Vector2(x, -8), lamp + Vector2(x * 0.9, 8), col, 1.6, true)
