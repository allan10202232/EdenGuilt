# 近身与长距离近战模板

## 文件与试玩

主菜单的“近战模板测试”可直接进入测试房。也可打开 `scenes/combat/melee_demo.tscn`，按 F6 单独运行。
测试房为左键短砍、右键长砍；A/D 改朝向，空格跳跃。木桩可重置，位置标注以初始角色位置为基准。
训练木桩为 3 HP 用于观察重复命中，正式验证关卡仍是 1 HP、一击倒且本局不刷新。
测试房单独开启试用光刃，不改变正式获取地点待定的设计。

| 文件 | 用途 |
| --- | --- |
| `scenes/combat/close_melee.tscn` | 近身短挥砍，可单独实例化 |
| `scenes/combat/reach_melee.tscn` | 长距离挥砍，可单独实例化 |
| `scenes/combat/melee_combat.tscn` | 两种攻击组成的套件，共享动作锁，已挂到占位角色 |
| `assets/combat/close_melee.tres`、`reach_melee.tres` | 可在 Inspector 调整的攻击参数 |
| `scripts/combat/melee_attack.gd` | 时间阶段、物理判定、去重和遮挡检查 |
| `scripts/combat/melee_hurtbox.gd` | 受击区域到伤害接收节点的映射 |
| `scenes/combat/melee_dummy.tscn` | 示例伤害接收器与几何木桩 |

## 默认参数

| 参数 | 近身 | 长距离 |
| --- | --- | --- |
| 判定长度 `reach` | 80 px | 180 px |
| 判定高度 `height` | 72 px | 42 px |
| 前方起点 `forward_offset` | 14 px | 14 px |
| 伤害 | 1 | 1 |
| 击退参数 | (180, -80) | (300, -50) |
| 前摇 | 0.06 秒 | 0.18 秒 |
| 生效 | 0.10 秒 | 0.14 秒 |
| 后摇 | 0.12 秒 | 0.20 秒 |
| 额外冷却 | 0.08 秒 | 0.14 秒 |

完整动作依次为 `WINDUP → ACTIVE → RECOVERY → COOLDOWN → IDLE`。
冷却从后摇结束后开始，因此默认整轮分别为 0.36 秒和 0.66 秒。只有 ACTIVE 阶段产生伤害。
`try_close/try_reach` 保留严格的立即请求接口；玩家鼠标经 `request_attack` 提供 140ms 的单次输入缓冲。
缓冲不会绕过共享动作锁，只在剩余窗口内变为可用时执行；受伤、技能中断、剧情或离开关卡会清除。
同一套件中两种攻击共享动作锁，不能左右键交替绕过后摇或冷却。

长度为矩形判定框的宽度：右向时覆盖本地 x=14～94 / 14～194，左向对称。
目标受击框与攻击框重叠即可命中，因此目标中心的实际可命中距离也受目标尺寸影响。
攻击判定跟随角色移动，攻击开始时锁定左右朝向；没有生成独立移动的投射物。

上述数值均是可修改的模板默认值，不是最终武器平衡。
当前展示为几何范围和亮线，正式挥砍动画、长兵器贴图、音效与特效由对应负责人替换。
接入正式动画时，可关闭组件的 `show_hitbox` 和 `show_placeholder_weapon`，保留命中逻辑。

## 接入角色

将 `melee_combat.tscn` 拖到正式角色 Node2D 下。在角色就绪时指定攻击者和可攻击条件：

```gdscript
@onready var combat: MeleeCombat = $MeleeCombat

func _ready() -> void:
    combat.setup(self, func() -> bool:
        return WorldProgress.can_play() and WorldProgress.has_ability(&"light_blade")
    )

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed(&"eden_slash"):
        combat.try_close(facing) # facing 是 -1 或 +1
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed(&"eden_reach_slash"):
        combat.try_reach(facing)
        get_viewport().set_input_as_handled()
```

输入映射由 `EdenInputBindings.configure()` 注册，不覆盖已有 `eden_*` 映射。
使用 `_unhandled_input` 可让菜单、重置按钮等 GUI 优先处理鼠标输入。
通用组件本身不读取按键，不依赖 GameSession、WorldProgress、音频管理器或动画节点。
传入的条件每个物理帧都检查；光刃被归还、玩家死亡或场景切换时，未完成攻击会停止结算。

也可只实例化单个模板：

```gdscript
var attack: MeleeAttack = preload("res://scenes/combat/reach_melee.tscn").instantiate()
add_child(attack)
attack.setup(self, can_attack)
attack.try_attack(1.0)
```

单个模板只管理自己的动作锁；同角色同时配置两种攻击时，建议通过 `MeleeCombat` 统一调用。
`cancel()` 可用于受击打断、切武器或重置测试。当前不包含蓄力、连招、输入缓存和最终硬直策略。

## 接入受击对象

攻击器默认查询物理层 3（掩码值 4）。敌人可添加一个或多个 Area2D，碰撞层设为 3，
挂上 `melee_hurtbox.gd`，其 `receiver_path` 指向同一个敌人节点。每个区域需要 CollisionShape2D。
例如 Hurtbox 是敌人的直接子节点时，保持默认 `receiver_path=".."`。

敌人实现：

```gdscript
func receive_melee_hit(hit: Dictionary) -> bool:
    if health <= 0 or invulnerable:
        return false
    health = maxi(0, health - int(hit.damage))
    velocity += hit.knockback # 按正式角色物理实现调整
    if health == 0:
        die()
    return true
```

数据包包含：`attack_id`、`damage`、`source`、`position`、`knockback`。
返回 `true` 表示接收了伤害，才会发出 `target_hit` 信号。示例木桩记录击退参数，不主动移动；正式敌人自行应用。
同一刀按接收节点去重，不按受击区域去重，因此多个 Hurtbox 或持续重叠都不会重复扣血。
一次生效阶段可以命中多个不同敌人。被无敌状态拒绝的同一次攻击也不会在后续帧反复尝试。

攻击者自身及其子节点不会成为目标。查询使用当前物理世界中的矩形形状，
同时向目标区域中心做墙体射线检查；默认墙体在物理层 1，可修改 `obstruction_mask`。
关闭遮挡检查可将掩码设为 0。中心射线是模板默认策略，正式复杂武器轨迹可由 A 替换。

## 动画、特效和声音

套件提供 `attack_started(profile)` 和 `target_hit(receiver, hit)`；
单个攻击组件额外提供 `phase_changed(phase)`、`attack_finished`、`attack_cancelled`。
可以据此切动画、播放挥砍/命中声音或显示特效。
当前角色在成功开始攻击时调用 `WorldProgress.report_ability_used(&"light_blade")`，复用光刃音效。

每次攻击都会复制参数快照，防止共享 `.tres` 在编辑中途改变本次命中的伤害或距离。
定制新招式时复制 `.tres` 并修改 ID 和参数，再赋给复制的模板场景；不要把多个武器意外改成同一份共享资源。

## 验证

`tests/melee_test.tscn` 检查短/长范围、前摇、重复区域去重、共享动作锁、左右朝向、墙体遮挡、
碰撞掩码、自身排除、移动跟随、参数快照、非法参数、能力失效中断、命中回调取消、真实鼠标和菜单进出。
`tests/run-tests.ps1` 现在同时运行阶段一流程与近战测试；加 `-Screenshots` 可生成两种攻击的渲染截图。

物理查询参考 Godot 官方的 [PhysicsDirectSpaceState2D](https://docs.godotengine.org/en/stable/classes/class_physicsdirectspacestate2d.html)。
