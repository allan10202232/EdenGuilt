# Contextual interaction affordances

`scripts/presentation/interaction_hints.gd` draws 38 px, dark bronze-and-gold
medallions with outlined key glyphs. The hint is anchored above its unit and
appears only inside the actual interaction radius. It disappears immediately
when leaving range, opening a modal, starting extraction or losing the action.

- T: nearby residents, the mine lever, Eden displays, elevator and the repaired exit.
- E: a grounded player at an unlearned oasis; the nearest active gas vent in
  mineralization range. Gas hints hide during cooldown and while crystallized.
- R: borrowed ability sources on the return journey; the Eden community archive.
- F: the nearby dark wall once Shadow Pierce is available.
- LMB: Eden's intact power conduit and the processing pod valve during its rescue.

The four-floor Eden uses this same medallion component for its own scene-local
interactions. The mine's new living seam offers E before learning and R on the
homeward journey; gas vents only offer a pulse once mineralization is acquired.

Checkpoint volumes remain functional without visible lights. Automatic exits
and pushable crates have no invented key binding. First-use movement/combat
tutorials and the settings reference remain available.

There are no money-like lantern, shard or biochar collectibles. The scrapyard's
upper path remains playable without awarding free score or carbon storage;
mineralization puzzle targets and the skill sources still serve their gameplay.

Attacking explicitly lowers a guard and clears stale impact pause; a held Q
cannot silently restart the same cancelled cast. Raising a guard cancels the
current attack. Moving or jumping with a guard uses the original locomotion
frames immediately, including during the raising transition. Releasing or
interrupting the guard clears that transient pose; holding Q through a full cast
still respects expiry and cooldown.

`tests/interactions_test.tscn` exercises proximity, consumed actions, narrative
gating, mine affordances and four real Eden shield/attack/jump cycles using
mouse/keyboard input. It is included in `tests/run-tests.ps1`.
