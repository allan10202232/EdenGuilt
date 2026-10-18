# EdenGuilt

> 根目录现在是三关动作探索试玩版。此前从 main 合入的《地脉固化》独立原型保存在 [`prototype/`](prototype/)，操作见 [`prototype/试玩说明.md`](prototype/试玩说明.md)。

横版 2D 类恶魔城项目，Godot **4.7.2 / GDScript / GL Compatibility**。
三关动作探索、实时碳账本与能效仪表盘、污染反馈、双形态、结局 A/B 与玩家个人可持续行为审计报告。

## 本次更新

- **开场动画**：增加吸魂器、伊甸环城、地下矿区和主角拾取吸魂器四幕英文旁白；插画逐像素显现并以像素方式转场，最后一幕缓慢淡入。按 Enter 推进并进入游戏。
- **生命显示与受伤规则**：HUD 改为五颗绿色像素生命球；敌人、Boss、弹丸和危险机关每次有效命中扣半颗，并从右向左逐颗扣除。十次有效受伤耗尽生命，检查点回复一颗半，死亡后恢复五颗。
- **土地抽取与绿洲**：三关的四个能力点都放置独立绿洲；按 E 后播放取出装置、下蹲引流、举起充能和收起装置的六帧动作。绿色生命流汇入球形吸魂器，草木与泉水逐步枯竭，约 2.4 秒后获得能力。返程共同修复并交还对应能力时，绿洲恢复。

## 打开和试玩

在 Godot 导入根目录 `project.godot`，按 **F5**，先播放四幕英文像素开场。
每按一次 **Enter** 推进一句旁白：吸魂器 → 伊甸环城 → 地下矿区 → 拾起吸魂器；最后一句后按 Enter 直接进入第一关。
前三幕逐像素显现，第四幕缓慢淡入，幕间逐像素消散。长按 Enter 不会连续跳过旁白，转场期间不接受重复推进。
从死亡/结局界面返回主菜单后，可点击“开始游戏”直接重玩；重新运行项目会重播开场。

| 操作 | 输入 |
| --- | --- |
| 开场旁白 / 下一幕 / 开始游戏 | Enter（也支持小键盘 Enter） |
| 左右移动 | A / D 或 ← / → |
| 跳跃 / 已获得后的二段跳 | 空格 |
| 快跑 | 按住 Shift |
| 碳矿化 | C；靠近毒雾节点，或在空中前方生成临时晶台 |
| 护盾 | 按住 Q；一次最长 1.4 秒，松开即结束，施放间隔 2.2 秒 |
| 黑穿 | F；穿敌人和专用紫色暗壁，普通地形仍阻挡 |
| 已获得后的近身光刃 / 长距离光刃 | 鼠标左键 / 鼠标右键 |
| 学习 / 与居民修复并卸下能力 | 靠近能力源后按 E / R |
| 循环拆解 | 靠近回收箱按 V |
| 光刃 | 本试玩版开局提供；正式获取地点仍待设计 |

去程为 **垃圾场 → 毒雾矿场 → 伊甸园**。在出生地捡到地脉提取器，靠近能力源按 E 学习。
垃圾场是废铁中的草木绿洲，矿场是苔藓泉水，伊甸园的护盾和黑穿分别有自己的花草绿洲。
站稳后靠近绿洲按一次 E，主角停步下蹲，用吸魂器引出土地生命流，再举起装置充能。
动作完成才授予能力并记录枯竭状态；期间战斗和游戏计时暂停，重复按 E 不会重复抽取。
未抽取的绿洲保留绿色；死亡继续和跨关回访会保留每个点的状态，中途返回菜单会取消未完成的抽取。
技能实际生效才记碳排；空按、冷却拒绝和普通第一段跳不记。获得能力使生态白化，累计排放影响雾霾与怪物。

| 关卡 | 探索与战斗 |
| --- | --- |
| 垃圾场 · 3840 px | 出生地，二段跳 +5 kg；上下碎片支路、断崖、机械拾荒者 |
| 毒雾矿场 · 4080 px | 碳矿化 +1 kg；毒雾节点固定 CO₂、生成晶桥，晶矿兽与喷口 |
| 伊甸园 · 4400 px | 盾 +20 kg、黑穿 +200 kg；紫色暗壁、能源守卫、漂绿真相与选择 |

击败伊甸守卫，进入最右侧能源档案，发现 10% 净土依赖向城外转移污染与开采代价。
选择时游戏与计时暂停，不能被敌人偷袭：

- **A · 揭露真相、逆向循环**：救出 3 位居民，提取器改装为逆向循环核心，主角由红转绿。
  档案门口 R 先与居民打通公共通路，再向左返程，原能力源 R 共同修复并卸下能力；伊甸园两处能力源都要返回。
  修桥、铺坡、关闭危险和拆暗壁先于失去技能，最后从垃圾场左端回家。
- **B · 留在伊甸园**：保留红色形态与污染转移，直接进入另一份哲思结语和审计报告。

双形态转换目前设在 A 选择确认时，方便后续调整剧情节奏。右上小地图显示能力源、检查点和当前位置。

## 碳账本与个人审计

仪表盘显示永久累计 CO₂、单列已固定 CO₂、模拟污染负荷、即时有效能利用率、热负荷和释放节奏。
约 **0.75 ± 0.20 秒**的精准节奏可达 **95%** 能效；连续高频释放会过热，能效最低 **30%**，即废热 **70%**。
每次近战基础 +0.25 kg，全局间隔短于 0.5 秒的高频近战额外 +1.75 kg；冷却失败不记账。
默认模拟污染负荷到 80 kg 出现雾霾，220 kg 触发怪物狂暴，400 kg 进入重度污染。技能不会因“空蓝”被锁住。

两种结局都展示 **Sustainability Audit Report**：各关/技能排放图、总有效功/总输入能效、废热、精准/高频次数、
救援、共同修复、循环拆解、材料回收，以及注明依据的现实量级类比；自动保存 HTML 可视化、JSON 汇总与 CSV 逐次记录。
点击“打开审计报告”在浏览器阅读，默认目录为 Godot 的 `user://audits/`（可通过编辑器打开用户数据目录定位）。

所有技能排放、阈值、固碳和回收数值可在 [`assets/carbon_rules.tres`](assets/carbon_rules.tres) 的 Inspector 调整。
玩法与计算口径见 [碳系统设计](docs/carbon-system.md)。汽油类比使用 [EPA 的 8.887 kg CO₂ / 美制加仑](https://www.epa.gov/energy/greenhouse-gas-equivalencies-calculator-calculations-and-references)；
材料替代比属于教学假设。游戏数据类比不代表现实排放、抵销或经核查减排；修复不会抹去累计排放历史。

金色碎片各加 100 分；小怪一击击败加 50 分，Boss 加 500 分。
玩家生命显示为五颗绿色像素生命球；每次有效受伤扣半颗，从最右一颗开始，先扣半颗再扣完该颗，
之后轮到左边一颗。敌人接触、弹丸、Boss 和危险机关都遵守同一规则，十次有效受伤耗尽生命。
受伤有 0.85 秒无敌时间，护盾、冲刺和黑穿期间可防御；狂暴提升怪物移动和攻击频率。
点亮灯火保存检查点并回复一颗半生命球。死亡或坠落后，弹窗提供：

- **从检查点继续**：恢复生命；保留得分、能力、世界进度、碳账本、热负荷和已发生的环保行为。
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
Q/E/R 和 F 黑穿的映射已由用户确认；光刃在试玩版开局提供，正式获取/交还地点和战斗平衡仍待设计。
当前进度保存在内存中，不提供跨进程存档。满血恢复和保留得分属于文档未规定部分的临时实现策略。

## 美术目录

美工提供的三张原图统一保存在 [`assets/art/originals/`](assets/art/originals/)，原图内容不改动。
内置 image_gen 参考原图生成的三关背景、三类敌人、地形图集及角色透明版位于
[`assets/art/generated/`](assets/art/generated/)。分类和替换方式见 [美术资源说明](assets/art/README.md)，
角色红、绿双形态各有 24 帧：待机、跑步、跳跃、二段跳、下落、落地、短砍、长砍、举盾、施法、黑穿、受击和倒地。
近战动作跟随真实判定阶段，命中有刀光与火花；详见 [动作与回归记录](docs/character-actions.md)。
完整提示词见 [场景生成记录](docs/art-generation-prompts.md) 和 [动作生成记录](docs/character-action-prompts.md)。
开场四幅插画、参考图与完整提示词见 [开场美术记录](docs/opening-art-prompts.md)；
旁白和播放节奏集中在 `scripts/ui/opening_cinematic.gd`，入口为 `scenes/opening.tscn`。
绿洲插画和六帧吸取动作素材使用内置 image_gen 生成，提示词见 [土地抽取美术记录](docs/land-extraction-art.md)。
每个绿洲的状态表现位于 `scripts/presentation/campaign_oasis.gd`，动作流程与生命流位于 `scripts/presentation/land_extraction.gd`。

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

增加 `-Screenshots` 会启用真实渲染并保存开场、生命球、绿洲抽取、主菜单、HUD、死亡、三关、Boss、返程、胜利及近战和角色动作截图：

```powershell
.\tests\run-tests.ps1 -Godot 'C:\Tools\Godot_v4.7.2-stable_win64_console.exe' -Screenshots
```

也可直接运行：

```text
godot --headless --path . --editor --import --quit
godot --headless --path . --audio-driver Dummy res://tests/startup_test.tscn
godot --headless --path . --audio-driver Dummy res://tests/opening_test.tscn
godot --headless --path . --audio-driver Dummy res://tests/health_test.tscn
godot --headless --path . --audio-driver Dummy res://tests/extraction_test.tscn
godot --headless --path . --audio-driver Dummy res://tests/phase_one_test.tscn
godot --headless --path . --audio-driver Dummy res://tests/melee_test.tscn
godot --headless --path . --audio-driver Dummy res://tests/carbon/carbon_test.tscn
godot --headless --path . --audio-driver Dummy res://tests/campaign/campaign_test.tscn
godot --headless --path . --audio-driver Dummy --fixed-fps 60 res://tests/campaign/action_test.tscn
godot --headless --path . --audio-driver Dummy --fixed-fps 60 res://tests/campaign/route_test.tscn
godot --headless --path . --audio-driver Dummy --fixed-fps 60 res://tests/campaign/walkthrough_test.tscn
```

验收程序在检查失败、引擎错误或警告时返回非零退出码；仅允许引擎提示忽略 `prototype/` 嵌套工程的已知警告。
生成的导入缓存、日志和截图位于已忽略的 `.godot/`、`test-output/`。
当前无窗口回归共 653 项通过，包含开场、生命球、四处绿洲抽取、正常输入、真实伤害与敌人 AI 的 A/B 完整试玩；原有试玩记录见 [试玩与卡点检查](docs/walkthrough-review.md)。
开场另经真实渲染检查，98 项通过；已查看像素显现、英文长句、地下矿区与最后一幕淡入的实际截图。
开场验收覆盖八句旁白顺序、长按/转场输入、窗口缩放、四张图片加载，以及最后一次 Enter 仅启动一局游戏。
生命球另经真实渲染检查，32 项通过，覆盖满血、半球、空球、最后半球，以及十次受伤后的死亡和检查点恢复。
绿洲抽取另经真实渲染检查，81 项通过；已查看三种绿洲、下蹲与举起吸魂器、生命流、枯竭和共同修复的实际截图。
抽取验收覆盖动作完成前不授予能力、冻结期间的碰撞与计时、重复输入、Eden 两个绿洲独立状态、检查点回访和中途退出的取消处理。
HUD 持续显示当前目标；居民共建后的危险区解除，守卫在入口内被击败时也会正确触发真相剧情。
入口另经全新目录、不带 `.godot/` 缓存的导入与启动检查。

如果编辑器提示 `CarbonLedger not declared`，检查 Project Settings → Globals → Autoload 是否有
`CarbonLedger = res://autoload/carbon_ledger.gd` 且已启用。四个系统的注册均保存在根目录 `project.godot`。
编辑器已打开时，外部修改此文件应选择 **Reload from disk**，保留新的工程配置。
验收脚本会在启动前检查四项注册与脚本路径，缺失时直接报明原因。
