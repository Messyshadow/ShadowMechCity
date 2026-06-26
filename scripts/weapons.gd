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
]

static func get_weapon(idx: int) -> Dictionary:
	return LIST[idx % LIST.size()]
