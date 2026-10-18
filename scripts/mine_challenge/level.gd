extends Node2D
const EnvironmentScript=preload("res://scripts/mine_challenge/environment.gd")
const MineAudio=preload("res://scripts/mine_challenge/mine_audio.gd")
const Effects=preload("res://scripts/mine_challenge/mineral_effects.gd")
const PlayerScript=preload("res://scripts/mine_challenge/player.gd")
const VentScene=preload("res://scenes/mine_challenge/toxic_gas_vent.tscn")
const SwitchScene=preload("res://scenes/mine_challenge/weight_switch_and_crate.tscn")
const LeverScene=preload("res://scenes/mine_challenge/gas_redirect_lever.tscn")
const AcidScene=preload("res://scenes/mine_challenge/deadly_acid_pit.tscn")
const BridgeScene=preload("res://scenes/mine_challenge/collapsing_crystal_bridge.tscn")
const SettingsScript=preload("res://scripts/ui/settings_panel.gd")
const GuideScript=preload("res://scripts/ui/first_use_guide.gd")
const LifeOrbsScript=preload("res://scripts/ui/life_orbs.gd")
const STAGES=["START", "CRYSTALLIZE THE FIRST VENT", "PUSH CRATE / OPEN GAS SHAFT", "CLIMB THE GAS SHAFT", "REDIRECT THE GAS FLOW", "CROSS THE COLLAPSING BRIDGE", "NARROW DOUBLE JUMP ASCENT", "EXIT"]
const STAGES_ZH=["矿坑入口", "矿化首个气柱", "推箱开启主气阀", "攀升毒气竖井", "重新引导气流", "穿越崩塌晶桥", "窄台二段跳攀升", "矿坑出口"]
const CHECKPOINTS=[Vector2(180,1778),Vector2(560,1778),Vector2(1200,1428),Vector2(1870,1818),Vector2(2540,698),Vector2(2510,1728),Vector2(4500,1678),Vector2(5340,378)]
const REGIONS=[Rect2(70,1650,490,200),Rect2(610,1545,1130,330),Rect2(1100,1300,720,170),Rect2(1820,460,620,1400),Rect2(2450,510,870,240),Rect2(2450,1450,2000,340),Rect2(4480,430,850,1290),Rect2(5290,240,280,180)]
var environment: Node2D
var mine_audio: Node
var interaction_hints: Node2D
var player: CharacterBody2D
var vents: Array[Node2D]=[]
var shaft_vents: Array[Node2D]=[]
var cliff_vents: Array[Node2D]=[]
var bridge: Node2D
var weight_switch: Node2D
var lever: Node2D
var current_stage := 1
var checkpoint_position := CHECKPOINTS[0]
var pulse_count := 0
var vents_mineralized := 0
var sequestered := 0.0
var _decks: Array[Rect2]=[]
var _trapdoor: StaticBody2D
var _hud: Control
var _stage_label: Label
var _jump_label: Label
var _carbon_label: Label
var _health_label: Label
var _life_orbs: LifeOrbsScript
var _cooldown_label: Label
var _cooldown: ProgressBar
var _tutorial: Label
var _tutorial_seconds := 0.0
var _summary: PanelContainer
var _settings: Control
var _clock := 0.0
var _campaign := false
var _cleared := false
var _persisted_valve := false
var _returning := false
var life_source: MineLifeSeam
var extraction: LandExtraction
var chapter_status: ChapterStatusHUD
var _local_result: Control

func _ready() -> void:
	set_meta(&"custom_hud",true)
	_campaign=get_parent().name=="LevelRoot"
	if not _campaign:
		WorldProgress.campaign_rules=true
		if GameSession.state!=GameSession.State.PLAYING: GameSession.start_run()
		if WorldProgress.current_scene==&"lone_tree": WorldProgress.borrow_ability(&"double_jump")
		WorldProgress.current_scene=&"grassland"
	WorldProgress.finish_scene_load()
	_returning=WorldProgress.core_reversed
	EdenInputBindings.configure()
	if not InputMap.has_action(&"mine_pulse"):
		InputMap.add_action(&"mine_pulse")
		for key in [KEY_E,KEY_J,KEY_C]:
			var event:=InputEventKey.new()
			event.physical_keycode=key
			InputMap.action_add_event(&"mine_pulse",event)
	mine_audio=MineAudio.new()
	add_child(mine_audio)
	environment=EnvironmentScript.new()
	environment.level=self
	add_child(environment)
	_build_layout()
	player=PlayerScript.new()
	player.name="Player"
	player.level=self
	player.position=CHECKPOINTS[0]
	add_child(player)
	life_source=MineLifeSeam.new()
	add_child(life_source)
	life_source.setup(&"mineralization","mine",Vector2(420,1800))
	extraction=LandExtraction.new()
	add_child(extraction)
	_read_progress()
	_build_hud()
	_build_interaction_hints()
	if not _campaign:
		var subtitles:=preload("res://scripts/ui/dialogue.gd").new()
		_hud.add_child(subtitles)
		WorldProgress.dialogue_requested.connect(subtitles.present)
		_local_result=preload("res://scenes/ui/result_dialog.tscn").instantiate()
		_hud.add_child(_local_result)
		_local_result.hide()
		GameSession.state_changed.connect(_on_standalone_state)
	if _returning:
		_build_return_route()
		current_stage=8
		checkpoint_position=CHECKPOINTS[7]
		player.position=checkpoint_position
	else:
		activate_stage(current_stage,true)
	GameText.language_changed.connect(_refresh_text)
	WorldProgress.ability_absorbed.connect(func(id: StringName) -> void:
		if id==&"mineralization": _tutorial_text(life_source.completion_notice())
	)
	_refresh_text()

func _build_layout() -> void:
	# Only entrance, checkpoint decks and the lever room are permanent.
	for rect: Rect2 in [Rect2(60,1800,540,44),Rect2(1120,1800,630,44),Rect2(1100,1450,720,30),Rect2(1820,1840,250,30),Rect2(2450,720,290,32),Rect2(2900,720,420,32),Rect2(2420,1750,180,32),Rect2(4450,1700,140,32),Rect2(5260,400,300,44)]:
		deck(rect)
	_trapdoor=deck(Rect2(2740,720,160,24))
	vent("first_bridge",Vector2(860,1800),520,4)
	vent("deck_relay_1",Vector2(1650,1670),106,4)
	vent("deck_relay_2",Vector2(1520,1540),106,4)
	for tier in 6:
		var point:=Vector2(2050 if tier%2==0 else 2250,1700-tier*220)
		shaft_vents.append(vent("shaft_%d"%tier,point,118,4,false))
		if tier<5:
			shaft_vents.append(vent("shaft_relay_%d"%tier,Vector2(2150,point.y-110),84,4,false))
	# Each of the four main cliff plumes has mineralizable relay gas below it.
	var cliff_points=[Vector2(4560,1610),Vector2(4650,1480),Vector2(4710,1375),Vector2(4765,1270),Vector2(4820,1170),Vector2(4880,1065),Vector2(4950,960),Vector2(5010,860),Vector2(5070,755),Vector2(5130,650),Vector2(5190,550)]
	for index in cliff_points.size():
		cliff_vents.append(vent("cliff_%d"%index,cliff_points[index],72,2.8,false))
	weight_switch=SwitchScene.instantiate()
	weight_switch.position=Vector2(1310,1450)
	weight_switch.switch_offset=Vector2(410,0)
	add_child(weight_switch)
	weight_switch.valve_changed.connect(_set_shaft)
	lever=LeverScene.instantiate()
	lever.latch_on_activate=true
	lever.position=Vector2(2820,720)
	add_child(lever)
	lever.redirected.connect(_redirect_gas)
	bridge=BridgeScene.instantiate()
	bridge.position=Vector2(2600,1750)
	bridge.segment_width=185.0
	add_child(bridge)
	var acid:=AcidScene.instantiate()
	acid.position.y=2050
	add_child(acid)
	acid.actor_dissolved.connect(func(actor: Node2D) -> void:
		if actor==player: player.dissolve()
	)
	for index in 8:
		area(REGIONS[index],"Stage%dCheckpoint"%(index+1)).body_entered.connect(func(actor: Node2D) -> void:
			if actor==player: activate_stage(index+1)
		)
	area(Rect2(5400,280,130,120),"Exit").body_entered.connect(func(actor: Node2D) -> void:
		if actor==player: finish()
	)
	area(Rect2(60,1660,50,150),"HomewardExit").body_entered.connect(func(actor: Node2D) -> void:
		if actor==player and _returning and WorldProgress.ability_state(&"mineralization")==WorldProgress.AbilityState.RETURNED:
			WorldProgress.enter_scene(&"lone_tree",CampaignLevels.definition(&"lone_tree").exit-Vector2(40,24))
	)

func deck(rect: Rect2) -> StaticBody2D:
	_decks.append(rect)
	var body:=StaticBody2D.new()
	body.position=rect.position
	body.collision_layer=1
	var collision:=CollisionShape2D.new()
	var shape:=RectangleShape2D.new()
	shape.size=rect.size
	collision.shape=shape
	collision.position=rect.size/2
	collision.one_way_collision=true
	body.add_child(collision)
	add_child(body)
	return body

func vent(id: String, point: Vector2, width: float, duration: float, powered: bool=true) -> Node2D:
	var node:=VentScene.instantiate()
	node.vent_id=id
	node.position=point
	node.width=width
	node.duration=duration
	node.powered=powered
	add_child(node)
	vents.append(node)
	return node

func area(rect: Rect2, title: String) -> Area2D:
	var node:=Area2D.new()
	node.name=title
	node.position=rect.get_center()
	node.collision_layer=0
	node.collision_mask=2
	var collision:=CollisionShape2D.new()
	var shape:=RectangleShape2D.new()
	shape.size=rect.size
	collision.shape=shape
	node.add_child(collision)
	add_child(node)
	return node

func activate_stage(stage: int, force: bool=false) -> void:
	if _returning: return
	var recovered_supply:=false
	# The upper balcony can be walked off without using the drop hatch. Arriving
	# at the real cliff proves the bridge was crossed, even if its trigger / lever
	# was missed. Restore the local supply and checkpoint instead of softlocking.
	if not force and stage==7 and current_stage in [5,6] and REGIONS[6].has_point(player.position):
		if not lever.active:
			lever.active=true
			_redirect_gas(true)
		current_stage=6
		recovered_supply=true
	if not force and (stage<=current_stage or stage>current_stage+1): return
	if stage>=6 and not lever.active: return
	current_stage=stage
	if not force:
		MineAudio.play_near(player,&"resonance",-8,0.82)
		Effects.burst(self,CHECKPOINTS[stage-1]+Vector2(0,16),&"resonance")
	checkpoint_position=CHECKPOINTS[stage-1]
	WorldProgress.set_checkpoint(StringName("mine/stage/%d"%stage),checkpoint_position,stage_name())
	_save_progress()
	_refresh_text()
	var id:="mine_stage_%d"%stage
	if GuideScript.claim(id):
		var hints=["Approach the living mineral seam to learn Carbon Mineralization.","Cast in mid-air to turn gas into a temporary bridge.","Push the crate onto the plate. Keep its weight there to power the shaft.","Jump, double jump, mineralize, land. Every relay is temporary gas-made rock.","Redirect the overhead gas pipe to open the descent hatch.","Keep moving! The bridge collapses from left to right.","Narrow platforms last 2.8 seconds. Land to refresh Double Jump.","Reach the illuminated doorway."]
		_tutorial_text(hints[stage-1])
	if recovered_supply:
		_tutorial_text("备用供气已恢复。矿化绿色毒雾，沿晶台向上攀登。")

func stage_name() -> String:
	return (STAGES_ZH if GameText.language=="zh_CN" else STAGES)[current_stage-1]

func mineralize_near(origin: Vector2, radius: float) -> int:
	if not WorldProgress.can_play() or not WorldProgress.has_ability(&"mineralization"): return 0
	var count:=0
	for node in vents:
		if origin.distance_to(node.global_position)<=radius and node.mineralize(): count+=1
	if count>0:
		pulse_count+=1
		vents_mineralized+=count
		sequestered+=150.0
		WorldProgress.report_ability_used(&"mineralization")
		CarbonLedger.store_carbon(StringName("mine_challenge/pulse_%d"%pulse_count),150.0)
		_save_progress()
	return count

func _set_shaft(open: bool) -> void:
	_persisted_valve=open
	for node in shaft_vents: node.set_powered(open and not _returning)
	_save_progress()

func _redirect_gas(active: bool) -> void:
	for node in cliff_vents: node.set_powered(active and not _returning)
	_trapdoor.get_child(0).set_deferred(&"disabled",active)
	_save_progress()
	queue_redraw()

func _build_interaction_hints() -> void:
	interaction_hints=preload("res://scripts/presentation/interaction_hints.gd").new()
	interaction_hints.actor=player
	add_child(interaction_hints)
	interaction_hints.offer(func() -> Vector2: return lever.position,func() -> String: return "T",115,Vector2(0,-100))
	interaction_hints.offer(func() -> Vector2: return Vector2(280,1778),func() -> String: return "T",115,Vector2(-24,-84))
	interaction_hints.offer(func() -> Vector2: return life_source.position,func() -> String:
		if _returning and WorldProgress.has_ability(&"mineralization"): return "R"
		return "E" if WorldProgress.ability_state(&"mineralization")==WorldProgress.AbilityState.UNAVAILABLE and player.is_on_floor() else ""
	,140,Vector2(0,-96))
	for node: Node2D in vents:
		interaction_hints.offer(func() -> Vector2: return node.position,func() -> String: return _vent_hint_key(node),player.pulse_radius,Vector2(0,-96))

func _vent_hint_key(node: Node2D) -> String:
	if _returning or not WorldProgress.has_ability(&"mineralization") or not node.powered or is_instance_valid(node.platform) or player.cooldown>0: return ""
	var distance:=player.position.distance_to(node.position)
	for other in vents:
		if other!=node and other.powered and not is_instance_valid(other.platform) and player.position.distance_to(other.position)<distance: return ""
	return "E"

func interact() -> void:
	if player.position.distance_to(lever.position)<115:
		lever.interact()
	elif player.position.distance_to(Vector2(280,1778))<115:
		WorldProgress.request_dialogue(GameText.t("艾拉 · 矿工"),[GameText.t("捕获的二氧化碳与矿物反应，能形成固态碳酸盐。这就是碳矿化。"),GameText.t("矿化后的气柱能暂时承重。平台碎裂后，碳仍留在落下的矿石中。"),GameText.t("每次有效矿化模拟固定 150 kg CO₂e。数值是关卡教学模型。")])

func restore_oasis() -> void:
	if not _returning or player.position.distance_to(life_source.position)>150: return
	WorldProgress.repair_current_region()
	WorldProgress.return_ability(&"mineralization")
	_tutorial_text("The mine is restored. Follow the ramp left to the Junkyard.")

func try_extract() -> bool:
	if WorldProgress.ability_state(&"mineralization")!=WorldProgress.AbilityState.UNAVAILABLE or player.position.distance_to(life_source.position)>140: return false
	extraction.begin(player,life_source)
	return true

func _on_standalone_state(_previous: int,current: int) -> void:
	if current==GameSession.State.GAME_OVER:
		_local_result.present(GameSession.last_result)
	elif current==GameSession.State.PLAYING:
		get_tree().reload_current_scene.call_deferred()
	elif current==GameSession.State.MAIN_MENU:
		get_tree().change_scene_to_file.call_deferred("res://scenes/main.tscn")

func reset_attempt() -> void:
	for node in vents: node.reset()
	bridge.reset()
	# Completed stages remain recoverable even if a mechanism was later undone.
	if current_stage>=4 and not _persisted_valve:
		weight_switch.crate.position=weight_switch.switch_offset+Vector2(0,-24)
		weight_switch.crate.velocity=Vector2.ZERO
		_set_shaft(true)
	if current_stage>=6 and not lever.active:
		lever.active=true
		_redirect_gas(true)
	if current_stage<=3 and not weight_switch.pressed:
		weight_switch.crate.position=Vector2(0,-24)
		weight_switch.crate.velocity=Vector2.ZERO
	_tutorial_text("Checkpoint restored. Your captured-carbon total is retained.")

func _save_progress() -> void:
	WorldProgress.mine_challenge={"stage":current_stage,"pulses":pulse_count,"vents":vents_mineralized,"stored":sequestered,"valve":_persisted_valve,"lever":lever.active if is_instance_valid(lever) else false}

func _read_progress() -> void:
	var data:=WorldProgress.mine_challenge
	current_stage=clampi(data.get("stage",1),1,8)
	pulse_count=data.get("pulses",0)
	vents_mineralized=data.get("vents",0)
	sequestered=data.get("stored",0.0)
	checkpoint_position=CHECKPOINTS[current_stage-1]
	player.position=checkpoint_position
	if data.get("valve",false) or current_stage>=4:
		weight_switch.crate.position=weight_switch.switch_offset+Vector2(0,-24)
		_set_shaft(true)
	if data.get("lever",false) or current_stage>=6:
		lever.active=true
		_redirect_gas(true)

func _build_return_route() -> void:
	for node in vents: node.set_powered(false)
	var body:=StaticBody2D.new()
	var slope:=PackedVector2Array([Vector2(200,1800),Vector2(5420,400),Vector2(5420,425),Vector2(200,1825)])
	var collision:=CollisionPolygon2D.new()
	collision.polygon=slope
	body.add_child(collision)
	add_child(body)

func _build_hud() -> void:
	var canvas:=CanvasLayer.new()
	canvas.layer=9
	add_child(canvas)
	_hud=Control.new()
	_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_hud.theme=preload("res://assets/ui_theme.tres")
	canvas.add_child(_hud)
	chapter_status=ChapterStatusHUD.new()
	_hud.add_child(chapter_status)
	_life_orbs=chapter_status.life_orbs
	_stage_label=chapter_status.stage_label
	_jump_label=chapter_status.jump_label
	_cooldown_label=chapter_status.skill_label
	_cooldown=chapter_status.cooldown
	_cooldown.max_value=0.6
	_carbon_label=chapter_status.carbon_label
	_health_label=chapter_status.detail_label
	var settings_button:=Button.new()
	settings_button.text=GameText.t("设置")
	settings_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	settings_button.offset_left=-150
	settings_button.offset_right=-20
	settings_button.offset_top=20
	settings_button.offset_bottom=64
	_hud.add_child(settings_button)
	_settings=SettingsScript.new()
	_hud.add_child(_settings)
	settings_button.pressed.connect(_settings.open)
	_tutorial=label(_hud,"",18)
	_tutorial.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_tutorial.offset_left=120
	_tutorial.offset_right=-120
	_tutorial.offset_top=-100
	_tutorial.offset_bottom=-24
	_tutorial.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_tutorial.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_tutorial.vertical_alignment=VERTICAL_ALIGNMENT_CENTER

func label(parent: Node, text: String, font_size: int) -> Label:
	var node:=Label.new()
	node.text=text
	node.add_theme_font_size_override(&"font_size",font_size)
	parent.add_child(node)
	return node

func _tutorial_text(text: String) -> void:
	if not is_instance_valid(_tutorial): return
	_tutorial.text=GameText.t(text)
	_tutorial_seconds=7.0

func _refresh_text() -> void:
	if not is_instance_valid(_stage_label): return
	_stage_label.text="%d / 8  %s"%[current_stage,stage_name()]
	if is_instance_valid(_tutorial): _tutorial.text=GameText.t(_tutorial.text)

func _process(delta: float) -> void:
	if WorldProgress.can_play():
		_clock+=delta
		_tutorial_seconds=maxf(0,_tutorial_seconds-delta)
	if is_instance_valid(_tutorial): _tutorial.visible=_tutorial_seconds>0 and WorldProgress.can_play()
	if is_instance_valid(player) and is_instance_valid(_jump_label):
		_jump_label.text=GameText.t("二段跳就绪") if player.jumps_used<2 else GameText.t("二段跳已用 · 落台恢复")
		_cooldown.value=0.6-player.cooldown
		_cooldown_label.text=GameText.t("矿化就绪") if player.cooldown<=0 else GameText.t("矿化冷却 %.1f 秒")%player.cooldown
		if not WorldProgress.has_ability(&"mineralization"):
			_cooldown_label.text=GameText.t("靠近能力源按 E 吸取") if WorldProgress.ability_state(&"mineralization")==WorldProgress.AbilityState.UNAVAILABLE else GameText.t("能力已交还 · 返程通路已开放")
		_health_label.text=GameText.t("已矿化 %d 个气柱")%vents_mineralized
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE and WorldProgress.can_play():
		_settings.open()
		get_viewport().set_input_as_handled()

func finish() -> void:
	if _returning or current_stage!=8 or _cleared or not WorldProgress.can_play(): return
	_cleared=true
	MineAudio.play_near(player,&"clear",-3)
	WorldProgress.narrative_active=true
	WorldProgress.narrative_kind=&"mine_clear"
	_summary=PanelContainer.new()
	_summary.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_summary.offset_left=-350
	_summary.offset_right=350
	_summary.offset_top=-190
	_summary.offset_bottom=190
	var summary_style:=StyleBoxFlat.new()
	summary_style.bg_color=Color(0.025,0.05,0.065,0.97)
	summary_style.border_color=Color(0.48,0.78,0.85)
	summary_style.border_width_left=3
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: summary_style.set_content_margin(side,24)
	_summary.add_theme_stylebox_override(&"panel",GothicSkin.panel(0,24))
	_hud.add_child(_summary)
	var box:=VBoxContainer.new()
	box.add_theme_constant_override(&"separation",16)
	_summary.add_child(box)
	label(box,GameText.t("矿坑挑战完成"),28)
	label(box,GameText.t("矿化气柱：%d\n永久固定：%.0f kg CO₂e")%[vents_mineralized,sequestered],22)
	var note:=label(box,GameText.t("临时承重的晶壳会碎裂，碳仍结合在固态矿石中。\n以上数值为游戏教学模型。"),16)
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var proceed:=Button.new()
	proceed.text=GameText.t("前往 Eden City")
	box.add_child(proceed)
	proceed.pressed.connect(continue_to_eden)
	proceed.grab_focus()

func continue_to_eden() -> void:
	if not _cleared: return
	WorldProgress.narrative_active=false
	WorldProgress.narrative_kind=&""
	if _campaign: WorldProgress.enter_scene(&"remnant_sea",Vector2(140,596))
	else:
		WorldProgress.current_scene=&"remnant_sea"
		WorldProgress.spawn_position=Vector2(140,596)
		get_tree().change_scene_to_file.call_deferred("res://scenes/main.tscn")

