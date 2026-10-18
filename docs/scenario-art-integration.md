# 三关 Scenario 场景美术

第一关使用用户提供的 `Scenario1.png`（垃圾场），第二关使用 `Scenario2.jpg`（矿坑）。
第三关使用 main 的 `伊甸园1-2.jpeg`（伊甸城），归档为 `Scenario3.jpeg`。
原图复制到 `assets/art/originals/scenarios/`，保持原始文件内容不变；根目录提供的图片也保留。

## 背景

背景沿关卡横向推进采用“原图 → 同风格生成中段 → 原图”的连续画幅，交界处由绘制透明渐变过渡。
所有图片保持原比例，按窗口尺寸覆盖显示，关卡两端不出现空白。
像素图采用最近邻过滤。背景中的台子只是原画装饰；实际站立面来自可碰撞的前景平台。

## 平台与地面

使用内置 image_gen，以各自 Scenario 原图作为风格参考生成独立透明图集。
每套图集包含地表、填充、宽悬台、窄悬台；按实际透明边界配置采样区域，保证站立面与碰撞位置对齐。
垃圾场使用锈铁废料、轮胎与橄榄色苔藓；矿坑使用灰紫岩层、白色晶体、木板与木梁。
伊甸城使用象牙白雕花石阶、翠绿藤蔓、花卉和灯火，延续原画的花园城与瀑布远景。

地面、悬台、返程晶桥与斜坡沿用原有碰撞轮廓，视觉替换不改路线、技能、生命球和毒雾解谜条件。
采集技能造成的生态白化与返程绿化仍由现有生态系统控制。

原图和新增中段、图集分别由 `scripts/campaign/level_catalog.gd` 引用，绘制逻辑位于 `scripts/campaign/level.gd`。
完整生成提示词保存在 `docs/scenario-art-prompts.json`。

新增素材路径：

- `assets/art/generated/scenarios/junkyard_middle.png`
- `assets/art/generated/scenarios/mine_middle.png`
- `assets/art/generated/scenarios/junkyard_terrain.png`
- `assets/art/generated/scenarios/mine_terrain.png`
- `assets/art/generated/scenarios/eden_middle.png`
- `assets/art/generated/scenarios/eden_terrain.png`

## 从 main 拉取的原画

`e69145b` 增加了 `伊甸园1-2.jpeg`；已合入 Programmer-2-phase-1，本地一、二关的 39 个改动/未跟踪路径在合并时按 SHA-256 逐一核对，内容未丢失。
原始上传文件保留。新上传的 `scene 1 landfill.jpg` 实际是 PNG，与 `Scenario1.png` 字节相同；其 `.import` 使用 Godot 的 Keep File，避免按错误扩展名导入失败。
实际游戏继续引用有正确 PNG 扩展名的 Scenario1 归档，未转换或重绘任何原图。

## 验证

Godot 4.7.2 真实渲染已检查两关起点、中段、终点，在 1152×720 和 960×600 下共保存 12 张截图到 `test-output/scenarios/`。
暂停状态移动镜头或缩放窗口也会重绘背景，画幅边缘没有空白。最小窗口下生命球、语言与主菜单按钮均完整显示。

本次相关验收 434 项通过：启动 29、去返程地形 54、普通输入 A/B 99、剧情和毒素 37、战役 81、原系统 107、生命球 27。
A/B 全程 0 次死亡。原图归档副本与根目录原图 SHA-256 相同，四张生成图片已复制到项目内。

## 伊甸城补充验收

第三关原图 `Scenario3.jpeg` 与 main 的 `伊甸园1-2.jpeg` SHA-256 相同。
新增 `eden_middle.png` 与透明 `eden_terrain.png` 均由内置 image_gen 参考这张原图生成，并保存在游戏项目内。
透明石台按实际顶部位置采样，地面填充避开图集左右留白；第一、二关的采样范围不变。

真实渲染查看第三关入口、中段和守卫区域，在 1152×720、960×600 下共 6 张截图，文件为 `test-output/scenarios/eden-*.png`。
本轮相关验收 327 项、0 失败：启动 29、剧情/学习/毒素 37、三关战役 81、生命球 27、往返路线 54、普通输入 A/B 99；A/B 均 0 次死亡。
验收同时扫描控制台的错误和警告；生命球测试退出前等待音频混音线程释放 WAV 播放对象，消除退出时偶发的测试资源警告。
以上新增内容保存在本地 Programmer-2-phase-1 工作区，尚未推送。
