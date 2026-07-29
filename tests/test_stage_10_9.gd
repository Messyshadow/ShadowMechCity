extends SceneTree

const SECRET_ROOMS := [
	"secret_hub_archive", "secret_mine_cache", "secret_factory_heat",
	"secret_water_cistern", "secret_temple_orbit", "secret_void_observatory",
	"secret_castle_ossuary",
]

var failures: Array[String] = []

func _init() -> void:
	var path := "res://scripts/portal_interaction.gd"
	_check(FileAccess.file_exists(path), "portal interaction script must exist")
	if FileAccess.file_exists(path):
		var portal = load(path)
		_check(not portal.requires_interaction({"side":"left"}), "ordinary left door remains automatic")
		_check(not portal.requires_interaction({"side":"right"}), "ordinary right door remains automatic")
		_check(portal.requires_interaction({"side":"up"}), "up portal requires interact")
		_check(portal.requires_interaction({"side":"down"}), "down shaft requires interact")
		_check(portal.requires_interaction({"side":"left", "hidden":true}), "hidden side door requires interact")
		_check(portal.requires_interaction({"side":"left", "trigger_mode":"interact"}), "explicit interact override works")
		_check(not portal.requires_interaction({"side":"up", "trigger_mode":"auto"}), "explicit auto override works")
		_check(portal.prompt_text({"side":"up"}, "破碎甲板", false, []).contains("向上攀登"), "up prompt names climb action")
		_check(portal.prompt_text({"side":"down"}, "地下水道", false, []).contains("向下进入"), "down prompt names descent")
		_check(portal.prompt_text({"side":"left", "hidden":true}, "遗失档案库", false, []).contains("隐藏回响"), "unvisited secret stays unnamed")
		_check(portal.prompt_text({"side":"left", "hidden":true}, "遗失档案库", true, []).contains("遗失档案库"), "visited secret shows target name")
		_check(portal.prompt_text({"side":"up"}, "破碎甲板", false, ["暗影滑翔翼"]).contains("需要：暗影滑翔翼"), "locked prompt lists missing abilities")
		var up_anchor: Vector2 = portal.anchor_position({"side":"up", "p":700}, [0, 0, 1400, 560])
		_check(up_anchor == Vector2(700, 530), "up teleport array must be anchored on the room floor")
		var hidden_anchor: Vector2 = portal.anchor_position({"side":"up", "p":1120, "hidden":true}, [0, 0, 1400, 560])
		_check(hidden_anchor == Vector2(1120, 54), "hidden up entrance must remain discoverable on the high route")
		var down_anchor: Vector2 = portal.anchor_position({"side":"down", "p":950}, [0, 0, 1900, 760])
		_check(down_anchor == Vector2(950, 726), "down interaction must align with the shaft mouth")
		var node := Area2D.new()
		node.set_script(portal)
		get_root().add_child(node)
		node.configure({"side":"up", "to":"void_deck"}, "破碎甲板", false, [])
		var counts := {"requested":0, "blocked":0}
		node.travel_requested.connect(func(_door): counts["requested"] += 1)
		node.force_prompt_visible(true)
		node.attempt_interaction()
		node.attempt_interaction()
		_check(counts["requested"] == 1, "interaction emits travel only once until reset")
		node.reset_request()
		node.configure({"side":"up", "to":"void_deck"}, "破碎甲板", false, ["暗影滑翔翼"])
		node.travel_blocked.connect(func(_missing): counts["blocked"] += 1)
		node.force_prompt_visible(true)
		node.attempt_interaction()
		_check(counts["blocked"] == 1, "missing ability blocks travel")
		node.queue_free()
	_check_main_integration()
	_check_visual_contract()
	_check_hidden_links()
	_finish()

func _check_main_integration() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for marker in [
		"const PORTAL_INTERACTION_SCRIPT",
		"PORTAL_INTERACTION_SCRIPT.requires_interaction",
		"travel_requested.connect",
		"travel_blocked.connect",
		"_make_shaft_safety_floor",
	]:
		_check(source.contains(marker), "main portal integration missing: " + marker)

func _check_visual_contract() -> void:
	var visual_path := "res://scripts/portal_visual.gd"
	_check(FileAccess.file_exists(visual_path), "portal visual script must exist")
	if FileAccess.file_exists(visual_path):
		var source := FileAccess.get_file_as_string(visual_path)
		for marker in ["func setup(", "func set_focused(", "draw_polyline", "CPUParticles2D"]:
			_check(source.contains(marker), "portal visual missing: " + marker)
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	_check(main_source.contains("PORTAL_VISUAL_SCRIPT"), "main must preload portal visual")
	_check(main_source.contains("visual.setup("), "main must configure portal visual")
	_check(main_source.contains("SHOT_PORTAL_PROMPT"), "main must expose deterministic portal prompt capture")
	_check(main_source.contains("SHOT_UNLOCK_ABILITIES"), "portal capture must support unlocked hidden entrances")

func _check_hidden_links() -> void:
	var rooms: Dictionary = load("res://scripts/rooms.gd").ROOMS
	var hidden_count := 0
	for from_id in rooms:
		for door in rooms[from_id].get("doors", []):
			if door.get("hidden", false):
				hidden_count += 1
				_check(SECRET_ROOMS.has(door["to"]), "hidden entrance target changed: " + str(door["to"]))
	_check(hidden_count == 7, "all seven hidden entrances must remain")

func _check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("PASS stage 10.9 portal contracts")
		quit(0)
		return
	for failure in failures: push_error(failure)
	quit(1)
