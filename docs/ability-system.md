# 能力、世界状态与检查点

## 依据与职责

需求原文：[Rules and Ability](design-rules.md)。这是项目设计资料。
B 负责状态、数据契约、UI 和声音接入；A 负责最终移动、跳跃、冲刺、防御、命中判定和敌人 AI。
当前 `placeholder_player.gd` 与静态方块怪为可删除的验证适配器，不是最终战斗实现。

| 规则 | B 提供的系统支持 |
| --- | --- |
| 孤木借二段跳；返程交还后枝干搭桥 | `double_jump` 状态、源地区校验、土地状态、通路标记及占位步行桥 |
| 草原借冲刺；返程交还后根系打开步行通道 | `dash` 状态、相同数据流程及占位步行桥 |
| 残海借护盾；返程交还后维持水源/屏障 | `shield` 状态、启用状态、区域保护标记和占位屏障 |
| 光刃近战与破坏机关；地点待定 | `light_blade` 状态与动作/音频事件；交还必须先确认撤离通路；机关由 A/关卡提供 |
| 怪物一击倒、不刷新 | 以稳定实体 ID 记录本局已击败状态，跨场景/检查点保留 |
| 死亡/坠落返回检查点 | 死亡弹窗“从检查点继续”，恢复最近一次场景入口 |
| 进入新场景成为检查点 | `enter_scene()` 提交场景 ID、入口位置和检查点，再安全替换场景 |
| 吸收使土地荒芜 | 产生 `wasted` 状态，UI 和场景观察 `world_changed` |

## 能力 API

ID 在 `AbilityCatalog` 集中定义：`double_jump`、`dash`、`shield`、`light_blade`。
每个能力只能沿 `UNAVAILABLE → BORROWED → RETURNED` 变化；归还后不可再次吸收。
重开整局时恢复 `UNAVAILABLE`。UI 显示“未获得 / 可用 / 已交还”，护盾激活时显示“防御中”。

```gdscript
# 在能力源附近，由关卡交互或 A 调用。三个已定地点的能力只允许在对应场景吸收。
WorldProgress.borrow_ability(&"double_jump")
WorldProgress.has_ability(&"double_jump")
WorldProgress.ability_state(&"double_jump")

# A 先确认动作实际执行成功，再报告事件，以播放音效。
WorldProgress.report_ability_used(&"dash")
WorldProgress.set_shield_active(true)

# 在原地区的归还交互点执行。
WorldProgress.return_ability(&"shield")
WorldProgress.route_open(&"shield")
WorldProgress.land_state(&"remnant_sea") # intact / wasted / restored
```

`return_ability()` 在同一次更新中先置位通路、再撤销能力并发出事件。
正式关卡应监听 `world_changed`，根据 `route_open()` 创建桥、移除残骸或打开保护区；
重新加载关卡时也读取快照，避免依赖只发生一次的事件。
占位关卡会生成有物理碰撞的桥，并在残海保护尖刺通路。正式屏障对攻击/伙伴的保护由 A 的玩法系统读取该标记实现。

光刃的获取/交还地点保持待定，B 没有给它指定正式区域。调试版本 F1 仅用于试用接口，
不产生“该区域正式提供光刃”的设计含义。正式关卡必须明确验证无攻击能力仍能离开，再调用：

```gdscript
WorldProgress.set_light_blade_escape_ready(true)
WorldProgress.return_ability(&"light_blade")
```

没有确认时交还返回 `false`，保留光刃并显示原因。关卡必须先实现真正可用的撤离路线，
上述确认不是自动寻路或几何验证。正式光刃机关和地点仍需后续设计。

## 场景与检查点

当前可用场景 ID：`lone_tree`、`grassland`、`remnant_sea`。
`scripts/main.gd` 的 `level_scene` 为孤木默认场景，`region_scenes` 映射另外两个 ID。
将它们替换成正式 PackedScene；新增区域时同时扩展 `AbilityCatalog.REGIONS` 和场景映射。

```gdscript
# 关卡出口：提供新场景及安全入口。通过检查后，新场景入口即为最新检查点。
WorldProgress.enter_scene(&"grassland", Vector2(100, 560))

# 新关卡 _ready：恢复位置和数据，再绑定。Stats 实现 restore_stats(snapshot)。
$Player.position = WorldProgress.spawn_position
$GameplayBridge.bind_source($Player/Stats, true)

# A 的伤害/死亡：原生命信号归零也会结算。
GameSession.player_died()
GameSession.player_died(&"fall")

# 由死亡弹窗或自己的恢复流程调用。
GameSession.resume_checkpoint()
```

`enter_scene()` 只在运行中接受有效的新区域；切换期间拒绝新的进度、伤害和得分事件。
场景实例替换推迟到物理回调之外，旧关卡桥接器会解绑；同一时间只保留一个活动关卡。
入口位置必须由关卡提供为安全位置，B 不推测地形。

当前死亡策略：显示 Game Over，再允许选择检查点继续。继续时恢复满血、保留当前得分和累计时间；
能力、返程、荒芜/恢复状态、已击败怪物、已拾取碎片均保留，不回滚到进入场景之前。
这些保留策略及满血恢复是文档未详述部分的临时选择。
“重新开始整局”才清空上述状态；回主菜单后再开始也视为新的一局。当前不写磁盘存档。

## 怪物与拾取物

稳定 ID 必须包含地区和本地实体 ID，不能使用实例 ID 或随机名称，否则重载后无法去重。

```gdscript
const MOB_ID: StringName = &"lone_tree/enemy_01"

func _ready() -> void:
    if WorldProgress.is_enemy_defeated(MOB_ID):
        queue_free()

func on_hit() -> void:
    if WorldProgress.mark_enemy_defeated(MOB_ID):
        queue_free() # 一击倒；分数和掉落如有需要也只在返回 true 时结算

# 相同规则用于一次性碎片，防止检查点恢复后重复刷分。
if WorldProgress.collect_once(&"lone_tree/shard_01"):
    $Player/Stats.add_score(100)
```

## 输入与占位数值

用户确认：Q 按住护盾、E 吸收、R 交还。其余按文档为 A/D 移动、空格跳、Shift 快跑、鼠标左键挥刃。
InputMap 使用 `eden_*` 前缀，已存在的映射不会被覆盖。点击 HUD 按钮不会同时挥刃。
Shift 在未借冲刺时仍支持文档中的普通快跑，借到冲刺后按下会触发短距离冲刺。

角色速度、跳高、冲刺时间/恢复间隔、无敌间隔、护盾无消耗、碎片 100 分和尖刺 25 伤害，
均为验证房的临时数值。没有将它们作为正式平衡规则，也没有给正式能力新增能量或冷却 UI。

## B 的状态与音频信号

`abilities_changed`、`shield_changed(active)`、`world_changed`、`checkpoint_changed`、
`notice_changed(text)` 供 UI 与场景使用；`ability_absorbed(id)`、`ability_returned(id)`、
`ability_used(id)`、`enemy_defeated(id)`、`GameSession.checkpoint_resumed` 供音效和表现接入。

新增占位音效 ID：`absorb`、`return`、`double_jump`、`dash`、`shield`、`slash`、`enemy_down`、`checkpoint`。
更换素材继续使用 `SoundManager.register_sound()`。声音与动画由事件驱动，不需要 A 访问 HUD 节点。

## 试玩验收路线

1. F5 → 开始游戏，在孤木靠近蓝色能力源按 E；HUD 显示二段跳可用、土地荒芜。
2. 通过两个缺口走到右端，进入草原；检查点变为草原。在源处 E 获得冲刺。
3. 进入残海，在源处 E 获得护盾；按住 Q 检查防御状态，再走到最右端触发返程。
4. 返回残海能力源按 R：护盾变“已交还”，屏障/通路出现；向左回草原。
5. 在草原、孤木各自能力源按 R；失去冲刺和二段跳后，使用步行桥穿越缺口。
6. 任意阶段死亡后选择检查点继续，确认位置、能力、归还与怪物状态正确。
7. F1 试用光刃，鼠标左键击败方块怪；重新进入场景或死亡恢复后不刷新该怪物。
8. 完成三种已定能力的交还后，从孤木最左端回家，显示胜利；重开整局会清空本局状态。

自动化验收覆盖真实鼠标事件、物理拾取/尖刺/出口、输入动作、数据换源、三场景往返、
光刃交还保护、死亡恢复与整局重置。`tests/run-tests.ps1 -Screenshots` 同时生成界面截图。
