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
| `enemies/forest_crawler.png` | 透明苔藓爬兽 |
| `enemies/scrap_scavenger.png` | 透明机械拾荒者 |
| `enemies/crystal_miner.png` | 透明晶矿兽；Boss 复用放大版 |
| `characters/hero_red.png` | shape1 的透明背景版本 |
| `characters/hero_green.png` | shape2 的透明背景版本 |
| `terrain/biome_atlas.png` | 两列三行图集：森林、垃圾场、矿厂；左列地表，右列填充 |

PNG 透明通道已在 Godot 实际加载验证。角色与敌人使用 AtlasTexture 的有效像素区域裁边，源 PNG 不改写。
纹理使用最近邻过滤；前景碰撞来自关卡数据，背景中的装饰平台没有碰撞。

替换同路径 PNG 后重新导入即可。更改地形图集时维持 2 × 3 布局；图集左列顶部四分之一用作地表。
修改角色或敌人外观不会自动改变碰撞体：玩家 28×48，小怪 34×40，Boss 72×88 px，需要在玩法脚本单独调整。
现阶段角色与敌人为静态透明图，代码提供朝向、轻微摆动、受击与攻击预警；逐帧动画由后续美术接入。
