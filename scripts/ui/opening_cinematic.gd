extends Control
## Opening-only presentation. The owner decides what to do after the last line.

signal sequence_finished

const REVEAL_SHADER = preload("res://assets/shaders/opening_reveal.gdshader")
const CHAPTERS: Array[Dictionary] = [
	{
		"title": "THE SOUL EXTRACTOR",
		"path": "res://assets/art/generated/opening/soul_extractor.png",
		"lines": [
			"The Soul Extractor turns the life force of the land into tangible technology.",
			"Once its life force is drained, the land can never be used again.",
		],
	},
	{
		"title": "EDEN, THE RING CITY",
		"path": "res://assets/art/generated/opening/eden_city.png",
		"lines": [
			"The abuse of Soul Extractors has left 90% of the world a lifeless crystalline desert.",
			"Only Eden, the ring city towering above the clouds, preserves the last 10%: forests, lakes, and an endless spring.",
		],
	},
	{
		"title": "BENEATH THE CITY",
		"path": "res://assets/art/generated/opening/undercity.png",
		"lines": [
			"Beneath the ring city, the poor live in mines carved into dead soil, surviving on synthetic protein.",
			"Each year, a few of the strongest and most vital are chosen to enter Eden.",
			"No one has ever heard back from them.",
		],
	},
	{
		"title": "A WAY IN",
		"path": "res://assets/art/generated/opening/discovery.png",
		"lines": [
			"Then our protagonist found a Soul Extractor—and resolved to enter Eden.",
		],
	},
]

@export_range(0.01, 20.0) var reveal_duration: float = 3.8
@export_range(0.01, 20.0) var final_reveal_duration: float = 3.2
@export_range(0.01, 5.0) var dissolve_duration: float = 0.65

var chapter_index: int = 0
var line_index: int = 0
var phase: StringName = &"revealing"
var is_complete: bool = false
var art_view: TextureRect
var narration_label: Label
var assets_ready: bool = false

var _textures: Array[Texture2D] = []
var _material: ShaderMaterial
var _subtitle_panel: Control
var _chapter_label: Label
var _advance_label: Label
var _progress_label: Label
var _missing_art_label: Label
var _phase_elapsed: float = 0.0
var _panel_top: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	_load_artwork()
	_build_presentation()
	resized.connect(_layout_presentation)
	_layout_presentation()
	_begin_chapter(0)


func _load_artwork() -> void:
	assets_ready = true
	for chapter in CHAPTERS:
		var texture: Texture2D = null
		var path: String = chapter["path"]
		if ResourceLoader.exists(path):
			texture = load(path) as Texture2D
		if texture == null:
			assets_ready = false
			push_warning("Opening artwork is missing or unreadable: " + path)
		_textures.append(texture)


func _build_presentation() -> void:
	_material = ShaderMaterial.new()
	_material.shader = REVEAL_SHADER
	art_view = TextureRect.new()
	art_view.name = "Artwork"
	art_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art_view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_view.material = _material
	add_child(art_view)

	_missing_art_label = Label.new()
	_missing_art_label.text = "Opening artwork could not be loaded."
	_missing_art_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_missing_art_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_missing_art_label.add_theme_color_override("font_color", Color.WHITE)
	_missing_art_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_missing_art_label)

	_subtitle_panel = Control.new()
	_subtitle_panel.name = "Subtitles"
	_subtitle_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_subtitle_panel)

	_chapter_label = Label.new()
	_chapter_label.add_theme_color_override("font_color", Color.WHITE)
	_chapter_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_subtitle_panel.add_child(_chapter_label)

	narration_label = Label.new()
	narration_label.name = "Narration"
	narration_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	narration_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	narration_label.add_theme_color_override("font_color", Color.WHITE)
	narration_label.add_theme_constant_override("line_spacing", 6)
	narration_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_subtitle_panel.add_child(narration_label)

	_advance_label = Label.new()
	_advance_label.add_theme_color_override("font_color", Color.WHITE)
	_advance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_advance_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_subtitle_panel.add_child(_advance_label)

	_progress_label = Label.new()
	_progress_label.add_theme_color_override("font_color", Color.WHITE)
	_progress_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_subtitle_panel.add_child(_progress_label)


func _layout_presentation() -> void:
	if art_view == null:
		return
	var viewport_size := size
	var ui_scale: float = clampf(viewport_size.y / 720.0, 0.78, 1.4)
	var horizontal_margin: float = maxf(32.0, (viewport_size.x - 1032.0 * ui_scale) * 0.5)
	_panel_top = viewport_size.y * 0.735
	art_view.position = Vector2(24.0 * ui_scale, 20.0 * ui_scale)
	art_view.size = Vector2(viewport_size.x - 48.0 * ui_scale, _panel_top - 34.0 * ui_scale)
	_missing_art_label.position = art_view.position
	_missing_art_label.size = art_view.size
	_subtitle_panel.position = Vector2(horizontal_margin, _panel_top + 12.0 * ui_scale)
	_subtitle_panel.size = Vector2(viewport_size.x - horizontal_margin * 2.0, viewport_size.y - _subtitle_panel.position.y)
	var content_width: float = _subtitle_panel.size.x
	_chapter_label.position = Vector2.ZERO
	_chapter_label.size = Vector2(content_width, 24.0 * ui_scale)
	_chapter_label.add_theme_font_size_override("font_size", int(14.0 * ui_scale))
	narration_label.position = Vector2(0, 30.0 * ui_scale)
	narration_label.size = Vector2(content_width, 88.0 * ui_scale)
	narration_label.add_theme_font_size_override("font_size", int(23.0 * ui_scale))
	_advance_label.position = Vector2(0, _subtitle_panel.size.y - 36.0 * ui_scale)
	_advance_label.size = Vector2(content_width, 24.0 * ui_scale)
	_advance_label.add_theme_font_size_override("font_size", int(13.0 * ui_scale))
	_progress_label.position = _advance_label.position
	_progress_label.size = Vector2(content_width * 0.5, 24.0 * ui_scale)
	_progress_label.add_theme_font_size_override("font_size", int(13.0 * ui_scale))
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("080d12"))
	if _panel_top > 0.0:
		draw_line(Vector2(40.0, _panel_top), Vector2(size.x - 40.0, _panel_top), Color("28342e"), 1.0)


func _begin_chapter(index: int) -> void:
	chapter_index = index
	line_index = 0
	phase = &"revealing"
	_phase_elapsed = 0.0
	_subtitle_panel.modulate.a = 1.0
	art_view.texture = _textures[chapter_index]
	_missing_art_label.visible = art_view.texture == null
	_material.set_shader_parameter("visibility", 0.0)
	_material.set_shader_parameter("soft_fade", chapter_index == CHAPTERS.size() - 1)
	_material.set_shader_parameter("chapter_seed", float(chapter_index * 73))
	if art_view.texture != null:
		var texture_size := art_view.texture.get_size()
		var grid_width: float = minf(texture_size.x, 384.0)
		_material.set_shader_parameter("pixel_grid", Vector2(grid_width, grid_width * texture_size.y / texture_size.x))
	_update_text()


func _update_text() -> void:
	var chapter: Dictionary = CHAPTERS[chapter_index]
	narration_label.text = chapter["lines"][line_index]
	_chapter_label.text = "%02d  /  %s" % [chapter_index + 1, chapter["title"]]
	_progress_label.text = "%02d / 04     %d / %d" % [chapter_index + 1, line_index + 1, chapter["lines"].size()]
	_advance_label.text = "ENTER  /  BEGIN" if chapter_index == CHAPTERS.size() - 1 else "ENTER  /  CONTINUE"


func _process(delta: float) -> void:
	if is_complete:
		return
	_phase_elapsed += delta
	if phase == &"revealing":
		var duration: float = final_reveal_duration if chapter_index == CHAPTERS.size() - 1 else reveal_duration
		var progress: float = minf(1.0, _phase_elapsed / maxf(duration, 0.001))
		_material.set_shader_parameter("visibility", smoothstep(0.0, 1.0, progress))
		if progress >= 1.0:
			phase = &"reading"
	elif phase == &"dissolving":
		var progress: float = minf(1.0, _phase_elapsed / maxf(dissolve_duration, 0.001))
		_material.set_shader_parameter("visibility", 1.0 - progress)
		_subtitle_panel.modulate.a = 1.0 - progress
		if progress >= 1.0:
			if chapter_index + 1 < CHAPTERS.size():
				_begin_chapter(chapter_index + 1)
			else:
				is_complete = true
				phase = &"finished"
				set_process(false)
				sequence_finished.emit()


func _input(event: InputEvent) -> void:
	if is_complete or not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if key_event.keycode != KEY_ENTER and key_event.keycode != KEY_KP_ENTER:
		return
	get_viewport().set_input_as_handled()
	if key_event.pressed and not key_event.echo:
		advance()


func advance() -> void:
	if is_complete or phase == &"dissolving":
		return
	# A press while the image builds also advances the narration exactly once.
	# Holding Enter never queues more advances across a transition.
	_material.set_shader_parameter("visibility", 1.0)
	phase = &"reading"
	var lines: Array = CHAPTERS[chapter_index]["lines"]
	if line_index + 1 < lines.size():
		line_index += 1
		_update_text()
	else:
		phase = &"dissolving"
		_phase_elapsed = 0.0
		_material.set_shader_parameter("soft_fade", false)
		_advance_label.text = ""


func get_sequence_state() -> Dictionary:
	return {
		"chapter": chapter_index,
		"line": line_index,
		"phase": phase,
		"finished": is_complete,
		"assets_ready": assets_ready,
		"text": narration_label.text if narration_label != null else "",
	}
