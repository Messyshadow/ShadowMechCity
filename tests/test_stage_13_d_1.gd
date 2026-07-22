extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	var main_src := FileAccess.get_file_as_string("res://scripts/main.gd")
	var game_src := FileAccess.get_file_as_string("res://scripts/game.gd")
	var pause_src := FileAccess.get_file_as_string("res://scripts/pause_menu.gd")
	_expect(FileAccess.file_exists("res://scripts/dash_gate.gd"), "dash gate component exists")
	_expect(FileAccess.file_exists("res://scripts/boss_retreat_console.gd"), "boss retreat console exists")
	for marker in ["boss_entry_room", "can_retreat_boss", "retreat_from_boss", "BOSS_RETREAT_CONSOLE"]:
		_expect(main_src.contains(marker), "main exposes " + marker)
	for marker in ["撤离 Boss 战（测试版）", "can_retreat_boss", "retreat_from_boss"]:
		_expect(pause_src.contains(marker), "pause menu exposes " + marker)
	_expect(game_src.contains('"retreat"'), "retreat input is registered")
	_expect(game_src.contains('"dash_gate_taught"'), "dash gate tutorial flag is persisted")
	var gate_src := FileAccess.get_file_as_string("res://scripts/dash_gate.gd")
	for marker in ["冲刺穿越相位屏障", "普通移动无法穿越", "direction_arrow", "dash_gate_taught", "collision_layer = 0b100000"]:
		_expect(gate_src.contains(marker), "dash gate behavior exists: " + marker)
	_expect(gate_src.contains("StyleBoxFlat.new"), "dash gate prompt has a high-contrast plate")
	_expect(main_src.contains("DASH_GATE_SCRIPT"), "main preloads the dash gate component")
	var console_src := FileAccess.get_file_as_string("res://scripts/boss_retreat_console.gd")
	for marker in ["长按 B 撤离 Boss 战", "hold_time", "retreat_from_boss", "progress"]:
		_expect(console_src.contains(marker), "retreat console behavior exists: " + marker)
	_expect(console_src.contains("StyleBoxFlat.new"), "retreat prompt has a high-contrast plate")
	for marker in ["not Game.has_item(\"boss_\" + room_id)", "_boss_entry_room = from_room", "_enter_room.call_deferred(target_room, room_id)"]:
		_expect(main_src.contains(marker), "retreat safety rule exists: " + marker)
	for marker in ["SHOT_13D1", "func _prepare_13d1_capture", '"dash_gate"', '"boss_retreat"']:
		_expect(main_src.contains(marker), "deterministic 13D.1 capture exists: " + marker)
	_expect(main_src.contains("func _clear_13d1_capture_enemies"), "13D.1 capture removes unrelated enemies")
	_expect(main_src.contains("_clear_13d1_capture_enemies(true)"), "boss capture preserves the boss")
	_expect(main_src.contains("enemy == _boss"), "capture clear distinguishes the boss from enemies")
	_expect(main_src.contains("func _freeze_13d1_capture_player"), "13D.1 capture owns a player-visibility freeze helper")
	if failures.is_empty():
		print("STAGE_13_D_1_PASS")
		quit(0)
	else:
		for failure in failures:
			push_error("STAGE_13_D_1: " + failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
