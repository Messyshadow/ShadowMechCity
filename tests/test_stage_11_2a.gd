extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run() -> void:
	var migration_source := FileAccess.get_file_as_string("res://scripts/progression_migration.gd")
	var game_source := FileAccess.get_file_as_string("res://scripts/game.gd")
	var inventory_source := FileAccess.get_file_as_string("res://scripts/inventory_panel.gd")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	_expect(FileAccess.file_exists("res://scripts/equipment_patch_data.gd"), "缺少装备量子补丁数据层")
	_expect(migration_source.contains("CURRENT_VERSION := 17"), "11.2a 存档版本必须升级到 v17")
	_expect(migration_source.contains("migrate_equipment"), "迁移器未接入装备稳定 ID 与补丁字段")
	_expect(not game_source.contains("gear_coins") and not game_source.contains("patch_currency"), "不得创建平行装备货币")
	_expect(inventory_source.contains("补丁报价预览") and inventory_source.contains("EquipmentPatchData.attribute_preview"), "背包详情缺少只读补丁报价预览")
	_expect(main_source.contains("SHOT_EQUIPMENT_PATCH") and main_source.contains("migrate_equipment"), "缺少 11.2a 确定性截图入口")

	if FileAccess.file_exists("res://scripts/equipment_patch_data.gd"):
		var patches = load("res://scripts/equipment_patch_data.gd")
		_expect(patches.BRANDS.size() >= 5, "首批品牌少于五家")
		var common := {"slot":"helmet", "rarity":0, "lv":2, "hp":2.0}
		var legendary := {"slot":"helmet", "rarity":3, "lv":2, "hp":2.0}
		_expect(patches.upgrade_quote(legendary)["cost"] > patches.upgrade_quote(common)["cost"], "高品质装备报价应更高")
		var advanced := common.duplicate(true)
		advanced["patch_level"] = 4
		_expect(patches.upgrade_quote(advanced)["cost"] > patches.upgrade_quote(common)["cost"], "更高补丁阶段报价应更高")
		var preview: Dictionary = patches.attribute_preview(common)
		_expect(float(preview["after"]["hp"]) > float(preview["before"]["hp"]), "属性预览没有显示升级收益")
		_expect(not common.has("patch_level"), "纯预览函数不得修改输入装备")

	var old := {
		"save_version":16, "coins":321, "skills":{"atk":2},
		"inventory":[
			{"slot":"helmet", "name":"旧式面甲", "rarity":1, "lv":3, "hp":2.0},
			{"kind":"material", "name":"齿轮碎片", "count":4},
		],
		"equipped":{"ring":{"slot":"ring", "name":"回声戒指", "rarity":2, "lv":1, "atk":2.0}},
	}
	var once: Dictionary = ProgressionMigration.migrate(old)
	var twice: Dictionary = ProgressionMigration.migrate(once)
	_expect(once == twice, "v17 装备迁移必须幂等")
	_expect(int(once.get("save_version", 0)) == 17, "旧存档未迁移到 v17")
	_expect(int(once.get("coins", 0)) == 321 and once.get("skills", {}) == old["skills"], "迁移破坏金币或技能")
	var helmet: Dictionary = once["inventory"][0]
	var ring: Dictionary = once["equipped"]["ring"]
	for field in ["item_instance_id", "brand_id", "quality", "patch_level", "patches", "cosmetic_id"]:
		_expect(helmet.has(field) and ring.has(field), "迁移装备缺少字段: " + field)
	_expect(int(helmet.get("patch_level", -1)) == 3 and int(helmet.get("lv", -1)) == 3, "旧 lv 没有完整保留为补丁阶段")
	_expect(str(helmet.get("item_instance_id", "")) != str(ring.get("item_instance_id", "")), "不同装备不得共享稳定 ID")
	_expect(not once["inventory"][1].has("item_instance_id"), "材料不应被错误迁移为装备")

	if failures.is_empty():
		print("PASS stage 11.2a equipment migration and quote contracts")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("FAIL stage 11.2a: %d contract(s)" % failures.size())
		quit(1)
