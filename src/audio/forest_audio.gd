class_name ForestAudio
extends Node
## Layered forest audio for a level:
##   * music and ambience: continuous, non-positional loops on the Music and
##     Ambience buses, faded in gently at the start;
##   * disturbances: short positional sounds (twig snaps, root cracks,
##     undergrowth) at irregular intervals, somewhere left or right of the girl,
##     on the Disturbances bus. They stay put in the world as she walks on.
## Sounds come from ForestSounds via AssetResolver (user overrides supported).
## Bus volumes: Godot's Audio panel (default_bus_layout.tres) or set_bus_volume_linear().
## Purely presentation: it never touches gameplay.

const MUSIC_BUS := &"Music"
const AMBIENCE_BUS := &"Ambience"
const DISTURBANCE_BUS := &"Disturbances"
const SILENT_DB := -60.0

## Seconds to fade the music and ambience in (no abrupt start).
@export var fade_in_time := 3.0
## Disturbances happen at random intervals in this range (seconds).
@export var disturbance_interval := Vector2(15, 45)
## Horizontal distance from the girl, left or right (px).
@export var disturbance_distance := Vector2(260, 720)
## Vertical band relative to her feet (negative = up in the trees).
@export var disturbance_height := Vector2(-170, 0)
## Random pitch range (+/- fraction) and volume drop (dB) per disturbance.
@export var pitch_jitter := 0.06
@export var volume_jitter_db := 3.0
## Disturbances fade with distance from the listener and are silent beyond this (px).
@export var hearing_distance := 1500.0

## Disturbances happen around this node (the girl). Set by the level.
var target: Node2D
var resolver: AssetResolver
var scheduler: DisturbanceScheduler
var music_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer

var _disturbance: AudioStreamPlayer2D


func _ready() -> void:
	resolver = AssetResolver.new(AssetResolver.default_override_root())
	scheduler = DisturbanceScheduler.new(ForestSounds.variation_counts())
	scheduler.interval_min = disturbance_interval.x
	scheduler.interval_max = disturbance_interval.y
	scheduler.distance_range = disturbance_distance
	scheduler.height_range = disturbance_height
	scheduler.pitch_jitter = pitch_jitter
	scheduler.volume_jitter_db = volume_jitter_db
	music_player = _start_loop(ForestSounds.MUSIC, MUSIC_BUS)
	ambience_player = _start_loop(ForestSounds.AMBIENCE, AMBIENCE_BUS)


func _process(delta: float) -> void:
	if scheduler.tick(delta) and is_instance_valid(target):
		play_disturbance(scheduler.pick())


## Play one disturbance event (from DisturbanceScheduler.pick()) around the target.
## Skipped while another is still sounding, to keep the forest sparse.
func play_disturbance(event: Dictionary) -> AudioStreamPlayer2D:
	if is_instance_valid(_disturbance) or not is_instance_valid(target):
		return null
	var sound: Dictionary = ForestSounds.DISTURBANCES[event.kind][event.variation]
	var stream := resolver.get_audio(sound.name)
	if stream == null:
		return null
	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	player.bus = DISTURBANCE_BUS
	player.volume_db = sound.gain_db + event.volume_db
	player.pitch_scale = event.pitch
	player.max_distance = hearing_distance
	add_child(player)
	player.global_position = target.global_position + event.offset
	player.finished.connect(player.queue_free)
	player.play()
	_disturbance = player
	return player


## Set a bus volume, 0.0 (silent) .. 1.0 (as authored) .. above 1.0 (louder).
static func set_bus_volume_linear(bus: StringName, volume: float) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index >= 0:
		AudioServer.set_bus_volume_linear(index, maxf(volume, 0.0))


static func get_bus_volume_linear(bus: StringName) -> float:
	var index := AudioServer.get_bus_index(bus)
	return AudioServer.get_bus_volume_linear(index) if index >= 0 else 0.0


func _start_loop(sound: Dictionary, bus: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus
	add_child(player)
	var stream := resolver.get_audio(sound.name)
	if stream == null:
		return player
	_make_looping(stream)
	player.stream = stream
	player.volume_db = SILENT_DB
	player.play()
	create_tween().tween_property(player, "volume_db", sound.gain_db, fade_in_time)
	return player


static func _make_looping(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(wav.get_length() * wav.mix_rate)
	elif "loop" in stream:
		stream.set("loop", true)
