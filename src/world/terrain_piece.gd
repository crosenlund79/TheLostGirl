@tool
class_name TerrainPiece
extends Polygon2D
## Solid black ground, log, stump or ledge. Edit the polygon with Godot's polygon
## editor: the collision is built from it at runtime and grass tufts are drawn
## along every walkable (upward-facing) edge.

@export var grass_density := 0.3:
	set(value):
		grass_density = value
		queue_redraw()
@export var grass_height := Vector2(4, 13):
	set(value):
		grass_height = value
		queue_redraw()
@export var grass_seed := 0:
	set(value):
		grass_seed = value
		queue_redraw()


func _ready() -> void:
	color = Palette.SILHOUETTE
	antialiased = true
	if Engine.is_editor_hint():
		return
	var body := StaticBody2D.new()
	body.name = "Body"
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionPolygon2D.new()
	shape.polygon = polygon
	body.add_child(shape)
	add_child(body)


func _draw() -> void:
	if grass_density <= 0.0 or polygon.size() < 3:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = grass_seed
	var batch := SilhouetteBatch.new()
	var count := polygon.size()
	for i in count:
		var a := polygon[i]
		var b := polygon[(i + 1) % count]
		var edge := b - a
		if absf(edge.x) < 1.0 or absf(edge.y) > absf(edge.x) * 1.2:
			continue
		if not Geometry2D.is_point_in_polygon((a + b) * 0.5 + Vector2(0, 3), polygon):
			continue
		for k in int(absf(edge.x) * grass_density):
			var root := a.lerp(b, rng.randf())
			var height := rng.randf_range(grass_height.x, grass_height.y)
			var lean := rng.randf_range(-0.55, 0.55)
			var half := rng.randf_range(1.2, 2.6)
			batch.triangle(root + Vector2(-half, 2), root + Vector2(lean * height, -height), root + Vector2(half, 2))
	batch.commit(self, Palette.SILHOUETTE)
