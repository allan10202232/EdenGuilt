# Land extraction art

All four assets were created with the built-in image_gen tool. Original assets are preserved; the new transparent PNGs are copied into this project. Runtime effects and ecological changes are drawn separately in Godot.

## Integration and verification — 2026-10-18

Merged main commit `ca1095d` into `Programmer-2-phase-1`. The four ability sources now use `LandExtraction` instead of the previous `LearningRitual`; the six poses run for 2.4 seconds and commit the acquired ability and depleted oasis together. All three Scenario backgrounds, generated middle sections and matching platforms are preserved, along with the four-part opening, five life orbs, NPCs, toxin puzzle and A/B endings.

Extraction notices and oasis labels follow the English/Chinese selection, including language changes during the action. Changing language does not reset depletion. External health, score and terminal-state signals are ignored while extracting, alongside the existing movement, collision and clock guards. Cancelling via the main menu grants no ability; checkpoint reloads preserve completed extraction, and community repair restores each oasis independently.

Godot 4.7.2 / GL Compatibility verification:

- Final headless suites: **728 checks, 0 failures** — startup 29, story/bilingual 37, opening 86, health 27, extraction 73, phase one 107, melee 39, carbon 43, campaign 81, character actions 28, enemy actions 25, route 54, normal-input walkthrough 99.
- Normal-input A/B walkthrough: both endings reached with **0 deaths**.
- Real-render extraction suite: **91 checks, 0 failures**, including 18 saved screenshots. Inspected kneeling, raised extractor, life flow, each biome's depletion, restored Eden, and live Chinese labels.
- No script/runtime errors or cleanup warnings; editor import only emits the known warning that the historical nested `prototype/` project is skipped.

Commands: `tests/run-tests.ps1 -Godot <Godot console executable>` for the full suite; run `res://tests/extraction_test.tscn` with `--rendering-method gl_compatibility -- --screenshots` for rendered extraction checks. Logs and images are ignored under `test-output/`.

## Assets

- `assets/art/generated/oases/junkyard_oasis.png`
- `assets/art/generated/oases/mine_oasis.png`
- `assets/art/generated/oases/eden_oasis.png`
- `assets/art/generated/animations/hero_extract_actions.png`

## References

`WechatIMG1395.jpg` establishes the world and pixel-art treatment for the oases. `assets/art/originals/main character shape1.png` preserves the protagonist identity; `hero_red_actions.png` supplies animation style and body proportions. References are not edited.

## Final prompts

### junkyard

Use case: stylized-concept. Asset type: transparent foreground oasis prop for the existing 2D side-scrolling pixel-art action game EdenGuilt. Create NEW artwork, references establish pixel clusters, palette and world only. A compact living island of grass and plants growing on a low flat oval mound, viewed from the side with a tiny amount of top surface visible; spread wide, about 2.2 times wider than tall. Roots/soil stay in a low thin base, no large floating-island underside. Local lush GREEN foliage, bright clean water, readable pixel clusters and stepped edges, dark outline and subtle muted shadows, detailed crisp pixel art suited to a high-quality game. All foliage stays inside frame, separate clean silhouette, generous transparent margins, genuinely transparent alpha background. Ground contact baseline uniform near lower 85% of canvas. No humans, spirits, character, buildings, UI, text, labels, borders or lettering. Subject: a stubborn miniature oasis amid small rusted scrap fragments. Fresh grasses and tiny white and yellow flowers, two bushy leafy saplings growing through an old broken metal ring, a shallow clear turquoise puddle between them, healthy rich dark soil and a few small mossy stones. Main sapling to one side; keep center low so a player can stand there visibly. Organic vegetation dominates the scrap. This surviving pocket must look much more alive than the rusty wasteland around it.

### mine

Use case: stylized-concept. Asset type: transparent foreground oasis prop for the existing 2D side-scrolling pixel-art action game EdenGuilt. Create NEW artwork, references establish pixel clusters, palette and world only. A compact living island of grass and plants growing on a low flat oval mound, viewed from the side with a tiny amount of top surface visible; spread wide, about 2.2 times wider than tall. Roots/soil stay in a low thin base, no large floating-island underside. Local lush GREEN foliage, bright clean water, readable pixel clusters and stepped edges, dark outline and subtle muted shadows, detailed crisp pixel art suited to a high-quality game. All foliage stays inside frame, separate clean silhouette, generous transparent margins, genuinely transparent alpha background. Ground contact baseline uniform near lower 85% of canvas. No humans, spirits, character, buildings, UI, text, labels, borders or lettering. Subject: an underground spring fed by a little trickle between small slate rocks. Abundant green moss, tiny ferns, a low young leafy tree on one side, a handful of small white crystals embedded only at the edges. Clear luminous blue-green shallow water is the focal center, gentle pale green firefly specks among the plants. Keep center low for a visible standing player. Healthy natural life in contrast to poisoned industrial mine.

### eden

Use case: stylized-concept. Asset type: transparent foreground oasis prop for the existing 2D side-scrolling pixel-art action game EdenGuilt. Create NEW artwork, references establish pixel clusters, palette and world only. A compact living island of grass and plants growing on a low flat oval mound, viewed from the side with a tiny amount of top surface visible; spread wide, about 2.2 times wider than tall. Roots/soil stay in a low thin base, no large floating-island underside. Local lush GREEN foliage, bright clean water, readable pixel clusters and stepped edges, dark outline and subtle muted shadows, detailed crisp pixel art suited to a high-quality game. All foliage stays inside frame, separate clean silhouette, generous transparent margins, genuinely transparent alpha background. Ground contact baseline uniform near lower 85% of canvas. No humans, spirits, character, buildings, UI, text, labels, borders or lettering. Subject: an especially vibrant untamed garden bed, with thick fresh grass, two low leafy bushes, clusters of pale gold and white wildflowers, ivy, and a tiny clean turquoise pool. A few weathered pale stone border fragments only at edges, plants visibly growing freely over them. Focal living sapling on one side; center remains low so a standing player can be seen. Lush natural green should stand out even within the artificially maintained ring-city garden.

### hero_extract

Use case: stylized-concept. Asset type: an actual transparent animation sprite sheet for EdenGuilt. Create NEW poses of EXACT same pixel-art protagonist as reference1; reference2 is only existing sprite style, body proportions, and facing reference. Preserve bone-white mask with dark central division, tall crimson ear-horns, red glowing eyes, ragged ivory cloak with crimson edges, dark short limbs, red chest gem. CRISP PIXEL ART, no smooth illustration. Exactly SIX full-body sprites on a perfectly regular 3-column by 2-row grid. Landscape 3:2 canvas, ideally1536x1024; each cell square, no grid lines, zero overlap or clipping, same character scale and fixed foot baseline around85% of each cell. All sprites face RIGHT in side/three-quarter view. Isolated sprites on genuinely transparent background, no scenery, no panel boxes, NO ground, no text/numbers/UI/watermarks. Frame order reading left-right top-bottom: (1) standing reaching for a small spherical bronze-and-green Soul Extractor at belt; (2) crouching slightly, taking the orb in both hands in front of chest; (3) kneeling with the orb lowered near ground, arms extended, looking down; (4) kneeling raising orb toward chest, cape lifts slightly as green life energy streams into it; (5) standing holding glowing sphere in hands before chest, leaning back slightly with force; (6) lowering the now charged sphere, returning toward a standing ready pose. Handheld sphere bronze/steel bands around GREEN glass core; size roughly one quarter of mask width. Small green light accents near hands only, no large baked beam or ground; runtime adds those. Keep silhouettes legible at 80px character height. Foremost priority fixed identity and consistent body baseline; six DIFFERENT visible extraction poses, not repeated idles.
