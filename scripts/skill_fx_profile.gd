class_name SkillFxProfile
extends RefCounted
## 六武器主动技能的统一视觉数据。这里只描述视觉语言与预算，不处理伤害。

const Z_RESIDUE := 17
const Z_BODY := 23
const Z_TELEGRAPH := 28
const Z_IMPACT := 31

const WEAPON_PROFILES := {
	"sword": {
		"shape": "arc",
		"primary": Color(0.38, 0.92, 1.0, 0.96),
		"secondary": Color(0.82, 0.98, 1.0, 0.72),
	},
	"hammer": {
		"shape": "block",
		"primary": Color(1.0, 0.58, 0.18, 0.96),
		"secondary": Color(1.0, 0.86, 0.38, 0.76),
	},
	"cannon": {
		"shape": "steam_beam",
		"primary": Color(0.72, 0.9, 1.0, 0.94),
		"secondary": Color(0.96, 1.0, 1.0, 0.72),
	},
	"dual_blades": {
		"shape": "cross",
		"primary": Color(0.3, 0.94, 1.0, 0.96),
		"secondary": Color(0.72, 0.34, 1.0, 0.82),
	},
	"spear": {
		"shape": "lance",
		"primary": Color(1.0, 0.78, 0.24, 0.97),
		"secondary": Color(1.0, 0.96, 0.66, 0.78),
	},
	"crossbow": {
		"shape": "reticle",
		"primary": Color(0.96, 0.25, 0.22, 0.94),
		"secondary": Color(0.42, 1.0, 0.58, 0.78),
	},
}

const CUE_TIERS := {
	"ground": {"scale": 0.9, "particle_budget": 24, "flash_alpha": 0.0, "duration": 0.34},
	"upper": {"scale": 1.0, "particle_budget": 28, "flash_alpha": 0.04, "duration": 0.38},
	"dash_atk": {"scale": 1.08, "particle_budget": 30, "flash_alpha": 0.05, "duration": 0.4},
	"burst": {"scale": 1.28, "particle_budget": 36, "flash_alpha": 0.1, "duration": 0.5},
	"ultimate": {"scale": 1.62, "particle_budget": 52, "flash_alpha": 0.24, "duration": 0.68},
}


static func profile(weapon_id: String, cue: String) -> Dictionary:
	var result: Dictionary = WEAPON_PROFILES.get(weapon_id, WEAPON_PROFILES["sword"]).duplicate(true)
	var tier: Dictionary = CUE_TIERS.get(cue, CUE_TIERS["ground"])
	result.merge(tier, true)
	result["weapon_id"] = weapon_id
	result["cue"] = cue
	result["z_residue"] = Z_RESIDUE
	result["z_body"] = Z_BODY
	result["z_telegraph"] = Z_TELEGRAPH
	result["z_impact"] = Z_IMPACT
	return result
