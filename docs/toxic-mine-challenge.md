# Level 2 — Toxic Mine Challenge

Open `scenes/mine_challenge/toxic_mine_challenge.tscn` and press **F6** for a
standalone run. Starting the campaign normally also loads this scene after the
Junkyard, through `scenes/campaign/toxic_mine.tscn`. The summit summary continues
to Eden City. All character, terrain, prop and sound assets are bundled; no paid
assets or external downloads are required.

## Controls

- A/D or arrows: move, 260 px/s. Space: jump; press again in midair for Double Jump.
- E or J: 260 px mineralization pulse, 0.6 s cooldown. C remains a compatibility alias.
- Push the crate by walking into it. T or left mouse button operates the lever.
- T near the entrance resident starts subtitles; T advances each line.
- Esc: settings, controls, language and sound. R at the entrance restores the mine
  on the A ending's return journey.

Both coyote time and jump buffering are 0.12 s. Gravity is 980 px/s²; jump and
double jump velocities are -420 and -390 px/s. Casting preserves velocity.

## Layout and timing

| Stage | Route | Checkpoint |
| --- | --- | --- |
| 1 | Safe entrance, crystal props and first-use tutorial | (180, 1778) |
| 2 | 520 px gas bridge, two mineralizable relays to the scaffold | (560, 1778) |
| 3 | Crate depresses weight plate and powers the shaft | (1200, 1428) |
| 4 | Six primary plumes spaced 220 px apart, with five smaller gas relays | (1870, 1818) |
| 5 | Lever reroutes the visible overhead gas pipeline and opens its hatch | (2540, 698) |
| 6 | Ten-segment collapsing crystal bridge | (2510, 1728) |
| 7 | Four main 72 px cliff plumes and seven 72 px gas relays, all lasting 2.8 s | (4500, 1678) |
| 8 | Summit exit and carbon sequestration summary | (5340, 378) |

All climbing relays are **ToxicGasVent instances**, converted by the same pulse.
There are no permanent intermediate climbing ledges. Permanent geometry is
limited to safe decks/checkpoints, the lever room and the exit. There are 25
mineralizable vents in total. Ordinary platforms last 4 s; during the last second
they shake and flash, then return to gas. Landing refreshes the double jump.

The specified physics permits about 168 px of total vertical rise. Intermediate
gas relays keep each ascent at 90–150 px while retaining six main shaft tiers and
four main cliff tiers. The bridge has a 0.45 s shake telegraph per segment, with
0.82 s propagation spacing and a 0.9 s initial reaction window. Its collapse wave
therefore stays behind a player moving at 260 px/s rather than making the span
mathematically impossible.

Acid begins at Y=2050. Death returns the player to the current safe deck after
0.2 s, clears transient platforms and resets the bridge. Stage progress, valves,
lever state and captured-carbon totals survive checkpoint reloads. A new run
clears them. Checkpoint triggers must be reached in order; the bridge checkpoint
also requires the lever to be active.

The mine's dedicated HUD shows the same five green life vessels as the campaign.
Entry preserves the previous chapter's health; each 10 HP gas hit removes half a
vessel immediately. Lethal acid empties them without opening global Game Over,
then the short checkpoint retry restores all five. The homeward exit derives
its destination from the current Junkyard exit, including the six-section layout.

## Reusable prefabs

All six scenes are under `scenes/mine_challenge/`, with their implementations in
`scripts/mine_challenge/`:

- `toxic_gas_vent.tscn`: Area2D gas hazard, particles, pulse conversion and power routing.
- `mineralized_platform.tscn`: one-way standable collision, lifetime and warning telegraph.
- `weight_switch_and_crate.tscn`: pushable CharacterBody2D crate and overlap pressure plate.
- `gas_redirect_lever.tscn`: interactive state switch and routing signal.
- `deadly_acid_pit.tscn`: lethal lake and fast respawn signal.
- `collapsing_crystal_bridge.tscn`: sequential segment collision removal and reset.

`player.gd` owns movement, coyote/buffer, pulse timing, toxic slowdown, jumping and
resonance. `level.gd` builds the layout and HUD, connects components and persists
chapter progress in `WorldProgress.mine_challenge`.

## Carbon accounting

Each **successful pulse** that converts at least one active plume adds **150 kg
CO₂e**. Hitting several plumes in one pulse still records one 150 kg batch. Empty
pulses, already-mineralized targets and cooldown rejections add no sequestration.
The vent count records conversion events, including repeated batches after a
vent returns to gas; it may exceed the 25 physical vents.

Temporary load-bearing crust can crumble while carbon remains bound in fallen
carbonate rubble. This is the level's simplified teaching model, not a real
engineering estimate. Storage is separate from gross skill emissions and is
included in the campaign's final audit. The A journey supplies a permanent ramp
built by residents so returning the ability cannot trap the player.

## Validation

`tests/mine_mechanics_test.tscn` covers pulse radius, cooldown, gas damage/slow,
platform expiry/recasting, resonance, jump grace/buffering, acid recovery and gates.
`tests/mine_challenge_test.tscn` traverses all eight stages with ordinary input,
then tests Eden City handoff and physically walks the mine's A return route.
Both are included in `tests/run-tests.ps1`.

Older actor/oasis tests explicitly use `tests/fixtures/legacy_mineralization_room.tscn`.
That fixture is not the production level; it preserves coverage of the original
controller and extraction systems used elsewhere in the game.

## Finished presentation pass

The playable route retains its geometry, timings and 25 gas-based footholds.
The mine uses a lantern-free Scenario2 painting with its matching mine-middle
panorama, authored rock/timber terrain and a 16-piece matching alpha sprite atlas.
Original source paintings remain in the repository. A parallax cavern backdrop,
foreground stalactites, hoists, pumps, gas pipes, resident and textured exit replace
the draft drawings. Decorative and checkpoint lights are removed; checkpoints
remain automatic. Nearby usable units display a round contextual key medallion.

The player renders the original HeroActionVisual red/green atlases and original
idle/run/jump/double-jump/landing/mineralization/hurt/respawn/slash motions, with
ActorGrounding contact shadows and real MeleeCombat. Physics remains local to
this chapter and unchanged. In particular, every climbing relay still requires
mineralization and expires normally.

Gas uses textured vapor, crystal ledges form with debris and fracture warnings,
the bridge sheds rotating crystal chunks, and acid uses a flowing foam shader.
The level-owned MineAudio supplies 13 layered effects plus separate looping
wind/drips/machinery and bowed-mineral music beds. It respects the shared SFX and
Music buses and mute settings, pauses with the level and stops on departure.
Legacy single-tone cues are suppressed only while this soundscape is present.

New artwork: `assets/art/generated/mine_challenge/mine_detail_atlas.png`.
Generation method and final prompt: `docs/mine-art-generation.json`.
Audio source and reproducible builder: `assets/audio/mine/build_audio.py`.
`tests/mine_polish_test.tscn` checks the actual artwork, original character,
rendering, audio and cleanup, and can save nine representative screenshots.
