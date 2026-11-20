# Project Brief — Single design and task handoff record

Game brief for this repository (TheLostGirl), created from the starter pack. This file **records** decisions and approvals; it never grants them. Only the user can approve scope, in their message in the current conversation. **Undecided = ask, don't choose.**

## Game decisions (user-confirmed only)

- **Game title:** Undecided (working name "The Lost Girl", from the repository name)
- **Godot version (pin minor, e.g. 4.x):** 4.7 (developed and tested with 4.7.2-stable), Compatibility (OpenGL) renderer — confirmed 2026-11-20
- **Premise / core player loop:** 2D side-scrolling silhouette horror platformer. A little girl with pigtails, carrying a teddy bear and followed by her pet dog, avoids roaming creatures by hiding under foreground cover. No combat.
- **Perspective / art direction:** 2D side view, silhouette style. Pure-black foreground (characters, ground, cover) against layered forest depth; background gradient from a sickly pale green-grey to a very dark, almost-black green that stays distinguishable from the black foreground. Mood: oppressive, lonely, unnatural, slightly fairy-tale but threatening. Prototype art is procedural (drawn in-engine) — confirmed 2026-11-20.
- **Confirmed mechanics and constraints:** move left/right, jump, crouch; dog companion follows the girl; hostile creatures patrol and are deadly on contact; she is hidden only while crouched fully inside cover (bushes, low tree branches), and creatures then pass her by.
- **Audio (confirmed 2026-11-20):** layered forest audio. "Lost in the fog" is a continuous soundtrack, "Ambiance_Layer1" a continuous forest loop, and twig snaps, root cracks and undergrowth (two variations each) play as random positional disturbances around the girl, initially 15–45 s apart, with slight random pitch, volume and position. Music, ambience and disturbances use separate buses with adjustable volumes. No obvious repetition, no loud jumpscares, no excessive sound activity.
- **Explicitly out of scope:** combat, inventory, dialogue systems, puzzle systems, collectibles, crafting, save/load complexity, elaborate UI.
- **Existing modules / boundaries:**
  - `src/player/` — Girl body (input → `GirlMotor` pure movement rules), `GirlRig` (procedural girl + teddy), `GirlEyes` (peeking eyes while hidden).
  - `src/companion/` — Dog follower (`DogTrail` pure path-following logic) and `DogRig`.
  - `src/enemy/` — Creature node, `CreatureBrain` (pure patrol/sight/chase/search logic), `CreatureRig`.
  - `src/hiding/` — `HidingRules` (pure "crouched and fully inside cover" rule) and `HideCover` (bush / low-branch cover with its zone).
  - `src/world/` — terrain pieces, background forest layers, foreground framing, sky and vignette shaders, exit lantern.
  - `src/style/` — `Palette` (every colour), shared drawing helpers (`SilhouetteDraw`, `SilhouetteBatch`, `TreePainter`).
  - `src/level/` — `prototype_level` scene and flow (checkpoints, caught → respawn, exit). Main scene.
  - `src/assets/` — `AssetResolver`, the single entry point for replaceable assets (`get_audio(logical_name)`; user override → packaged file).
  - `src/audio/` — `ForestAudio` (plays the layers), `ForestSounds` (logical names and calibrated gain trims), `DisturbanceScheduler` (pure timing/variation rules). Buses in `default_bus_layout.tres`: Music, Ambience, Disturbances → Master (hard limiter, −1 dBFS ceiling).
  - Contracts: creatures read the girl's position and `is_hidden()`; the girl reads cover zones via the `hide_cover` group; the dog reads the girl's position/crouch and the `creature` group; the level wires targets (including `ForestAudio.target`) and handles `caught_player`. No autoloads.
- **Testing framework (GUT or GdUnit4) and commands:** GUT 9.7.1 (for Godot 4.7), vendored in `addons/gut/`, configured by `.gutconfig.json`. From the project folder:
  - `godot --headless --import` (once, or after adding scripts with a new `class_name`)
  - `godot --headless -s addons/gut/gut_cmdln.gd` (runs `tests/unit` and `tests/integration`, then exits)
- **Target platforms:** Undecided (runtime asset overrides currently cover Windows/Linux only; other platforms need an explicit decision)
- **Asset override notes:** Art is still procedural (no image files). Audio uses the `custom/` override resolver (implemented 2026-11-20 with the first audio files): a user file `custom/audio/<folder>/<name>.ogg` (or `.wav`) replaces `res://assets/audio/<folder>/<name>.mp3` after a game restart, e.g. `custom/audio/music/lost_in_the_fog.ogg`. Logical names are listed in `src/audio/forest_sounds.gd`. The user's original uploads stay untouched in `assets/_inbox/` (excluded from import and export by `.gdignore`); the working copies live in `assets/audio/`. Verification against an exported build is pending (no export requested).

## Current approved development objective

**Status: Implemented on branch `claude/sweet-mayer-5s7ipk`, awaiting user review.** This heading records an objective *after* the user approves it in conversation; it is not an instruction to implement, and a later task needs fresh approval.

- **User approval (reference / summary):** User's message of 2026-11-20 ("Audio assets and forest ambience"), bundling two objectives.
- **Objectives:** (1) move the four audio files uploaded to the repository root into `assets/_inbox/` without losing or overwriting anything; (2) implement the layered forest audio system described under *Audio* above.
- **In scope:** working copies in `assets/audio/`, originals preserved in `assets/_inbox/`; music and ambience loops; random positional disturbances; three buses with adjustable volumes; the `custom/` audio override resolver required by guideline 3 now that audio files exist; level-matching so nothing jumps out.
- **Out of scope:** gameplay or art changes, other sounds (footsteps, creatures, UI), a volume-settings UI, builds/exports.
- **Acceptance criteria / done when:** all eight files accounted for in `assets/_inbox/`; the level plays music, ambience and disturbances on separate buses; disturbances vary type, variation, pitch, volume and position at irregular 15–45 s intervals; overrides and fallbacks work; tests pass headless.
- **Relevant module tests:** `tests/unit/test_asset_resolver.gd`, `test_disturbance_scheduler.gd`; integration `tests/integration/test_forest_audio.gd`, plus the wiring check in `test_level_flow.gd`.
- **Relevant manual checks (listening, not automatable):** the music and ambience fade in and loop without a gap; disturbances are audible but never startling, come from the left or right and stay put as she walks; no sound repeats back to back; the bus faders in Godot's Audio panel change each layer independently; an OGG dropped into `custom/audio/...` replaces its sound after a restart.

**Previous objective (prototype level, 2026-11-20):** implemented on the same branch, awaiting review. Its tests: `tests/unit/test_girl_motor.gd`, `test_hiding_rules.gd`, `test_dog_trail.gd`, `test_creature_brain.gd`; integration `test_hiding_contract.gd`, `test_dog_follows_girl.gd`, `test_level_flow.gd`. Manual checklist (feel/visuals, not automatable):
  1. Silhouettes read: pigtails, dress and dangling teddy visible; teddy swings as she walks and lags on stops/turns.
  2. Crouch and jump poses are distinct; standing behind cover, her head clearly pokes out; crouched inside, only her faint eyes show and the screen edges darken.
  3. The dog trails behind, hops where she jumped, sits when idle, lies down when she crouches, cowers near creatures.
  4. Creatures lurch, twitch and sniff; when one spots her its eyes flare and it lunges after a short pause; hiding mid-chase makes it lose her.
  5. Being caught fades out and returns her to the last checkpoint; reaching the lantern shows the end message, and Jump restarts.

## Proposals awaiting user approval

None. Keep proposals clearly separate from confirmed decisions and active work. Do not promote them to tasks automatically.
