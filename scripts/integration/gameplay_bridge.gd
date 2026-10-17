class_name GameplayBridge
extends Node
## Bind programmer A's stat node without coupling it to the HUD or scene structure.

var _source: Node


func bind_source(source: Node, restore_session: bool = false) -> bool:
	if not is_instance_valid(source):
		return false
	for event: StringName in [&"health_changed", &"score_changed"]:
		if not source.has_signal(event):
			push_warning("GameplayBridge: missing signal %s" % event)
			return false
	for property: StringName in [&"health", &"max_health", &"score"]:
		if not _has_property(source, property):
			push_warning("GameplayBridge: missing property %s" % property)
			return false
	if restore_session and not source.has_method(&"restore_stats"):
		push_warning("GameplayBridge: checkpoint support requires restore_stats(snapshot)")
		return false
	unbind_source()
	_source = source
	if restore_session:
		_source.call(&"restore_stats", GameSession.stats_snapshot())
	_source.connect(&"health_changed", _on_health_changed)
	_source.connect(&"score_changed", _on_score_changed)
	if _source.has_signal(&"died"):
		_source.connect(&"died", _on_died)
	_source.tree_exiting.connect(unbind_source, CONNECT_ONE_SHOT)
	# Read the snapshot too, so signals emitted before binding are not lost.
	_on_score_changed(int(_source.get("score")))
	_on_health_changed(int(_source.get("health")), int(_source.get("max_health")))
	return true


func unbind_source() -> void:
	if is_instance_valid(_source):
		for binding: Array in [
			[&"health_changed", _on_health_changed],
			[&"score_changed", _on_score_changed],
			[&"died", _on_died],
			[&"tree_exiting", unbind_source],
		]:
			if _source.has_signal(binding[0]) and _source.is_connected(binding[0], binding[1]):
				_source.disconnect(binding[0], binding[1])
	_source = null


func _exit_tree() -> void:
	unbind_source()


func _on_health_changed(current: int, maximum: int) -> void:
	GameSession.sync_health(current, maximum)


func _on_score_changed(value: int) -> void:
	GameSession.sync_score(value)


func _on_died() -> void:
	GameSession.player_died()


func _has_property(source: Node, property: StringName) -> bool:
	for entry: Dictionary in source.get_property_list():
		if entry.name == property:
			return true
	return false
