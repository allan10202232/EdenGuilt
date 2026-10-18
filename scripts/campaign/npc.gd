class_name CampaignNPC
extends Node2D
var player: CharacterBody2D
var region: StringName
var _clock:=0.0
var _prompt: Label

func _ready() -> void:
	var sprite:=Sprite2D.new()
	sprite.texture=CampaignLevels.trimmed_texture("characters/hero_green")
	sprite.scale=Vector2.ONE*58.0/sprite.texture.get_height()
	sprite.position.y=-14
	sprite.modulate=Color(0.77,0.79,0.64) if region==&"grassland" else Color(0.78,0.87,0.68)
	add_child(sprite)
	_prompt=Label.new()
	_prompt.theme=preload("res://assets/ui_theme.tres")
	_prompt.add_theme_font_size_override(&"font_size",14)
	_prompt.add_theme_color_override(&"font_outline_color",Color.BLACK)
	_prompt.add_theme_constant_override(&"outline_size",4)
	_prompt.position=Vector2(-70,-83)
	add_child(_prompt)
	GameText.language_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	# The level's circular T medallion owns the proximity affordance.
	_prompt.text=""

func _process(delta: float) -> void:
	if not is_instance_valid(player): return
	_prompt.visible=WorldProgress.can_play() and player.position.distance_to(position)<110
	if WorldProgress.can_play(): _clock+=delta
	get_child(0).position.y=-14+sin(_clock*1.8)*1.5

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"eden_talk") and not event.is_echo() and WorldProgress.can_play() and is_instance_valid(player) and player.position.distance_to(position)<110:
		var content:=conversation()
		if WorldProgress.request_dialogue(content.speaker,content.lines):
			player.combat.cancel()
			get_viewport().set_input_as_handled()

func conversation() -> Dictionary:
	if WorldProgress.returning:
		return {"speaker":GameText.t("同行的居民"),"lines":[GameText.t("我们会一起修好回家的路。力量可以交还，你不必独自承担。"),GameText.t("回到每处绿洲与居民共同修复。累计碳账本不会清零，但大地可以重新生长。")]}
	match region:
		&"lone_tree":
			return {"speaker":GameText.t("莫斯 · 拾荒者"),"lines":[GameText.t("你醒在垃圾场。城里丢下的东西，最终都会来到这里。"),GameText.t("地面的余绿还能回应提取器。前方绿洲的生命能够汇聚，赋予你二段跳。"),GameText.t("二段跳能帮你越过断崖，但每次都会留下 5 kg 的模拟碳排放。"),GameText.t("向右穿过矿洞，你会看到 Eden City。别只相信城墙内的春天。")]}
		&"grassland":
			return {"speaker":GameText.t("艾拉 · 矿工"),"lines":[GameText.t("矿洞的毒素来自伊甸城的废气。碰到浓雾会中毒，离开毒雾后会慢慢恢复。"),GameText.t("先从绿洲获得碳矿化，再固化节点。每次成功施法记 1 kg。"),GameText.t("石刻给出了次序：I 晶桥，II 上游喷口，III 下游喷口。先接通晶桥，再依次封住两处毒源。"),GameText.t("三个封印全部固定，出口的净化门才会打开。走错顺序不会消耗碳排放。")]}
	return {"speaker":GameText.t("赛恩 · 守档人"),"lines":[GameText.t("欢迎来到 Eden City。这里的绿色并没有消除污染，只是把它送到了别人看不见的地方。"),GameText.t("城内有两处绿洲，分别赋予护盾和黑穿。黑穿能够穿过紫色暗壁。"),GameText.t("击败能源守卫，进入右侧档案。是否公开真相，由你决定。")]}
