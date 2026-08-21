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
	var game := _source("res://scripts/game.gd")
	var migration := _source("res://scripts/progression_migration.gd")
	var main := _source("res://scripts/main.gd")
	var enemy := _source("res://scripts/enemy.gd")
	var projectile := _source("res://scripts/enemy_projectile.gd")
	var robot_data := _source("res://scripts/robot_data.gd")
	var robot := _source("res://scripts/summon_robot.gd")
	var controller := _source("res://scripts/summon_controller.gd")
	var map_panel := _source("res://scripts/map_panel.gd")
	var rooms := _source("res://scripts/rooms.gd")

	for marker in ["robot_roster", "summon_loadout", "summon_slot_level", "summon_changed", "ensure_starter_robot"]:
		_expect(game.contains(marker), "Game 缺少召唤持久字段: " + marker)
	_expect(game.contains('"summon":') and game.contains("KEY_C"), "缺少 C 键召唤输入")
	_expect(migration.contains("CURRENT_VERSION := 14"), "存档版本未升级到 14")
	for marker in ["robot_roster", "summon_loadout", "summon_slot_level"]:
		_expect(migration.contains(marker), "迁移器缺少字段: " + marker)

	for marker in ["class_name RobotData", "scrap_hound_mk1", "starter_bastion_001"]:
		_expect(robot_data.contains(marker), "机器人数据缺少: " + marker)
	for marker in ["class_name SummonRobot", 'add_to_group("summon_ally")', "func take_damage", "func _find_target", "func _attack_target"]:
		_expect(robot.contains(marker), "召唤机器人缺少: " + marker)
	for marker in ["class_name SummonController", "func on_room_entered", "func toggle_summon", "func deploy_for_qa", "SUMMON HUD"]:
		_expect(controller.contains(marker), "召唤控制器缺少: " + marker)
	_expect(controller.contains("summon_loadout") and controller.contains("summon_slot_level"), "控制器未使用持久阵容")
	_expect(main.contains("SUMMON_CONTROLLER_SCRIPT") and main.contains("summon_controller.on_room_entered"), "主场景未接入召唤控制器")
	_expect(main.contains("SHOT_SUMMON"), "Godot Capture 缺少召唤验收入口")
	_expect(enemy.contains('is_in_group("summon_ally")'), "敌人接触伤害未覆盖召唤物")
	_expect(projectile.contains('is_in_group("summon_ally")'), "敌人弹幕未覆盖召唤物")

	for marker in ["REGION_NAMES", "REGION_OFFSETS", "THEME_COLORS", "selected_room_id", "debug_reveal_all", "_draw_room_details", "_atlas_position"]:
		_expect(map_panel.contains(marker), "商业化地图缺少: " + marker)
	for name in ["机械中枢", "废铁矿坑", "蒸汽铸造厂", "腐化水道", "遗迹神殿", "虚空要塞", "暗影王城"]:
		_expect(map_panel.contains(name), "地图缺少完整区域名: " + name)
	_expect(main.contains("SHOT_MAP_FULL"), "Godot Capture 缺少全图集验收入口")
	for name in ["机械中枢·中央车站", "废铁矿坑·矿车总站", "腐化水道·地下入口", "蒸汽铸造厂·泰坦炉心"]:
		_expect(rooms.contains(name), "房间缺少完整地名: " + name)

	# 行为契约：旧存档必须补齐稳定实例 ID，且不得丢失原有物品。
	var migrated: Dictionary = ProgressionMigration.migrate({
		"save_version": 13,
		"inventory": [{"item_id": "legacy_blade"}],
		"summon_slot_level": 9,
	})
	_expect(int(migrated.get("save_version", 0)) == 14, "旧存档未迁移到 v14")
	_expect((migrated.get("inventory", []) as Array).size() == 1, "迁移丢失旧背包")
	_expect((migrated.get("robot_roster", []) as Array).size() == 1, "迁移未补发初始机器人")
	_expect(str((migrated["robot_roster"] as Array)[0].get("robot_instance_id", "")) == RobotData.STARTER_INSTANCE_ID, "初始机器人实例 ID 不稳定")
	_expect(int(migrated.get("summon_slot_level", 0)) == 3, "召唤槽未限制在 1~3")
	_expect((migrated.get("summon_loadout", []) as Array) == [RobotData.STARTER_INSTANCE_ID], "迁移未配置初始出战位")

	if failures.is_empty():
		print("PASS stage 11.1a summon and commercial map contracts")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("FAIL stage 11.1a/map: %d contract(s)" % failures.size())
		quit(1)
