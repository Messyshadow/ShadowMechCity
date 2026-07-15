extends SceneTree

const EXPECTED_NPCS := ["smith", "alchemist", "cartographer", "collector", "bounty"]
const PROGRESSED_EXPECTED := {
	"smith": "smith_arsenal",
	"alchemist": "alchemist_memory",
	"cartographer": "cartographer_secret",
	"collector": "collector_archive",
	"bounty": "bounty_veteran",
}

var failures: Array[String] = []

func _init() -> void:
	_validate_hub_contract()
	_validate_source_contracts()
	_validate_dialogue_resources()
	if failures.is_empty():
		print("PASS stage 12.1 dialogue and hub NPC contracts")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _validate_hub_contract() -> void:
	var hub: Dictionary = Rooms.ROOMS.get("hub", {})
	var placements: Array = hub.get("npcs", [])
	_check(placements.size() == EXPECTED_NPCS.size(), "hub must place exactly five NPCs")
	for id in EXPECTED_NPCS:
		var count := 0
		for placement in placements:
			if placement.size() >= 3 and str(placement[2]) == id:
				count += 1
		_check(count == 1, "hub must place NPC exactly once: " + id)

func _validate_source_contracts() -> void:
	var game_source := FileAccess.get_file_as_string("res://scripts/game.gd")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var player_source := FileAccess.get_file_as_string("res://scripts/player.gd")
	var camera_source := FileAccess.get_file_as_string("res://scripts/follow_camera.gd")
	for marker in ["dialogue_flags", "story_flags", "narrative_snapshot", "dialogue_started", "dialogue_ended"]:
		_check(game_source.contains(marker), "game persistence/runtime missing marker: " + marker)
	_check(game_source.contains('"interact"'), "Game.ACTIONS must register interact")
	for marker in ["_spawn_npc", "_start_dialogue", "SHOT_DIALOGUE", "SHOT_DIALOGUE_PROGRESS", "SHOT_DIALOGUE_CHOICE", "SHOT_NPC_PROMPT"]:
		_check(main_source.contains(marker), "main dialogue integration missing marker: " + marker)
	_check(player_source.contains("input_locked"), "player must support dialogue input lock")
	_check(player_source.contains("func set_input_locked"), "player input lock must cleanly cancel combat state")
	_check(camera_source.contains("dialogue_focus"), "camera must expose a stable dialogue focus offset")
	_check(ResourceLoader.exists("res://scripts/npc_actor.gd"), "npc_actor.gd must exist")
	_check(ResourceLoader.exists("res://scripts/dialogue_panel.gd"), "dialogue_panel.gd must exist")
	if ResourceLoader.exists("res://scripts/npc_actor.gd"):
		var actor_script = load("res://scripts/npc_actor.gd")
		_check(actor_script != null and actor_script.can_instantiate(), "npc_actor.gd must compile and instantiate")
	if ResourceLoader.exists("res://scripts/dialogue_panel.gd"):
		var panel_script = load("res://scripts/dialogue_panel.gd")
		_check(panel_script != null and panel_script.can_instantiate(), "dialogue_panel.gd must compile and instantiate")

func _validate_dialogue_resources() -> void:
	if not ResourceLoader.exists("res://scripts/npc_data.gd"):
		_check(false, "npc_data.gd must exist")
		return
	if not ResourceLoader.exists("res://scripts/dialogue_data.gd"):
		_check(false, "dialogue_data.gd must exist")
		return
	if not ResourceLoader.exists("res://scripts/dialogue_runner.gd"):
		_check(false, "dialogue_runner.gd must exist")
		return
	var npc_script = load("res://scripts/npc_data.gd")
	var dialogue_script = load("res://scripts/dialogue_data.gd")
	var runner_script = load("res://scripts/dialogue_runner.gd")
	var npcs: Dictionary = npc_script.NPCS
	var routes: Dictionary = dialogue_script.ROUTES
	_check(npcs.size() == EXPECTED_NPCS.size(), "NPC data must contain exactly five records")
	for id in EXPECTED_NPCS:
		_check(npcs.has(id), "NPC data missing: " + id)
		_check(routes.has(id), "dialogue route missing: " + id)
		if not routes.has(id):
			continue
		_validate_route(id, routes[id])
		var runner = runner_script.new()
		_check(runner.has_method("begin_at"), "dialogue runner must support deterministic QA node entry")
		var low := {"visited_count":1, "hidden_count":0, "boss_count":0, "memory_count":0, "weapon_count":3}
		var first: Dictionary = runner.begin(id, low, {})
		_check(str(first.get("id", "")).ends_with("_first"), id + " low state must select first-meet node")
		var seen_flags := {"met_%s" % id: true}
		var repeat: Dictionary = runner.begin(id, low, seen_flags)
		_check(str(repeat.get("id", "")).ends_with("_repeat"), id + " met state must select repeat node")
		var high := {"visited_count":30, "hidden_count":4, "boss_count":4, "memory_count":5, "weapon_count":6}
		var progressed: Dictionary = runner.begin(id, high, seen_flags)
		_check(progressed.get("id", "") == PROGRESSED_EXPECTED[id], id + " high state must select progressed node")
		if id == "bounty" and runner.has_method("begin_at"):
			var choice_node: Dictionary = runner.begin_at("bounty", "bounty_choice")
			_check(choice_node.get("id", "") == "bounty_choice" and choice_node.get("choices", []).size() == 2,
				"deterministic bounty choice entry must expose two choices")

func _validate_route(id: String, route: Dictionary) -> void:
	var entries: Array = route.get("entries", [])
	var nodes: Dictionary = route.get("nodes", {})
	_check(entries.size() >= 3, id + " needs first/repeat/progressed entries")
	_check(not nodes.is_empty(), id + " needs dialogue nodes")
	var has_first := false
	var has_repeat := false
	var has_progressed := false
	for entry in entries:
		var target := str(entry.get("node", ""))
		_check(nodes.has(target), "%s entry target missing: %s" % [id, target])
		if target.ends_with("_first"): has_first = true
		elif target.ends_with("_repeat"): has_repeat = true
		else: has_progressed = true
	_check(has_first and has_repeat and has_progressed, id + " must expose first/repeat/progressed routes")
	for node_id in nodes:
		var node: Dictionary = nodes[node_id]
		_check(str(node.get("text", "")).strip_edges() != "", "%s node has empty text: %s" % [id, node_id])
		_check(node.has("events") and node["events"] is Array, "%s node events must be explicit: %s" % [id, node_id])
		_check(node.has("choices") and node["choices"] is Array, "%s node choices must be explicit: %s" % [id, node_id])
		var next_id := str(node.get("next", ""))
		_check(next_id == "" or nodes.has(next_id), "%s next target missing: %s" % [id, next_id])
		for choice in node.get("choices", []):
			_check(nodes.has(str(choice.get("to", ""))), "%s choice target missing from %s" % [id, node_id])

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
