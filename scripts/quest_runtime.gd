extends RefCounted
## 不依赖 Autoload 的纯任务求值器，供 Game、UI 与无头测试共同使用。

const QuestData = preload("res://scripts/quest_data.gd")

func evaluate_all(snapshot: Dictionary, persisted_flags: Dictionary = {}) -> Dictionary:
	var result := {}
	var previous_complete := true
	for quest_id in QuestData.MAIN_ORDER:
		var quest: Dictionary = QuestData.QUESTS.get(quest_id, {})
		var objective_states: Array[Dictionary] = []
		var done_count := 0
		for raw_objective in quest.get("objectives", []):
			var objective: Dictionary = raw_objective
			var done := _objective_done(objective, snapshot)
			if done:
				done_count += 1
			objective_states.append({
				"type": str(objective.get("type", "")),
				"id": str(objective.get("id", "")),
				"text": str(objective.get("text", "")),
				"hint": str(objective.get("hint", "")),
				"done": done,
			})
		var complete := not objective_states.is_empty() and done_count == objective_states.size()
		complete = complete or bool(persisted_flags.get("complete:" + quest_id, false))
		var status := "locked"
		if complete:
			status = "complete"
		elif previous_complete:
			status = "active"
		result[quest_id] = {
			"id": quest_id,
			"chapter": str(quest.get("chapter", "")),
			"title": str(quest.get("title", quest_id)),
			"summary": str(quest.get("summary", "")),
			"giver": str(quest.get("giver", "")),
			"status": status,
			"done": done_count,
			"total": objective_states.size(),
			"objectives": objective_states,
		}
		previous_complete = complete
	return result

func pick_tracked(states: Dictionary, preferred: String = "") -> String:
	if states.has(preferred) and str(states[preferred].get("status", "")) == "active":
		return preferred
	for quest_id in QuestData.MAIN_ORDER:
		if str(states.get(quest_id, {}).get("status", "")) == "active":
			return quest_id
	for index in range(QuestData.MAIN_ORDER.size() - 1, -1, -1):
		var quest_id: String = QuestData.MAIN_ORDER[index]
		if str(states.get(quest_id, {}).get("status", "")) == "complete":
			return quest_id
	return QuestData.MAIN_ORDER[0] if not QuestData.MAIN_ORDER.is_empty() else ""

func _objective_done(objective: Dictionary, snapshot: Dictionary) -> bool:
	var objective_id := str(objective.get("id", ""))
	match str(objective.get("type", "")):
		"visited":
			return _dict_has_truthy(snapshot.get("visited", {}), objective_id)
		"item":
			return _dict_has_truthy(snapshot.get("items", {}), objective_id)
		"flag":
			return _dict_has_truthy(snapshot.get("dialogue_flags", {}), objective_id) or _dict_has_truthy(snapshot.get("story_flags", {}), objective_id)
		_:
			push_error("Unknown quest objective type: " + str(objective.get("type", "")))
			return false

func _dict_has_truthy(value: Variant, key: String) -> bool:
	return value is Dictionary and bool(value.get(key, false))
