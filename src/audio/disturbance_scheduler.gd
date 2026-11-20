class_name DisturbanceScheduler
extends RefCounted
## Pure rules for random forest disturbances (no Nodes, seedable, unit-testable):
## WHEN the next one happens (irregular intervals) and WHAT it is: a type other
## than the previous one, a variation other than that type's previous one, and
## slightly randomised pitch, volume and position around the listener.

var interval_min := 15.0
var interval_max := 45.0
## Pitch varies by up to +/- this fraction (0.06 = about one semitone).
var pitch_jitter := 0.06
## Volume is lowered by 0..this many dB.
var volume_jitter_db := 3.0
## Horizontal distance from the listener, either side (px).
var distance_range := Vector2(260, 720)
## Vertical offset from the listener's feet (negative = up into the trees).
var height_range := Vector2(-170, 0)

var rng := RandomNumberGenerator.new()

var _variations := {}
var _time_left := 0.0
var _started := false
var _last_kind := ""
var _last_variation := {}


## variations: {kind: number of variations}. seed_value < 0 randomises.
func _init(variations: Dictionary, seed_value: int = -1) -> void:
	_variations = variations
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()


func next_interval() -> float:
	return rng.randf_range(interval_min, interval_max)


## Advance time; true when a disturbance is due (the next one is then scheduled).
## The first interval is drawn on the first tick, so settings changed before it apply.
func tick(delta: float) -> bool:
	if not _started:
		_started = true
		_time_left = next_interval()
	_time_left -= delta
	if _time_left > 0.0:
		return false
	_time_left = next_interval()
	return true


## The next disturbance: {kind, variation, pitch, volume_db, offset}.
func pick() -> Dictionary:
	var kinds: Array = _variations.keys()
	if kinds.size() > 1:
		kinds.erase(_last_kind)
	var kind: String = kinds[rng.randi_range(0, kinds.size() - 1)]
	var count: int = _variations[kind]
	var variation := rng.randi_range(0, count - 1)
	if count > 1 and variation == _last_variation.get(kind, -1):
		variation = (variation + rng.randi_range(1, count - 1)) % count
	_last_kind = kind
	_last_variation[kind] = variation
	var side := -1.0 if rng.randf() < 0.5 else 1.0
	return {
		"kind": kind,
		"variation": variation,
		"pitch": 1.0 + rng.randf_range(-pitch_jitter, pitch_jitter),
		"volume_db": -rng.randf_range(0.0, volume_jitter_db),
		"offset": Vector2(side * rng.randf_range(distance_range.x, distance_range.y),
			rng.randf_range(height_range.x, height_range.y)),
	}
