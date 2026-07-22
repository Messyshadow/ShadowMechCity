class_name CombatFeedback
extends RefCounted
## 统一命中反馈数据。数值有硬上限，避免多段攻击把镜头和顿帧无限叠加。

const BOSS_RESPONSE_SCALE := 0.42

const PROFILES := {
	"light": {
		"hitstop": 0.035, "time_scale": 0.08, "shake": 3.0,
		"knockback": 0.72, "ring_width": 3.0, "particle_amount": 10,
	},
	"heavy": {
		"hitstop": 0.065, "time_scale": 0.055, "shake": 7.0,
		"knockback": 1.0, "ring_width": 5.0, "particle_amount": 17,
	},
	"armor_break": {
		"hitstop": 0.09, "time_scale": 0.04, "shake": 11.0,
		"knockback": 1.18, "ring_width": 7.0, "particle_amount": 24,
	},
	"finisher": {
		"hitstop": 0.12, "time_scale": 0.035, "shake": 15.0,
		"knockback": 1.35, "ring_width": 9.0, "particle_amount": 30,
	},
}

const PALETTES := {
	"flesh": {
		"core": Color(1.0, 0.92, 0.72),
		"spark": Color(1.0, 0.28, 0.22),
		"residue": Color(0.55, 0.04, 0.08, 0.72),
		"pitch": 0.88, "volume_db": -8.0,
	},
	"metal": {
		"core": Color(0.9, 0.98, 1.0),
		"spark": Color(1.0, 0.72, 0.18),
		"residue": Color(0.22, 0.62, 0.88, 0.66),
		"pitch": 1.28, "volume_db": -7.0,
	},
	"stone": {
		"core": Color(1.0, 0.84, 0.56),
		"spark": Color(0.72, 0.48, 0.28),
		"residue": Color(0.28, 0.2, 0.16, 0.72),
		"pitch": 0.68, "volume_db": -5.5,
	},
	"shield": {
		"core": Color(0.9, 1.0, 1.0),
		"spark": Color(0.18, 0.88, 1.0),
		"residue": Color(0.1, 0.42, 0.72, 0.72),
		"pitch": 1.48, "volume_db": -7.5,
	},
	"void": {
		"core": Color(1.0, 0.84, 1.0),
		"spark": Color(0.72, 0.3, 1.0),
		"residue": Color(0.22, 0.02, 0.4, 0.78),
		"pitch": 0.54, "volume_db": -6.5,
	},
}

static func profile(tier: String) -> Dictionary:
	return (PROFILES.get(tier, PROFILES["light"]) as Dictionary).duplicate(true)

static func material_palette(material: String) -> Dictionary:
	return (PALETTES.get(material, PALETTES["metal"]) as Dictionary).duplicate(true)

static func tier_for_hit(amount: int, is_finisher: bool = false, armor_break: bool = false) -> String:
	if is_finisher:
		return "finisher"
	if armor_break:
		return "armor_break"
	return "heavy" if amount >= 4 else "light"

static func material_for_enemy(enemy_type: String, behavior: String = "") -> String:
	var id := enemy_type.to_lower()
	if id.contains("void") or behavior in ["teleflyer", "storm_mage"]:
		return "void"
	if id.contains("shield"):
		return "shield"
	if id.contains("rock") or id.contains("stone") or id.contains("golem"):
		return "stone"
	if id.contains("beast") or id.contains("wolf") or id.contains("mushroom"):
		return "flesh"
	return "metal"

static func play_material_sfx(context: Node, material: String, tier: String = "light") -> void:
	if context == null or not is_instance_valid(context):
		return
	var main := context.get_node_or_null("/root/Main")
	if main == null or not main.has_method("play_sfx"):
		return
	var palette := material_palette(material)
	var volume_db := float(palette.get("volume_db", -8.0))
	if tier in ["armor_break", "finisher"]:
		volume_db += 1.5
	main.play_sfx("hit", volume_db, float(palette.get("pitch", 1.0)))
