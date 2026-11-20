extends GutTest
## ForestAudio + AssetResolver + audio buses: the layered forest audio contract.

var audio: ForestAudio
var girl: Node2D


func before_each() -> void:
	AssetResolver.clear_cache()
	girl = Node2D.new()
	girl.position = Vector2(1000, 0)
	add_child_autofree(girl)
	audio = ForestAudio.new()
	add_child_autofree(audio)
	audio.target = girl


func after_each() -> void:
	ForestAudio.set_bus_volume_linear(ForestAudio.MUSIC_BUS, 1.0)


func test_three_separate_buses_feed_master() -> void:
	for bus in [ForestAudio.MUSIC_BUS, ForestAudio.AMBIENCE_BUS, ForestAudio.DISTURBANCE_BUS]:
		var index := AudioServer.get_bus_index(bus)
		assert_gt(index, 0, "%s bus exists" % bus)
		assert_eq(AudioServer.get_bus_send(index), &"Master")


func test_master_has_a_safety_limiter() -> void:
	assert_true(AudioServer.get_bus_effect(0, 0) is AudioEffectHardLimiter, "no clipping if sounds pile up")
	assert_true(AudioServer.is_bus_effect_enabled(0, 0))


func test_every_catalogued_sound_resolves() -> void:
	var resolver := AssetResolver.new("")
	for logical_name in ForestSounds.all_names():
		assert_not_null(resolver.get_audio(logical_name), logical_name)


func test_two_variations_of_each_disturbance_type() -> void:
	assert_eq(ForestSounds.variation_counts(), {"twig_snap": 2, "root_crack": 2, "undergrowth": 2})


func test_music_and_ambience_loop_on_their_own_buses() -> void:
	assert_eq(audio.music_player.bus, ForestAudio.MUSIC_BUS)
	assert_eq(audio.ambience_player.bus, ForestAudio.AMBIENCE_BUS)
	assert_true(audio.music_player.playing)
	assert_true(audio.ambience_player.playing)
	assert_true(audio.music_player.stream.get("loop"))
	assert_true(audio.ambience_player.stream.get("loop"))
	assert_eq(audio.music_player.get_class(), "AudioStreamPlayer", "music is not positional")


func test_music_fades_in_rather_than_starting_loud() -> void:
	assert_lt(audio.music_player.volume_db, ForestSounds.MUSIC.gain_db - 20.0)
	await wait_seconds(audio.fade_in_time + 0.3)
	assert_almost_eq(audio.music_player.volume_db, ForestSounds.MUSIC.gain_db, 0.01)


func test_disturbance_is_positional_near_the_girl_on_its_bus() -> void:
	var event := audio.scheduler.pick()
	var player := audio.play_disturbance(event)
	assert_not_null(player)
	assert_eq(player.bus, ForestAudio.DISTURBANCE_BUS)
	var offset := player.global_position - girl.global_position
	assert_between(absf(offset.x), audio.disturbance_distance.x, audio.disturbance_distance.y)
	assert_between(offset.y, audio.disturbance_height.x, audio.disturbance_height.y)
	var sound: Dictionary = ForestSounds.DISTURBANCES[event.kind][event.variation]
	assert_almost_eq(player.volume_db, sound.gain_db + event.volume_db, 0.001)
	assert_almost_eq(player.pitch_scale, event.pitch, 0.001)


func test_only_one_disturbance_at_a_time() -> void:
	assert_not_null(audio.play_disturbance(audio.scheduler.pick()))
	assert_null(audio.play_disturbance(audio.scheduler.pick()))


func test_bus_volume_is_adjustable() -> void:
	ForestAudio.set_bus_volume_linear(ForestAudio.MUSIC_BUS, 0.5)
	assert_almost_eq(ForestAudio.get_bus_volume_linear(ForestAudio.MUSIC_BUS), 0.5, 0.001)
