# 图像生成记录

## eden_garden · 新版第三幕

参考既有森林背景与 shape1 原画，内置 image_gen，`transparent_background=false`。输出：`assets/art/generated/backgrounds/eden_garden.png`。

```text
Use case: stylized-concept. Production 2D side scrolling metroidvania background, 16:9 panoramic pixel art. Use the attached forest panorama and ivory masked chibi knight as STYLE REFERENCES only: crisp chunky pixels, dark outlines, layered depth. Create EDEN GARDEN, a falsely sustainable privileged city: warm sunlit ivory gothic greenhouse towers and elegant glass biodomes, lush emerald hanging gardens, pale gold sunbeams, immaculate sky bridges in the distance, apparently perfect eternal spring. Restrained hidden dark industrial intake pipes at the very bottom hint that this sanctuary runs on pollution exported elsewhere. Rich layered painterly PIXEL ART consistent with the reference, not smooth vector art or 3D. Side-on orthographic decorative backdrop only, clear central/lower gameplay area; no foreground gameplay floor, no characters, no enemies, no labels, no text, no UI, no watermark. Seam-friendly horizontal edges. Keep bright structure detail in distant planes, high readability for small characters.
```

使用 Codex 内置 image_gen，以 `assets/art/originals/` 原画为参考；输出复制至 `assets/art/generated/`。
角色仅请求背景透明化，其余为风格参考生成。所有角色/敌人调用使用 `transparent_background=true`，背景/地形为 `false`。
背景和地形参考矿洞 JPG 及两张角色 PNG；敌人参考两张角色 PNG；角色编辑仅引用各自原 PNG。

## forest_enemy

```text
Use case: stylized-concept. Asset type: transparent 2D game enemy sprite. The attached pictures are STYLE REFERENCES only. Create a NEW enemy matching their chunky crisp pixel art, thick near-black outline, strong readable chibi silhouette, ivory mask-like face, small vivid glowing eyes, limited palette. A single full-body side-view enemy facing LEFT, neutral walking-ready pose, centered, entire body visible with 10 percent padding, on a genuinely transparent background. No floor, shadows on a background, checkerboard, labels, UI, text or watermark. It must read well when displayed at 60 to 85 pixels tall in a side-scrolling metroidvania. Enemy: a low, hunched thornback forest crawler, beetle-like wooden body with four sturdy root legs, pale cracked bark face, luminous turquoise slit eyes, dark green moss plates and curled fern horns. Dangerous small woodland guardian, charming but hostile. Mostly earthy dark green and ivory with a few amber spores.
```

## junkyard_enemy

```text
Use case: stylized-concept. Asset type: transparent 2D game enemy sprite. The attached pictures are STYLE REFERENCES only. Create a NEW enemy matching their chunky crisp pixel art, thick near-black outline, strong readable chibi silhouette, ivory mask-like face, small vivid glowing eyes, limited palette. A single full-body side-view enemy facing LEFT, neutral walking-ready pose, centered, entire body visible with 10 percent padding, on a genuinely transparent background. No floor, shadows on a background, checkerboard, labels, UI, text or watermark. It must read well when displayed at 60 to 85 pixels tall in a side-scrolling metroidvania. Enemy: a squat scrap scavenger automaton, four crab-like mechanical legs and one oversized blunt metal claw, worn ivory faceplate, hot amber single eye, rust-orange armor made of discarded machine parts and trailing teal wire. Strong compact side-view silhouette. Small robot for an abandoned junkyard.
```

## mine_enemy

```text
Use case: stylized-concept. Asset type: transparent 2D game enemy sprite. The attached pictures are STYLE REFERENCES only. Create a NEW enemy matching their chunky crisp pixel art, thick near-black outline, strong readable chibi silhouette, ivory mask-like face, small vivid glowing eyes, limited palette. A single full-body side-view enemy facing LEFT, neutral walking-ready pose, centered, entire body visible with 10 percent padding, on a genuinely transparent background. No floor, shadows on a background, checkerboard, labels, UI, text or watermark. It must read well when displayed at 60 to 85 pixels tall in a side-scrolling metroidvania. Enemy: a heavy crystal-armored mining creature, squat quadruped made of coal-black rock and ivory bony plates, bright cyan crystal growths along shoulders and back, violet shadows, two small red eyes, pick-shaped rocky forelimbs. Side-on small cave monster, imposing when scaled up as a mine foreman boss.
```

## hero_red

```text
Use case: background-extraction. Asset type: transparent game character cutout. Edit the supplied artwork: remove ONLY its off-white background, making it genuinely transparent. Preserve the existing entire red-horned ivory-mask knight pixel-for-pixel in appearance: exact original proportions, horn shapes, red eyes, red cape, chest jewel, black outline, pixel-art shading and centered framing. Do not redesign the face, costume or pose. Keep the full character and its feet visible; no shadow, added objects, text, frame or watermark. Clean alpha edges.
```

## hero_green

```text
Use case: background-extraction. Asset type: transparent game character cutout. Edit the supplied artwork: remove ONLY its white background, making it genuinely transparent. Preserve the entire original green leaf-horned ivory-mask forest knight: exact original silhouette, green foliage, cyan eyes, glowing green chest emblem, black outline and chunky pixel-art shading. Do not redesign the face, costume, emblem or pose. Keep the full character and its feet visible, centered; no shadow, added objects, text, frame or watermark. Clean alpha edges.
```

## terrain_atlas

```text
Use case: stylized-concept. Asset type: a production pixel-art terrain texture atlas for a side-scrolling metroidvania. Match attached environmental pixel-art reference and character palettes, chunky crisp pixels and near-black outlines. Make one exactly aligned 2-column by 3-row texture atlas, portrait 2:3 aspect ratio, ideally 1024x1536. Six equal square cells with NO gaps, borders, padding, labels or text. Each cell completely filled to its edges with the requested terrain, not isolated floating objects. Top row FOREST: left is mossy grass-topped dark stone ledge with green roots on its top 15 percent and stratified soil/stone below; right is matching dark cracked earth/rock fill. Middle row JUNKYARD: left is a rust-orange steel platform surface with bolts, riveted dark plates below; right is matching rusted charcoal scrap metal fill. Bottom row MINE: left is blue-violet cut stone platform surface with tiny cyan crystal flecks at its top 15 percent; right is matching dark violet coal rock fill with occasional subtle turquoise veins. Orthographic flat side view, no perspective, even lighting; each cell should horizontally tile. No characters, floor shadows, UI, logos or watermark.
```


## forest_background

```text
Use case: stylized-concept. Asset type: production 2D side-scrolling metroidvania parallax BACKGROUND. Reference image 1 is environmental pixel art mood, images 2 and 3 are character style references only, do not place these characters in the scene. Match their crisp chunky pixels, dark near-black outlines, limited dramatic palette and ivory/red/green highlights. Side-on orthographic view, panoramic 16:9, 1536x864 or larger. Beautiful cohesive pixel art, low detail and darkness in the lower central gameplay area so characters and platforms will read. Background scenery only; no characters, enemies, foreground gameplay floor, HUD, text, logos or watermarks. Seam-friendly left/right edges for horizontal parallax repetition. Level 01 FOREST: ancient overgrown twilight woodland, gigantic twisting trees, layers of emerald and teal foliage receding into blue mist, tiny pale fungal lights, hanging roots and abandoned pointed stone arches. Muted moonlight through dense canopy. Rich adventurous dark fantasy forest, distant ruined gate with restrained ivory highlights. Keep large trunks in distant planes, readable clear midground.
```

## junkyard_background

```text
Use case: stylized-concept. Asset type: production 2D side-scrolling metroidvania parallax BACKGROUND. Reference image 1 is environmental pixel art mood, images 2 and 3 are character style references only, do not place these characters in the scene. Match their crisp chunky pixels, dark near-black outlines, limited dramatic palette and ivory/red/green highlights. Side-on orthographic view, panoramic 16:9, 1536x864 or larger. Beautiful cohesive pixel art, low detail and darkness in the lower central gameplay area so characters and platforms will read. Background scenery only; no characters, enemies, foreground gameplay floor, HUD, text, logos or watermarks. Seam-friendly left/right edges for horizontal parallax repetition. Level 02 JUNKYARD: sprawling mechanical graveyard at smoky dusk, heaps of dead robots, stacked rusted car bodies and broken factory silhouettes, sagging cables and a distant crane. Oxidized orange and ochre metal, charcoal shadows, muted petrol-teal haze, tiny amber furnace lights. Far industrial skyline. Same dark fantasy pixel-world as the forest; readable open midground.
```

## mine_background

```text
Use case: stylized-concept. Asset type: production 2D side-scrolling metroidvania parallax BACKGROUND. Reference image 1 is environmental pixel art mood, images 2 and 3 are character style references only, do not place these characters in the scene. Match their crisp chunky pixels, dark near-black outlines, limited dramatic palette and ivory/red/green highlights. Side-on orthographic view, panoramic 16:9, 1536x864 or larger. Beautiful cohesive pixel art, low detail and darkness in the lower central gameplay area so characters and platforms will read. Background scenery only; no characters, enemies, foreground gameplay floor, HUD, text, logos or watermarks. Seam-friendly left/right edges for horizontal parallax repetition. Level 03 MINE FACTORY: underground mining foundry inside enormous rock vaults, layers of violet-black stone, cyan glowing crystal veins, abandoned rails and ore lifts, iron gantries, distant smelter vents with restrained orange glow. Strong blue-violet depth and wisps of fog. Gothic industrial cavern, side-on background only; open readable midground.
```
