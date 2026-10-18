class_name ParkourHUD
extends CanvasLayer

var level: Node
var section_label: Label
var jump_label: Label
var deaths_label: Label
var hint_label: Label
var progress: ProgressBar

func _ready() -> void:
	# The shared UI (layer 10) owns settings and story modals. Keep this
	# chapter's status below them so it cannot cover buttons or subtitles.
	layer = 9
	var panel := PanelContainer.new()
	panel.position = Vector2(24, 104)
	panel.custom_minimum_size = Vector2(390, 170)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025,0.055,0.07,0.98)
	style.border_color = Color("69dbb3")
	style.set_border_width_all(2)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 7)
	panel.add_child(rows)
	for kind in 4:
		var label := Label.new()
		label.add_theme_font_size_override("font_size", 17 if kind == 0 else 14)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rows.add_child(label)
		match kind:
			0: section_label = label
			1: jump_label = label
			2: deaths_label = label
			3:
				hint_label = label
				label.custom_minimum_size.x = 364
				label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	progress = ProgressBar.new()
	progress.custom_minimum_size.y = 5
	progress.max_value = 9600
	progress.show_percentage = false
	rows.add_child(progress)

func _process(_delta: float) -> void:
	if not is_instance_valid(level) or not is_instance_valid(level.player): return
	var info: Dictionary = ScrapyardLayout.SECTIONS[level.current_section]
	section_label.text = "%d / 6  %s" % [level.current_section + 1, ScrapyardLayout.text(info.name, info.zh)]
	var ready: bool = level.player.air_jump_available()
	jump_label.text = ScrapyardLayout.text("AIR JUMP  ", "二段跳  ") + (ScrapyardLayout.text("RETURNED · rescue path open", "已交还 · 返程通道已铺设") if WorldProgress.route_open(&"double_jump") else ScrapyardLayout.text("READY  ●", "可用  ●") if ready else ScrapyardLayout.text("USED · land to recharge", "已使用 · 落地恢复") if WorldProgress.has_ability(&"double_jump") else ScrapyardLayout.text("LOCKED · E at oasis", "未获得 · 绿洲处按 E"))
	jump_label.modulate = Color("a4ffd3") if ready else Color("d9c8a0")
	deaths_label.text = ScrapyardLayout.text("DEATHS / RESPAWNS  %d   ·   CP %d / 6", "死亡 / 重生  %d   ·   检查点 %d / 6") % [WorldProgress.scrapyard_deaths, level.current_section + 1]
	hint_label.text = ScrapyardLayout.text(info.tip, info.hint) + "\n" + ScrapyardLayout.text("CO₂ %.0f kg gross · %.0f kg stored*", "CO₂ 累计 %.0f kg · 固定 %.0f kg*") % [CarbonLedger.gross_kg, CarbonLedger.stored_kg]
	progress.value = level.player.position.x
