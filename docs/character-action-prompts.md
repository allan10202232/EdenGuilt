# 双形态逐帧动作生成记录

使用内置 `image_gen`，透明背景参数为 true；两张图各 1536×1024，六列四行。
参考图分别为 `assets/art/generated/characters/hero_red.png`、`hero_green.png`。
原始角色图与美工原画不覆盖。最终资源复制至：

- `assets/art/generated/animations/hero_red_actions.png`
- `assets/art/generated/animations/hero_green_actions.png`

## 红色形态提示词

```text
Use case: stylized-concept
Asset type: transparent 2D platformer character action sprite sheet.
Reference image: provided image is the existing hero identity and art style, not a sheet to preserve.
Primary request: create a production sprite sheet of this exact small masked horned knight with dark body, ivory mask, glowing eyes/chest and red cape. Face RIGHT in all frames. Crisp hand-drawn game art with bold dark contours.
Composition: exactly 6 equal columns by 4 equal rows, 24 cells, landscape canvas aspect 3:2. One complete pose per cell. No grid lines, no labels. Same character scale and consistent feet baseline within every cell; centered body, generous margins for weapon and cape. All cells stay independent, no overlapping neighboring cells.
Row 1 left to right: 6 distinct consecutive run-cycle poses with visibly alternating legs and arms, flowing cape.
Row 2 left to right: idle stance; idle breathing stance; upward jump with tucked knees; second air jump spinning tuck; falling with spread cape; landing crouch.
Row 3 left to right: short sword slash windup; short sword slash striking forward; short slash follow-through; long melee thrust windup; long sword thrust fully extended right; thrust recovery.
Row 4 left to right: shield raising gesture; braced shield holding gesture; carbon mineralization casting with downward outstretched hand; forward shadow pierce dash pose; hurt recoil; fallen defeated on ground.
Constraints: preserve reference identity, colors, horns and mask. Real limb and body pose changes, no merely repeated idle sprite. Transparent background with clean alpha. No scenery, text, watermark, bounding boxes, decorative panels or shadows on the background.
```

## 绿色形态提示词

```text
Use case: stylized-concept
Asset type: transparent 2D platformer character action sprite sheet.
Reference image: provided image is the existing hero identity and art style, not a sheet to preserve.
Primary request: create a production sprite sheet of this exact small masked horned knight with dark body, ivory mask, glowing eyes/chest and green cape. Face RIGHT in all frames. Crisp hand-drawn game art with bold dark contours.
Composition: exactly 6 equal columns by 4 equal rows, 24 cells, landscape canvas aspect 3:2. One complete pose per cell. No grid lines, no labels. Same character scale and consistent feet baseline within every cell; centered body, generous margins for weapon and cape. All cells stay independent, no overlapping neighboring cells.
Row 1 left to right: 6 distinct consecutive run-cycle poses with visibly alternating legs and arms, flowing cape.
Row 2 left to right: idle stance; idle breathing stance; upward jump with tucked knees; second air jump spinning tuck; falling with spread cape; landing crouch.
Row 3 left to right: short sword slash windup; short sword slash striking forward; short slash follow-through; long melee thrust windup; long sword thrust fully extended right; thrust recovery.
Row 4 left to right: shield raising gesture; braced shield holding gesture; carbon mineralization casting with downward outstretched hand; forward shadow pierce dash pose; hurt recoil; fallen defeated on ground.
Constraints: preserve reference identity, colors, horns and mask. Real limb and body pose changes, no merely repeated idle sprite. Transparent background with clean alpha. No scenery, text, watermark, bounding boxes, decorative panels or shadows on the background.
```
