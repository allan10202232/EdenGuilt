# EdenGuilt

> 根目录现在是三关动作探索试玩版。此前从 main 合入的《地脉固化》独立原型保存在 [`prototype/`](prototype/)，操作见 [`prototype/试玩说明.md`](prototype/试玩说明.md)。

横版 2D 类恶魔城项目，Godot **4.7.2 / GDScript / GL Compatibility**。
保留程序员 B 的流程、HUD、音频、能力与进度接口，加入三张独立地图、同风格敌人和往返探索路线。

## 打开和试玩

在 Godot 导入根目录 `project.godot`，按 **F5**，点击“开始游戏”。

| 操作 | 输入 |
| --- | --- |
| 左右移动 | A / D 或 ← / → |
| 跳跃 / 已获得后的二段跳 | 空格 |
| 快跑 / 已获得后的冲刺 | 按住 Shift / 按下 Shift |
| 已获得后的护盾 | 按住 Q |
| 已获得后的近身光刃 / 长距离光刃 | 鼠标左键 / 鼠标右键 |
| 吸收 / 交还 | 靠近能力源后按 E / R |
| 光刃 | 本试玩版开局提供；正式获取地点仍待设计 |

去程为 **森林 → 垃圾场 → 矿厂**。靠近绿色精灵按 E，依次获得二段跳、冲刺、护盾。
吸收后土地变荒芜；能力可以打开本关的封锁。各关最右侧门通往下一关，左右入口允许回溯。

| 关卡 | 探索与战斗 |
| --- | --- |
| 森林 · 3840 px | 树冠碎片、谷底支路、二段跳断崖、5 只苔藓爬兽 |
| 垃圾场 · 4080 px | 废铁高架、冲刺缺口、预警电弧、6 只会射击的机械拾荒者 |
| 矿厂 · 4400 px | 晶矿竖井、蒸汽喷口、5 只晶矿兽、6 HP 晶甲监工 Boss |

击败矿厂监工后进入最右侧救援舱，三名伙伴开始跟随，主角切换绿色形态。
向左返程，在三个原能力源按 R 交还能力；桥梁、坡道和关闭的危险喷口让失去能力后的路线仍可通过。
交还三种能力后，从森林最左端回家，触发胜利。右上小地图显示当前地图、能力源、检查点和位置。

金色碎片各加 100 分；小怪一击击败加 50 分，Boss 加 500 分。尖刺和喷口扣 20 生命，
小怪接触/弹丸扣 15，Boss 接触扣 25、范围攻击扣 30。伤害有短暂无敌，护盾和冲刺可防御。
点亮灯火保存检查点并回复 30 生命。死亡或坠落后，弹窗提供：

- **从检查点继续**：回到最近灯火或场景入口，恢复生命；保留得分、能力、交还状态、已击败怪物和已拾取碎片。
- **重新开始整局**：重置全部本局进度。
- **返回主菜单**：结束当前游玩；下次开始建立新的一局。

## 阶段一交付

- [x] 主菜单、场景切换、死亡/胜利结算、检查点继续和整局重开。
- [x] 血量、得分、四种能力、护盾状态、地区/土地/检查点的信号驱动 HUD。
- [x] 获得/交还能力与去程/返程的世界状态，光刃交还前检查撤离通路确认。
- [x] 跨场景及死亡后的怪物不刷新、碎片不重复计分。
- [x] SoundManager 的音效池、BGM、音量、静音及能力/检查点事件接口。
- [x] 真实 UI 输入、物理碰撞、跨场景及检查点恢复的自动化验收。

三关使用独立地形、背景、敌人、检查点和返程路线。原几何验证房仍保留，自动化测试使用 `campaign_mode=false`。
Q/E/R 的映射已由用户确认；光刃在试玩版开局提供，正式获取/交还地点和战斗平衡仍待设计。
当前进度保存在内存中，不提供跨进程存档。满血恢复和保留得分属于文档未规定部分的临时实现策略。

## 美术目录

美工提供的三张原图统一保存在 [`assets/art/originals/`](assets/art/originals/)，原图内容不改动。
内置 image_gen 参考原图生成的三关背景、三类敌人、地形图集及角色透明版位于
[`assets/art/generated/`](assets/art/generated/)。分类和替换方式见 [美术资源说明](assets/art/README.md)，
完整提示词见 [生成记录](docs/art-generation-prompts.md)。角色目前使用静态图的位移/倾斜反馈，尚无逐帧动作动画。

## 近战攻击模板

主菜单点击 **近战模板测试**，可以直接试玩。也可在编辑器打开 `scenes/combat/melee_demo.tscn` 按 F6。
该测试房自动开启试用光刃，提供重置按钮和 3 HP 木桩，便于比较两种攻击。

| 模板 | 输入 | 判定长度 / 高度 | 前摇 / 生效 / 后摇 / 冷却 |
| --- | --- | --- | --- |
| `scenes/combat/close_melee.tscn` | 左键 | 80 / 72 px | 0.06 / 0.10 / 0.16 / 0.12 秒 |
| `scenes/combat/reach_melee.tscn` | 右键 | 180 / 42 px | 0.18 / 0.14 / 0.30 / 0.30 秒 |

两者都是跟随角色的近战判定。默认每刀伤害为 1，三关普通小怪一击倒、Boss 需要 6 次命中；
攻击范围、伤害、击退参数和时间在 `assets/combat/*.tres` 中调整。
组件支持朝向、前后摇、冷却、同一目标去重、墙体遮挡和能力失效中断。
复制场景/资源和接入正式角色的步骤见 [近战模板说明](docs/melee-templates.md)。

详细接口见 [程序员 B 交接文档](docs/programmer-b-phase-one.md)和[能力与检查点接入说明](docs/ability-system.md)。

## 自动化验收

在仓库目录运行（替换为本机的 Godot 控制台程序路径）：

```powershell
.\tests\run-tests.ps1 -Godot 'C:\Tools\Godot_v4.7.2-stable_win64_console.exe'
```

增加 `-Screenshots` 会启用真实渲染并保存主菜单、HUD、死亡、三关、Boss、返程、胜利及近战模板截图：

```powershell
.\tests\run-tests.ps1 -Godot 'C:\Tools\Godot_v4.7.2-stable_win64_console.exe' -Screenshots
```

也可直接运行：

```text
godot --headless --path . --editor --import --quit
godot --headless --path . --audio-driver Dummy res://tests/phase_one_test.tscn
godot --headless --path . --audio-driver Dummy res://tests/melee_test.tscn
godot --headless --path . --audio-driver Dummy res://tests/campaign/campaign_test.tscn
```

验收程序在检查失败、引擎错误或警告时返回非零退出码；仅允许引擎提示忽略 `prototype/` 嵌套工程的已知警告。
生成的导入缓存、日志和截图位于已忽略的 `.godot/`、`test-output/`。
