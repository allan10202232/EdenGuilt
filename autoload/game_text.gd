extends Node
const STRINGS = preload("res://localization/strings.tres")
## Both aliases are registered so already visible labels can change language live.
signal language_changed
var language: String = "en"
var catalog: Dictionary = {}
var _known: Dictionary = {}
var _patterns: Array[Dictionary] = []


func _enter_tree() -> void:
	catalog=STRINGS.messages
	var english:=Translation.new()
	english.locale="en"
	var chinese:=Translation.new()
	chinese.locale="zh_CN"
	for source: String in catalog:
		var translated: String=catalog[source]
		_known[source]=true
		_known[translated]=true
		english.add_message(source,translated)
		english.add_message(translated,translated)
		chinese.add_message(source,source)
		chinese.add_message(translated,source)
	TranslationServer.add_translation(english)
	TranslationServer.add_translation(chinese)
	var preferences:=ConfigFile.new()
	if preferences.load("user://preferences.cfg")==OK:
		language=preferences.get_value("display","language","en")
	if language not in ["en","zh_CN"]: language="en"
	TranslationServer.set_locale(language)


func t(source: String) -> String:
	if source.is_empty() or _known.has(source):
		return String(TranslationServer.translate(source))
	# Notices and snapshots may already contain formatted values in the old locale.
	# Match complete known templates, keeping numbers and semantic names intact.
	if _patterns.is_empty(): _build_patterns()
	for entry in _patterns:
		for regex: RegEx in entry.regexes:
			var matched:=regex.search(source)
			if matched==null: continue
			var destination: String=entry.en if language=="en" else entry.zh
			var placeholders:=RegEx.new()
			placeholders.compile("%(?:[0-9]+|\\.[0-9]+)?[sdf]")
			var text: String=""
			var cursor:=0
			var index:=1
			for slot in placeholders.search_all(destination):
				text+=destination.substr(cursor,slot.get_start()-cursor)+t(matched.get_string(index))
				cursor=slot.get_end()
				index+=1
			text+=destination.substr(cursor)
			return text.replace("%%","%")
	return String(TranslationServer.translate(source))


func _build_patterns() -> void:
	var placeholders:=RegEx.new()
	placeholders.compile("%(?:[0-9]+|\\.[0-9]+)?[sdf]")
	for source: String in catalog:
		if source.length()>400 or source.begins_with("<") or placeholders.search(source)==null: continue
		var regexes: Array[RegEx]=[]
		for template: String in [source,catalog[source]]:
			var pattern: String="(?s)^"
			var cursor:=0
			for slot in placeholders.search_all(template):
				pattern+=_escape(template.substr(cursor,slot.get_start()-cursor).replace("%%","%"))+"(.*?)"
				cursor=slot.get_end()
			pattern+=_escape(template.substr(cursor).replace("%%","%"))+"$"
			var regex:=RegEx.new()
			regex.compile(pattern)
			regexes.append(regex)
		_patterns.append({"zh":source,"en":catalog[source],"regexes":regexes})


func _escape(source: String) -> String:
	var result: String=""
	for character in source:
		if character in ".^$*+?()[]{}\\|": result+="\\"
		result+=character
	return result


func audit_template() -> String:
	# Keep the export template as one resource dependency, with no duplicated HTML.
	for source: String in catalog:
		if source.begins_with("<!doctype html>"):
			return catalog[source] if language=="en" else source
	return ""


func set_language(next: String, persist: bool=true) -> void:
	if next not in ["en","zh_CN"] or language==next: return
	language=next
	TranslationServer.set_locale(language)
	if persist:
		var preferences:=ConfigFile.new()
		preferences.load("user://preferences.cfg")
		preferences.set_value("display","language",language)
		preferences.save("user://preferences.cfg")
	language_changed.emit()
