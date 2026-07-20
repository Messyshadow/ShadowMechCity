extends SceneTree

var failures: Array[String] = []

const ROLE_BY_ID := {
	"void_eagle": "harrier",
	"void_wyvern": "ambusher",
	"storm_mage": "controller",
	"soul_shield": "vanguard",
	"soul_spear": "lancer",
	"soul_cannon": "artillery",
}

const STRATEGY_MARKERS := [
	"_b_harrier", "_b_ambusher", "_b_controller",
	"_b_vanguard", "_b_lancer", "_b_artillery",
]

func _init() -> void:
	var main_src := FileAccess.get_file_as_string("res://scripts/main.gd")
	var enemy_src := FileAccess.get_file_as_string("res://scripts/enemy.gd")
	var director_path := "res://scripts/enemy_combat_director.gd"
	var director_src := FileAccess.get_file_as_string(director_path) if FileAccess.file_exists(director_path) else ""

	_expect(not main_src.is_empty(), "main source is readable")
	_expect(not enemy_src.is_empty(), "enemy source is readable")
	_expect(FileAccess.file_exists(director_path), "room combat director exists")
	for api in ["register_enemy", "unregister_enemy", "request_action", "notify_action_finished", "formation_offset"]:
		_expect(director_src.contains("func %s" % api), "director exposes %s" % api)

	for enemy_id in ROLE_BY_ID:
		var definition_line := _definition_line(main_src, enemy_id)
		_expect(not definition_line.is_empty(), "%s definition exists" % enemy_id)
		_expect(definition_line.contains('"role": "%s"' % ROLE_BY_ID[enemy_id]), "%s uses %s role" % [enemy_id, ROLE_BY_ID[enemy_id]])

	for marker in STRATEGY_MARKERS:
		_expect(enemy_src.contains("func %s" % marker), "enemy strategy exists: %s" % marker)
	_expect(enemy_src.contains("request_action"), "enemy strategies request coordinated actions")
	_expect(enemy_src.contains("formation_offset"), "enemy strategies consume formation slots")
	_expect(main_src.contains("SHOT_ENEMY_SQUAD"), "squad capture hook exists")

	var rooms = load("res://scripts/rooms.gd").ROOMS
	_expect(_room_has_types(rooms, "void_hangar", ["void_eagle", "void_wyvern", "storm_mage"]), "void hangar contains full coordinated trio")
	_expect(_room_has_types(rooms, "castle_gallery", ["soul_shield", "soul_spear", "soul_cannon"]), "castle gallery contains full coordinated trio")

	if failures.is_empty():
		print("STAGE_13_C_PASS")
		quit(0)
	else:
		for failure in failures:
			push_error("STAGE_13_C: " + failure)
		quit(1)

func _definition_line(source: String, enemy_id: String) -> String:
	for line in source.split("\n"):
		if line.contains('"%s": {' % enemy_id):
			return line
	return ""

func _room_has_types(rooms: Dictionary, room_id: String, required: Array) -> bool:
	if not rooms.has(room_id):
		return false
	var found: Array[String] = []
	for spawn in rooms[room_id].get("enemies", []):
		if spawn.size() >= 3:
			found.append(str(spawn[2]))
	for enemy_id in required:
		if not found.has(str(enemy_id)):
			return false
	return true

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
