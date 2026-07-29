extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_check(FileAccess.file_exists("res://scripts/shaft_transition.gd"), "missing playable shaft transition component")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var player_source := FileAccess.get_file_as_string("res://scripts/player.gd")
	var camera_source := FileAccess.get_file_as_string("res://scripts/follow_camera.gd")
	_check(main_source.contains("SHAFT_TRANSITION_SCRIPT"), "main must load the shaft transition component")
	_check(main_source.contains("await shaft.finished"), "room change must wait for playable descent completion")
	_check(main_source.contains("player.z_index = 10"), "player must render above shaft architecture during descent")
	_check(main_source.contains("player.z_index = 0"), "player render order must reset after descent")
	var shaft_func_start := main_source.find("func _play_shaft_transition")
	var shaft_func_end := main_source.find("\nfunc ", shaft_func_start + 1)
	var shaft_func_source := main_source.substr(shaft_func_start, shaft_func_end - shaft_func_start)
	_check(shaft_func_start >= 0 and not shaft_func_source.contains("player.set_physics_process(false)"), "shaft descent must preserve player physics")
	_check(player_source.contains("var shaft_mode := false"), "player needs a shaft input mode")
	_check(player_source.contains("const SHAFT_FALL_SPEED := 230.0"), "playable shaft needs a camera-readable fall speed")
	_check(player_source.contains("if shaft_mode and velocity.y > SHAFT_FALL_SPEED"), "shaft fall speed must be capped without changing normal rooms")
	_check(player_source.contains("if shaft_mode:") and player_source.contains("return\n\n\t# 切换武器"), "shaft mode must gate combat after movement and wall mechanics")
	_check(camera_source.contains("func begin_shaft"), "camera needs a temporary shaft follow mode")
	_check(camera_source.contains("func end_shaft"), "camera must restore normal follow after descent")
	_check(main_source.contains('if _qa_option("SHOT_SHAFT") == "1"'), "godot-capture needs a playable shaft burst mode")
	_check(main_source.contains("func _shaft_capture_burst"), "shaft burst capture helper is missing")
	_check(main_source.contains("for i in range(8)"), "shaft QA must capture eight changing frames")
	_check(main_source.contains("create_timer(0.38)"), "shaft burst must span the full multi-second descent")
	if FileAccess.file_exists("res://scripts/shaft_transition.gd"):
		var shaft_source := FileAccess.get_file_as_string("res://scripts/shaft_transition.gd")
		for marker in ["signal finished", "const SHAFT_DEPTH := DOWN_DEPTH", "func setup", "_make_wall", "_make_ledge", "_make_bottom_trigger", "TIMEOUT_SECONDS"]:
			_check(shaft_source.contains(marker), "shaft component missing: " + marker)
		_check(shaft_source.contains("z_index = -1"), "shaft art must render behind the player")
		_check(shaft_source.contains("_make_ledge(-52.0, depth * 0.28)") and shaft_source.contains("shape.size = Vector2(50.0, 12.0)"), "shaft ledges must leave a clear central fall lane")
		_check(shaft_source.contains('call_deferred("_emit_finished")'), "bottom trigger must leave the physics flush before changing rooms")
	if failures.is_empty():
		print("PASS stage 10.6.5 playable shaft contracts")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
