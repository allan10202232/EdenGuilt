# EdenGuilt

> 仓库根目录是独立的系统验证工程；此前制作的《地脉固化》可玩原型保存在 [`prototype/`](prototype/)。在 Godot 中导入 `prototype/project.godot`，按 F5 运行。原型的操作和流程见 [`prototype/试玩说明.md`](prototype/试玩说明.md)。

横版 2D 类恶魔城项目，使用 **Godot 4.7.2 / GDScript / GL Compatibility**。
已将相邻 `eden` 项目的引擎配置、图标及文本配置整合到本仓库；原项目保留。

## 运行

1. 在 Godot 中导入仓库根目录的 `project.godot`。
2. 按 **F6** 可运行当前场景；正常试玩请按 **F5** 运行项目，从主菜单开始。
3. 点击“开始游戏”。**A/D 或左右方向键**移动，**空格/W/上方向键**跳跃。

金色碎片每个加 100 分，红色尖刺每次扣 25 生命（0.85 秒受伤间隔），落入深渊死亡。
抵达关卡右端的绿色门扉获胜。死亡和胜利均显示结算弹窗，可重新开始或返回主菜单。

## 程序员 B：第一阶段

- [x] 主菜单 → 游戏关卡 → Game Over / 胜利结算 → 重开 / 返回主菜单。
- [x] HUD 生命条、生命数值、得分通过信号实时响应游戏数据，支持可变生命上限。
- [x] `GameplayBridge` 对接程序员 A 的数据源，支持首次快照同步、重新绑定和解绑。
- [x] 常驻 `SoundManager`：音效注册/播放、多音效声道、BGM 播放/停止、音量及静音接口。
- [x] 横版占位验证关卡，以及真实 UI 输入和物理碰撞的自动化验收。

角色、石台、背景、碎片、尖刺和出口全部为几何占位素材；音效为代码合成短音。
当前角色移动只服务于系统验证；正式角色、攻击、敌人 AI 与美术仍由对应负责人接入。

详细职责、数据契约、音频 API 和验收步骤见 [程序员 B 第一阶段交接文档](docs/programmer-b-phase-one.md)。

## 自动化验收

在仓库目录运行（把路径替换为自己的 Godot 控制台程序）：

```powershell
.\tests\run-tests.ps1 -Godot 'C:\Tools\Godot_v4.7.2-stable_win64_console.exe'
```

需要渲染并保存主菜单、关卡、死亡和胜利截图时：

```powershell
.\tests\run-tests.ps1 -Godot 'C:\Tools\Godot_v4.7.2-stable_win64_console.exe' -Screenshots
```

也可以跨平台直接运行：

```text
godot --headless --path . --editor --import --quit
godot --headless --path . --audio-driver Dummy res://tests/phase_one_test.tscn
```

验收脚本会检查引擎退出码、错误日志和检查结果，任一失败都返回非零退出码。
生成的导入缓存、日志和截图均在 `.godot/`、`test-output/` 中，并已加入 Git 忽略规则。
