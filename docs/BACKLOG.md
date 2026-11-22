# Deferred observations — not approved tasks

Record only observations found during approved work. An item here is **not** permission to implement or add to the current objective.

| Date | Observation | Context |
| --- | --- | --- |
| 2026-11-20 | The reference image mentioned in the prototype request never arrived; the art direction follows the written description only. | Prototype request |
| 2026-11-20 | `custom/` override resolver now exists for audio (`AssetResolver.get_audio`); graphics overrides remain unused while the art is procedural. | Audio task |
| 2026-11-20 | Only forest audio exists. Footsteps, creature breathing and a heartbeat while hidden would likely add a lot of tension. | Prototype review |
| 2026-11-20 | Creatures never notice the dog (it hides with her when she crouches). Decide whether the dog should ever matter to detection. | Dog follower |
| 2026-11-20 | Creature movement is one-axis on flat ground; slopes, platforms or drops inside a patrol would need ground-following. | Creature brain |
| 2026-11-20 | Godot 4.7 Compatibility renderer does not support 2D MSAA. Static layers are batched into one triangle list each (about 9,200 → 195 draw calls per frame), which drops edge antialiasing there; characters keep antialiased drawing. | Rendering performance |
| 2026-11-20 | Characters are about 69 px tall at 720p. Camera zoom and the `Palette` colours are the quickest knobs if readability or mood needs tuning after playtesting. (Addressed 2026-11-22: 1.35× camera, the girl is about 93 px on screen.) | Visual review |
| 2026-11-20 | Two uploaded file names differ from the request: `Ambiance_Layer1.mp3` (request: `Ambiance_layer1`) and `Undergrowth 1/2.mp3` (request: `Undergrow 1/2`). Treated as the same files. | Audio task |
| 2026-11-20 | `assets/README.md` allows OGG (and WAV) overrides only, while the supplied files are MP3. Godot 4.7 can load MP3 at runtime, so MP3 overrides would be easy, but they need a contract change. | Audio task |
| 2026-11-20 | `assets/README.md` only describes Claude-made `template_` fallbacks. The user's own packaged audio lives in `assets/audio/` without a prefix (the resolver accepts both); the contract could say so. | Audio task |
| 2026-11-20 | Gain trims in `forest_sounds.gd` also apply to overrides, so a replacement mastered much louder or quieter than the original needs its trim adjusted. Root crack 2 played about 6 dB hotter in game than its file loudness predicted, so new disturbance files should be calibrated in game the same way. | Audio task |
| 2026-11-20 | Quitting while music plays can print "ObjectDB instances leaked / resources still in use". This is a Godot shutdown race, reproduced with a bare AudioStreamPlayer, and harmless; a graceful quit (stop audio, wait a few frames) would silence it. | Audio task |
| 2026-11-20 | The music restarts from the beginning when the level restarts after the ending (scene reload). | Audio task |
| 2026-11-22 | The taller creatures' arms visibly reach about 90 px ahead, but the catch area is unchanged (46 × 112 px around the body), so claws can pass close to her before a catch. Deliberate, to keep gameplay identical; worth watching in playtests. | Refinement pass |
| 2026-11-22 | When she hides near the edge of a bush, the lying dog can poke out of the cover. Creatures ignore the dog, but it may read as "not hidden". (Still true after the dog rebuild: the bigger dog lies about 50 px behind her so it never covers her own silhouette.) | Refinement pass |
| 2026-11-22 | Godot pans 2D sounds by their on-screen position, so camera zoom affects the disturbance mix. Re-measured at 1.35×: levels moved by 0.3 LU or less. Re-check if the zoom changes a lot. | Refinement pass |
| 2026-11-22 | In pure black silhouette the dog reads as a big, long-coated, Bernese-proportioned dog, but its breed can't be pinned down beyond that (it could pass for a large retriever): the markings that identify a Bernese can't show in silhouette. | Dog rebuild |
| 2026-11-22 | Found during the dog rebuild: when she stopped shortly after a jump, the dog stopped on her jump arc and hung in mid-air (the old dog could too). Fixed: it settles onto the ground below unless it is trotting. | Dog rebuild |
| 2026-11-22 | When she turns back towards the dog it eases off and lets her pass, briefly overlapping her (no collision, by design), then turns and follows. | Dog rebuild |
| 2026-11-22 | On a slope all four paws are placed at the same height (no per-paw ground fitting); only the level's one slope is affected. | Dog rebuild |
