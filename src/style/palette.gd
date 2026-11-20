class_name Palette
extends RefCounted
## Every colour used by the procedural prototype art, in one place.
## Tweak values here to retune the whole mood; nothing else hardcodes colours.

## Pure-black foreground: ground, characters, hiding cover.
const SILHOUETTE := Color(0.008, 0.012, 0.009)

## Sky gradient: very dark green (top) -> sickly pale green-grey glow (horizon)
## -> dark green below the horizon. The dark ends stay distinguishable from SILHOUETTE.
const SKY_TOP := Color(0.05, 0.085, 0.06)
const SKY_GLOW := Color(0.70, 0.74, 0.64)
const SKY_BOTTOM := Color(0.09, 0.13, 0.095)

## Background forest layers, far (palest) to near (darkest, but never pure black).
const LAYER_FAR := Color(0.47, 0.53, 0.45)
const LAYER_MID := Color(0.25, 0.31, 0.245)
const LAYER_NEAR := Color(0.105, 0.145, 0.11)

## Mist drifting between layers and floating spores.
const FOG := Color(0.74, 0.78, 0.68)
const SPORE := Color(0.82, 0.86, 0.76, 0.35)

## The girl's eyes, shown only while she peeks out from cover.
const GIRL_EYE := Color(0.88, 0.91, 0.82, 0.85)

## Creature eyes / grin: pale so they read against the black silhouettes.
const CREATURE_EYE := Color(0.90, 0.93, 0.82)
const CREATURE_GRIN := Color(0.85, 0.88, 0.78, 0.55)

## Screen-edge darkness (vignette) and hint text.
const VIGNETTE := Color(0.0, 0.015, 0.005)
const HINT_TEXT := Color(0.80, 0.84, 0.74, 0.62)

## The faint light at the end of the level.
const EXIT_GLOW := Color(0.86, 0.88, 0.70)
