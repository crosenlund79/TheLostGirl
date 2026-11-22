extends GutTest
## DogTrail: the dog's follow point is measured along the girl's actual path.

var trail: DogTrail


func before_each() -> void:
	trail = DogTrail.new()


func test_reset_with_a_point_behind() -> void:
	trail.reset(Vector2(100, 0), Vector2(50, 0))
	assert_eq(trail.point_behind(0.0), Vector2(100, 0))
	assert_eq(trail.point_behind(25.0), Vector2(75, 0))


func test_distance_beyond_the_trail_clamps_to_oldest_point() -> void:
	trail.reset(Vector2(100, 0), Vector2(50, 0))
	assert_eq(trail.point_behind(500.0), Vector2(50, 0))


func test_tiny_moves_are_not_recorded() -> void:
	trail.reset(Vector2.ZERO)
	assert_eq(trail.record(Vector2(1, 0)), 0.0)
	assert_eq(trail.point_count(), 1)


func test_record_reports_how_much_the_trail_grew() -> void:
	trail.reset(Vector2.ZERO)
	assert_almost_eq(trail.record(Vector2(6, 8)), 10.0, 0.001)


func test_follow_point_tracks_the_path_not_a_straight_line() -> void:
	# She walked right 100 px, then jumped straight up 50 px (an L-shaped path).
	trail.reset(Vector2.ZERO)
	for x in range(5, 101, 5):
		trail.record(Vector2(x, 0))
	for y in range(5, 51, 5):
		trail.record(Vector2(100, -y))
	assert_almost_eq(trail.point_behind(50.0).distance_to(Vector2(100, 0)), 0.0, 0.01, "50 px back is the corner")
	assert_almost_eq(trail.point_behind(70.0).distance_to(Vector2(80, 0)), 0.0, 0.01, "70 px back is on the floor")


func test_trail_is_pruned_to_max_length() -> void:
	trail.max_length = 100.0
	trail.reset(Vector2.ZERO)
	for x in range(5, 1001, 5):
		trail.record(Vector2(x, 0))
	assert_lte(trail.length(), 100.0 + 5.0)
	assert_eq(trail.point_behind(0.0), Vector2(1000, 0))
