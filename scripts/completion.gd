class_name Completion
extends RefCounted
## 纯统计模块：只读取房间定义与存档状态，不修改游戏。

static func snapshot(rooms: Dictionary, visited: Dictionary, items: Dictionary,
		permanent_chests: Dictionary, unlocked_weapons: Array[String], collected: Dictionary) -> Dictionary:
	var hidden_ids: Array[String] = []
	var boss_ids: Array[String] = []
	var chest_ids: Array[String] = []
	var collectible_ids: Array[String] = []
	for id in rooms:
		var room: Dictionary = rooms[id]
		if room.get("hidden_room", false): hidden_ids.append(id)
		if room.has("boss"): boss_ids.append("boss_" + id)
		for item in room.get("items", []):
			if item[2] == "chest":
				var cid: String = item[3] if item.size() > 3 and item[3] != "" else "%s:chest:%d:%d" % [id, int(item[0]), int(item[1])]
				if not chest_ids.has(cid): chest_ids.append(cid)
		for secret in room.get("secrets", []):
			if not collectible_ids.has(secret[3]): collectible_ids.append(secret[3])
	var valid_weapon_ids: Array[String] = []
	for weapon in Weapons.LIST: valid_weapon_ids.append(weapon["id"])
	var categories := {
		"rooms": _category(_count_keys(rooms.keys(), visited), rooms.size()),
		"hidden": _category(_count_keys(hidden_ids, visited), hidden_ids.size()),
		"bosses": _category(_count_keys(boss_ids, items), boss_ids.size()),
		"chests": _category(_count_keys(chest_ids, permanent_chests), chest_ids.size()),
		"weapons": _category(_count_values(valid_weapon_ids, unlocked_weapons), valid_weapon_ids.size()),
		"collectibles": _category(_count_keys(collectible_ids, collected), collectible_ids.size()),
	}
	var done := 0; var total := 0
	for key in categories:
		done += categories[key]["done"]; total += categories[key]["total"]
	categories["done"] = done; categories["total"] = total
	categories["percent"] = 0 if total <= 0 else clampi(roundi(done * 100.0 / total), 0, 100)
	return categories

static func _category(done: int, total: int) -> Dictionary:
	return {"done": done, "total": total}

static func _count_keys(ids: Array, state: Dictionary) -> int:
	var result := 0
	for id in ids:
		if state.has(id): result += 1
	return result

static func _count_values(valid: Array[String], state: Array[String]) -> int:
	var result := 0
	for id in valid:
		if state.has(id): result += 1
	return result
