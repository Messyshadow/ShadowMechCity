extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _source(path: String) -> String:
	return FileAccess.get_file_as_string(path)


func _run() -> void:
	var data := _source("res://scripts/robot_data.gd")
	var game := _source("res://scripts/game.gd")
	var migration := _source("res://scripts/progression_migration.gd")
	var robot := _source("res://scripts/summon_robot.gd")
	var controller := _source("res://scripts/summon_controller.gd")
	var main := _source("res://scripts/main.gd")

	for model_id in ["scrap_hound_mk1", "bulwark_mole_mk1", "sky_rail_drone_mk1", "lumen_wisp_mk1"]:
		_expect(data.contains(model_id), "缺少机器人型号: " + model_id)
	for marker in ["mobility", "combat_style", "role_records", "ROLE_INSTANCE_IDS"]:
		_expect(data.contains(marker), "机器人数据缺少差异字段: " + marker)
	_expect(migration.contains("CURRENT_VERSION := 15"), "存档版本未升级到 15")
	_expect(game.contains("ensure_role_roster"), "Game 未补齐定位阵容")
	_expect(game.contains('"summon_cycle":') and game.contains("KEY_Z"), "缺少 Z 键型号切换")
	for marker in ["func cycle_standby_model", "summon_cycle", "func select_model_for_qa"]:
		_expect(controller.contains(marker), "召唤控制器缺少: " + marker)
	for marker in ["_tick_ground", "_tick_air", "_support_pulse", "force_support_pulse_for_qa", "_unstuck_timer", "combat_style"]:
		_expect(robot.contains(marker), "机器人差异 AI 缺少: " + marker)
	_expect(main.contains("SHOT_SUMMON_MODEL") and main.contains("SHOT_SUMMON_ARENA"), "Godot Capture 缺少型号/独立战斗场入口")

	var role_records: Array = RobotData.role_records()
	_expect(role_records.size() == 4, "原型阵容必须正好包含四种型号")
	var mobility_count := {"ground": 0, "air": 0}
	var model_seen := {}
	for record in role_records:
		var model_id := str(record.get("model_id", ""))
		var profile := RobotData.profile(model_id)
		model_seen[model_id] = true
		var mobility := str(profile.get("mobility", ""))
		mobility_count[mobility] = int(mobility_count.get(mobility, 0)) + 1
	_expect(int(mobility_count["ground"]) == 2, "必须有两种地面定位")
	_expect(int(mobility_count["air"]) == 2, "必须有两种空中定位")
	_expect(model_seen.size() == 4, "四个原型不得重复型号")

	var migrated: Dictionary = ProgressionMigration.migrate({
		"save_version": 14,
		"robot_roster": [RobotData.starter_record()],
		"summon_loadout": [RobotData.STARTER_INSTANCE_ID],
		"inventory": [{"item_id": "legacy_blade"}],
	})
	_expect(int(migrated.get("save_version", 0)) == 15, "v14 未迁移至 v15")
	_expect((migrated.get("robot_roster", []) as Array).size() == 4, "迁移未补齐四定位阵容")
	_expect((migrated.get("inventory", []) as Array).size() == 1, "迁移破坏旧背包")
	_expect((migrated.get("summon_loadout", []) as Array) == [RobotData.STARTER_INSTANCE_ID], "迁移不应擅自改变出战型号")

	if failures.is_empty():
		print("PASS stage 11.1b air/ground role contracts")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("FAIL stage 11.1b: %d contract(s)" % failures.size())
		quit(1)
