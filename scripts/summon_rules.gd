class_name SummonRules
extends RefCounted
## 11.1c 纯规则：阵容容量、唯一型号、编队站位与量子超载预算。


static func slot_upgrade_cost(current_slots: int) -> int:
	match clampi(current_slots, 1, 3):
		1: return 2
		2: return 3
		_: return 0


static func unique_loadout(source: Variant, limit: int, roster: Array = []) -> Array[String]:
	var model_by_id := {}
	for record in roster:
		if record is Dictionary:
			model_by_id[str(record.get("robot_instance_id", ""))] = str(record.get("model_id", ""))
	var result: Array[String] = []
	var used_instances := {}
	var used_models := {}
	if source is Array:
		for raw_id in source:
			var instance_id := str(raw_id)
			var model_id: String = str(model_by_id.get(instance_id, instance_id))
			if instance_id.is_empty() or used_instances.has(instance_id) or used_models.has(model_id):
				continue
			used_instances[instance_id] = true
			used_models[model_id] = true
			result.append(instance_id)
			if result.size() >= clampi(limit, 1, 3):
				break
	return result


static func formation_offset(index: int, count: int, mobility: String) -> Vector2:
	var slots := [-1.0, 0.0, 1.0]
	var normalized := clampi(index, 0, mini(2, maxi(0, count - 1)))
	var lateral: float = float(slots[normalized + (1 if count == 2 else 0)])
	if count == 1:
		lateral = -1.0
	return Vector2(lateral * 92.0, -116.0 if mobility == "air" else -30.0)


static func overload_profile(active_count: int) -> Dictionary:
	match clampi(active_count, 0, 3):
		2: return {"gain": 8.0, "decay": 10.0, "power_scale": 0.86, "lock_seconds": 2.0}
		3: return {"gain": 14.0, "decay": 6.0, "power_scale": 0.72, "lock_seconds": 2.4}
		_: return {"gain": 0.0, "decay": 18.0, "power_scale": 1.0, "lock_seconds": 0.0}
