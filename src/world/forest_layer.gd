@tool
class_name ForestLayer
extends Node2D
## One background depth layer: a rolling ground mound and a row of procedural
## trees in a single flat colour, with a band of mist over their roots.
## Place it inside a Parallax2D; paler + slower layers read as further away.

enum Tone { FAR, MID, NEAR }

@export var tone: Tone = Tone.MID:
	set(value):
		tone = value
		queue_redraw()
## Horizontal extent (from, to) in this layer's local space.
@export var span := Vector2(-800, 3200):
	set(value):
		span = value
		queue_redraw()
@export var tree_gap := Vector2(70, 160):
	set(value):
		tree_gap = value
		queue_redraw()
@export var tree_height := Vector2(260, 420):
	set(value):
		tree_height = value
		queue_redraw()
@export var trunk_width := Vector2(6, 12):
	set(value):
		trunk_width = value
		queue_redraw()
@export var tree_style: TreePainter.Style = TreePainter.Style.GNARLED:
	set(value):
		tree_style = value
		queue_redraw()
@export var ground_wave := 14.0:
	set(value):
		ground_wave = value
		queue_redraw()
## Opacity of the mist band over this layer's roots (0 = none).
@export var fog_strength := 0.35:
	set(value):
		fog_strength = value
		queue_redraw()
@export var fog_height := 110.0:
	set(value):
		fog_height = value
		queue_redraw()
@export var layer_seed := 1:
	set(value):
		layer_seed = value
		queue_redraw()


func get_color() -> Color:
	match tone:
		Tone.FAR:
			return Palette.LAYER_FAR
		Tone.NEAR:
			return Palette.LAYER_NEAR
	return Palette.LAYER_MID


func _ground_y(x: float) -> float:
	return sin(x * 0.0042 + float(layer_seed)) * ground_wave + sin(x * 0.011 + float(layer_seed) * 2.0) * ground_wave * 0.4


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = layer_seed
	# Everything in this layer shares one colour, so it goes out as one draw call.
	var batch := SilhouetteBatch.new()

	var x := span.x + rng.randf_range(0.0, tree_gap.y)
	while x < span.y:
		TreePainter.paint_tree(batch, rng, Vector2(x, _ground_y(x) + 4.0), rng.randf_range(tree_height.x, tree_height.y),
			rng.randf_range(trunk_width.x, trunk_width.y), tree_style)
		x += rng.randf_range(tree_gap.x, tree_gap.y)

	var mound := PackedVector2Array()
	var step := 40.0
	var px := span.x
	while px <= span.y:
		mound.append(Vector2(px, _ground_y(px)))
		px += step
	mound.append(Vector2(span.y, 1600))
	mound.append(Vector2(span.x, 1600))
	batch.polygon(mound)
	batch.commit(self, get_color())

	if fog_strength > 0.0:
		var fog := Palette.FOG
		var clear := Color(fog, 0.0)
		var thick := Color(fog, fog_strength)
		draw_polygon(PackedVector2Array([
			Vector2(span.x, -fog_height), Vector2(span.y, -fog_height),
			Vector2(span.y, 20), Vector2(span.x, 20),
		]), PackedColorArray([clear, clear, thick, thick]))
		draw_polygon(PackedVector2Array([
			Vector2(span.x, 20), Vector2(span.y, 20), Vector2(span.y, 260), Vector2(span.x, 260),
		]), PackedColorArray([thick, thick, Color(fog, fog_strength * 0.6), Color(fog, fog_strength * 0.6)]))
