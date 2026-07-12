extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	var rooms: Dictionary = load("res://scripts/rooms.gd").ROOMS
	_check(rooms.has("depths"), "missing depths room")
	if rooms.has("depths"):
		_check_depths_route(rooms["depths"])
	var portal := FileAccess.get_file_as_string("res://scripts/downward_portal_visual.gd")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	_check(main_source.contains('_qa_option("SHOT_OUTPUT")'), "published builds need a writable QA screenshot output path")
	_check(main_source.contains("save_error != OK"), "QA screenshot saves must report failures")
	var title_source := FileAccess.get_file_as_string("res://scripts/title_menu.gd")
	_check(title_source.contains('_qa_option("SHOT_ROOM") != ""'), "published room QA must leave the title scene")
	_check(title_source.contains('change_scene_to_file.call_deferred("res://main.tscn")'), "published room QA must enter the game scene")
	_check(main_source.contains('env_name.to_lower().replace("_", "-")'), "published QA must accept command-line options when environment variables are unavailable")
	for marker in ["_draw_lintel", "_draw_support_braces", "_draw_guide_lamps", "_draw_landing_cues"]:
		_check(portal.contains(marker), "downward entrance missing structural visual: " + marker)
	if failures.is_empty():
		print("PASS stage 10.6.4 entrance and reachability contracts")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check_depths_route(room: Dictionary) -> void:
	var up_x := -1.0
	for door in room.get("doors", []):
		if door.get("side", "") == "up":
			up_x = float(door["p"])
	_check(up_x >= 0.0, "depths needs an up door")
	var current_y := float(room["bounds"][3])
	var current_left := 0.0
	var current_right := float(room["bounds"][2])
	var route: Array = room.get("platforms", []).duplicate()
	route.sort_custom(func(a: Array, b: Array) -> bool: return float(a[1]) > float(b[1]))
	var reached := false
	for platform in route:
		var left := float(platform[0])
		var right := left + float(platform[2])
		var rise := current_y - float(platform[1])
		var gap := maxf(maxf(left - current_right, current_left - right), 0.0)
		if rise > 0.0 and rise <= 90.0 and gap <= 45.0:
			current_y = float(platform[1])
			current_left = left
			current_right = right
			if up_x >= left and up_x <= right and current_y <= 130.0:
				reached = true
				break
	_check(reached, "depths up-door route needs <=90px rises and <=45px horizontal gaps")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
