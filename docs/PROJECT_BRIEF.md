# Project Brief — Single design and task handoff record

Game brief for this repository (TheLostGirl), created from the starter pack. This file **records** decisions and approvals; it never grants them. Only the user can approve scope, in their message in the current conversation. **Undecided = ask, don't choose.**

## Game decisions (user-confirmed only)

- **Game title:** Undecided (working name "The Lost Girl", from the repository name)
- **Godot version (pin minor, e.g. 4.x):** 4.7 (developed and tested with 4.7.2-stable), Compatibility (OpenGL) renderer — confirmed 2026-11-20
- **Premise / core player loop:** 2D side-scrolling silhouette horror platformer. A little girl with pigtails, carrying a teddy bear and followed by her pet dog, avoids roaming creatures by hiding under foreground cover. No combat.
- **Perspective / art direction:** 2D side view, silhouette style. Pure-black foreground (characters, ground, cover) against layered forest depth; background gradient from a sickly pale green-grey to a very dark, almost-black green that stays distinguishable from the black foreground. Mood: oppressive, lonely, unnatural, slightly fairy-tale but threatening. Prototype art is procedural (drawn in-engine) — confirmed 2026-11-20.
- **Confirmed mechanics and constraints:** move left/right, jump, crouch; dog companion follows the girl; hostile creatures patrol and are deadly on contact; she is hidden only while crouched fully inside cover (bushes, low tree branches), and creatures then pass her by.
- **Explicitly out of scope:** combat, inventory, dialogue systems, puzzle systems, collectibles, crafting, save/load complexity, elaborate UI.
- **Existing modules / boundaries:**
  - `src/player/` — Girl body (input → `GirlMotor` pure movement rules), `GirlRig` (procedural girl + teddy), `GirlEyes` (peeking eyes while hidden).
  - `src/companion/` — Dog follower (`DogTrail` pure path-following logic) and `DogRig`.
  - `src/enemy/` — Creature node, `CreatureBrain` (pure patrol/sight/chase/search logic), `CreatureRig`.
  - `src/hiding/` — `HidingRules` (pure "crouched and fully inside cover" rule) and `HideCover` (bush / low-branch cover with its zone).
  - `src/world/` — terrain pieces, background forest layers, foreground framing, sky and vignette shaders, exit lantern.
  - `src/style/` — `Palette` (every colour), shared drawing helpers (`SilhouetteDraw`, `SilhouetteBatch`, `TreePainter`).
  - `src/level/` — `prototype_level` scene and flow (checkpoints, caught → respawn, exit). Main scene.
  - Contracts: creatures read the girl's position and `is_hidden()`; the girl reads cover zones via the `hide_cover` group; the dog reads the girl's position/crouch and the `creature` group; the level wires targets and handles `caught_player`. No autoloads.
- **Testing framework (GUT or GdUnit4) and commands:** GUT 9.7.1 (for Godot 4.7), vendored in `addons/gut/`, configured by `.gutconfig.json`. From the project folder:
  - `godot --headless --import` (once, or after adding scripts with a new `class_name`)
  - `godot --headless -s addons/gut/gut_cmdln.gd` (runs `tests/unit` and `tests/integration`, then exits)
- **Target platforms:** Undecided (runtime asset overrides currently cover Windows/Linux only; other platforms need an explicit decision)
- **Asset override notes:** The prototype ships no image or audio files (all art is procedural), so the `custom/` override resolver is deferred until the first file-based art or audio is introduced — confirmed 2026-11-20. When that happens, `assets/README.md` applies in full.

## Current approved development objective

**Status: Implemented on branch `claude/sweet-mayer-5s7ipk`, awaiting user review.** This heading records an objective *after* the user approves it in conversation; it is not an instruction to implement, and a later task needs fresh approval.

- **User approval (reference / summary):** User's message of 2026-11-20 asking for a small playable silhouette-horror prototype scene; Godot 4.7, GUT and procedural art confirmed in the same conversation.
- **Objective (one by default):** One short playable prototype level to judge the silhouette horror mood, the girl + teddy silhouette, the dog follower, enemy-avoidance tension and crouch-to-hide.
- **In scope:** girl (pigtails, wobbling teddy), dog follower, patrolling creatures deadly on contact, crouch-to-hide under bushes and low branches, layered gradient forest, minimal hint labels, one short level (safe start, jumps/logs/stumps, three creature encounters, exit), checkpoints/respawn needed to make it playable.
- **Out of scope:** the items listed above, audio, builds/exports, the `custom/` resolver (deferred), polish beyond judging the direction.
- **Acceptance criteria / done when:** the main scene runs from the editor; the level can be finished; standing or crouching outside cover gets her caught on contact, crouching fully under cover lets creatures pass; the dog trails her; module and integration tests pass headless.
- **Relevant module tests:** `tests/unit/test_girl_motor.gd`, `test_hiding_rules.gd`, `test_dog_trail.gd`, `test_creature_brain.gd`.
- **Relevant integration/manual checks:** `tests/integration/test_hiding_contract.gd` (girl + cover + creature), `test_dog_follows_girl.gd`, `test_level_flow.gd`. Manual checklist (feel/visuals, not automatable):
  1. Silhouettes read: pigtails, dress and dangling teddy visible; teddy swings as she walks and lags on stops/turns.
  2. Crouch and jump poses are distinct; standing behind cover, her head clearly pokes out; crouched inside, only her faint eyes show and the screen edges darken.
  3. The dog trails behind, hops where she jumped, sits when idle, lies down when she crouches, cowers near creatures.
  4. Creatures lurch, twitch and sniff; when one spots her its eyes flare and it lunges after a short pause; hiding mid-chase makes it lose her.
  5. Being caught fades out and returns her to the last checkpoint; reaching the lantern shows the end message, and Jump restarts.

## Proposals awaiting user approval

None. Keep proposals clearly separate from confirmed decisions and active work. Do not promote them to tasks automatically.
