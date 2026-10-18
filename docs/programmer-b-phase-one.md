# 程序员 B 第一阶段交接

## 当前范围

Godot 4.7.2，入口 `scenes/main.tscn`。已根据 [能力规则原文](design-rules.md)实现：
主菜单、能力 HUD、世界进度、死亡/胜利结算、检查点继续、整局重开和音频事件。
现默认启动森林、垃圾场、矿厂三个独立布局的可玩关卡，接入原画角色、生成背景/敌人、近战、巡逻/射击/Boss 与往返路线；
详见 [三关试玩版说明](three-level-campaign.md)。原几何房保留为接口回归测试，逐帧动画、正式音频与最终平衡仍待后续完善。

| 文件 | 职责 |
| --- | --- |
| `autoload/game_session.gd` | 流程状态、生命/得分快照、结算记录、检查点继续与重开 |
| `autoload/world_progress.gd` | 四能力、土地/通路、场景入口检查点、单次怪物/拾取进度 |
| `scripts/integration/ability_catalog.gd` | 能力/地区 ID、文案、对应地点和音效 ID |
| `scripts/integration/gameplay_bridge.gd` | A 的数据源 → GameSession → HUD；加载时恢复数据 |
| `scripts/main.gd` | 场景映射和安全替换、UI 状态、输入映射 |
| `scenes/ui/`、`scripts/ui/` | 可替换皮肤的菜单、HUD、结算和恢复按钮 |
| `autoload/sound_manager.gd` | 多音效声道、BGM、独立 Music/SFX 音量及静音 |
| `scripts/combat/`、`scenes/combat/`、`assets/combat/` | 可复用短/长近战模板、受击接口和独立测试房 |
| `scripts/campaign/`、`scenes/campaign/` | 三关数据、碰撞地形、敌人、检查点、救援和返程 |
| `assets/art/originals/`、`assets/art/generated/` | 原画归档与配套生成素材 |
| `scripts/placeholder_*.gd`、对应场景 | 旧验证房；三关仍复用玩家与 Stats 适配器 |

## A 的生命与得分数据契约

数据节点必须提供 `health`、`max_health`、`score` 三个整数属性，以及以下信号：

```gdscript
signal health_changed(current: int, maximum: int)
signal score_changed(value: int)
signal died # 可选，无参数
```

支持跨场景和检查点恢复时，再实现：

```gdscript
func restore_stats(snapshot: Dictionary) -> void:
	max_health = maxi(1, int(snapshot.get("max_health", 100)))
	health = clampi(int(snapshot.get("health", max_health)), 0, max_health)
	score = maxi(0, int(snapshot.get("score", 0)))
	health_changed.emit(health, max_health)
	score_changed.emit(score)
```

正式关卡加载时：

```gdscript
func _ready() -> void:
	$Player.position = WorldProgress.spawn_position
	$GameplayBridge.bind_source($Player/Stats, true)
```

`true` 表示先将 GameSession 的快照传给 A 的 `restore_stats()`，再连接信号并同步当前值。
不支持恢复的旧数据源仍可用 `bind_source(source)` 做基本绑定；启用恢复却没有恢复方法会返回 `false` 并提示。
源替换和离树会解绑旧回调，避免重复更新。生命归零和 `died` 同时发出也只结算一次。

也可从自己的事件总线直接调用 `GameSession.sync_health(current, maximum)` 和
`GameSession.sync_score(total)`。不要只给字段赋值，字段赋值不会发出 UI 更新事件。
游戏数据由 A 修改；GameSession 是 UI/流程快照，世界状态由 WorldProgress 统一持有。

## 流程

```text
主菜单 → 开始整局 → 游戏中 → 死亡弹窗 → 从检查点继续 → 游戏中
					   │         ├→ 重新开始整局 → 清空本局进度
					   │         └→ 返回主菜单
					   ├→ 进入新场景 → 更新入口检查点 → 游戏中
					   └→ 胜利结算 → 重开 / 返回主菜单
```

死亡继续保留能力、交还状态、土地/通路、击败和拾取记录及得分，临时采用满血恢复；
新的一局才清空它们。入口检查点和所有本局进度仅在内存中，不提供磁盘存档。
结算后锁定终局事件，停止关卡处理并禁用背景 UI 按钮；物理回调内不直接销毁碰撞节点。

三关在 `main.gd` 的 `CAMPAIGN_SCENES` 映射，`campaign_mode=false` 使用旧 `level_scene/region_scenes` 验收房。场景出口调用
`WorldProgress.enter_scene(id, safe_spawn_position)`，胜利由关卡调用 `GameSession.complete_level()`。
完整能力 API、稳定实体 ID、光刃撤离保护和试玩路线见 [能力与检查点接入说明](ability-system.md)。

## 音频

```gdscript
# 以下正式素材路径为示例；仓库只提供代码合成占位音。
SoundManager.register_sound(&"hurt", preload("res://assets/audio/hurt.wav"))
SoundManager.play_sfx(&"hurt")
SoundManager.play_sfx(&"pickup", -6.0, 1.1) # dB、音调倍率
SoundManager.play_music(preload("res://assets/audio/level_theme.ogg"), -12.0)
SoundManager.stop_music()
SoundManager.stop_sfx()
SoundManager.set_music_volume(0.5) # 线性 0～1
SoundManager.set_sfx_volume(0.8)
SoundManager.set_muted(true)
```

默认声音包括 UI、跳跃、受伤、拾取、胜负和所有能力/检查点事件；通过同名 ID 注册正式资源替换。
SFX 最多同时使用 8 个播放器，超出时复用最旧播放器。未知 ID 返回 `false`，不打断游戏。
BGM 循环由音频资源自身的 Loop 设置决定。静音/音量跨场景保持，当前不跨进程保存。

## 验证

运行命令见根目录 README。验收程序检测引擎错误/警告、退出码和最终检查结果，失败返回非零。
界面截图模式使用真实渲染；音频使用 Dummy 驱动验证调用与状态，音色和最终响度请正常运行试听。
近战模板复用、调参与动画/受击接入见 [近战模板说明](melee-templates.md)。
正式美术、玩法平衡和与 A 的最终代码联调仍需后续负责人协作完成。
