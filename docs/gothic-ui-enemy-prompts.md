# 哥特 UI 与敌人动作生成记录

生成方式：内置 imagegen。原有角色与敌人图保留；新增纹理与逐帧图作为独立文件接入。

## scrap_scavenger

保存：`assets/art/generated/animations/scrap_scavenger_actions.png`

Use case: stylized-concept. Asset: production 2D side-scroller pixel-art enemy animation sprite sheet, exactly 1536x1024, exactly 6 columns and 4 rows of square 256x256 cells. Reference is identity/style reference. Face RIGHT in every frame, same scale and centered body anchor in each cell, feet on local baseline y236. Transparent background, no grid, no text, no frame numbers, no stray objects, every entire pose inside own cell. Preserve crisp dark outlined pixel art. Exactly 24 separate full-body poses in reading order: row1 six visibly different articulated walking cycle poses. Row2: idle breathe, idle exhale, attack crouch anticipation, attack raise, maximum windup, attack impact. Row3: followthrough, strike extension, recovery, hit recoil left, hit recoil right, stagger. Row4: deep crouch, jump rising stretch, fall tucked, landing squash, collapsing death, dead body. Animation must show clear joint articulation and changing silhouettes, not copies. Rusty claw beast: ivory horned mask, amber eye, rusty orange plates, dark metal limbs, exposed teal cable, barrel backpack. Attack raises claw/cannon then recoils. Physical mechanics, no laser.

## crystal_miner

保存：`assets/art/generated/animations/crystal_miner_actions.png`

Use case: stylized-concept. Asset: production 2D side-scroller pixel-art enemy animation sprite sheet, exactly 1536x1024, exactly 6 columns and 4 rows of square 256x256 cells. Reference is identity/style reference. Face RIGHT in every frame, same scale and centered body anchor in each cell, feet on local baseline y236. Transparent background, no grid, no text, no frame numbers, no stray objects, every entire pose inside own cell. Preserve crisp dark outlined pixel art. Exactly 24 separate full-body poses in reading order: row1 six visibly different articulated walking cycle poses. Row2: idle breathe, idle exhale, attack crouch anticipation, attack raise, maximum windup, attack impact. Row3: followthrough, strike extension, recovery, hit recoil left, hit recoil right, stagger. Row4: deep crouch, jump rising stretch, fall tucked, landing squash, collapsing death, dead body. Animation must show clear joint articulation and changing silhouettes, not copies. Rocky mining beast: ivory mask pink-red eyes, dark purple limbs, cyan crystals on back, pickaxe claws. Attack winds pick then sweeps forward.

## forest_crawler

保存：`assets/art/generated/animations/forest_crawler_actions.png`

Use case: stylized-concept. Asset: production 2D side-scroller pixel-art enemy animation sprite sheet, exactly 1536x1024, exactly 6 columns and 4 rows of square 256x256 cells. Reference is identity/style reference. Face RIGHT in every frame, same scale and centered body anchor in each cell, feet on local baseline y236. Transparent background, no grid, no text, no frame numbers, no stray objects, every entire pose inside own cell. Preserve crisp dark outlined pixel art. Exactly 24 separate full-body poses in reading order: row1 six visibly different articulated walking cycle poses. Row2: idle breathe, idle exhale, attack crouch anticipation, attack raise, maximum windup, attack impact. Row3: followthrough, strike extension, recovery, hit recoil left, hit recoil right, stagger. Row4: deep crouch, jump rising stretch, fall tucked, landing squash, collapsing death, dead body. Animation must show clear joint articulation and changing silhouettes, not copies. Mossy bark crawler: ivory bone mask, cyan eyes, bark limbs, green moss armor, fern antlers and orange mushrooms. Pounce with strong crouch, stretch and claw sweep.

## eden_warden

保存：`assets/art/generated/animations/eden_warden_actions.png`

Use case: stylized-concept. Asset: production 2D side-scroller pixel-art enemy animation sprite sheet, exactly 1536x1024, exactly 6 columns and 4 rows of square 256x256 cells. Reference is identity/style reference. Face RIGHT in every frame, same scale and centered body anchor in each cell, feet on local baseline y236. Transparent background, no grid, no text, no frame numbers, no stray objects, every entire pose inside own cell. Preserve crisp dark outlined pixel art. Exactly 24 separate full-body poses in reading order: row1 six visibly different articulated walking cycle poses. Row2: idle breathe, idle exhale, attack crouch anticipation, attack raise, maximum windup, attack impact. Row3: followthrough, strike extension, recovery, hit recoil left, hit recoil right, stagger. Row4: deep crouch, jump rising stretch, fall tucked, landing squash, collapsing death, dead body. Animation must show clear joint articulation and changing silhouettes, not copies. Create distinct large ancient Eden warden in this same pixel art style: broad bone and bark shoulders, imposing antler crown, broken tarnished gold armor, heavy root claws, moss. Heavy two-handed ground slam. Visually different from small crawler. No technological circuits.

## UI atlas

保存：`assets/art/generated/ui/gothic_atlas.png`

Use case: stylized-concept. Asset type: 2D gothic fantasy game UI reusable nine-slice texture atlas, exactly 1024x1024, four square 512x512 tiles in a precise 2x2 arrangement with no gap. Top-left: very dark warm charcoal basalt and worn leather, fine tarnished brass border, small carved leaf corner ornaments within 24 pixels of edge. Top-right: faded ivory aged parchment, quiet subtle fiber texture, fine brown ink border, restrained burned edges. Bottom-left: dark oxblood worn leather with fine aged brass border. Bottom-right: deep muted moss-green vellum, brass border and sparse ivy corners. Each tile is an empty quiet rectangular panel with no writing, no symbols in the center. Border thin and within 24px; all tiles completely opaque, no rounded corners. Subtle painterly pixel-art surface suited to dark metroidvania. Readability for UI text essential: calm low contrast interior. No lettering, no UI screenshot, no glow, no cyan, no sci-fi, no futuristic technology, no glass.
