# Project Brief — Single design and task handoff record

Game brief for this repository (TheLostGirl), created from the starter pack. This file **records** decisions and approvals; it never grants them. Only the user can approve scope, in their message in the current conversation. **Undecided = ask, don't choose.**

## Game decisions (user-confirmed only)

- **Game title:** Undecided (working name "The Lost Girl", from the repository name)
- **Godot version (pin minor, e.g. 4.x):** 4.7 (developed and tested with 4.7.2-stable), Compatibility (OpenGL) renderer — confirmed 2026-11-20
- **Premise / core player loop:** 2D side-scrolling silhouette horror platformer. A little girl with pigtails, carrying a teddy bear and followed by her pet dog, avoids roaming creatures by hiding under foreground cover. No combat.
- **Perspective / art direction:** 2D side view, silhouette style. Pure-black foreground (characters, ground, cover) against layered forest depth; background gradient from a sickly pale green-grey to a very dark, almost-black green that stays distinguishable from the black foreground. Mood: oppressive, lonely, unnatural, slightly fairy-tale but threatening. Prototype art is procedural (drawn in-engine) — confirmed 2026-11-20.
- **Confirmed mechanics and constraints:** move left/right, jump, crouch; dog companion follows the girl; hostile creatures patrol and are deadly on contact; she is hidden only while crouched fully inside cover (bushes, low tree branches), and creatures then pass her by.
- **Presentation refinements (confirmed 2026-11-22, from the user's hands-on playtest):** the girl must read clearly on screen (pigtails and teddy recognisable), solved with a closer camera rather than rescaling her; creatures are taller, gangly, hunched and off-balance, as if about to tip over, with strained reaching and sniffing (predatory and wrong, not cartoony); the camera eases in subtly when a creature investigates near her hiding place; the dog is big and round with a Bernese Mountain Dog-like silhouette, warm and non-threatening. Dog rebuilt in a second pass the same day (user: "one last attempt", otherwise remove it): articulated anatomical silhouette, natural walk/trot gait without skating, smooth following.
- **Audio (confirmed 2026-11-20):** layered forest audio. "Lost in the fog" is a continuous soundtrack, "Ambiance_Layer1" a continuous forest loop, and twig snaps, root cracks and undergrowth (two variations each) play as random positional disturbances around the girl, initially 15–45 s apart, with slight random pitch, volume and position. Music, ambience and disturbances use separate buses with adjustable volumes. No obvious repetition, no loud jumpscares, no excessive sound activity.
- **Explicitly out of scope:** combat, inventory, dialogue systems, puzzle systems, collectibles, crafting, save/load complexity, elaborate UI.
- **Existing modules / boundaries:**
  - `src/player/` — Girl body (input → `GirlMotor` pure movement rules), `GirlRig` (procedural girl + teddy), `GirlEyes` (peeking eyes while hidden).
  - `src/companion/` — Dog follower (eases along her trail with acceleration, settles on the ground when stopping, waits when she doubles back; `DogTrail` pure path logic) and `DogRig` (articulated vector silhouette: torso, neck, head with jaw, ear, tail, four two-joint legs; walk/trot gait with planted paws).
  - `src/enemy/` — Creature node, `CreatureBrain` (pure patrol/sight/chase/search logic), `CreatureRig`.
  - `src/hiding/` — `HidingRules` (pure "crouched and fully inside cover" rule) and `HideCover` (bush / low-branch cover with its zone).
  - `src/world/` — terrain pieces, background forest layers, foreground framing, sky and vignette shaders, exit lantern.
  - `src/style/` — `Palette` (every colour), shared drawing helpers (`SilhouetteDraw`, `SilhouetteBatch`, `TreePainter`).
  - `src/level/` — `prototype_level` scene and flow (checkpoints, caught → respawn, exit). Main scene. `TensionCamera`: 1.35× follow camera with slight look-ahead that pushes in when a creature investigates near the hidden girl.
  - `src/assets/` — `AssetResolver`, the single entry point for replaceable assets (`get_audio(logical_name)`; user override → packaged file).
  - `src/audio/` — `ForestAudio` (plays the layers), `ForestSounds` (logical names and calibrated gain trims), `DisturbanceScheduler` (pure timing/variation rules). Buses in `default_bus_layout.tres`: Music, Ambience, Disturbances → Master (hard limiter, −1 dBFS ceiling).
  - Contracts: creatures read the girl's position and `is_hidden()`; the girl reads cover zones via the `hide_cover` group; the dog reads the girl's position/crouch and the `creature` group; the level wires targets (including `ForestAudio.target` and the camera's `watch()`) and handles `caught_player`. The camera reads the girl's `is_hidden()` and each creature's brain state. No autoloads.
- **Testing framework (GUT or GdUnit4) and commands:** GUT 9.7.1 (for Godot 4.7), vendored in `addons/gut/`, configured by `.gutconfig.json`. From the project folder:
  - `godot --headless --import` (once, or after adding scripts with a new `class_name`)
  - `godot --headless -s addons/gut/gut_cmdln.gd` (runs `tests/unit` and `tests/integration`, then exits)
- **Target platforms:** Undecided (runtime asset overrides currently cover Windows/Linux only; other platforms need an explicit decision)
- **Asset override notes:** Art is still procedural (no image files). Audio uses the `custom/` override resolver (implemented 2026-11-20 with the first audio files): a user file `custom/audio/<folder>/<name>.ogg` (or `.wav`) replaces `res://assets/audio/<folder>/<name>.mp3` after a game restart, e.g. `custom/audio/music/lost_in_the_fog.ogg`. Logical names are listed in `src/audio/forest_sounds.gd`. The user's original uploads stay untouched in `assets/_inbox/` (excluded from import and export by `.gdignore`); the working copies live in `assets/audio/`. Verification against an exported build is pending (no export requested).

## Current approved development objective

**Status: Implemented on branch `claude/sweet-mayer-5s7ipk`, awaiting user review.** This heading records an objective *after* the user approves it in conversation; it is not an instruction to implement, and a later task needs fresh approval.

- **User approval (reference / summary):** User's message of 2026-11-22 ("One Last Attempt at the Dog"): rebuild the dog so it genuinely looks and moves like a Bernese Mountain Dog companion, or say honestly that it cannot be done in this style; the alternative is removing the dog.
- **Objective:** a convincing Bernese-like silhouette (sturdy rounded body, broad chest, short-looking legs, proper muzzle, floppy ears, bushy tail) with natural movement (coordinated four-legged gait, weight, head and tail motion, natural stops and turns, relaxed idle, no skating or rubbery limbs).
- **In scope:** dog drawing and animation from scratch, how the follower moves (speed easing, ground settling, behaviour when she turns back), mandatory visual verification.
- **Out of scope:** everything else in the prototype; the follower's role (trails her path, lies down behind her when she crouches, cowers near creatures, never blocks her, ignored by creatures).
- **Acceptance criteria / done when:** visually verified beside the girl, walking, trotting, stopping, turning, idle poses, at gameplay scale against the forest; gameplay unchanged; tests pass.
- **Relevant tests:** `tests/unit/test_dog_rig_gait.gd` (no skating, paws settle); `tests/unit/test_dog_trail.gd`; `tests/integration/test_dog_follows_girl.gd` (follow distances, ground settling after a jump, no retracing when she turns back).
- **Relevant manual checks (next playtest):** does it read as a lovable big dog beside her at normal play; does the walk-to-trot and the stop look natural; does the short turn read as turning; is lying down behind her when she crouches pleasing, and is she still readable.

**Previous objective (refinement pass, 2026-11-22):** implemented on the same branch, awaiting review. Its tests: `tests/unit/test_tension_camera.gd`, the camera case in `tests/integration/test_hiding_contract.gd`, camera wiring in `test_level_flow.gd`. Manual checks: the girl's pigtails and teddy read while walking; the camera's look-ahead and push-in feel calm; the push-in follows a creature investigating her bush; creatures feel tall, teetering and strained without looking silly.

**Earlier objective (forest audio, 2026-11-20):** implemented on the same branch, awaiting review. Its tests: `tests/unit/test_asset_resolver.gd`, `test_disturbance_scheduler.gd`; integration `tests/integration/test_forest_audio.gd`. Listening checks: the loops fade in and repeat without a gap; disturbances are audible but never startling and come from the sides; nothing repeats back to back; each bus fader works; an OGG in `custom/audio/...` replaces its sound after a restart.

**First objective (prototype level, 2026-11-20):** implemented on the same branch, awaiting review. Its tests: `tests/unit/test_girl_motor.gd`, `test_hiding_rules.gd`, `test_dog_trail.gd`, `test_creature_brain.gd`; integration `test_hiding_contract.gd`, `test_dog_follows_girl.gd`, `test_level_flow.gd`. Manual checklist (feel/visuals, not automatable):
  1. Silhouettes read: pigtails, dress and dangling teddy visible; teddy swings as she walks and lags on stops/turns.
  2. Crouch and jump poses are distinct; standing behind cover, her head clearly pokes out; crouched inside, only her faint eyes show and the screen edges darken.
  3. The dog trails behind, hops where she jumped, sits when idle, lies down when she crouches, cowers near creatures.
  4. Creatures lurch, twitch and sniff; when one spots her its eyes flare and it lunges after a short pause; hiding mid-chase makes it lose her.
  5. Being caught fades out and returns her to the last checkpoint; reaching the lantern shows the end message, and Jump restarts.

## Proposals awaiting user approval

None. Keep proposals clearly separate from confirmed decisions and active work. Do not promote them to tasks automatically.
