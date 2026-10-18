# 房间切换、开放式电梯与精简 HUD

## 已接入的内容

- 三章左上统一为五枚像素树叶，每次普通伤害扣半枚，坠落扣一枚；生命数据与原战斗系统一致。
- 右上只保留本章目标和局部地图。地图来自实际承重平台，显示玩家位置、目标菱形及矿化后临时晶台；随玩家移动更新，中英文跟随设置。
- 移除实时排放、固碳、冷却、能力列表、护盾能量、Boss 血量及常驻设置按钮。Esc 仍可打开设置；靠近交互对象才显示圆形按键提示；剧情字幕、结局选择和死亡窗口保留。
- `CarbonLedger` 继续记录整局数据，只在最终致谢 / 可持续行为审计中展示总排放、固定量及明细。矿坑小结和死亡窗口不再展示碳记录。
- 第一章直接继承第二章污水组件，共用水体、泡沫、蒸汽材质。第一章关闭组件伤害，仍由既有坠落规则扣血，避免重复伤害。
- 第一章静态、传送带、塌台、吊台统一使用 `junkyard_terrain.png` 的完整承重边，不再随机混用带透明缺口的裁片；保留已有第一章色调。
- 原章节出口统一经过渐暗 / 渐亮；伊甸城电梯从倒计时传送替换为实体开放式升降台。第三救援舱与落脚台移到井侧，留出真实电梯井。

## 运行

正常游戏：打开项目，F5，进入原有开场和主菜单。所有现有跑步、跳跃、二段跳、攻击、护盾和黑穿沿用原控制器与资源。

独立联调房间：打开 `res://scenes/tests/navigation_test_room.tscn`，F6。

1. A/D 移动，Space 跳跃 / 二段跳，Q 护盾，F / Shift 黑穿，鼠标左右键攻击。
2. 从两侧边缘可以往返两个房间；靠近晶矿拱门按 T 进入，T 返回。
3. 第一房间中间有上下两层开放式升降台，站稳后按 T；可在行进中跑动、跳离、二段跳、冲刺。
4. 停靠点旁的机械开关可按 T 呼叫电梯，也可以近战击打。Esc 打开设置。

测试房间仅替换房间几何，角色和 Camera2D 实例始终保留。正式章节沿用各自原有角色工厂，旧关卡移出树后再创建新关卡，场景树中只有一个玩家；生命、能力、救援与章节进度由原有全局状态保留。

## 场景切换实现

现有 `scripts/main.gd` 继续作为章节宿主；`RoomTransitionController` 是它的子节点，没有增加 Autoload。原 `WorldProgress.enter_scene()` 多了可选配置字典，原调用方式兼容。

流程为：锁操作 → 原镜头沿入口方向偏移 14px → 0.15 秒渐暗 → 全黑时提交场景替换 → 选中 SpawnPoint、设置朝向、镜头边界并重置平滑 → 保持黑屏一帧 → 0.25 秒渐亮 → 恢复操作。另有短暂重入保护。返回菜单或结束游戏会取消未完成切换，防止过期回调重新加载关卡。

`WorldProgress.scene_transition_active` 与原有 `transitioning` 分开：关卡构造时允许同步初始化检查点，整个可见切换期间角色、机关和计时仍被锁定。

### 在其他房间复用

1. 实例化 `scenes/transitions/spawn_point.tscn`。设置唯一 `spawn_id`、朝向；位置是角色身体中心，不是脚底。可选 `override_camera_bounds` 设置房间镜头范围。
2. 实例化 `transition_zone.tscn`，设置 `zone_size`、`target_scene`、`target_spawn_id`。方向由 `entry_direction` 指定：右 `(1,0)`、左 `(-1,0)`、上 `(0,-1)`、下 `(0,1)`。淡入淡出时长均可调整。
3. 房门使用 `door_transition.tscn`，其他目标参数相同。门会自动显示附近的 T 提示，无需重复建立 Input Map。
4. 用 `source_spawn_id` 指向本门 / 本出口的返回标记；留空时自动选择玩家最近的 SpawnPoint。返回门勾选 `return_to_previous`，宿主会读取历史入口，无需再填写目标路径与入口。
5. 正式三章之间可设置 `target_region` 为 `lone_tree`、`grassland`、`remnant_sea`，继续走原世界进度接口。命名入口已由主宿主安装。

通用房间宿主应加入 `scene_transition_host` 组并实现 `request_room_transition(options)`。示例见 `navigation_test_room.gd`：先调用 `transitions.resolve_options()` 获取返回目标，再把提交替换房间的 Callable 交给 `transitions.request()`。只有房间几何需要替换时，把现有角色留在宿主下即可。已有章节上下层使用电梯与 Camera2D 平滑跟随，不加载新场景。

## 开放式升降台实现与复用

实例化 `res://scenes/movement/open_elevator.tscn`。预制体含 `Platform`（AnimatableBody2D，`sync_to_physics=true`）、实体碰撞、`OperationArea`、`TopPoint` 和 `BottomPoint`。使用原矿坑木架、链条、机械和音效资源。

Inspector 参数：

| 参数 | 含义 |
|---|---|
| `move_speed` / `acceleration` / `deceleration` | 匀速上限、启动加速、制动减速 |
| `top_position` / `bottom_position` | 相对电梯根节点的停靠坐标，修改后自动布置 Marker2D |
| `platform_width` | 平台实体宽度 |
| `interaction_enabled` | 是否允许启动 / 呼叫 |
| `automatic_return` / `return_delay` | 上层无人后延时回到底层 |
| `start_at_top` | 检查点恢复时的初始停靠层 |
| `obstruction_mask` | 阻挡电梯的建筑层，默认 1、16、32；不包含玩家层 2 |
| `handle_input` | 默认自动处理 T；已有宿主消费 T 时关闭，由宿主调用 `activate()` |
| `start_sound` / `movement_sound` / `dock_sound` | 启动、运动循环、停靠的 AudioStream 接口 |

状态明确为 `IDLE_BOTTOM`、`MOVING_UP`、`IDLE_TOP`、`MOVING_DOWN`；物理步内按加速和剩余刹车距离移动，精确停靠。只抖动视觉支架，不抖动碰撞体。运动前通过 `body_test_motion` 检查建筑阻挡，遇阻停止并发出 `obstructed`，可反向恢复。

角色使用 Godot 自带移动平台速度，不绑定角色位置。原角色已配置 `floor_snap_length=8`、`PLATFORM_ON_LEAVE_ADD_UPWARD_VELOCITY`，下降保持接触，跳离保留合理的上升速度。玩家层 2，地形 / 电梯层 1。

请在静态地板中留出平台宽度加少量间隙的完整竖井，不要让电梯必须穿过建筑。伊甸城已实际切出井道并调整救援落脚台。电梯两端周围留出站立和跳离空间。

可选实例化 `scenes/movement/elevator_switch.tscn`：设置 `elevator_path` 和 `call_top`，`activation_mode` 可选交互、攻击或两者。组件自动建立近战 Hurtbox 和提示。程序也可直接调用 `activate()`、`call_to_stop(at_top)`，监听 `movement_started`、`arrived`、`obstructed`，无需手动连接基础信号。

## 文件清单

新增：

- `scripts/transitions/{scene_transition,spawn_point,transition_zone,door_transition}.gd`：切换控制器、入口标记、边缘区域和房门。
- `scenes/transitions/{spawn_point,transition_zone,door_transition}.tscn`：三个可实例化组件。
- `scripts/movement/{open_elevator,elevator_switch}.gd` 和 `scenes/movement/{open_elevator,elevator_switch}.tscn`：升降台、停靠呼叫 / 攻击开关。
- `scripts/transitions/{navigation_test_room,test_room_geometry}.gd`，`scenes/tests/{navigation_test_room,transition_room_a,transition_room_b}.tscn`：双房间测试场。
- `scripts/ui/objective_minimap.gd`：目标、局部几何与玩家位置。
- `tests/navigation_system_test.{gd,tscn}`：真实碰撞、输入、切换和升降回归。
- 本文档，以及上述新脚本的 Godot UID 文件。

修改：

- `scripts/main.gd`、`autoload/{world_progress,game_session}.gd`、`scripts/campaign/level.gd`：接入原场景管理与进度、命名入口和切换锁，渐隐期间暂停计时并拒绝过期伤害信号。
- `scripts/eden/level.gd`：真正的两层升降台、井道、救援站位、精简 HUD 与城市字幕交谈。
- `scripts/placeholder_player.gd`、`scripts/mine_challenge/player.gd`：移动平台承载参数。
- `scripts/mine_challenge/{level,deadly_acid_pit}.gd`、`scripts/parkour/{toxic_water,scrapyard_surface}.gd`：精简矿坑 UI、共享污水和统一平台贴图。
- `scripts/ui/{chapter_status_hud,life_orbs,hud,carbon_dashboard,toxin_status,result_dialog,sustainability_report}.gd`：树叶生命、地图、隐藏实时记录和最终致谢。
- `tests/run-tests.ps1` 以及现有章节、UI、交互、场景、跑酷、矿坑和伊甸城测试：等待真实渐隐完成，验证新 HUD 合约与实体升降路线；未跳过旧能力断言。

无需新增 Autoload、Input Map 或手动连接基础信号。现有 `EdenInputBindings` 和章节输入配置继续生效。

## 验证

2026-10-18 最终回归：25 套、1490 项检查，0 失败。包含 38 项新增切换 / 电梯检查、47 项章节一致性检查、77 项新版伊甸城连续跑图，以及 163 项普通输入 A/B 跑图（0 死亡）。全项目导入与脚本加载通过，无缓存副本首次导入和最终导航回归通过。真实渲染中已检查树叶、地图、平台、污水和双房间电梯画面。

运行所有回归：

```powershell
.\tests\run-tests.ps1 -Godot 'E:\Software\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
```

独立测试：`res://tests/navigation_system_test.tscn`，F6。它验证四个方向的边缘入口、门双向往返、自动返回入口、重复触发保护、淡出取消、血量能力保留、单个角色、相机平滑、上下停靠、上下降承载、跳离 / 二段跳 / 冲刺、跑动、攻击开关、建筑阻挡恢复、无人自动回程及禁用交互。

现有 `eden_route_test.tscn` 继续从入口跑完整战斗和三人救援，不通过角色传送或模拟击败跳过升降路线。三章真实渲染截图输出到 `test-output/screenshots/chapter-status-*.png`；双房间截图为 `test-output/navigation-room.png`。

音频资源加载与生命周期通过 Dummy 音频驱动验证；音量、混音与听感尚未逐项人工试听。正式三章已验证，用户未来自建房间的出口位置、相机边界和电梯井净空仍需按具体地图检查。
