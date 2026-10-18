# EdenGuilt — Three-Minute Project Presentation

Three speakers, approximately one minute each. Each section contains about 120 words. Rehearse at a natural pace with short pauses; speaker labels and this timing note are not spoken.

## Speaker 1 — Story and Project Vision (0:00–1:00)

Hello everyone. Our project is EdenGuilt, a pixel-art, two-dimensional action adventure about the environmental cost of progress.

Players travel through three connected chapters: the Scrapyard, the Toxic Mine, and Eden City. They gain abilities by extracting energy from living land. Each new power opens another route, while the surrounding environment visibly loses its vitality.

Eden City initially appears to be a perfect green paradise. Later, players discover that its prosperity depends on displaced pollution and the exploitation of human life.

The ending presents two choices: stay in Eden and preserve that system, or expose the truth, rescue trapped residents, and return home to restore the damaged regions.

Our central question is: what does progress really cost, and who pays for it?

## Speaker 2 — Gameplay and Sustainability Systems (1:00–2:00)

The gameplay makes that question something players experience through their actions.

In the Scrapyard, players learn double jumping through industrial obstacles. In the Toxic Mine, they learn carbon mineralization: turning captured carbon dioxide into solid carbonate rock. Our game represents this process by transforming dangerous gas into temporary crystal platforms.

Players combine jumps, airborne mineralization, switches, and collapsing bridges across eight stages. Eden City then adds shield parries, phase dashes, and a final rescue route.

Behind the scenes, an event-based carbon ledger records successful skill uses, emissions, carbon storage, and energy efficiency. Totals appear only in the final Sustainability Audit Report, keeping exploration visually clear.

The report connects gameplay choices with environmental consequences. Its figures are educational simulations that help players reflect on their decisions.

## Speaker 3 — Technical Architecture and Validation (2:00–3:00)

We built EdenGuilt in Godot 4 using GDScript and reusable scene components.

The player controller uses CharacterBody2D, with jump buffering and coyote time to make movement more forgiving. Combat combines timed hitboxes, animation states, brief hit pauses, and sound feedback.

Signals connect gameplay events to shared systems that preserve health, abilities, and progress between chapters.

Our transition controller fades the screen, selects a named entrance, positions the camera, and prevents repeated loading. The open elevator uses AnimatableBody2D and Godot’s platform physics, so players can move and jump while riding.

We also use shaders for environmental changes and build the minimap from level geometry.

Finally, we verified the project with 1,490 automated checks, including room transitions, elevator behavior, and complete ending routes. Thank you.
