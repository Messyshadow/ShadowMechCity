extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	var weapons_script = load("res://scripts/weapons.gd")
	var ids: Array[String] = []
	for weapon in weapons_script.LIST:
		ids.append(weapon["id"])
	_check(weapons_script.LIST.size() == 6, "stage 10.7 needs exactly six demo weapons")
	for required in ["relic_blade", "void_blade", "corrupt_scythe"]:
		_check(ids.has(required), "missing stage 10.7 weapon: " + required)
	var expected_traits := {"relic_blade":"rune_wave", "void_blade":"void_harvest", "corrupt_scythe":"corrosion"}
	for weapon in weapons_script.LIST:
		if expected_traits.has(weapon["id"]):
			_check(weapon.get("trait", "") == expected_traits[weapon["id"]], "wrong trait for " + weapon["id"])
	var game := FileAccess.get_file_as_string("res://scripts/game.gd")
	for marker in ["var unlocked_weapons", "func unlock_weapon", "func is_weapon_unlocked", '"unlocked_weapons": unlocked_weapons', "_migrate_weapon_unlocks"]:
		_check(game.contains(marker), "weapon unlock/save system missing: " + marker)
	var player := FileAccess.get_file_as_string("res://scripts/player.gd")
	for marker in ["_next_unlocked_weapon", "_relic_hit_charge", "_release_rune_wave", 'weapon.get("crit_bonus"', "_heal_void_harvest", "apply_corrosion"]:
		_check(player.contains(marker), "player weapon trait missing: " + marker)
	var enemy := FileAccess.get_file_as_string("res://scripts/enemy.gd")
	for marker in ["var corrosion_time", "func apply_corrosion", "CORROSION_TICK", "_tick_corrosion"]:
		_check(enemy.contains(marker), "enemy corrosion missing: " + marker)
	var rooms: Dictionary = load("res://scripts/rooms.gd").ROOMS
	for room_id in ["temple_sanctum", "void_core", "water_boss"]:
		_check(not rooms[room_id].get("weapons", []).is_empty(), room_id + " needs a one-time weapon reward")
	for asset in ["relic_blade.svg", "void_blade.svg", "corrupt_scythe.svg"]:
		_check(FileAccess.file_exists("res://assets/weapons/" + asset), "missing original weapon asset: " + asset)
	if failures.is_empty():
		print("PASS stage 10.7 weapon contracts")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
