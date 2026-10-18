# 美术资源

## 原画 originals/

这里集中存放用户/美工提供的图片，保留原文件内容：

| 文件 | 用途 |
| --- | --- |
| `main character shape1.png` | 红色面具骑士，去程主角造型参考 |
| `main character shape2.png` | 绿色森林精灵，返程主角与能力源参考 |
| `11461792281823_.pic.jpg` | 像素矿洞、木架和晶体的环境参考 |

原根目录的两张角色图此前已改名为 shape1/shape2，本次沿用这两个文件名并集中到这里。
原画不直接做透明化或重绘；版权和作者署名仍按美工提供的信息维护，不自动补写作者。

## 生成素材 generated/

使用 Codex 内置 image_gen，以原画为图像参考。详细提示词和约束见 [生成记录](../../docs/art-generation-prompts.md)。

| 路径 | 内容 |
| --- | --- |
| `backgrounds/forest.png` | 绿青色古林和废墟，横向视差背景 |
| `backgrounds/junkyard.png` | 橙锈色机械墓场，横向视差背景 |
| `backgrounds/mine.png` | 蓝紫晶矿与冶炼厂，横向视差背景 |
| `backgrounds/eden_garden.png` | 新版伊甸园：明亮温室与白金高塔，底部暗藏工业管线；内置 image_gen 参考旧素材生成 |
| `enemies/forest_crawler.png` | 透明苔藓爬兽 |
| `enemies/scrap_scavenger.png` | 透明机械拾荒者 |
| `enemies/crystal_miner.png` | 透明晶矿兽，现用于毒雾矿场 |
| `characters/hero_red.png` | shape1 的透明背景版本 |
| `characters/hero_green.png` | shape2 的透明背景版本 |
| `animations/hero_red_actions.png` | 红色形态 24 帧动作，6×4 格 |
| `animations/hero_green_actions.png` | 绿色形态 24 帧动作，6×4 格 |
| `terrain/biome_atlas.png` | 两列三行图集：森林、垃圾场、矿厂；左列地表，右列填充 |
| `opening/soul_extractor.png` | 开场第一幕：球形吸魂器 |
| `opening/eden_city.png` | 开场第二幕：结晶荒漠之上的伊甸环城 |
| `opening/undercity.png` | 开场第三幕：地下死土矿区与聚落 |
| `opening/discovery.png` | 开场第四幕：红色形态主角拾起吸魂器 |

PNG 透明通道已在 Godot 实际加载验证。角色与敌人使用 AtlasTexture 的有效像素区域裁边，源 PNG 不改写。
纹理使用最近邻过滤；前景碰撞来自关卡数据，背景中的装饰平台没有碰撞。

替换同路径 PNG 后重新导入即可。更改地形图集时维持 2 × 3 布局；图集左列顶部四分之一用作地表。
修改角色或敌人外观不会自动改变碰撞体：玩家 28×48，小怪 34×40，Boss 72×88 px，需要在玩法脚本单独调整。
主战役角色改用 24 帧动作图集；固定格取帧并按脚底基准校正位置，原透明单图仍供能力源与居民使用。
动作及帧布局见 [动作说明](../../docs/character-actions.md)，内置 image_gen 的完整提示词见 [动作生成记录](../../docs/character-action-prompts.md)。
敌人仍使用静态透明图，保留移动、受击与攻击预警反馈。

新版三关复用图集：垃圾场用第 2 行、矿场用第 3 行、伊甸园用第 1 行；伊甸守卫暂复用放大的苔藓兽。
原森林背景保留为可复用美术，不再作为第一关入口。

开场插画使用独立的像素显现/消散材质，不修改原图片。英文旁白由界面绘制，
不烘焙进插画；窗口缩放时保留图片比例和完整画面。参考图和提示词见 [开场美术记录](../../docs/opening-art-prompts.md)。
