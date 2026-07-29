extends SceneTree

const SKILLS := preload("res://scripts/skills_data.gd")
const GRAPH := preload("res://scripts/skill_graph.gd")

const EXPECTED := [
	"sword_thunder_spin", "sword_shadow_dragon",
	"hammer_core_burst", "hammer_rail_drive",
	"cannon_overpressure_rise", "cannon_star_pressure",
	"dual_mirror_storm", "dual_rift_prison",
	"spear_skywheel_rise", "spear_dragon_drill",
	"crossbow_rift_rain", "crossbow_hunter_terminal",
]

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run() -> void:
	var by_id := {}
	var positions_by_family := {}
	for node in SKILLS.TREE:
		by_id[str(node.get("id", ""))] = node
		var family := str(node.get("family", ""))
		if family != "":
			positions_by_family.get_or_add(family, {})
			var key := str(Vector2(node.get("pos", Vector2.ZERO)))
			_expect(not positions_by_family[family].has(key),
				"%s 家族存在完全重叠坐标 %s" % [family, key])
			positions_by_family[family][key] = true

	for id in EXPECTED:
		_expect(by_id.has(id), "缺少技能节点 %s" % id)
		if not by_id.has(id):
			continue
		var node: Dictionary = by_id[id]
		for key in ["input", "usage", "preview_pattern", "preview_intensity", "weapon_required"]:
			_expect(str(node.get(key, "")).strip_edges() != "", "%s 缺少 %s" % [id, key])

	var validation: Dictionary = GRAPH.validate(SKILLS.TREE)
	_expect(validation.get("errors", []).is_empty(),
		"技能图谱校验失败: %s" % str(validation.get("errors", [])))
	for family in SKILLS.FAMILIES:
		_expect(SKILLS.nodes_for("战斗", family).size() >= 6,
			"%s 家族技能少于 6 个" % family)

	var preview_source := FileAccess.get_file_as_string("res://scripts/skill_preview.gd")
	_expect(preview_source.contains("PREVIEW_SIZE := Vector2i(410, 190)"),
		"技能预览尚未扩大到 410x190")
	_expect(preview_source.contains("SkillPreviewEffect"),
		"技能预览尚未接入 SkillPreviewEffect")
	for caption in ["① 起手预警", "② 技能释放", "③ 命中反馈", "④ 残留效果", "⑤ 收招复位"]:
		_expect(preview_source.contains(caption), "技能预览缺少阶段标题 %s" % caption)
	for forbidden in ["Area2D.new()", "Game.spend", "save_game"]:
		_expect(not preview_source.contains(forbidden), "技能预览不得包含 %s" % forbidden)

	_expect(FileAccess.file_exists("res://scripts/skill_preview_effect.gd"),
		"缺少纯视觉 SkillPreviewEffect")
	if FileAccess.file_exists("res://scripts/skill_preview_effect.gd"):
		var effect_source := FileAccess.get_file_as_string("res://scripts/skill_preview_effect.gd")
		for pattern in ["slash_spin", "ground_smash", "pressure_jet", "pressure_beam",
				"cross_slash", "shadow_dash", "spear_rise", "spear_drill",
				"arrow_rain", "reticle_burst"]:
			_expect(effect_source.contains("\"%s\"" % pattern),
				"预览效果缺少 pattern %s" % pattern)
		_expect(not effect_source.contains("Area2D.new()"),
			"预览效果不得创建伤害碰撞")

	if failures.is_empty():
		print("PASS stage 13.4.1 skill showcase contracts")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("FAIL stage 13.4.1: %d contract(s)" % failures.size())
		quit(1)
