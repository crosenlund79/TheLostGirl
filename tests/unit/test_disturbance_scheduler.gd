extends GutTest
## DisturbanceScheduler: irregular timing, no obvious repetition, small random
## variation in pitch, volume and position.

const DT := 1.0 / 60.0
const VARIATIONS := {"twig_snap": 2, "root_crack": 2, "undergrowth": 2}

var scheduler: DisturbanceScheduler


func before_each() -> void:
	scheduler = DisturbanceScheduler.new(VARIATIONS, 1234)


func _seconds_until_next() -> float:
	var elapsed := 0.0
	while not scheduler.tick(DT):
		elapsed += DT
		if elapsed > 120.0:
			break
	return elapsed + DT


func test_intervals_are_irregular_and_within_range() -> void:
	var intervals: Array[float] = []
	for i in 20:
		intervals.append(_seconds_until_next())
	for interval in intervals:
		assert_between(interval, scheduler.interval_min - DT, scheduler.interval_max + DT)
	assert_gt(intervals.max() - intervals.min(), 10.0, "intervals vary noticeably")


func test_nothing_happens_before_the_minimum_interval() -> void:
	var fired := false
	for i in int(scheduler.interval_min / DT) - 2:
		fired = fired or scheduler.tick(DT)
	assert_false(fired)


func test_changed_interval_settings_apply_from_the_start() -> void:
	scheduler.interval_min = 1.0
	scheduler.interval_max = 2.0
	assert_between(_seconds_until_next(), 1.0 - DT, 2.0 + DT)


func test_never_the_same_type_twice_in_a_row() -> void:
	var previous := ""
	for i in 200:
		var event := scheduler.pick()
		assert_ne(event.kind, previous)
		previous = event.kind


func test_never_the_same_variation_of_a_type_twice_in_a_row() -> void:
	var last := {}
	for i in 200:
		var event := scheduler.pick()
		assert_ne(event.variation, last.get(event.kind, -1))
		last[event.kind] = event.variation


func test_every_type_and_variation_gets_used() -> void:
	var seen := {}
	for i in 60:
		var event := scheduler.pick()
		seen["%s/%d" % [event.kind, event.variation]] = true
	assert_eq(seen.size(), 6)


func test_pitch_volume_and_position_vary_slightly() -> void:
	var sides := {}
	for i in 200:
		var event := scheduler.pick()
		assert_between(event.pitch, 1.0 - scheduler.pitch_jitter, 1.0 + scheduler.pitch_jitter)
		assert_between(event.volume_db, -scheduler.volume_jitter_db, 0.0)
		var offset: Vector2 = event.offset
		assert_between(absf(offset.x), scheduler.distance_range.x, scheduler.distance_range.y)
		assert_between(offset.y, scheduler.height_range.x, scheduler.height_range.y)
		sides[signf(offset.x)] = true
	assert_eq(sides.size(), 2, "sounds come from both sides")
