class_name ProgressionMigration
extends RefCounted

const CURRENT_VERSION := 13
const LEGACY_SKILL_IDS := [
	"hp", "power", "speed", "dashcd", "triple", "atk", "crit", "lifesteal",
	"wave", "spin", "mp_max", "mp_regen", "skill_dmg", "skill_cd", "magnet", "ultimate",
]

static func migrate(source: Dictionary) -> Dictionary:
	var data := source.duplicate(true)
	if int(data.get("save_version", 0)) >= CURRENT_VERSION:
		return data
	var old_skills = data.get("skills", {})
	var safe_skills := {}
	if old_skills is Dictionary:
		for id in LEGACY_SKILL_IDS:
			if old_skills.has(id):
				safe_skills[id] = maxi(0, int(old_skills[id]))
		for id in old_skills:
			if not safe_skills.has(id):
				safe_skills[id] = old_skills[id]
	data["skills"] = safe_skills
	if not (data.get("inventory", []) is Array):
		data["inventory"] = []
	if not (data.get("equipped", {}) is Dictionary):
		data["equipped"] = {}
	if not (data.get("abilities", {}) is Dictionary):
		data["abilities"] = {}
	data["compat_progression"] = data.get("compat_progression", {})
	data["save_version"] = CURRENT_VERSION
	return data
