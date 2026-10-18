# EdenGuilt

> 根目录现在是三关动作探索试玩版。此前从 main 合入的《地脉固化》独立原型保存在 [`prototype/`](prototype/)，操作见 [`prototype/试玩说明.md`](prototype/试玩说明.md)。

横版 2D 类恶魔城项目，Godot **4.7.2 / GDScript / GL Compatibility**。
三关动作探索、实时碳账本与能效仪表盘、污染反馈、双形态、结局 A/B 与玩家个人可持续行为审计报告。

第一关垃圾场直接使用 `Scenario1.png`，第二关毒雾矿坑直接使用 `Scenario2.jpg`；中段背景、地面与悬台以原图为参考生成。
第三关下两层使用用户提供的 `Eden 1-2.jpeg`，上两层切换到 `scene 03bg.jpeg` 的人体处理穹顶；平台采用对应的藤蔓白石和处理厂走道。
素材与衔接方式见 [场景美术整合](docs/scenario-art-integration.md)。

## 本次更新

- **主菜单语言与字号**：左侧文案完整跟随英文 / 中文设置切换，修复英文模式残留中文；标题、正文、说明使用固定字号并自动换行。
- **垃圾场酸水**：新增像素波面、泡沫、上浮气泡和水深流动纹理，水体延伸至镜头外，消除平直色块底边；坠落判定保持不变。
- **伊甸战斗与返程修复**：恢复右键重击，护盾改用 Q / K；攻击判定框隐藏，保留刀光。Boss 冲锋朝向、动作衔接、破防提示与受击反馈同步完善，核心暴露 20 秒、撞墙反击窗口 5.4 秒。修复弹反后角色和刀光永久卡帧；救齐三人后，入口常驻提示先 R 修复交还、再 T 回矿坑。可用 [`试玩第三关Boss修复.cmd`](试玩第三关Boss修复.cmd) 直接检查最终战。
- **矿坑第七段供气修复**：主拉杆开启后保持供气，重复 T / 左键不会再次关闭；从第五段绕落到第七段时，末端供气和漏过的检查点自动恢复，HUD 同步到第七段。可双击 [`试玩第二关供气修复.cmd`](试玩第二关供气修复.cmd) 直接检查截图位置。
- **第三关四层 EDEN**：按新流程图搭建 01–12 节点，由天堂入口、荣升花园上升到人体处理厂、生命熔炉；接入用户两张原画、盾能量与精准弹反、黑冲穿墙、净园执事和三阶段核心战。循环结局需亲自下降救出三只培养舱，回入口共同修复后继续矿坑 / 垃圾场返程。详见 [第三关结构与操作](docs/eden-four-floors.md)。
- **第三关整合验证**：最新 EDEN 功能专项 **76 项通过**、连续输入全程 **77 项通过**，均为 0 失败，覆盖四层上升、三阶段核心、三舱救援、弹反后动画恢复与 R → T 返程。界面、抽取和培养舱另经 GL 实际渲染检查。详见 [第三关验证](docs/eden-four-floors.md) 与 [统一状态面板](docs/chapter-status-and-fall-recovery.md)。
- **第一关六段跑酷重做**：垃圾场扩展至 9600 px，依次包含塌台、传送带、废料高塔、磁力吊机双路线、液压机和最终逃脱；加入五类可复用机关、六个即时重生检查点、空中跳跃状态与死亡计数。第一关使用指定的 260 / 980 / -420 / -380 运动参数，离地宽限与输入缓冲各 0.12 秒。详见 [第一关结构与试玩](docs/scrapyard-parkour.md)。
- **压机难度与场景融合**：压机两次下砸间隔由 2.25 s 延长至 4.5 s，增加抬起后的安全等待；只有底部齿面判伤，侧面与机壳接触安全。全部平台复用垃圾场像素废料材质，配合旧家电、锈铁链条和旧警示漆，保留塌台预警和传送带方向提示。
- **开场动画**：增加吸魂器、伊甸环城、地下矿区和主角拾取吸魂器四幕英文旁白；插画逐像素显现并以像素方式转场，最后一幕缓慢淡入。按 Enter 推进并进入游戏。
- **三关统一状态面板**：左上角统一采用第二关的面板布局，显示五颗绿色生命球、段落、二段跳、能力冷却、累计排放和碳固定。三关共用同一个组件和全局账本；修改前的界面、脚本和主题完整保存在 [`backups/hud-before-unification-20261018/`](backups/hud-before-unification-20261018/README.md)。
- **坠落扣血与 Game Over**：普通有效命中扣半颗生命球；坠入酸池扣一整颗，保留此前伤势，非致命时立即回到当前检查点。检查点和自动重生均不补血，生命耗尽后进入 Game Over，由玩家选择继续或重开。
- **土地抽取与矿脉**：四个能力点均播放取出装置、下蹲引流、举起充能和收起装置的六帧动作，约 2.4 秒后获得能力。垃圾场和伊甸城保留绿洲，第二关改为与洞窟岩层、矿石和设备相融的微光苔藓矿脉；能量汇入吸魂器时矿脉逐渐失去微光。第二关不再开局自动授予矿化，需先在入口按 E 吸取；返程修复后恢复矿脉生机。
- **场景渐变与探索精简**：吸取期间背景、地面与场景物件同步逐步褪色，完成后保留荒芜滤镜；伊甸城两个能力点分两次加深，共同修复时平滑恢复。已删除黄色收集水晶、回收箱与 V 回收操作，HUD 保持原色。
- **动作与手感**：双形态补绘跑跳与六帧挥砍；加入攻击输入缓冲、轻重跳、命中停顿、轻微镜头反馈和六种战斗音效。角色与敌人统一像素采样，按地区染色，脚下阴影与前景草叶建立地面接触感。

## 打开和试玩

只试玩新第一关：双击 [`试玩第一关.cmd`](试玩第一关.cmd)，或在 Godot 打开 `scenes/parkour/play_scrapyard.tscn` 按 **F6**，直接开始新的一局。
直接检查压机和平台外观：双击 [`试玩压机调整.cmd`](试玩压机调整.cmd)，从第五段开始并预先获得二段跳。
只试玩第二关：双击 [`试玩第二关.cmd`](试玩第二关.cmd)，向右走到入口的微光矿脉，按 **E** 完成吸取，再用 **E / J / C** 固化毒雾。
只试玩新第三关：双击 [`试玩第三关.cmd`](试玩第三关.cmd)，从右下角天堂入口开始；已保留二段跳、矿化，护盾和黑冲需在本关吸取。左键轻击、右键重击，Q / K 持盾，Shift / L / F 黑冲，下 + 空格向下穿台。

在 Godot 导入根目录 `project.godot`，按 **F5**，先播放四幕英文像素开场。
每按一次 **Enter** 推进一句旁白：吸魂器 → 伊甸环城 → 地下矿区 → 拾起吸魂器；最后一句后按 Enter 直接进入第一关。
前三幕逐像素显现，第四幕缓慢淡入，幕间逐像素消散。长按 Enter 不会连续跳过旁白，转场期间不接受重复推进。
从死亡/结局界面返回主菜单后，可点击“开始游戏”直接重玩；重新运行项目会重播开场。
旧的菜单后三幕开场已被替换，不会在四幕开场后重复播放。游戏界面默认英文，可在菜单、HUD、对话或结算页选择 English / 简体中文，选择会保存。

| 操作 | 输入 |
| --- | --- |
| 开场旁白 / 下一幕 / 开始游戏 | Enter（也支持小键盘 Enter） |
| 左右移动 | A / D 或 ← / → |
| 跳跃 / 已获得后的二段跳 | 空格 |
| 跳跃高度 | 三个生产章节均为固定跳跃弧线；第一关二段跳 -380，第二、三关 -390 |
| 移动速度 | 三关基础速度 260；第一关二段跳短暂加速，第三关 Shift / L / F 黑冲 |
| 碳矿化 | 第二、三关 E / J / C，把毒雾转为临时晶台；能力源附近 E 优先吸取 |
| 护盾 / 弹反 | 第三关按住 Q / K，持续耗能；命中前 0.18 秒内起盾弹反 |
| 黑冲 | 第三关 Shift / L / F；穿过专用相位墙并免疫冲刺期间身体碰撞，普通地形仍阻挡 |
| 光刃攻击 | 鼠标左键轻击、右键长距离重击；攻击判定框在正式关卡隐藏 |
| 学习 / 与居民修复并卸下能力 | 靠近能力源后按 E / R |
| NPC 对话 | 靠近居民按 T；Enter / T 继续，Esc 结束 |
| 光刃 | 本试玩版开局提供；正式获取地点仍待设计 |

去程为 **垃圾场 Junkyard → 毒雾矿坑 Toxic Mine Pit → 伊甸城 Eden City**，三个独立场景、三关完整流程。
垃圾场是废铁中的草木绿洲，矿坑是岩层内的微光苔藓矿脉；伊甸花园提供护盾，人体处理层的维护根系提供黑冲。
站稳后靠近能力源按一次 E，主角停步下蹲，用吸魂器引出土地生命流，再举起装置充能。
动作完成才授予能力并记录枯竭状态；期间战斗和游戏计时暂停，重复按 E 不会重复抽取。
未抽取的绿洲保留绿色；死亡继续和跨关回访会保留每个点的状态，中途返回菜单会取消未完成的抽取。
技能实际生效才记碳排；空按、冷却拒绝和普通第一段跳不记。获得能力使生态白化，累计排放影响雾霾与怪物。

| 关卡 | 探索与战斗 |
| --- | --- |
| 垃圾场 · 9600 px | 六段废料跑酷，二段跳 +5 kg；磁铁上层回收生物炭奖励、分段即时重生、返程连续安全步道 |
| 毒雾矿坑 · 八段攀爬 | 入口矿脉吸取 → 毒雾晶台 → 重量开关 → 竖井 → 管线拉杆 → 塌桥 → 悬崖 → 出口；E / J / C 固化毒雾，有效批次单列固定 150 kg CO₂e |
| Eden · 四层 2400 × 2600 px | 盾 +20 kg、黑冲 +200 kg；十二节点、三灯弹反、净园执事、相位维护与气井、三阶段核心、下降救援三只培养舱 |

在伊甸四层拆除树心外的生命抽取装置，发现净土的春天依赖培养舱中的活人，以及向城外转移的污染与开采代价。目标是拆除机器、保留树。
选择时游戏与计时暂停，不能被敌人偷袭：

- **A · 揭露真相、逆向循环**：主角由红转绿，先从 4F 下降，亲自救出右上平台、处理厂和荣升电梯三只培养舱的居民，计数从 0 / 3 增至 3 / 3。
  回 1F 入口 R 共同修复并交还护盾、黑冲，T 回矿坑；再于矿脉交还矿化、垃圾场交还二段跳，带大家回家。
  修桥、铺坡、关闭危险和拆暗壁先于失去技能；Game Over 继续保留已救人数，循环模式不会自动算作救人。
- **B · 留在伊甸园**：保留红色形态与污染转移，直接进入另一份哲思结语和审计报告。

双形态转换设在 A 选择确认时。左上显示统一状态面板，第三关另显示盾能量、能力标记、节点、Boss 协议和培养舱救援计数。

## 碳账本与个人审计

三关左上角显示永久累计 CO₂ 和单列已固定 CO₂；账本另记录模拟污染负荷、即时有效能利用率、热负荷和释放节奏，并在结算审计中汇总。
约 **0.75 ± 0.20 秒**的精准节奏可达 **95%** 能效；连续高频释放会过热，能效最低 **30%**，即废热 **70%**。
每次近战基础 +0.25 kg，全局间隔短于 0.5 秒的高频近战额外 +1.75 kg；冷却失败不记账。
默认模拟污染负荷到 80 kg 出现雾霾，220 kg 触发怪物狂暴，400 kg 进入重度污染。技能不会因“空蓝”被锁住。

两种结局都展示 **Sustainability Audit Report**：各关/技能排放图、总有效功/总输入能效、废热、精准/高频次数、
救援、共同修复，以及注明依据的现实量级类比；自动保存 HTML 可视化、JSON 汇总与 CSV 逐次记录。
点击“打开审计报告”在浏览器阅读，默认目录为 Godot 的 `user://audits/`（可通过编辑器打开用户数据目录定位）。

所有技能排放、阈值和固碳数值可在 [`assets/carbon_rules.tres`](assets/carbon_rules.tres) 的 Inspector 调整。
玩法与计算口径见 [碳系统设计](docs/carbon-system.md)。汽油类比使用 [EPA 的 8.887 kg CO₂ / 美制加仑](https://www.epa.gov/energy/greenhouse-gas-equivalencies-calculator-calculations-and-references)；
游戏数据类比不代表现实排放、抵销或经核查减排；修复不会抹去累计排放历史。

小怪一击击败加 50 分，Boss 加 500 分；黄色收集物已移除。
玩家生命显示为五颗绿色像素生命球；普通有效受伤扣半颗，从最右一颗开始，先扣半颗再扣完该颗，
之后轮到左边一颗。敌人接触、弹丸、Boss 和落物遵守半球规则；坠入酸池或被第一关压机底齿压中扣一整颗。
受伤有 0.85 秒无敌时间，护盾、冲刺和黑穿期间可防御；狂暴提升怪物移动和攻击频率。
检查点只保存位置，不回复生命。坠落从当前血量减 20 HP，例如 90 → 70，而非恢复满血；尚有生命则快速重生，能力、世界进度与碳账本保留。血量耗尽才弹出 Game Over，提供：

- **从检查点继续**：恢复生命；保留得分、能力、世界进度、碳账本、热负荷和已发生的环保行为。
- **重新开始整局**：重置全部本局进度。
- **返回主菜单**：结束当前游玩；下次开始建立新的一局。

## 阶段一交付

- [x] 主菜单、场景切换、死亡/胜利结算、检查点继续和整局重开。
- [x] 血量、得分、四种能力、护盾状态、地区/土地/检查点的信号驱动 HUD。
- [x] 获得/交还能力与去程/返程的世界状态，光刃交还前检查撤离通路确认。
- [x] 跨场景及死亡后的怪物不刷新、已固化毒源不重置。
- [x] SoundManager 的音效池、BGM、音量、静音及能力/检查点事件接口。
- [x] 真实 UI 输入、物理碰撞、跨场景及检查点恢复的自动化验收。

三关使用独立地形、背景、敌人、检查点和返程路线。原几何验证房仍保留，自动化测试使用 `campaign_mode=false`。
Q/E/R 和 F 黑穿的映射已由用户确认；光刃在试玩版开局提供，正式获取/交还地点和战斗平衡仍待设计。
当前进度保存在内存中，不提供跨进程存档。只有新的一局或玩家在 Game Over 后主动选择“从检查点继续”才恢复满血。

## 美术目录

美工提供的三张原图统一保存在 [`assets/art/originals/`](assets/art/originals/)，原图内容不改动。
内置 image_gen 参考原图生成的三关背景、三类敌人、地形图集及角色透明版位于
[`assets/art/generated/`](assets/art/generated/)。分类和替换方式见 [美术资源说明](assets/art/README.md)，
角色红、绿双形态各有一套 24 帧基础动作与一套 24 帧补绘运动表；短砍、长砍分别使用六帧连续动作，技能与倒地沿用基础表。
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
| `scenes/combat/close_melee.tscn` | 左键 | 80 / 72 px | 0.06 / 0.10 / 0.12 / 0.08 秒 |
| `scenes/combat/reach_melee.tscn` | 右键 | 180 / 42 px | 0.18 / 0.14 / 0.20 / 0.14 秒 |

两者都是跟随角色的近战判定。默认每刀伤害为 1，三关普通小怪一击倒、Boss 需要 6 次命中；
实际鼠标输入支持 140ms 的末段缓冲，提前按下不会跳过当前攻击；命中有 35–55ms 的局部停顿和轻微镜头反馈。
角色及敌人使用统一像素采样与地区环境光色，脚下阴影跟随真实地面；详见 [动作手感与环境融合](docs/combat-feel.md)。
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
六段跑酷首轮整合的全套验收合计 **981 项通过，0 失败**；其中跑酷专项 92 项，正常输入 A/B 完整试玩 163 项。本次压机节奏、底部判伤与材质调整后，跑酷专项扩展至 **100 项通过**。已验证六段即时重生、上下路线、奖励不重复、无跳跃返程，以及矿坑/伊甸城运动配置隔离。实机画面另验证了 HUD、酸池、平台预警与人物可见性，详见 [第一关实现说明](docs/scrapyard-parkour.md)。
此前场景整合无窗口验收合计 795 项通过，包含四幕开场、生命球、四处绿洲抽取与场景渐变、双语对话、毒素谜题、攻击缓冲、轻重跳与正常输入 A/B 完整试玩；见 [抽取与场景渐变记录](docs/land-extraction-art.md)。
开场另经真实渲染检查，98 项通过；已查看像素显现、英文长句、地下矿区与最后一幕淡入的实际截图。
开场验收覆盖八句旁白顺序、长按/转场输入、窗口缩放、四张图片加载，以及最后一次 Enter 仅启动一局游戏。
生命球另经真实渲染检查，32 项通过，覆盖满血、半球、空球、最后半球，以及十次受伤后的死亡和检查点恢复。
绿洲抽取另经真实渲染检查，128 项通过；已查看三种绿洲、下蹲与举起吸魂器、生命流、场景渐变、枯竭、共同修复和中英文切换的实际截图。
抽取验收覆盖动作完成前不授予能力、冻结期间的碰撞与计时、重复输入、Eden 两个绿洲独立状态、检查点回访和中途退出的取消处理。
HUD 持续显示当前目标；居民共建后的危险区解除，守卫在入口内被击败时也会正确触发真相剧情。
入口另经全新目录、不带 `.godot/` 缓存的导入与启动检查。

如果编辑器提示 `CarbonLedger not declared`，检查 Project Settings → Globals → Autoload 是否有
`CarbonLedger = res://autoload/carbon_ledger.gd` 且已启用。四个系统的注册均保存在根目录 `project.godot`。
编辑器已打开时，外部修改此文件应选择 **Reload from disk**，保留新的工程配置。
验收脚本会在启动前检查四项注册与脚本路径，缺失时直接报明原因。

## Toxic Mine Challenge / 第二关

Open `scenes/mine_challenge/toxic_mine_challenge.tscn` and press F6, or use `试玩第二关.cmd`. Walk to the entrance's glowing ore seam and press E to extract its life before using E / J / C to mineralize gas; Space double jumps. The campaign loads this eight-stage mine after the Junkyard. See [level documentation](docs/toxic-mine-challenge.md) and [shared HUD / fall recovery](docs/chapter-status-and-fall-recovery.md).
