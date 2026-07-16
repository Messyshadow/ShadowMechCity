extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_check(ResourceLoader.exists("res://scripts/cinematic_data.gd"), "cinematic_data.gd must exist")
	_check(ResourceLoader.exists("res://scripts/cinematic_panel.gd"), "cinematic_panel.gd must exist")
	_check(ResourceLoader.exists("res://scripts/tutorial_guide.gd"), "tutorial_guide.gd must exist")
	if ResourceLoader.exists("res://scripts/cinematic_data.gd"):
		var data = load("res://scripts/cinematic_data.gd")
		_check(data != null, "cinematic data must compile")
		if data:
			_check(data.INTRO.size() == 4, "opening must contain four authored beats")
			_check(data.ENDING.size() == 3, "ending must contain three authored beats")
			for beat in data.INTRO + data.ENDING:
				_check(str(beat.get("title", "")) != "" and str(beat.get("text", "")) != "", "every cinematic beat needs title and text")
	for path in ["res://scripts/cinematic_panel.gd", "res://scripts/tutorial_guide.gd"]:
		if ResourceLoader.exists(path):
			var script = load(path)
			_check(script != null and script.can_instantiate(), path + " must compile and instantiate")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	for marker in ["CINEMATIC_PANEL_SCRIPT", "TUTORIAL_GUIDE_SCRIPT", "intro_seen", "ending_seen", "SHOT_INTRO", "SHOT_TUTORIAL", "SHOT_ENDING_12_4"]:
		_check(main_source.contains(marker), "main integration missing marker: " + marker)
	var tutorial_source := FileAccess.get_file_as_string("res://scripts/tutorial_guide.gd")
	for marker in ["tutorial_complete", "move_left", "jump", "attack", "dash", "interact", "map_menu"]:
		_check(tutorial_source.contains(marker), "tutorial missing action/state marker: " + marker)
	_check(tutorial_source.contains("func _input(event"), "tutorial must observe raw input before menu panels consume map/interact actions")
	var title_source := FileAccess.get_file_as_string("res://scripts/title_menu.gd")
	_check(title_source.contains("阶段 12.4"), "title needs visible stage 12.4 build marker")
	if failures.is_empty():
		print("PASS stage 12.4 cinematic and tutorial contracts")
		quit(0); return
	for failure in failures: push_error(failure)
	quit(1)

func _check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
