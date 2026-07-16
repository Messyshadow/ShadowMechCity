extends SceneTree

const SIDE_IDS := ["forged_arsenal", "sealed_memories", "beyond_the_map", "last_witnesses", "lord_hunt"]
const MEMORY_IDS := ["memory_hub_archive", "memory_mine_cache", "memory_factory_heat", "memory_water_cistern", "memory_temple_orbit", "memory_void_observatory", "memory_castle_ossuary"]
var failures: Array[String] = []

func _init() -> void:
	var data = load("res://scripts/quest_data.gd")
	var runtime_script = load("res://scripts/quest_runtime.gd")
	_check(data != null and runtime_script != null, "quest resources must compile")
	if data and runtime_script:
		_check(data.SIDE_ORDER == SIDE_IDS, "five NPC side quests must use the authored order")
		_check(data.COLLECTIBLE_ORDER == MEMORY_IDS, "seven regional memories must form the archive")
		for id in SIDE_IDS:
			_check(data.SIDE_QUESTS.has(id), "missing side quest: " + id)
		for id in MEMORY_IDS:
			var entry: Dictionary = data.COLLECTIBLES.get(id, {})
			_check(not entry.is_empty(), "missing collectible record: " + id)
			_check(str(entry.get("title", "")) != "" and str(entry.get("lore", "")) != "", id + " needs title and lore")
		var runtime = runtime_script.new()
		_check(runtime.has_method("evaluate_side"), "runtime must evaluate side quests")
		if runtime.has_method("evaluate_side"):
			var low: Dictionary = runtime.evaluate_side(_snapshot([], [], [], [], 0), {})
			_check(low.get("forged_arsenal", {}).get("status", "") == "locked", "side quest locks before meeting its NPC")
			var high: Dictionary = runtime.evaluate_side(_snapshot(MEMORY_IDS, ["boss_mine_boss", "boss_boss", "boss_water_boss", "boss_temple_sanctum", "boss_void_throne", "boss_castle_knights", "boss_castle_throne"], ["met_smith", "met_alchemist", "met_cartographer", "met_collector", "met_bounty"], ["sword", "hammer", "cannon", "greatsword", "void_blade", "scythe"], 7), {})
			for id in SIDE_IDS:
				_check(high.get(id, {}).get("status", "") == "complete", "old-save facts must complete side quest: " + id)
	var panel_source := FileAccess.get_file_as_string("res://scripts/quest_panel.gd")
	for marker in ["主线", "支线", "收藏", "COLLECTIBLE_ORDER", "evaluate_side"]:
		_check(panel_source.contains(marker), "mission archive missing tab/runtime marker: " + marker)
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for marker in ["SHOT_SIDE_QUESTS", "SHOT_COLLECTIBLES"]:
		_check(main_source.contains(marker), "main capture hook missing: " + marker)
	if failures.is_empty():
		print("PASS stage 12.3 side quest and collectible archive contracts")
		quit(0)
		return
	for failure in failures: push_error(failure)
	quit(1)

func _snapshot(memories: Array, bosses: Array, flags: Array, weapons: Array, hidden_count: int) -> Dictionary:
	var collected := {}; var items := {}; var dialogue := {}
	for id in memories: collected[id] = true
	for id in bosses: items[id] = true
	for id in flags: dialogue[id] = true
	return {"visited":{}, "items":items, "dialogue_flags":dialogue, "story_flags":{}, "collected":collected, "unlocked_weapons":weapons, "hidden_count":hidden_count, "boss_count":bosses.size(), "memory_count":memories.size(), "weapon_count":weapons.size(), "kills":60}

func _check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
