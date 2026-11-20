class_name AssetResolver
extends RefCounted
## The single entry point for replaceable assets (contract: assets/README.md).
## Callers ask for a logical name and never hardcode file paths:
##
##   get_audio("music/lost_in_the_fog")
##     1. user override  <override root>/audio/music/lost_in_the_fog.ogg (or .wav)
##     2. packaged file  res://assets/audio/music/lost_in_the_fog.<ext>
##                       (or a Claude-made res://assets/audio/music/template_lost_in_the_fog.<ext>)
##
## A missing or invalid override falls back to the packaged file with a warning;
## nothing crashes. Which file a name resolves to is decided once per session,
## so override changes take effect after restarting the game (no hot-reload).
## Only that decision (a path) is kept session-wide; loaded streams belong to
## the resolver instance and are freed with it.

## Override formats allowed by the contract. WAV qualifies because Godot 4.7
## can load WAV at runtime (AudioStreamWAV.load_from_file).
const AUDIO_OVERRIDE_EXTENSIONS: Array[String] = ["ogg", "wav"]
const PACKAGED_AUDIO_DIR := "res://assets/audio"
const PACKAGED_AUDIO_EXTENSIONS: Array[String] = ["ogg", "mp3", "wav"]

## "root|audio|name" -> chosen file path ("" = nothing found), for the session.
static var _resolved := {}

## Folder holding the user's `audio/` (and later `graphics/`) overrides.
## Empty string disables overrides.
var override_root := ""

var _streams := {}


func _init(root: String = "") -> void:
	override_root = root


## Where overrides live (computed here only): the project's custom/ folder in
## the editor, custom/ next to the executable in Windows/Linux exports.
## Other platforms are deferred (assets/README.md), so overrides are off there.
static func default_override_root() -> String:
	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path("res://custom")
	if OS.has_feature("windows") or OS.has_feature("linuxbsd") or OS.has_feature("linux"):
		return OS.get_executable_path().get_base_dir().path_join("custom")
	return ""


## Forget which files were chosen (tests only; the game never re-resolves).
static func clear_cache() -> void:
	_resolved.clear()


func get_audio(logical_name: String) -> AudioStream:
	if _streams.has(logical_name):
		return _streams[logical_name]
	var key := "%s|audio|%s" % [override_root, logical_name]
	if not _resolved.has(key):
		_resolved[key] = _find_audio(logical_name)
	var stream := _open_audio(_resolved[key])
	if stream == null:
		push_warning("AssetResolver: no audio found for '%s'." % logical_name)
	_streams[logical_name] = stream
	return stream


## Path of the file to use for a logical name: a valid override, else the packaged file.
func _find_audio(logical_name: String) -> String:
	if not override_root.is_empty():
		for ext in AUDIO_OVERRIDE_EXTENSIONS:
			var path := override_root.path_join("audio").path_join("%s.%s" % [logical_name, ext])
			if not FileAccess.file_exists(path):
				continue
			if _decode_audio_file(path, ext) != null:
				return path
			push_warning("AssetResolver: ignoring invalid override '%s'; using the packaged sound." % path)
	var folder := PACKAGED_AUDIO_DIR.path_join(logical_name.get_base_dir())
	for prefix in ["", "template_"]:
		for ext in PACKAGED_AUDIO_EXTENSIONS:
			var path := folder.path_join("%s%s.%s" % [prefix, logical_name.get_file(), ext])
			if ResourceLoader.exists(path):
				return path
	return ""


static func _open_audio(path: String) -> AudioStream:
	if path.is_empty():
		return null
	if path.begins_with("res://"):
		return load(path) as AudioStream
	return _decode_audio_file(path, path.get_extension())


## Runtime decode of a user file. The header is checked first so an obviously
## wrong file is rejected quietly instead of tripping decoder errors.
static func _decode_audio_file(path: String, ext: String) -> AudioStream:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var head := file.get_buffer(12)
	file.close()
	if head.size() < 12:
		return null
	match ext:
		"ogg":
			if head.slice(0, 4).get_string_from_ascii() != "OggS":
				return null
			return AudioStreamOggVorbis.load_from_file(path)
		"wav":
			if head.slice(0, 4).get_string_from_ascii() != "RIFF" or head.slice(8, 12).get_string_from_ascii() != "WAVE":
				return null
			return AudioStreamWAV.load_from_file(path)
	return null
