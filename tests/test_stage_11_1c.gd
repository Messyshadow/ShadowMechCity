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
	var rules_source := _source("res://scripts/summon_rules.gd")
	var game_source := _source("res://scripts/game.gd")
	var migration_source := _source("res://scripts/progression_migration.gd")
	var controller_source := _source("res://scripts/summon_controller.gd")
	var robot_source := _source("res://scripts/summon_robot.gd")
	var panel_source := _source("res://scripts/summon_roster_panel.gd")
	var main_source := _source("res://scripts/main.gd")

	_expect(migration_source.contains("CURRENT_VERSION := 16"), "存档版本未升级到 16")
	_expect(game_source.contains("func upgrade_summon_slots"), "Game 缺少技能点解锁召唤槽")
	_expect(game_source.contains('"summon_roster":') and game_source.contains("KEY_G"), "缺少 G 键阵容入口")
	for marker in ["slot_upgrade_cost", "unique_loadout", "formation_offset", "overload_profile"]:
		_expect(rules_source.contains(marker), "召唤纯规则缺少: " + marker)
	for marker in ["active_robots", "overload_value", "_deploy_loadout", "attack_committed"]:
		_expect(controller_source.contains(marker), "多召唤控制器缺少: " + marker)
	for marker in ["configure_formation", "formation_index", "power_scale", "overload_lock"]:
		_expect(robot_source.contains(marker), "伙伴协同协议缺少: " + marker)
	for marker in ["量子伙伴阵列", "assign_selected_model", "unlock_next_slot", "不同型号", "量子超载"]:
		_expect(panel_source.contains(marker), "阵容 UI 缺少: " + marker)
	_expect(main_source.contains("SHOT_SUMMON_ROSTER") and main_source.contains("SHOT_SUMMON_TEAM"), "缺少 11.1c 确定性截图入口")

	if FileAccess.file_exists("res://scripts/summon_rules.gd"):
		var rules = load("res://scripts/summon_rules.gd")
		_expect(rules.slot_upgrade_cost(1) == 2, "1→2 槽费用应为 2 技能点")
		_expect(rules.slot_upgrade_cost(2) == 3, "2→3 槽费用应为 3 技能点")
		_expect(rules.slot_upgrade_cost(3) == 0, "三槽后不得继续升级")
		var ids := ["starter_bastion_001", "prototype_bulwark_001", "starter_bastion_001", "prototype_skyrail_001"]
		var unique: Array = rules.unique_loadout(ids, 3)
		_expect(unique == ["starter_bastion_001", "prototype_bulwark_001", "prototype_skyrail_001"], "阵容必须去重且最多三台")
		_expect(rules.formation_offset(0, 3, "ground") != rules.formation_offset(1, 3, "ground"), "三台编队不得重叠")
		_expect(float(rules.overload_profile(3).get("gain", 0.0)) > float(rules.overload_profile(2).get("gain", 0.0)), "三召唤应有更高超载压力")

	var migrated: Dictionary = ProgressionMigration.migrate({
		"save_version": 15,
		"skill_points": 7,
		"summon_slot_level": 3,
		"summon_loadout": ["starter_bastion_001", "starter_bastion_001", "prototype_skyrail_001"],
		"robot_roster": RobotData.role_records(),
		"inventory": [{"item_id": "legacy_blade"}],
	})
	_expect(int(migrated.get("save_version", 0)) == 16, "v15 未迁移至 v16")
	_expect((migrated.get("summon_loadout", []) as Array).size() == 2, "迁移应移除重复型号")
	_expect(int(migrated.get("skill_points", 0)) == 7, "迁移不得消耗旧技能点")
	_expect((migrated.get("inventory", []) as Array).size() == 1, "迁移破坏旧背包")

	if failures.is_empty():
		print("PASS stage 11.1c multi-slot formation contracts")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("FAIL stage 11.1c: %d contract(s)" % failures.size())
		quit(1)
