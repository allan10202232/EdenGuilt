# 程序员 B 第一阶段交接

## 范围和运行入口

使用 Godot 4.7.2，入口为 `scenes/main.tscn`。所有视觉元素为临时几何图形，
声音为代码合成短音，不依赖外部素材。默认关卡是横版平台验证房，用于验收 B 的系统；
不包含程序员 A 的正式战斗、角色动画或敌人 AI，也不代表正式关卡设计。

在 Godot 中打开根目录 `project.godot`，按 F5。原来的相邻 `eden` 项目没有被移动或修改。

## 模块

| 文件 | 职责 |
| --- | --- |
| `autoload/game_session.gd` | 全局状态、UI 只读快照、结算记录、开始/重开/返回入口 |
| `autoload/sound_manager.gd` | 音效池、BGM、静音与独立 Music/SFX 音量 |
| `scripts/main.gd` | 实例化/释放关卡、UI 可见性、结算时停止关卡处理 |
| `scenes/ui/`、`scripts/ui/` | 可在编辑器中替换样式的主菜单、HUD、结算弹窗 |
| `scripts/integration/gameplay_bridge.gd` | A 的数据源 → GameSession → HUD 的信号适配 |
| `scripts/integration/placeholder_stats.gd` | 遵循数据契约的最小占位实现 |
| `scenes/placeholder_*.tscn`、对应脚本 | 横版占位角色和验证关卡，可整体替换 |

状态图：

```text
MAIN_MENU --开始游戏--> PLAYING --生命归零/死亡--> GAME_OVER
                          |                         |
                          +--到达出口------------> VICTORY
                          ^                         |
                          +---------重新开始--------+
MAIN_MENU <------------返回主菜单-------------------+
```

`GameSession` 是常驻 Autoload，不随关卡销毁。重开时旧关卡从树中移除并释放，
重新实例化关卡，血量/得分/计时/结算快照重置。结算时先锁定状态，关卡处理在安全时机停用，
后续伤害、得分、胜利或死亡信号不能覆写本次结果。HUD 背景按钮在结算时禁用，键盘焦点置于重开按钮。

## 程序员 A 的接入契约

A 的数据节点需要提供以下属性和信号（名字、参数数量和类型保持一致）：

```gdscript
extends Node

signal health_changed(current: int, maximum: int)
signal score_changed(value: int)
signal died # 可选，无参数

var health: int = 100
var max_health: int = 100
var score: int = 0

func take_damage(amount: int) -> void:
    if health <= 0:
        return
    health = clampi(health - amount, 0, max_health)
    health_changed.emit(health, max_health)
    if health == 0:
        died.emit()

func add_score(amount: int) -> void:
    score = maxi(0, score + amount)
    score_changed.emit(score)
```

1. 在正式关卡根节点下添加 Node，挂载 `gameplay_bridge.gd`。
2. 在关卡 `_ready()` 中绑定 A 的数据节点：

   ```gdscript
   func _ready() -> void:
       $GameplayBridge.bind_source($Player/Stats)
   ```

3. 将 `scenes/main.tscn` 根节点的 `level_scene` 属性替换为正式关卡 PackedScene。
4. 正式关卡满足胜利条件时调用 `GameSession.complete_level()`。
5. 如果 A 没有提供生命变化信号，死亡时也可直接调用 `GameSession.player_died()`。

桥接器绑定时会先同步 `score`、`health` 和 `max_health` 的当前值，之后实时转发信号。
换源会自动断开旧信号；源或关卡离树时会解绑。生命为零自动失败，所以可选 `died` 与
生命归零同时发送也只会结算一次。HUD 不轮询、不访问 Player 路径，支持变化的生命上限。

如果 A 已有自己的事件总线，也可以直接调用：

```gdscript
GameSession.sync_health(current_health, maximum_health)
GameSession.sync_score(total_score)
GameSession.player_died()
GameSession.complete_level()
```

游戏中的血量与得分由 A 的数据节点负责修改，`sync_*` 是供 UI 使用的快照接口。
不要只改 `GameSession.health` / `score` 字段；直接赋值不会发出 UI 更新信号。
新建关卡时应自行初始化 A 的数据节点，桥接器不会反向覆盖 A 的数据。

## 音频接口

```gdscript
# 用正式素材替换同名占位音效；空资源不会覆盖现有声音。
SoundManager.register_sound(&"hurt", preload("res://assets/audio/hurt.wav"))
SoundManager.play_sfx(&"hurt")
SoundManager.play_sfx(&"pickup", -6.0, 1.1) # 音量 dB、音调倍率

SoundManager.play_music(preload("res://assets/audio/level_theme.ogg"), -12.0)
SoundManager.stop_music()
SoundManager.stop_sfx()
SoundManager.set_music_volume(0.5) # 线性值，限制在 0～1
SoundManager.set_sfx_volume(0.8)
SoundManager.set_muted(true)
```

上述正式音频路径仅是接入示例，仓库不包含这些音频文件。初始可用音效 ID：
`ui_confirm`、`pickup`、`hurt`、`jump`、`victory`、`game_over`。
未知 ID 返回 `false`，不会中断游戏。音效最多同时占用 8 个播放器，超过时复用最旧的播放器。
BGM 由独立播放器负责；循环由音频资源的 Loop 设置决定。
静音和音量使用独立的 Music/SFX 总线，在主菜单、重开和返回流程中保持，当前不跨进程保存。

接口沿用 Godot 的 [Autoload](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html)
与 [AudioServer 总线](https://docs.godotengine.org/en/stable/classes/class_audioserver.html) 机制。

## 验收

自动化命令见根目录 README。`tests/run-tests.ps1` 会先导入项目，再执行验收场景，
同时检查返回码、日志里的错误/警告和最终结果；可以用 `-Screenshots` 保存真实渲染截图。
测试用 UI 鼠标事件触发开始/重开/返回和静音，用物理碰撞触发拾取、尖刺、出口和深渊死亡，
并测试 A 风格的数据源、非默认生命上限、源替换/解绑、结算保护和音频接口。
音频验收使用 Dummy 驱动验证调用和状态，最终音色及响度请通过正常运行项目试听。

人工验收步骤：

1. F5 启动，看到主菜单；点“开始游戏”进入横版关卡。
2. 左右移动并跳台，拾取金色碎片；得分立即增加 100。
3. 站上红色尖刺，观察生命数值和生命条同步降低。
4. 生命归零或掉入深渊，看到 Game Over 弹窗，背景关卡停止。
5. 点“重新开始”，生命回到 100、得分归零，碎片恢复。
6. 穿过两处深渊并抵达右侧绿色门扉，看到胜利结算；确认同样可以重开。
7. 在关卡或结算界面返回主菜单，再次开始；切换静音，确认状态保持。
