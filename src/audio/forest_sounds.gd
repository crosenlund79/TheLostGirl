class_name ForestSounds
extends RefCounted
## Catalogue of the forest audio: logical asset names (resolved by AssetResolver,
## so each can be replaced from custom/audio/...) and a per-sound gain trim.
##
## The trims level-match the supplied recordings so no single sound jumps out.
## They come from EBU R128 measurements of the original files (integrated or
## max-momentary loudness, true peak) and stay valid for a replacement file
## mastered at a similar level. The overall mix is then set on the audio buses.

## "Lost in the fog": integrated -15.8 LUFS, peak -1.9 dBTP -> about -24 LUFS.
const MUSIC := {"name": "music/lost_in_the_fog", "gain_db": -8.0}

## "Ambiance_Layer1": seamless 30 s loop, integrated -38.6 LUFS, peak -17 dBTP
## -> about -25.6 LUFS, just under the music.
const AMBIENCE := {"name": "ambience/ambiance_layer_1", "gain_db": 13.0}

## Two variations per disturbance type. Trims were calibrated in game (Godot
## 4.7.2 Movie Maker capture): played 450 px left or right of the girl at pitch
## 1.0, every file peaks at about -25 LUFS momentary, just under the music +
## ambience bed (about -22 LUFS short-term). The random 0..-3 dB and distance
## then spread them around that: audible, but never louder than the bed.
## Comments: max momentary loudness / true peak of the source file.
const DISTURBANCES := {
	"twig_snap": [
		{"name": "disturbances/twig_snap_1", "gain_db": 6.0},   # -22.2 LUFS / -0.1 dBTP
		{"name": "disturbances/twig_snap_2", "gain_db": 6.5},   # -22.7 LUFS / -0.8 dBTP
	],
	"root_crack": [
		{"name": "disturbances/root_crack_1", "gain_db": 2.0},  # -18.1 LUFS / -0.8 dBTP
		{"name": "disturbances/root_crack_2", "gain_db": 0.5},  # -23.3 LUFS / -1.3 dBTP, ~6 dB hotter in game
	],
	"undergrowth": [
		{"name": "disturbances/undergrowth_1", "gain_db": 11.0},  # -27.3 LUFS / -14.6 dBTP
		{"name": "disturbances/undergrowth_2", "gain_db": 15.0},  # -31.3 LUFS / -15.9 dBTP
	],
}


## {kind: number of variations}, as DisturbanceScheduler expects.
static func variation_counts() -> Dictionary:
	var counts := {}
	for kind in DISTURBANCES:
		counts[kind] = DISTURBANCES[kind].size()
	return counts


static func all_names() -> Array[String]:
	var names: Array[String] = [MUSIC.name, AMBIENCE.name]
	for kind in DISTURBANCES:
		for sound in DISTURBANCES[kind]:
			names.append(sound.name)
	return names
