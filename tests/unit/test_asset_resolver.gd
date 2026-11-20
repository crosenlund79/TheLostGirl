extends GutTest
## AssetResolver: user override -> packaged fallback, per assets/README.md.
## Overrides are written to an injected temporary folder (never to custom/).

const NAME := "disturbances/twig_snap_1"
const PACKAGED_PATH := "res://assets/audio/disturbances/twig_snap_1.mp3"
const OGG_FIXTURE := "res://tests/fixtures/audio/tone.ogg"
const WAV_FIXTURE := "res://tests/fixtures/audio/tone.wav"

var root := ""


func before_each() -> void:
	AssetResolver.clear_cache()
	root = OS.get_user_data_dir().path_join("test_overrides_%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(root.path_join("audio/disturbances"))


func after_each() -> void:
	_remove_tree(root)
	AssetResolver.clear_cache()


func _override_path(ext: String) -> String:
	return root.path_join("audio/%s.%s" % [NAME, ext])


func _write(path: String, bytes: PackedByteArray) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(bytes)
	file.close()


func _remove_tree(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for sub in dir.get_directories():
		_remove_tree(path.path_join(sub))
	for file in dir.get_files():
		dir.remove(file)
	DirAccess.remove_absolute(path)


func test_editor_override_root_is_the_projects_custom_folder() -> void:
	assert_eq(AssetResolver.default_override_root(), ProjectSettings.globalize_path("res://custom"))


func test_missing_override_falls_back_to_packaged_file() -> void:
	var stream := AssetResolver.new(root).get_audio(NAME)
	assert_not_null(stream)
	assert_eq(stream.resource_path, PACKAGED_PATH)


func test_empty_root_disables_overrides() -> void:
	_write(_override_path("ogg"), FileAccess.get_file_as_bytes(OGG_FIXTURE))
	var stream := AssetResolver.new("").get_audio(NAME)
	assert_eq(stream.resource_path, PACKAGED_PATH)


func test_ogg_override_takes_precedence() -> void:
	_write(_override_path("ogg"), FileAccess.get_file_as_bytes(OGG_FIXTURE))
	var stream := AssetResolver.new(root).get_audio(NAME)
	assert_true(stream is AudioStreamOggVorbis, "user OGG wins over the packaged MP3")
	assert_gt(stream.get_length(), 0.1)


func test_wav_override_is_supported() -> void:
	_write(_override_path("wav"), FileAccess.get_file_as_bytes(WAV_FIXTURE))
	var stream := AssetResolver.new(root).get_audio(NAME)
	assert_true(stream is AudioStreamWAV)


func test_invalid_override_warns_and_falls_back() -> void:
	_write(_override_path("ogg"), "definitely not audio".to_utf8_buffer())
	var stream := AssetResolver.new(root).get_audio(NAME)
	assert_eq(stream.resource_path, PACKAGED_PATH)
	assert_push_warning("ignoring invalid override")


func test_unsupported_override_format_is_ignored() -> void:
	_write(_override_path("mp3"), FileAccess.get_file_as_bytes("res://assets/audio/disturbances/twig_snap_2.mp3"))
	var stream := AssetResolver.new(root).get_audio(NAME)
	assert_eq(stream.resource_path, PACKAGED_PATH)


func test_choice_is_fixed_for_the_session() -> void:
	assert_eq(AssetResolver.new(root).get_audio(NAME).resource_path, PACKAGED_PATH)
	_write(_override_path("ogg"), FileAccess.get_file_as_bytes(OGG_FIXTURE))
	var later := AssetResolver.new(root).get_audio(NAME)
	assert_eq(later.resource_path, PACKAGED_PATH, "an override added mid-session waits for a restart")


func test_a_resolver_reuses_its_loaded_stream() -> void:
	_write(_override_path("ogg"), FileAccess.get_file_as_bytes(OGG_FIXTURE))
	var resolver := AssetResolver.new(root)
	assert_same(resolver.get_audio(NAME), resolver.get_audio(NAME))


func test_unknown_name_returns_null_with_a_warning() -> void:
	assert_null(AssetResolver.new(root).get_audio("music/does_not_exist"))
	assert_push_warning("no audio found")
