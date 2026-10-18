extends Control

const SettingsPanelScript = preload("res://scripts/ui/settings_panel.gd")
signal start_requested
var _settings: SettingsPanelScript


func _ready() -> void:
	_settings = SettingsPanelScript.new()
	add_child(_settings)
	var settings_button := Button.new()
	settings_button.text = GameText.t("设置")
	%StartButton.get_parent().add_child(settings_button)
	%StartButton.get_parent().move_child(settings_button,3)
	settings_button.pressed.connect(_settings.open)
	GameText.language_changed.connect(func() -> void: settings_button.text = GameText.t("设置"))
	$Margin/Columns/Panel/Actions/Controls.hide()
	$Margin/Columns/Panel/Actions/Note.hide()
	%MuteButton.hide()
	$Margin/Columns/Panel/Actions/LanguagePicker.hide()
	%CombatDemoButton.hide()
	%StartButton.pressed.connect(_start)
	%MuteButton.pressed.connect(_toggle_sound)
	%CombatDemoButton.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/combat/melee_demo.tscn")
	)
	SoundManager.mute_changed.connect(_update_sound)
	_update_sound(SoundManager.muted)


func focus_default() -> void:
	%StartButton.grab_focus()


func _start() -> void:
	SoundManager.play_sfx(&"ui_confirm")
	start_requested.emit()


func _toggle_sound() -> void:
	SoundManager.set_muted(not SoundManager.muted)
	SoundManager.play_sfx(&"ui_confirm")


func _update_sound(muted: bool) -> void:
	%MuteButton.text = GameText.t("声音：关闭") if muted else GameText.t("声音：开启")
