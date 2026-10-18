class_name LanguagePicker
extends OptionButton

func _ready() -> void:
	name="LanguagePicker"
	auto_translate_mode=Node.AUTO_TRANSLATE_MODE_DISABLED
	add_item("English")
	add_item("简体中文")
	add_theme_font_size_override(&"font_size",16)
	custom_minimum_size.x=126
	item_selected.connect(func(index: int) -> void: GameText.set_language("en" if index==0 else "zh_CN"))
	GameText.language_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	select(0 if GameText.language=="en" else 1)

static func popup_is_open(root: Node) -> bool:
	for picker in root.find_children("*","OptionButton",true,false):
		if picker.get_popup().visible: return true
	return false
