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
		_check(portal.prompt_text({"side":"up"}, "破碎甲板", false, []).contains("启动传送阵"), "up prompt names teleport action")
		_check(portal.prompt_text({"side":"down"}, "地下水道", false, []).contains("向下进入"), "down prompt names descent")
		_check(portal.prompt_text({"side":"left", "hidden":true}, "遗失档案库", false, []).contains("隐藏回响"), "unvisited secret stays unnamed")
		_check(portal.prompt_text({"side":"left", "hidden":true}, "遗失档案库", true, []).contains("遗失档案库"), "visited secret shows target name")
		_check(portal.prompt_text({"side":"up"}, "破碎甲板", false, ["暗影滑翔翼"]).contains("需要：暗影滑翔翼"), "locked prompt lists missing abilities")
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
	_check_hidden_links()
	_finish()

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
