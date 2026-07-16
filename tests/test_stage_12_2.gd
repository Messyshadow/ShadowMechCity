extends SceneTree

const EXPECTED_QUESTS := ["echo_coordinates", "broken_network", "void_skyline", "last_light"]

var failures: Array[String] = []

func _init() -> void:
	_validate_source_contracts()
	_validate_quest_resources()
	if failures.is_empty():
		print("PASS stage 12.2 main quest, journal and title art contracts")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _validate_source_contracts() -> void:
	var game_source := FileAccess.get_file_as_string("res://scripts/game.gd")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var title_source := FileAccess.get_file_as_string("res://scripts/title_menu.gd")
	for marker in ["quest_flags", "tracked_quest_id", "quest_snapshot", "quest_changed"]:
		_check(game_source.contains(marker), "game quest persistence/runtime missing marker: " + marker)
	_check(game_source.contains('"quest_menu"') and game_source.contains("KEY_N"), "Game.ACTIONS must register quest_menu on N")
	for marker in ["_setup_quest_ui", "SHOT_QUEST_LOG", "SHOT_QUEST_TRACKER"]:
		_check(main_source.contains(marker), "main quest integration missing marker: " + marker)
	_check(title_source.contains("shadow_mech_city_title.png"), "title menu must consume the generated hero bitmap")
	_check(title_source.contains("阶段 12."), "title menu must expose a visible stage 12 build marker")
	_check(ResourceLoader.exists("res://scripts/quest_panel.gd"), "quest_panel.gd must exist")
	_check(ResourceLoader.exists("res://scripts/quest_tracker.gd"), "quest_tracker.gd must exist")
	for script_path in ["res://scripts/quest_panel.gd", "res://scripts/quest_tracker.gd"]:
		if ResourceLoader.exists(script_path):
			var ui_script = load(script_path)
			_check(ui_script != null and ui_script.can_instantiate(), script_path + " must compile and instantiate")
	_check(ResourceLoader.exists("res://assets/bg/title/shadow_mech_city_title.png"), "generated title hero bitmap must exist")

func _validate_quest_resources() -> void:
	if not ResourceLoader.exists("res://scripts/quest_data.gd"):
		_check(false, "quest_data.gd must exist")
		return
	if not ResourceLoader.exists("res://scripts/quest_runtime.gd"):
		_check(false, "quest_runtime.gd must exist")
		return
	var data_script = load("res://scripts/quest_data.gd")
	var runtime_script = load("res://scripts/quest_runtime.gd")
	_check(data_script != null and runtime_script != null, "quest data/runtime must compile")
	if data_script == null or runtime_script == null:
		return
	var order: Array = data_script.MAIN_ORDER
	var quests: Dictionary = data_script.QUESTS
	_check(order == EXPECTED_QUESTS, "main quest order must match the four authored chapters")
	for id in EXPECTED_QUESTS:
		_check(quests.has(id), "quest data missing chapter: " + id)
		if not quests.has(id):
			continue
		var quest: Dictionary = quests[id]
		_check(str(quest.get("title", "")).strip_edges() != "", id + " needs a title")
		_check(str(quest.get("summary", "")).strip_edges() != "", id + " needs a summary")
		_check(quest.get("objectives", []).size() >= 2, id + " needs at least two objectives")
		for objective in quest.get("objectives", []):
			_check(["flag", "visited", "item"].has(str(objective.get("type", ""))), id + " has unsupported objective type")
			_check(str(objective.get("id", "")) != "", id + " objective needs an id")
			_check(str(objective.get("text", "")) != "", id + " objective needs display text")
	var runtime = runtime_script.new()
	_check(runtime.has_method("evaluate_all"), "quest runtime must expose evaluate_all")
	_check(runtime.has_method("pick_tracked"), "quest runtime must expose pick_tracked")
	var low := _snapshot([], [], [], [])
	var low_states: Dictionary = runtime.evaluate_all(low, {})
	_check(low_states.get("echo_coordinates", {}).get("status", "") == "active", "first chapter must be active for a fresh game")
	_check(low_states.get("broken_network", {}).get("status", "") == "locked", "second chapter must start locked")
	var mid := _snapshot(
		["hub", "mine", "factory_entry", "sewer_entry", "temple_entry"],
		["boss_mine_boss", "boss_boss", "boss_water_boss", "boss_temple_sanctum"],
		["met_cartographer"], [])
	var mid_states: Dictionary = runtime.evaluate_all(mid, {})
	_check(mid_states.get("echo_coordinates", {}).get("status", "") == "complete", "old save facts must auto-complete chapter one")
	_check(mid_states.get("broken_network", {}).get("status", "") == "complete", "three regional bosses must complete chapter two")
	_check(mid_states.get("void_skyline", {}).get("status", "") == "active", "chapter three must unlock after chapter two")
	var done := _snapshot(
		["hub", "mine", "factory_entry", "sewer_entry", "temple_entry", "void_gate", "castle_gate", "castle_throne"],
		["boss_mine_boss", "boss_boss", "boss_water_boss", "boss_temple_sanctum", "boss_void_throne", "boss_castle_throne"],
		["met_cartographer"], [])
	var done_states: Dictionary = runtime.evaluate_all(done, {})
	for id in EXPECTED_QUESTS:
		_check(done_states.get(id, {}).get("status", "") == "complete", "completed save must finish chapter: " + id)

func _snapshot(visited_ids: Array, item_ids: Array, dialogue_ids: Array, story_ids: Array) -> Dictionary:
	var visited := {}
	var items := {}
	var dialogue := {}
	var story := {}
	for id in visited_ids: visited[id] = true
	for id in item_ids: items[id] = true
	for id in dialogue_ids: dialogue[id] = true
	for id in story_ids: story[id] = true
	return {"visited":visited, "items":items, "dialogue_flags":dialogue, "story_flags":story, "unlocked_weapons":[]}

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
