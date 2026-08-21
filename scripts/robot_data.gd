class_name RobotData
extends RefCounted
## 召唤机器人的纯数据与存档规范化。场景节点不得写入这些记录。

const STARTER_INSTANCE_ID := "starter_bastion_001"
const PROFILES := {
	"scrap_hound_mk1": {
		"name": "先锋犬 MK-I",
		"company": "铸魂工坊",
		"role": "地面·近战护卫",
		"max_hp": 12,
		"damage": 2,
		"move_speed": 185.0,
		"attack_range": 112.0,
		"attack_cooldown": 1.05,
		"rebuild_seconds": 12.0,
		"accent": Color("53e6ff"),
	},
}


static func starter_record() -> Dictionary:
	return {
		"robot_instance_id": STARTER_INSTANCE_ID,
		"model_id": "scrap_hound_mk1",
		"level": 1,
		"xp": 0,
		"learned_skills": ["guard_bolt"],
		"upgrades": {},
		"affinity": 0,
	}


static func profile(model_id: String) -> Dictionary:
	return PROFILES.get(model_id, PROFILES["scrap_hound_mk1"]).duplicate(true)


static func normalize_roster(source: Variant) -> Array:
	var result: Array = []
	var used := {}
	if source is Array:
		for raw in source:
			if not (raw is Dictionary):
				continue
			var record: Dictionary = raw.duplicate(true)
			var instance_id := str(record.get("robot_instance_id", ""))
			var model_id := str(record.get("model_id", ""))
			if instance_id.is_empty() or not PROFILES.has(model_id) or used.has(instance_id):
				continue
			used[instance_id] = true
			record["level"] = maxi(1, int(record.get("level", 1)))
			record["xp"] = maxi(0, int(record.get("xp", 0)))
			record["learned_skills"] = record.get("learned_skills", []) if record.get("learned_skills", []) is Array else []
			record["upgrades"] = record.get("upgrades", {}) if record.get("upgrades", {}) is Dictionary else {}
			record["affinity"] = maxi(0, int(record.get("affinity", 0)))
			result.append(record)
	return result


static func normalize_loadout(source: Variant, roster: Array, slot_level: int) -> Array[String]:
	var valid := {}
	for record in roster:
		if record is Dictionary:
			valid[str(record.get("robot_instance_id", ""))] = str(record.get("model_id", ""))
	var result: Array[String] = []
	var used_models := {}
	if source is Array:
		for raw_id in source:
			var instance_id := str(raw_id)
			if not valid.has(instance_id):
				continue
			var model_id: String = valid[instance_id]
			if used_models.has(model_id):
				continue
			used_models[model_id] = true
			result.append(instance_id)
			if result.size() >= clampi(slot_level, 1, 3):
				break
	if result.is_empty() and valid.has(STARTER_INSTANCE_ID):
		result.append(STARTER_INSTANCE_ID)
	return result
