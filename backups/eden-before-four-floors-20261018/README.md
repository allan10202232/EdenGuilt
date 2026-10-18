# Eden backup before the four-floor chapter

`eden_city.tscn` is the former horizontal production scene, before its alias was
changed to the new four-floor chapter. `level.gd` is a copy of the then-current
shared campaign implementation, including the previous session's fall policy.
The other chapters continue using the live shared implementation.

`.gdignore` prevents this archive registering duplicate Godot classes. The
historical controller/geometry regression scene remains runnable through
`tests/fixtures/legacy_eden_room.tscn`; production uses `scenes/eden/eden_chapter.tscn`.
