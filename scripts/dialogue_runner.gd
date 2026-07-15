class_name DialogueRunner
extends RefCounted
## 无 UI 的对话状态机，便于阶段 12.2 任务系统和自动测试复用。

const DIALOGUE_DATA := preload("res://scripts/dialogue_data.gd")

var route: Dictionary = {}
var route_id := ""
var node_id := ""

func begin(id: String, snapshot: Dictionary, flags: Dictionary) -> Dictionary:
	route_id = id
	route = DIALOGUE_DATA.ROUTES.get(id, {})
	if route.is_empty():
		return _missing_node(id)
	for candidate in route.get("entries", []):
		if _conditions_match(candidate.get("conditions", {}), snapshot, flags):
			node_id = str(candidate.get("node", ""))
			return current()
	return _missing_node(id)

func begin_at(id: String, target_node: String) -> Dictionary:
	route_id = id
	route = DIALOGUE_DATA.ROUTES.get(id, {})
	if route.is_empty() or not route.get("nodes", {}).has(target_node):
		return _missing_node("%s:%s" % [id, target_node])
	node_id = target_node
	return current()

func current() -> Dictionary:
	if node_id == "":
		return {}
	var nodes: Dictionary = route.get("nodes", {})
	if not nodes.has(node_id):
		return _missing_node(node_id)
	var result: Dictionary = nodes[node_id].duplicate(true)
	result["id"] = node_id
	return result

func advance(choice_index := -1) -> Dictionary:
	var node := current()
	if node.is_empty():
		return {}
	var target := str(node.get("next", ""))
	var choices: Array = node.get("choices", [])
	if choice_index >= 0 and choice_index < choices.size():
		target = str(choices[choice_index].get("to", ""))
	node_id = target
	return {} if target == "" else current()

func set_flags_from(node: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for event in node.get("events", []):
		var value := str(event)
		if value.begins_with("set:") and value.length() > 4:
			result.append(value.trim_prefix("set:"))
	return result

func _conditions_match(conditions: Dictionary, snapshot: Dictionary, flags: Dictionary) -> bool:
	for key in conditions:
		var value = conditions[key]
		match str(key):
			"visited_count_gte", "hidden_count_gte", "boss_count_gte", "memory_count_gte", "weapon_count_gte":
				var field := str(key).trim_suffix("_gte")
				if int(snapshot.get(field, 0)) < int(value):
					return false
			"flag_present":
				if not flags.has(str(value)):
					return false
			"flag_missing":
				if flags.has(str(value)):
					return false
			_:
				push_error("Unknown dialogue condition: " + str(key))
				return false
	return true

func _missing_node(id: String) -> Dictionary:
	push_error("Dialogue node or route missing: " + id)
	return {"id":"missing", "text":"通讯记录损坏。", "next":"", "choices":[], "events":[]}
