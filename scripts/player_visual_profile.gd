class_name PlayerVisualProfile
extends RefCounted
## 主角视觉姿态数据。碰撞、伤害和输入仍由 player.gd / weapons.gd 决定。

const POSES := {
	"sword": {
		"hand": Vector2(6, -34), "sprite_offset": Vector2(0, -22),
		"visual_scale": 1.4, "rest_rot": -0.5,
		"swing_from": -2.0, "swing_to": 0.7,
		"upper_from": -2.7, "upper_to": -0.3,
		"offhand": false, "recoil": Vector2.ZERO, "visible_during_attack": true,
	},
	"hammer": {
		"hand": Vector2(4, -32), "sprite_offset": Vector2(0, -25),
		"visual_scale": 1.42, "rest_rot": -0.72,
		"swing_from": -2.3, "swing_to": 0.62,
		"upper_from": -2.72, "upper_to": -0.16,
		"offhand": false, "recoil": Vector2(-5, 2), "visible_during_attack": true,
	},
	"cannon": {
		"hand": Vector2(9, -35), "sprite_offset": Vector2(22, 0),
		"visual_scale": 1.25, "rest_rot": 0.0,
		"swing_from": -0.08, "swing_to": 0.04,
		"upper_from": -1.48, "upper_to": -1.62,
		"offhand": false, "recoil": Vector2(-10, 1), "visible_during_attack": true,
	},
	"dual_blades": {
		"hand": Vector2(7, -34), "sprite_offset": Vector2(4, -18),
		"visual_scale": 0.72, "rest_rot": -0.38,
		"swing_from": -2.18, "swing_to": 0.82,
		"upper_from": -2.78, "upper_to": -0.18,
		"offhand": true, "offhand_hand": Vector2(-5, -33),
		"offhand_offset": Vector2(2, -17), "offhand_rest_rot": 0.48,
		"recoil": Vector2.ZERO, "visible_during_attack": true,
	},
	"spear": {
		"hand": Vector2(9, -33), "sprite_offset": Vector2(34, 0),
		"visual_scale": 0.9, "rest_rot": -0.16,
		"swing_from": -1.58, "swing_to": 0.18,
		"upper_from": -2.18, "upper_to": -0.48,
		"offhand": false, "recoil": Vector2(-3, 0), "visible_during_attack": true,
	},
	"crossbow": {
		"hand": Vector2(11, -35), "sprite_offset": Vector2(20, 0),
		"visual_scale": 0.82, "rest_rot": 0.0,
		"swing_from": -0.06, "swing_to": 0.03,
		"upper_from": -1.5, "upper_to": -1.62,
		"offhand": false, "recoil": Vector2(-7, 1), "visible_during_attack": true,
	},
}

const ALIASES := {
	"relic_blade": "sword",
	"void_blade": "sword",
	"corrupt_scythe": "hammer",
}


static func pose(weapon_id: String) -> Dictionary:
	var family_id := String(ALIASES.get(weapon_id, weapon_id))
	return POSES.get(family_id, POSES["sword"]).duplicate(true)
