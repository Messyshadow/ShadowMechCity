class_name SkillGraph
extends RefCounted

static func validate(nodes: Array) -> Dictionary:
	var errors: Array[String] = []
	var ids := {}
	for node in nodes:
		var id := str(node.get("id", ""))
		if id == "" or ids.has(id):
			errors.append("duplicate/empty id: " + id)
		ids[id] = node
	for node in nodes:
		for req in node.get("req", []):
			if not ids.has(str(req)):
				errors.append("missing prerequisite %s for %s" % [req, node["id"]])
		if int(node.get("max", -1)) < 0:
			errors.append("negative max: " + str(node["id"]))
	var checked := {}
	for node in nodes:
		var id := str(node["id"])
		if _has_cycle(id, ids, {}, checked):
			errors.append("cycle at " + id)
	return {"errors": errors}

static func _has_cycle(id: String, ids: Dictionary, visiting: Dictionary, checked: Dictionary) -> bool:
	if visiting.has(id):
		return true
	if checked.has(id) or not ids.has(id):
		return false
	var next_visiting := visiting.duplicate()
	next_visiting[id] = true
	for req in ids[id].get("req", []):
		if _has_cycle(str(req), ids, next_visiting, checked):
			return true
	checked[id] = true
	return false

static func nearest_in_direction(current_id: String, direction: Vector2, nodes: Array) -> String:
	var current := {}
	for node in nodes:
		if node["id"] == current_id:
			current = node
			break
	if current.is_empty() or direction.is_zero_approx():
		return ""
	var best := ""
	var best_score := INF
	for node in nodes:
		if node["id"] == current_id:
			continue
		var delta: Vector2 = Vector2(node["pos"]) - Vector2(current["pos"])
		if delta.dot(direction) <= 0.0:
			continue
		var angle_penalty := 1.0 - delta.normalized().dot(direction.normalized())
		var score := angle_penalty * 1000.0 + delta.length()
		if score < best_score:
			best_score = score
			best = str(node["id"])
	return best
