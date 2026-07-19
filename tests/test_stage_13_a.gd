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
