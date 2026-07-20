class_name Weapons
extends RefCounted
## 武器数据 (数据驱动: 伤害/范围/手感/外观)

const LIST := [
	{
		"id": "sword", "name": "铁剑", "type": "melee",
		"damage": 2, "combo": 3, "atk_time": 0.27,
		"hit_size": Vector2(120, 116), "reach": 60,
		"color": Color(0.6, 0.95, 1.0), "shake": 4.0,
		"sprite": "res://assets/weapons/sword.png",
		"hand": Vector2(6, -34), "rest_rot": -0.5,
		"fx": "slash", "fx_scale": 1.0, "fx_tint": Color(0.7, 0.95, 1.0), "sfx": "attack",
	},
	{
		"id": "hammer", "name": "重锤", "type": "melee",
		"damage": 4, "combo": 2, "atk_time": 0.46,
		"hit_size": Vector2(132, 116), "reach": 60,
		"color": Color(1.0, 0.6, 0.25), "shake": 9.0,
		"sprite": "res://assets/weapons/hammer.png",
		"hand": Vector2(4, -32), "rest_rot": -0.7,
		"fx": "bolt", "fx_scale": 0.95, "fx_tint": Color(1.0, 0.7, 0.35), "sfx": "atk_hammer",
	},
	{
		"id": "cannon", "name": "蒸汽炮", "type": "ranged",
		"damage": 3, "combo": 1, "atk_time": 0.32,
		"hit_size": Vector2(0, 0), "reach": 42,
		"color": Color(0.85, 0.7, 1.0), "shake": 6.0,
		"sprite": "res://assets/weapons/cannon.png",
		"hand": Vector2(10, -34), "rest_rot": 0.0,
		"fx": "spin", "fx_scale": 1.15, "fx_tint": Color(0.95, 0.85, 1.0), "sfx": "atk_cannon",
	},
	{
		"id": "relic_blade", "name": "遗迹大剑", "type": "melee", "trait": "rune_wave",
		"damage": 7, "combo": 3, "atk_time": 0.30, "hit_size": Vector2(146, 124), "reach": 72,
		"color": Color(0.95, 0.78, 0.28), "shake": 7.0, "sprite": "res://assets/weapons/relic_blade.svg",
		"hand": Vector2(5, -34), "rest_rot": -0.58, "fx": "slash", "fx_scale": 1.25,
		"fx_tint": Color(1.0, 0.78, 0.25), "sfx": "attack",
	},
	{
		"id": "void_blade", "name": "虚空之刃", "type": "melee", "trait": "void_harvest",
		"damage": 9, "combo": 4, "atk_time": 0.22, "hit_size": Vector2(132, 116), "reach": 66,
		"crit_bonus": 0.20, "color": Color(0.72, 0.35, 1.0), "shake": 6.0,
		"sprite": "res://assets/weapons/void_blade.svg", "hand": Vector2(7, -34), "rest_rot": -0.52,
		"fx": "spin", "fx_scale": 1.12, "fx_tint": Color(0.74, 0.36, 1.0), "sfx": "attack",
	},
	{
		"id": "corrupt_scythe", "name": "腐化镰刀", "type": "melee", "trait": "corrosion",
		"damage": 8, "combo": 2, "atk_time": 0.44, "hit_size": Vector2(190, 135), "reach": 82,
		"color": Color(0.48, 1.0, 0.42), "shake": 8.0, "sprite": "res://assets/weapons/corrupt_scythe.svg",
		"hand": Vector2(3, -34), "rest_rot": -0.75, "fx": "bolt", "fx_scale": 1.35,
		"fx_tint": Color(0.46, 1.0, 0.38), "sfx": "atk_hammer",
	},
	{
		"id": "dual_blades", "name": "影铸双刃", "type": "melee", "family": "双刀",
		"damage": 5, "combo": 4, "atk_time": 0.18, "hit_size": Vector2(112, 104), "reach": 54,
		"color": Color(0.42, 0.92, 1.0), "shake": 4.5,
		"sprite": "res://assets/weapons/dual_blades.svg", "hand": Vector2(7, -34), "rest_rot": -0.38,
		"fx": "slash", "fx_scale": 0.86, "fx_tint": Color(0.48, 0.9, 1.0), "sfx": "attack",
		"acquisition": "熔炉区秘室·废热回收井", "combo_skill": "dual_execution",
	},
	{
		"id": "spear", "name": "天穹齿轮枪", "type": "melee", "family": "长枪",
		"damage": 7, "combo": 3, "atk_time": 0.34, "hit_size": Vector2(190, 76), "reach": 92,
		"color": Color(0.95, 0.78, 0.28), "shake": 6.5,
		"sprite": "res://assets/weapons/spear.svg", "hand": Vector2(9, -33), "rest_rot": -0.16,
		"fx": "bolt", "fx_scale": 1.08, "fx_tint": Color(0.98, 0.78, 0.28), "sfx": "attack",
		"acquisition": "遗迹圣殿秘室·星轨祭坛", "combo_skill": "spear_dragon",
	},
	{
		"id": "crossbow", "name": "裂隙连发弩", "type": "ranged", "family": "弓弩",
		"damage": 6, "combo": 2, "atk_time": 0.30, "hit_size": Vector2.ZERO, "reach": 48,
		"color": Color(1.0, 0.44, 0.3), "shake": 5.5,
		"sprite": "res://assets/weapons/crossbow.svg", "hand": Vector2(12, -34), "rest_rot": 0.0,
		"fx": "bolt", "fx_scale": 0.82, "fx_tint": Color(1.0, 0.5, 0.3), "sfx": "atk_cannon",
		"acquisition": "虚空要塞秘室·裂隙观星台", "combo_skill": "crossbow_barrage",
	},
]

static func get_weapon(idx: int) -> Dictionary:
	return LIST[idx % LIST.size()]
