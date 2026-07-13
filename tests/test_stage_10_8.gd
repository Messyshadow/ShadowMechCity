extends SceneTree

const SECRET_ROOMS := [
	"secret_hub_archive", "secret_mine_cache", "secret_factory_heat",
	"secret_water_cistern", "secret_temple_orbit", "secret_void_observatory",
	"secret_castle_ossuary",
]
const VALID_ABILITIES := ["dash", "bomb", "aqua", "double_jump", "wall_climb", "glide", "shadow_glider"]
var failures: Array[String] = []

func _init() -> void:
	var rooms: Dictionary = load("res://scripts/rooms.gd").ROOMS
	var chest_ids: Array[String] = []
	var memory_ids: Array[String] = []
	for id in SECRET_ROOMS:
		_check(rooms.has(id), "missing secret room: " + id)
		if not rooms.has(id): continue
		var room: Dictionary = rooms[id]
		_check(room.get("hidden_room", false), id + " must be marked hidden_room")
		_check(room.has("region"), id + " needs region metadata")
		_check(not room.get("doors", []).is_empty(), id + " needs a return door")
		var memories: Array = room.get("secrets", []).filter(func(s): return s[2] == "memory")
		_check(memories.size() == 1, id + " needs exactly one memory core")
		if memories.size() == 1: memory_ids.append(memories[0][3])
		var explicit_chests: Array = room.get("items", []).filter(func(item): return item[2] == "chest" and item.size() > 3 and item[3] != "")
		_check(explicit_chests.size() == 1, id + " needs exactly one explicit chest id")
		if explicit_chests.size() == 1: chest_ids.append(explicit_chests[0][3])
	_check(chest_ids.size() == 7 and _unique(chest_ids), "secret chest ids must be unique")
	_check(memory_ids.size() == 7 and _unique(memory_ids), "memory ids must be unique")

	var hidden_links := 0
	for from_id in rooms:
		for door in rooms[from_id].get("doors", []):
			for ability in door.get("requires", []):
				_check(VALID_ABILITIES.has(ability), "invalid ability requirement: " + str(ability))
			if door.get("hidden", false):
				hidden_links += 1
				_check(SECRET_ROOMS.has(door["to"]), "hidden entrance must target a stage 10.8 room")
	_check(hidden_links == 7, "needs exactly seven parent hidden entrances")

	var game_source := FileAccess.get_file_as_string("res://scripts/game.gd")
	for marker in ["var permanent_chests", '"permanent_chests": permanent_chests', "func completion_snapshot"]:
		_check(game_source.contains(marker), "game persistence/completion missing: " + marker)
	var pickup_source := FileAccess.get_file_as_string("res://scripts/pickup.gd")
	_check(pickup_source.contains('"memory"'), "memory pickup support missing")
	var map_source := FileAccess.get_file_as_string("res://scripts/map_panel.gd")
	for marker in ["completion_snapshot", "hidden_room", "percent"]:
		_check(map_source.contains(marker), "completion map UI missing: " + marker)
	_check(FileAccess.file_exists("res://scripts/completion.gd"), "completion.gd missing")
	if FileAccess.file_exists("res://scripts/completion.gd"):
		var all_visited := {}; var all_items := {}; var all_chests := {}; var all_collected := {}
		for id in rooms:
			all_visited[id] = true
			if rooms[id].has("boss"): all_items["boss_" + id] = true
			for item in rooms[id].get("items", []):
				if item[2] == "chest":
					var cid: String = item[3] if item.size() > 3 and item[3] != "" else "%s:chest:%d:%d" % [id, int(item[0]), int(item[1])]
					all_chests[cid] = true
			for secret in rooms[id].get("secrets", []): all_collected[secret[3]] = true
		var unlocked: Array[String] = []
		for weapon in load("res://scripts/weapons.gd").LIST: unlocked.append(weapon["id"])
		var snap: Dictionary = load("res://scripts/completion.gd").snapshot(rooms, all_visited, all_items, all_chests, unlocked, all_collected)
		_check(snap.get("percent", -1) == 100, "fully completed state must equal 100 percent")

	if failures.is_empty():
		print("PASS stage 10.8 hidden/completion contracts"); quit(0); return
	for failure in failures: push_error(failure)
	quit(1)

func _unique(values: Array[String]) -> bool:
	var seen := {}
	for value in values:
		if seen.has(value): return false
		seen[value] = true
	return true

func _check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
