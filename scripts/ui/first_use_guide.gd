class_name FirstUseGuide
extends RefCounted
## Separate preferences file: hints survive death, restarts and app launches.
static var _loaded := false
static var _seen := ConfigFile.new()

static func seen(id: String) -> bool:
	if not _loaded:
		_seen.load("user://tutorial_seen.cfg")
		_loaded = true
	return _seen.get_value("seen",id,false)

static func claim(id: String) -> bool:
	if seen(id): return false
	_seen.set_value("seen",id,true)
	_seen.save("user://tutorial_seen.cfg")
	return true
