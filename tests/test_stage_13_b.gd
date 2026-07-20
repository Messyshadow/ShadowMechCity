extends SceneTree

var failures: Array[String] = []

const NEW_WEAPONS := ["dual_blades", "spear", "crossbow"]
const FAMILY_BY_ID := {
	"dual_blades": "双刀",
	"spear": "长枪",
	"crossbow": "弓弩",
}
const ROOM_REWARDS := {
	"secret_factory_heat": "dual_blades",
	"secret_temple_orbit": "spear",
	"secret_void_observatory": "crossbow",
}

func _init() -> void:
	var weapons = load("res://scripts/weapons.gd")
	var by_id := {}
	for weapon in weapons.LIST:
		by_id[str(weapon["id"])] = weapon
	for weapon_id in NEW_WEAPONS:
		_check(by_id.has(weapon_id), "missing 13B weapon: " + weapon_id)
		if not by_id.has(weapon_id):
			continue
		var weapon: Dictionary = by_id[weapon_id]
		_check(weapon.get("family", "") == FAMILY_BY_ID[weapon_id], "wrong family for " + weapon_id)
		_check(str(weapon.get("acquisition", "")) != "", "missing acquisition text for " + weapon_id)
		_check(str(weapon.get("combo_skill", "")) != "", "missing combo skill for " + weapon_id)
		_check(FileAccess.file_exists("res://assets/weapons/%s.svg" % weapon_id), "missing original SVG for " + weapon_id)

	var rooms: Dictionary = load("res://scripts/rooms.gd").ROOMS
	for room_id in ROOM_REWARDS:
		var found := false
		for reward in rooms[room_id].get("weapons", []):
			if reward.size() >= 3 and str(reward[2]) == ROOM_REWARDS[room_id]:
				found = true
		_check(found, "%s must reward %s" % [room_id, ROOM_REWARDS[room_id]])

	var player_source := FileAccess.get_file_as_string("res://scripts/player.gd")
	for marker in [
		"func _dual_blades_heavy", "func _spear_heavy", "func _crossbow_heavy",
		"func _dual_blades_attack_fx", "func _spear_attack_fx", "func _fire_crossbow",
		'"dual_blades":', '"spear":', '"crossbow":',
	]:
		_check(player_source.contains(marker), "player 13B behavior missing: " + marker)

	var skills = load("res://scripts/skills_data.gd")
	for weapon_id in NEW_WEAPONS:
		var family: String = FAMILY_BY_ID[weapon_id]
		var nodes: Array = skills.nodes_for("战斗", family)
		_check(nodes.size() >= 4, "%s needs root, two basic nodes and combo node" % family)
		var combos := 0
		for node in nodes:
			if node.get("type", "") == "组合":
				combos += 1
		_check(combos >= 1, "%s needs a real combo node" % family)

	var inventory_source := FileAccess.get_file_as_string("res://scripts/inventory_panel.gd")
	_check(inventory_source.contains("Weapons.LIST"), "inventory must project real unlocked weapons")
	_check(not inventory_source.contains("双刀、长枪与弓弩将在 13B 加入掉落"), "13B placeholder must be removed")
	_finish()

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("PASS stage 13B weapon family contracts")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
