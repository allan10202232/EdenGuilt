extends Node
## Exercise narration with actual key events; visual mode records every illustration.

const OPENING_PATH := "res://scenes/opening_cinematic.tscn"
const LINE_COUNTS := [2, 2, 3, 1]
const EXPECTED_ASSETS := ["soul_extractor", "eden_city", "undercity", "discovery"]
var _checks := 0
var _failures := 0
var _finished_count := 0
var _opening
var _screenshots := false


func _ready() -> void:
	_screenshots = "--screenshots" in OS.get_cmdline_user_args()
	get_tree().create_timer(35.0).timeout.connect(func() -> void:
		push_error("Opening acceptance timed out")
		get_tree().quit(1)
	)
	_run.call_deferred()


func _run() -> void:
	var packed := load(OPENING_PATH) as PackedScene
	_check(packed != null, "opening cinematic scene loads")
	if packed == null:
		_finish()
		return
	get_window().content_scale_size = Vector2i(1280, 720)
	get_window().size = Vector2i(1280, 720)
	_opening = packed.instantiate()
	_opening.reveal_duration = 1.1 if _screenshots else 0.50
	_opening.final_reveal_duration = 1.1 if _screenshots else 0.50
	_opening.dissolve_duration = 0.15
	_opening.sequence_finished.connect(func() -> void: _finished_count += 1)
	add_child(_opening)
	await _frames(2)
	_check(_opening.CHAPTERS.size() == 4, "four chapters present")
	_check(_opening.get_sequence_state().assets_ready, "all four illustrations are ready")
	var count := 0
	for chapter_index in 4:
		var chapter: Dictionary = _opening.CHAPTERS[chapter_index]
		var lines: Array = chapter.lines
		_check(lines.size() == LINE_COUNTS[chapter_index], "chapter %d has the requested line count" % (chapter_index + 1))
		count += lines.size()
		var texture := load("res://assets/art/generated/opening/%s.png" % EXPECTED_ASSETS[chapter_index]) as Texture2D
		_check(texture != null and texture.get_width() > 0 and texture.get_height() > 0, "illustration %d is a valid texture" % (chapter_index + 1))
		for line in lines:
			_check(not String(line).is_empty() and not _has_chinese(String(line)), "English narrative text: " + String(line))
	_check(count == 8, "all eight narration lines are present")
	_check("90%" in _opening.CHAPTERS[1].lines[0] and "10%" in _opening.CHAPTERS[1].lines[1], "Eden narration preserves the requested world proportions")
	_check(GameSession.state == GameSession.State.MAIN_MENU and not CarbonLedger.enabled, "opening has no gameplay or ledger side effects")
	var initial_state: Dictionary = _opening.get_sequence_state()
	_key(true, true)
	_key(false)
	await _frames(1)
	_check(_opening.chapter_index == initial_state.chapter and _opening.line_index == initial_state.line, "held Enter echo and key release do not advance narration")
	if _screenshots:
		await _capture("opening-01-pixel-reveal")
	# A deliberate Enter during reveal advances only the immediately following line.
	_check(_opening.phase == &"revealing", "early input is tested while the illustration is still revealing")
	_key(true)
	_key(false)
	await _frames(2)
	_check(_opening.chapter_index == 0 and _opening.line_index == 1, "Enter during reveal advances exactly one line")
	await _wait_reading()
	await _verify_layout("extractor line 2")
	await _capture("opening-01-soul-extractor")
	for chapter_index in range(1, 4):
		_key(true)
		_key(false)
		await _frames(1)
		_check(_opening.phase == &"dissolving", "last line starts a pixel transition")
		_key(true)
		_key(false)
		_key(true, true)
		_key(false)
		await _wait_reveal_or_reading()
		_check(_opening.chapter_index == chapter_index and _opening.line_index == 0, "transition input never skips the next chapter's first line")
		if _screenshots:
			await get_tree().create_timer(0.20).timeout
			await _capture("opening-%02d-reveal" % (chapter_index + 1))
		await _wait_reading()
		_check(_opening.art_view.texture.resource_path == "res://assets/art/generated/opening/%s.png" % EXPECTED_ASSETS[chapter_index], "chapter selects the correct illustration")
		for line_index in LINE_COUNTS[chapter_index]:
			_check(_opening.chapter_index == chapter_index and _opening.line_index == line_index, "narration order chapter %d line %d" % [chapter_index + 1, line_index + 1])
			_check(_opening.narration_label.text == String(_opening.CHAPTERS[chapter_index].lines[line_index]), "visible narration matches the active line")
			await _verify_layout("chapter %d line %d" % [chapter_index + 1, line_index + 1])
			await _capture("opening-%02d-line-%d" % [chapter_index + 1, line_index + 1])
			if line_index + 1 < LINE_COUNTS[chapter_index]:
				_key(true)
				_key(false)
				await _frames(2)
	_check(_finished_count == 0 and not _opening.is_complete, "final image waits for a deliberate Enter")
	_check(GameSession.elapsed_seconds == 0.0 and CarbonLedger.action_count == 0 and CarbonLedger.clock_seconds == 0.0, "narration does not run hidden timers or carbon actions")
	_key(true, false, KEY_KP_ENTER)
	_key(false, false, KEY_KP_ENTER)
	await get_tree().create_timer(0.30).timeout
	_check(_finished_count == 1 and _opening.is_complete, "keypad Enter finishes the cinematic once")
	for index in 3:
		_key(true)
		_key(false)
		_opening.advance()
	await _frames(2)
	_check(_finished_count == 1, "late input cannot emit completion twice")
	_check(GameSession.state == GameSession.State.MAIN_MENU and not CarbonLedger.enabled, "standalone cinematic never starts gameplay itself")
	_finish()


func _verify_layout(label: String) -> void:
	for viewport_size in [Vector2i(1280, 720), Vector2i(960, 600)]:
		get_window().content_scale_size = viewport_size
		get_window().size = viewport_size
		await _frames(3)
		var narration: Label = _opening.narration_label
		var viewport_rect := Rect2(Vector2.ZERO, Vector2(viewport_size))
		var rect := narration.get_global_rect()
		_check(viewport_rect.encloses(rect), "%s fits viewport %s" % [label, viewport_size])
		var font: Font = narration.get_theme_font("font")
		var line_height := font.get_height(narration.get_theme_font_size("font_size"))
		var text_height := narration.get_line_count() * line_height + maxi(0, narration.get_line_count() - 1) * narration.get_theme_constant("line_spacing")
		_check(text_height <= narration.size.y + 2.0, "%s has room for all text lines at %s" % [label, viewport_size])
		if label == "chapter 2 line 2" and viewport_size == Vector2i(960, 600):
			await _capture("opening-02-long-text-960")
	get_window().content_scale_size = Vector2i(1280, 720)
	get_window().size = Vector2i(1280, 720)
	await _frames(2)


func _wait_reading() -> void:
	var deadline := Time.get_ticks_msec() + 4000
	while _opening.phase != &"reading" and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	_check(_opening.phase == &"reading", "illustration becomes fully readable")


func _wait_reveal_or_reading() -> void:
	var deadline := Time.get_ticks_msec() + 2000
	while _opening.phase == &"dissolving" and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	_check(_opening.phase in [&"revealing", &"reading"], "pixel transition reaches next image")


func _key(pressed: bool, echo: bool = false, code: Key = KEY_ENTER) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	event.echo = echo
	get_viewport().push_input(event)


func _has_chinese(value: String) -> bool:
	for index in value.length():
		if value.unicode_at(index) >= 0x4e00 and value.unicode_at(index) <= 0x9fff:
			return true
	return false


func _capture(label: String) -> void:
	if not _screenshots:
		return
	await _frames(2)
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://test-output/screenshots")
	var error := get_viewport().get_texture().get_image().save_png("res://test-output/screenshots/%s.png" % label)
	_check(error == OK, "capture " + label)


func _frames(count: int) -> void:
	for index in count:
		await get_tree().process_frame


func _check(ok: bool, label: String) -> void:
	_checks += 1
	if ok:
		print("PASS: ", label)
	else:
		_failures += 1
		push_error("FAIL: " + label)


func _finish() -> void:
	print("OPENING: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(0 if _failures == 0 else 1)
