class_name TreePainter
extends RefCounted
## Paints twisted, slightly fairy-tale tree silhouettes into a SilhouetteBatch.
## Deterministic for a given RandomNumberGenerator seed.

enum Style { GNARLED, SPINDLY }


static func paint_tree(batch: SilhouetteBatch, rng: RandomNumberGenerator, base: Vector2, height: float,
		trunk_width: float, style: Style = Style.GNARLED) -> void:
	var gnarled := style == Style.GNARLED
	var segments := 7
	var seg_len := (height + 30.0) / float(segments)
	var pos := base + Vector2(0, 30)
	var angle := -PI * 0.5 + rng.randf_range(-0.1, 0.1)
	var width := trunk_width
	# Root flare so trunks grip the ground.
	batch.quad(base + Vector2(-trunk_width * 1.6, 8), base + Vector2(-trunk_width * 0.45, -trunk_width * 1.5),
		base + Vector2(trunk_width * 0.45, -trunk_width * 1.5), base + Vector2(trunk_width * 1.6, 8))
	for i in segments:
		angle += rng.randf_range(-0.17, 0.17) if gnarled else rng.randf_range(-0.035, 0.035)
		var end := pos + Vector2.from_angle(angle) * seg_len
		var next_width := width * (0.88 if gnarled else 0.93)
		batch.limb(pos, end, width, next_width)
		if i >= 2 and rng.randf() < (0.7 if gnarled else 0.4):
			var side := -1.0 if rng.randf() < 0.5 else 1.0
			_branch(batch, rng, end, angle + side * rng.randf_range(0.6, 1.25),
				seg_len * rng.randf_range(1.0, 1.8), next_width * 0.55, 2 if gnarled else 1, gnarled)
		pos = end
		width = next_width
	for k in rng.randi_range(2, 3):
		_branch(batch, rng, pos, angle + rng.randf_range(-0.9, 0.9), seg_len * rng.randf_range(1.0, 1.5),
			width * 0.8, 2 if gnarled else 1, gnarled)


static func _branch(batch: SilhouetteBatch, rng: RandomNumberGenerator, start: Vector2, angle: float,
		length: float, width: float, depth: int, gnarled: bool) -> void:
	var pos := start
	var a := angle
	var w := width
	for i in 3:
		a += rng.randf_range(-0.38, 0.38)
		if gnarled:
			a = lerp_angle(a, PI * 0.5, 0.05)
		var end := pos + Vector2.from_angle(a) * length / 3.0
		var next_w := maxf(w * 0.72, 0.9)
		batch.limb(pos, end, w, next_w)
		pos = end
		w = next_w
	if depth > 0:
		for k in rng.randi_range(2, 3):
			_branch(batch, rng, pos, a + rng.randf_range(-0.75, 0.75), length * rng.randf_range(0.45, 0.7),
				w * 0.85, depth - 1, gnarled)
	elif gnarled and rng.randf() < 0.3:
		# Hanging moss strand.
		var drop := rng.randf_range(10.0, 34.0)
		batch.limb(pos, pos + Vector2(rng.randf_range(-3.0, 3.0), drop), 1.2, 1.2)
