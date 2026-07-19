extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	var path := "res://scripts/stat_resolver.gd"
	_check(FileAccess.file_exists(path), "stat resolver must exist")
	if FileAccess.file_exists(path):
		var resolver = load(path)
		var snapshot: Dictionary = resolver.resolve(
			{"attack":10.0, "max_health":5.0, "move_speed":250.0},
			{"attack_flat":2.0, "attack_percent":0.10, "max_health":1.0},
			{"attack_flat":3.0, "move_speed_percent":0.08},
			{"attack_percent":0.20})
		_check(is_equal_approx(snapshot["attack"], 19.5), "flat attack must apply before total percent")
		_check(is_equal_approx(snapshot["max_health"], 6.0), "health modifiers must aggregate")
		_check(is_equal_approx(snapshot["move_speed"], 270.0), "speed percent must resolve from base")
		_check(resolver.resolve({}, {"unknown":3}, {}, {}).get("unknown", 0) == 0, "unknown stats must not leak")
	var data = load("res://scripts/skills_data.gd")
	var graph = load("res://scripts/skill_graph.gd") if FileAccess.file_exists("res://scripts/skill_graph.gd") else null
	_check(graph != null, "skill graph helper must exist")
	if graph:
		var report: Dictionary = graph.validate(data.TREE)
		_check(report.get("errors", []).is_empty(), "skill graph must be structurally valid: %s" % [report.get("errors", [])])
		_check(data.PAGES == ["基础", "身法", "战斗", "探索"], "four progression pages must stay ordered")
		var combat: Array = data.nodes_for("战斗", "刀剑")
		_check(combat.size() >= 5, "sword family needs a usable first tree")
		var root: Dictionary = combat[0]
		var right_id: String = graph.nearest_in_direction(root["id"], Vector2.RIGHT, combat)
		_check(right_id != "", "spatial navigation must find a right-hand node")
		for node in data.TREE:
			for field in ["id", "name", "page", "pos", "type", "usage", "desc", "max", "cost", "req"]:
				_check(node.has(field), "skill node missing field %s: %s" % [field, node.get("id", "?")])
	var migration = load("res://scripts/progression_migration.gd") if FileAccess.file_exists("res://scripts/progression_migration.gd") else null
	_check(migration != null, "progression migration must exist")
	if migration:
		var old := {
			"skills":{"hp":2,"spin":1},
			"inventory":[{"slot":"helmet","rarity":1,"lv":2}],
			"equipped":{},
			"abilities":{"wall_climb":true},
			"unlocked_weapons":["sword","hammer","cannon"],
		}
		var once: Dictionary = migration.migrate(old)
		var twice: Dictionary = migration.migrate(once)
		_check(once == twice, "save migration must be idempotent")
		_check(once["skills"] == old["skills"], "legacy skill levels must survive")
		_check(once["inventory"].size() == 1 and once["abilities"].has("wall_climb"), "inventory and abilities must survive")
	var game_source := FileAccess.get_file_as_string("res://scripts/game.gd")
	for marker in ["save_version", "ProgressionMigration.migrate", "attribute_snapshot", "StatResolver.resolve"]:
		_check(game_source.contains(marker), "Game integration missing: " + marker)
	for ui_path in ["res://scripts/skill_node_control.gd", "res://scripts/skill_preview.gd"]:
		_check(FileAccess.file_exists(ui_path), "skill UI helper missing: " + ui_path)
	var skill_panel_source := FileAccess.get_file_as_string("res://scripts/skill_panel.gd")
	for marker in ["SubViewportContainer", "SkillGraph.nearest_in_direction", "usage", "input", "基础", "身法", "战斗", "探索", "_select_family", "open_for_qa"]:
		_check(skill_panel_source.contains(marker), "skill panel surface missing: " + marker)
	var items_data = load("res://scripts/items_data.gd")
	var items_source := FileAccess.get_file_as_string("res://scripts/items_data.gd")
	_check(items_source.contains("const CATEGORIES"), "inventory categories must exist")
	if items_source.contains("const CATEGORIES"):
		_check(items_data.CATEGORIES == ["武器", "防具", "饰品", "消耗品", "材料", "任务"], "inventory categories must stay ordered")
	var gear_mods: Dictionary = items_data.equipment_modifiers({"ring":{"atk":2.0,"def":1.0,"hp":3.0,"crit":0.1,"ls":1.0,"spd":0.04,"lv":0}})
	_check(is_equal_approx(gear_mods.get("attack_flat", 0.0), 2.0), "legacy attack gear must map into unified stats")
	_check(is_equal_approx(gear_mods.get("armor", 0.0), 1.0), "legacy defense gear must map into unified stats")
	var compare_script = load("res://scripts/item_compare.gd") if FileAccess.file_exists("res://scripts/item_compare.gd") else null
	_check(compare_script != null, "item comparison helper must exist")
	if compare_script:
		var rows: Array = compare_script.compare({"atk":3.0}, {"atk":1.0})
		_check(rows[0]["delta"] == 2.0 and rows[0]["tone"] == "gain", "item comparison must return signed gains")
	_check(FileAccess.file_exists("res://scripts/character_equipment_preview.gd"), "character equipment preview must exist")
	var inventory_source := FileAccess.get_file_as_string("res://scripts/inventory_panel.gd")
	for marker in ["open_for_qa", "source_index", "_sort_filtered", "GridContainer", "CATEGORIES"]:
		_check(inventory_source.contains(marker), "inventory panel surface missing: " + marker)
	_finish()

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("PASS stage 13A progression contracts")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
