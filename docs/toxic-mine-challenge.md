# Level 2 — Toxic Mine Challenge

Open `scenes/mine_challenge/toxic_mine_challenge.tscn` and press **F6** for a
standalone run. Starting the campaign normally also loads this scene after the
Junkyard, through `scenes/campaign/toxic_mine.tscn`. The summit summary continues
to Eden City. All character, terrain, prop and sound assets are bundled; no paid
assets or external downloads are required.

## Controls

- A/D or arrows: move, 260 px/s. Space: jump; press again in midair for Double Jump.
- E at the entrance's glowing ore seam: a 2.4 s extraction animation unlocks mineralization. It is no longer granted automatically.
- E or J after extraction: 260 px mineralization pulse, 0.6 s cooldown. C remains a compatibility alias.
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

Acid begins at Y=2050. A fall deducts one full life vessel (20 HP) from the
current health. If any health remains, the player returns to the safe deck after
0.2 s without healing, clearing transient platforms and resetting the bridge. Stage progress, valves,
lever state and captured-carbon totals survive checkpoint reloads. A new run
clears them. Checkpoint triggers must be reached in order; the bridge checkpoint
also requires the lever to be active.

The main gas lever now latches after opening: repeated T or melee clicks cannot
shut off the cliff route. Walking off the upper balcony can bypass the drop
hatch and its stage-6 trigger. If a player who has reached stage 5 or 6 physically
enters the stage-7 cliff ledge, its backup supply restores the gas and records
the crossed bridge checkpoint before enabling stage 7. Remote stage-skip calls
remain rejected. The return trip keeps the gas off.

`试玩第二关供气修复.cmd` / `scenes/mine_challenge/play_cliff_check.tscn`
previews the reported ledge with the stale stage-5 state, exercising the real
recovery instead of directly enabling its gas.

All three chapters now share the mine-style `ChapterStatusHUD`: five green life
vessels, stage, double-jump availability, skill cooldown, gross emissions and
stored carbon. Entry preserves the previous chapter's health; each 10 HP gas
hit removes half a vessel. Checkpoints and automatic fall retries do not heal.
Reaching zero from damage or falls opens Game Over. Only a deliberate continue
or a new run restores health. The homeward exit derives its destination from
the current Junkyard exit, including the six-section layout.

The entrance life source is a damp ore seam at X=420, built from the mine's
existing rock/ore atlas with pale blue-green lichen veins rather than garden
grass and water. Extraction reuses the original six-frame device/kneeling
animation and energy flow. Its light fades gradually; only completion unlocks
the pulse. Movement, hazards and game time pause during the action. Repeated
interaction cannot grant the skill twice; depletion persists across retries and
revisits. The A return restores the seam while returning mineralization.

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
`life_seam.gd` provides the mine-specific source artwork and text;
`LandExtraction` provides the shared action and completion/cancellation rules.

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

`tests/mine_supply_recovery_test.tscn` adds 16 regression checks for the exact
stage-5 HUD / stage-7 ledge mismatch, visible gas, repeat lever interaction,
mineralization, falls, Game Over continue, return safety and new-run reset. It
also saves `test-output/screenshots/mine-cliff-supply-recovered.png` with
`--screenshots` for actual rendering inspection.

Older actor/oasis tests explicitly use `tests/fixtures/legacy_mineralization_room.tscn`.
That fixture is not the production level; it preserves coverage of the original
controller and extraction systems used elsewhere in the game.

## Finished presentation pass

The playable route retains its geometry, timings and 25 gas-based footholds.
The mine now uses the unchanged original Scenario2 painting plus the existing
mine-middle panorama, authored rock/timber terrain and a new 16-piece matching
alpha sprite atlas. A parallax cavern backdrop, foreground stalactites, lanterns,
hoists, pumps, gas pipes, resident and textured exit replace the draft drawings.

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
