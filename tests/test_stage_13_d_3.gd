extends SceneTree

var failures: Array[String] = []

const NODE_IDS := [
	"sword_resonance", "hammer_demolition", "cannon_steam_jet",
	"dual_grapple", "spear_drill", "crossbow_remote",
]
const TAGS := [
	"sword_wave", "hammer_charge", "cannon_steam",
	"dual_grapple", "spear_drill", "crossbow_remote",
]
const TARGETS := [
	"relay", "brittle_wall", "steam_anchor",
	"grapple_anchor", "drill_wall", "remote_switch",
]

func _init() -> void:
	var component_path := "res://scripts/skill_interactable.gd"
	_expect(FileAccess.file_exists(component_path), "unified skill interactable component exists")
	var component_src := FileAccess.get_file_as_string(component_path) if FileAccess.file_exists(component_path) else ""
	for marker in ["func setup", "func supports", "func try_skill_interaction", "func interaction_distance_from", "allowed_tags", "interaction_cooldown"]:
		_expect(component_src.contains(marker), "component exposes %s" % marker)
	for target in TARGETS:
		_expect(component_src.contains('"%s"' % target), "component supports target %s" % target)

	var data_src := FileAccess.get_file_as_string("res://scripts/skills_data.gd")
	for node_id in NODE_IDS:
		_expect(data_src.contains('"id": "%s"' % node_id), "skill data contains %s" % node_id)
	for field in ["interaction_tags", "resource_rule", "preview_stages", "environment_use"]:
		_expect(data_src.count('"%s"' % field) >= 6, "six functional nodes expose %s" % field)
	for stage in ["startup", "travel", "impact", "interaction", "recovery"]:
		_expect(data_src.count('"%s"' % stage) >= 6, "all functional previews include %s" % stage)

	var player_src := FileAccess.get_file_as_string("res://scripts/player.gd")
	_expect(player_src.contains("func _try_skill_interaction"), "player uses a shared interaction helper")
	_expect(player_src.contains("interaction_distance_from"), "player measures distance to the target surface")
	for tag in TAGS:
		_expect(player_src.contains('"%s"' % tag), "player emits %s" % tag)

	var rooms_src := FileAccess.get_file_as_string("res://scripts/rooms.gd")
	_expect(rooms_src.count('"skill_targets"') >= 3, "optional rooms contain representative skill targets")
	for target in TARGETS:
		_expect(rooms_src.contains('"%s"' % target), "room data places %s" % target)

	var preview_src := FileAccess.get_file_as_string("res://scripts/skill_preview.gd")
	for marker in ["training_dummy", "environment_target", "stage_caption", "preview_stages"]:
		_expect(preview_src.contains(marker), "five-stage preview exposes %s" % marker)

	var main_src := FileAccess.get_file_as_string("res://scripts/main.gd")
	for marker in ["skill_targets", "SKILL_INTERACTABLE_SCRIPT", "SHOT_13D3", "func _prepare_13d3_capture"]:
		_expect(main_src.contains(marker), "main integrates %s" % marker)

	if failures.is_empty():
		print("STAGE_13_D_3_PASS")
		quit(0)
	else:
		for failure in failures:
			push_error("STAGE_13_D_3: " + failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
