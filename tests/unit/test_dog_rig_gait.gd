extends GutTest
## DogRig gait: planted paws stay put in the world (no skating) at walking and
## trotting speeds, and all four paws settle back home when the dog stops.

const DT := 1.0 / 60.0

var carrier: Node2D
var rig: DogRig


func before_each() -> void:
	carrier = Node2D.new()
	add_child_autofree(carrier)
	rig = DogRig.new()
	carrier.add_child(rig)
	rig.reset_pose(1)


## Moves the dog at a steady speed and returns the worst drift (world px) of
## any paw while it was planted on the ground.
func _max_planted_drift(speed: float, seconds: float) -> float:
	var contact := {}
	var worst := 0.0
	for i in int(seconds / DT):
		carrier.position.x += speed * DT
		rig.set_state(Vector2(speed, 0), 1, false, false)
		rig._process(DT)
		if i < 30:
			continue  # let the gait settle in first
		for leg in 4:
			var x: float = rig.to_global(rig._feet[leg]).x
			if rig._lift[leg] == 0.0:
				if not contact.has(leg):
					contact[leg] = x
				worst = maxf(worst, absf(x - contact[leg]))
			else:
				contact.erase(leg)
	return worst


func test_planted_paws_do_not_skate_while_walking() -> void:
	assert_lt(_max_planted_drift(60.0, 3.0), 0.01)


func test_planted_paws_do_not_skate_while_trotting() -> void:
	assert_lt(_max_planted_drift(150.0, 3.0), 0.01)


func test_paws_settle_home_after_stopping() -> void:
	_max_planted_drift(150.0, 1.0)
	for i in int(1.5 / DT):
		rig.set_state(Vector2.ZERO, 1, false, false)
		rig._process(DT)
	for leg in 4:
		assert_almost_eq(rig._feet[leg].distance_to(rig._home(leg)), 0.0, 0.05, "paw %d back home" % leg)
