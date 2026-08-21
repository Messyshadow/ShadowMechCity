class_name RobotData
extends RefCounted
## 召唤机器人的纯数据与存档规范化。场景节点不得写入这些记录。

const STARTER_INSTANCE_ID := "starter_bastion_001"
const ROLE_INSTANCE_IDS := {
	"scrap_hound_mk1": STARTER_INSTANCE_ID,
	"bulwark_mole_mk1": "prototype_bulwark_001",
	"sky_rail_drone_mk1": "prototype_skyrail_001",
	"lumen_wisp_mk1": "prototype_lumen_001",
}
const PROFILES := {
	"scrap_hound_mk1": {
		"name": "先锋犬 MK-I",
		"company": "铸魂工坊",
		"role": "地面·近战护卫",
		"mobility": "ground",
		"combat_style": "striker",
		"draw_style": "hound",
		"max_hp": 12,
		"damage": 2,
		"move_speed": 185.0,
		"attack_range": 112.0,
		"attack_cooldown": 1.05,
		"rebuild_seconds": 12.0,
		"accent": Color("53e6ff"),
	},
	"bulwark_mole_mk1": {
		"name": "壁垒鼹 MK-I",
		"company": "铸魂工坊",
		"role": "地面·重装盾卫",
		"mobility": "ground",
		"combat_style": "vanguard",
		"draw_style": "mole",
		"max_hp": 20,
		"damage": 1,
		"move_speed": 142.0,
		"attack_range": 88.0,
		"attack_cooldown": 1.35,
		"rebuild_seconds": 15.0,
		"accent": Color("ffb84f"),
	},
	"sky_rail_drone_mk1": {
		"name": "天轨蜂 MK-I",
		"company": "虚空蒸汽局",
		"role": "空中·远程炮击",
		"mobility": "air",
		"combat_style": "artillery",
		"draw_style": "drone",
		"max_hp": 9,
		"damage": 3,
		"move_speed": 215.0,
		"attack_range": 360.0,
		"attack_cooldown": 1.75,
		"rebuild_seconds": 13.0,
		"accent": Color("ff6e4a"),
	},
	"lumen_wisp_mk1": {
		"name": "流明萤 MK-I",
		"company": "遗迹符文院",
		"role": "空中·修复支援",
		"mobility": "air",
		"combat_style": "support",
		"draw_style": "wisp",
		"max_hp": 10,
		"damage": 1,
		"move_speed": 195.0,
		"attack_range": 260.0,
		"attack_cooldown": 2.2,
		"support_cooldown": 5.0,
		"rebuild_seconds": 11.0,
		"accent": Color("75ffb5"),
	},
}


static func starter_record() -> Dictionary:
	return _record_for("scrap_hound_mk1")


static func _record_for(model_id: String) -> Dictionary:
	return {
		"robot_instance_id": str(ROLE_INSTANCE_IDS[model_id]),
		"model_id": model_id,
		"level": 1,
		"xp": 0,
		"learned_skills": [str(PROFILES[model_id]["combat_style"]) + "_protocol"],
		"upgrades": {},
		"affinity": 0,
	}


static func role_records() -> Array:
	var records: Array = []
	for model_id in ROLE_INSTANCE_IDS:
		records.append(_record_for(str(model_id)))
	return records


static func ensure_role_roster(source: Variant) -> Array:
	var result := normalize_roster(source)
	var existing := {}
	for record in result:
		existing[str(record.get("model_id", ""))] = true
	for prototype in role_records():
		if not existing.has(str(prototype["model_id"])):
			result.append(prototype)
	return result


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
