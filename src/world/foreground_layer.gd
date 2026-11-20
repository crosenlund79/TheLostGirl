@tool
class_name ForegroundLayer
extends Node2D
## Out-of-focus black framing in front of the action: tall grass clumps along
## the bottom of the screen and gnarled branches hanging from the top.
## Place inside a Parallax2D with scroll_scale.x > 1 so it slides past quickly.

## Horizontal extent (from, to) in local space.
@export var span := Vector2(-600, 5800):
	set(value):
		span = value
		queue_redraw()
## Local y of the grass clump roots (bottom framing).
@export var grass_y := 300.0:
	set(value):
		grass_y = value
		queue_redraw()
## Local y the hanging branches grow down from (top framing).
@export var canopy_y := -470.0:
	set(value):
		canopy_y = value
		queue_redraw()
@export var clump_gap := Vector2(700, 1400):
	set(value):
		clump_gap = value
		queue_redraw()
@export var layer_seed := 7:
	set(value):
		layer_seed = value
		queue_redraw()


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = layer_seed
	var batch := SilhouetteBatch.new()
	var x := span.x
	while x < span.y:
		x += rng.randf_range(clump_gap.x, clump_gap.y)
		_paint_grass_clump(batch, rng, Vector2(x, grass_y))
	x = span.x
	while x < span.y:
		x += rng.randf_range(clump_gap.x * 1.2, clump_gap.y * 1.4)
		_paint_hanging_branch(batch, rng, Vector2(x, canopy_y))
	batch.commit(self, Palette.SILHOUETTE)


func _paint_grass_clump(batch: SilhouetteBatch, rng: RandomNumberGenerator, root: Vector2) -> void:
	# Tall enough that some blades rise past the ground line and frame the action.
	batch.disc(root + Vector2(0, 30), 70.0)
	var tallest := rng.randf_range(320.0, 420.0)
	for i in rng.randi_range(10, 16):
		var base := root + Vector2(rng.randf_range(-50.0, 50.0), 0)
		var height := rng.randf_range(0.5, 1.0) * tallest
		var lean := rng.randf_range(-0.6, 0.6)
		var mid := base + Vector2(lean * height * 0.4, -height * 0.55)
		var tip := base + Vector2(lean * height, -height)
		var half := rng.randf_range(3.5, 7.0)
		batch.quad(base + Vector2(-half, 0), mid + Vector2(-half * 0.6, 0), mid + Vector2(half * 0.6, 0), base + Vector2(half, 0))
		batch.triangle(mid + Vector2(-half * 0.6, 0), tip, mid + Vector2(half * 0.6, 0))


func _paint_hanging_branch(batch: SilhouetteBatch, rng: RandomNumberGenerator, root: Vector2) -> void:
	var points := PackedVector2Array([root])
	var pos := root
	var angle := PI * 0.5 + rng.randf_range(-0.6, 0.6)
	for i in 5:
		angle += rng.randf_range(-0.4, 0.4)
		pos += Vector2.from_angle(angle) * rng.randf_range(22.0, 34.0)
		points.append(pos)
	batch.chain(points, 16.0, 3.0)
	for i in range(1, points.size()):
		for k in 2:
			var start := points[i]
			var end := start + Vector2(rng.randf_range(-14.0, 14.0), rng.randf_range(10.0, 40.0))
			batch.limb(start, end, 1.5, 1.5)
			batch.disc(end, rng.randf_range(2.0, 4.0))
