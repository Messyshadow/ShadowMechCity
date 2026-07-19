class_name StatResolver
extends RefCounted

const DEFAULTS := {
	"attack": 0.0,
	"max_health": 0.0,
	"armor": 0.0,
	"crit_chance": 0.0,
	"crit_damage": 1.5,
	"move_speed": 0.0,
	"stagger_power": 1.0,
	"skill_damage": 1.0,
	"cooldown_rate": 1.0,
	"max_mp": 0.0,
	"mp_regen": 0.0,
}

const FLAT_TO_FINAL := {
	"attack_flat": "attack",
	"max_health": "max_health",
	"armor": "armor",
	"crit_chance": "crit_chance",
	"crit_damage": "crit_damage",
	"stagger_power": "stagger_power",
	"max_mp": "max_mp",
	"mp_regen": "mp_regen",
}

const PERCENT_TO_FINAL := {
	"attack_percent": "attack",
	"move_speed_percent": "move_speed",
	"skill_damage_percent": "skill_damage",
	"cooldown_reduction": "cooldown_rate",
}

static func resolve(base: Dictionary, skill: Dictionary, gear: Dictionary, temporary: Dictionary) -> Dictionary:
	var out := DEFAULTS.duplicate(true)
	for key in out:
		out[key] = float(base.get(key, out[key]))
	var flats := {}
	var percents := {}
	for source in [skill, gear, temporary]:
		for key in source:
			if FLAT_TO_FINAL.has(key):
				flats[key] = float(flats.get(key, 0.0)) + float(source[key])
			elif PERCENT_TO_FINAL.has(key):
				percents[key] = float(percents.get(key, 0.0)) + float(source[key])
	for key in flats:
		var final_key: String = FLAT_TO_FINAL[key]
		out[final_key] += float(flats[key])
	for key in percents:
		var final_key: String = PERCENT_TO_FINAL[key]
		if key == "cooldown_reduction":
			out[final_key] = maxf(0.1, out[final_key] - float(percents[key]))
		else:
			out[final_key] *= 1.0 + float(percents[key])
	out["crit_chance"] = clampf(out["crit_chance"], 0.0, 1.0)
	return out
