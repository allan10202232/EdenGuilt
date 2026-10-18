# 三关动作探索试玩版

Godot 导入仓库根目录 `project.godot` 后按 F5。默认主菜单启动三关；`prototype/` 仍是此前 main 分支的独立工程。

## 路线

森林吸收二段跳 → 垃圾场吸收冲刺 → 矿厂吸收护盾 → 击败晶甲监工 → 最右端救援舱救出伙伴。
随后向左返程，在矿厂、垃圾场、森林原能力源按 R 依次交还，最后从森林左端回家。
救援前禁止交还关卡能力，避免首次探索时失去关键技能。光刃暂为开局武器，不纳入三种必要交还。

每关有三个或四个灯火检查点，触碰可回复 30 生命。死亡后可满血从最近检查点继续，
保留得分、敌人击败、碎片拾取、已借/已还能力和返程状态；重新开始整局清空上述数据。没有磁盘存档。

森林有上下碎片支路和断崖；垃圾场有高架废铁台、冲刺缺口及有预警的电弧；矿厂有晶矿竖井、蒸汽区和终点战斗。
普通小怪 1 HP，Boss 6 HP。机械敌人预警后射击，监工预警后发动近身范围攻击。护盾和冲刺期间免伤。
完成交还会生成桥梁/坡道；矿厂返程关闭蒸汽，垃圾场返程关闭电弧，避免对应能力失去后软锁。

## 代码与扩展

| 文件 | 内容 |
| --- | --- |
| `scripts/campaign/level_catalog.gd` | 三关布局、颜色、敌人巡逻范围、能力源、检查点、返回路线 |
| `scripts/campaign/level.gd` | 地形碰撞、视差画面、场景出口、拾取、伙伴跟随和返程安装 |
| `scripts/campaign/enemy.gd` | 巡逻、接触伤害、机械射击、Boss 预警与近战受击 |
| `scripts/campaign/hazard.gd` | 关闭 → 预警 → 喷发的时序危险 |
| `scripts/campaign/projectile.gd` | 有墙体遮挡的机械弹丸 |
| `scripts/ui/route_map.gd` | 当前关卡的路线缩略图 |
| `scenes/campaign/` | 三个可独立编辑的关卡场景 |

复用旧 WorldProgress 的稳定 ID，避免破坏 A/B 接口：`lone_tree` 显示为森林，`grassland` 显示为垃圾场，
`remnant_sea` 显示为矿厂。这是本次用户指定三关主题后的映射，不修改原始设计文档的历史内容。

`main.gd` 的 `campaign_mode` 默认开启，`CAMPAIGN_SCENES` 映射三关；关闭后使用旧 `level_scene/region_scenes` 的几何验收房。
玩家目前复用 `placeholder_player.gd` 的玩法适配器，并由 `campaign_character` 开关切换成原画透明角色。
E/Q/R 和两种近战仍沿用已约定接口。正式替换角色或战斗时保留 Stats/GameplayBridge 与 MeleeCombat 的契约。

`WorldProgress.set_checkpoint(id, position, label)` 保存本关灯火位置，返回值为是否改变；调用者可据此播放反馈或治疗。
本局持续实体 ID 为 `地区/mob_N`、`地区/shard_N`、`remnant_sea/boss`，重载时跳过已击败/拾取实体。
背景图片只是装饰；所有站立面都由关卡数据创建碰撞并绘制前景地形，避免背景平台误导。

## 验收与当前限制

`tests/run-tests.ps1` 依次运行旧系统验收、近战验收和 `tests/campaign/campaign_test.tscn`。
三关验收通过实际加载场景、物理近战判定和输入检查敌人、能力、灯火、死亡恢复、Boss、救援和完整跨场景返程；
同时通过真实跳跃验证森林两处断崖、垃圾场冲刺缺口、矿厂入口及上升路段、失去二段跳后的返程坡道。
伙伴跟随以实际移动验证间距。场景间长距离移动使用测试传送缩短运行时间。
`-Screenshots` 保存真实渲染截图供画面检查，不代表已经覆盖所有玩家操作组合。

2026-10-17 验证：Godot 4.7.2、GL Compatibility 真实渲染；系统 112 项、近战 41 项、三关 71 项，共 224 项通过。
三张移动后的原画 Git blob 与移动前相同。三关、Boss、伙伴跟随及胜利截图已人工查看，位于 `test-output/screenshots/`。

这是可玩的三关原型；角色/敌人目前使用静态美术加代码摆动，尚未制作逐帧动画、正式 BGM、磁盘存档或发布包。
普通小怪一击倒、护盾持续免伤、Boss 复用晶矿兽大图等属于试玩调参，后续可以替换。
