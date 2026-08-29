extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run() -> void:
	var game_source := FileAccess.get_file_as_string("res://scripts/game.gd")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	_expect(FileAccess.file_exists("res://scripts/equipment_upgrade_panel.gd"), "缺少量子升级台分类界面")
	_expect(FileAccess.file_exists("res://scripts/equipment_upgrade_terminal.gd"), "缺少枢纽实体升级终端")
	_expect(FileAccess.file_exists("res://scripts/quantum_upgrade_visual.gd"), "缺少卫星量子投射演出")
	for marker in ["find_equipment_by_id", "apply_equipment_patch", "insufficient_coins", "save_game()"]:
		_expect(game_source.contains(marker), "Game 升级交易协议缺少: " + marker)
	for marker in ["SHOT_EQUIPMENT_TERMINAL", "SHOT_EQUIPMENT_TERMINAL_WORLD", "_spawn_equipment_upgrade_terminal"]:
		_expect(main_source.contains(marker), "11.2b capture/枢纽入口缺少: " + marker)

	if FileAccess.file_exists("res://scripts/equipment_upgrade_panel.gd"):
		var panel_source := FileAccess.get_file_as_string("res://scripts/equipment_upgrade_panel.gd")
		for marker in ["全部装备", "防具", "饰品", "请求卫星投射", "确认升级", "取消", "余额不足", "open_for_qa"]:
			_expect(panel_source.contains(marker), "量子升级台状态或分类缺少: " + marker)
		_expect(panel_source.contains("item_instance_id"), "升级台不得用背包数组下标作为身份")

	var game = load("res://scripts/game.gd").new()
	var item := EquipmentPatchData.ensure_item({
		"slot":"helmet", "name":"协议测试面甲", "rarity":0, "lv":0,
		"hp":2.0, "def":1.0,
	}, "test:11.2b")
	game.inventory = [item]
	game.equipped = {}
	game.coins = 500
	var item_id := str(item["item_instance_id"])
	var quote: Dictionary = EquipmentPatchData.upgrade_quote(item)
	var before_coins: int = game.coins
	var success: Dictionary = game.apply_equipment_patch(item_id)
	_expect(success.get("ok", false), "足额金币升级应成功")
	_expect(game.coins == before_coins - int(quote["cost"]), "成功升级扣款不正确")
	_expect(int(game.inventory[0].get("patch_level", 0)) == 1, "成功升级未增加补丁等级")
	_expect((game.inventory[0].get("patches", []) as Array).size() == 1, "成功升级未记录补丁历史")
	var level_after_success := int(game.inventory[0]["patch_level"])
	game.coins = 0
	var rejected: Dictionary = game.apply_equipment_patch(item_id)
	_expect(not rejected.get("ok", true) and rejected.get("reason", "") == "insufficient_coins", "余额不足必须明确拒绝")
	_expect(int(game.inventory[0]["patch_level"]) == level_after_success and game.coins == 0, "拒绝交易不得修改装备或金币")
	_expect(ProgressionMigration.CURRENT_VERSION == 17, "11.2b 不应重复升级存档版本")
	game.free()

	if failures.is_empty():
		print("PASS stage 11.2b quantum upgrade terminal contracts")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("FAIL stage 11.2b: %d contract(s)" % failures.size())
		quit(1)
