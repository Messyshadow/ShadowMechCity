extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	var feedback_path := "res://scripts/combat_feedback.gd"
	_expect(FileAccess.file_exists(feedback_path), "combat feedback helper exists")
	if FileAccess.file_exists(feedback_path):
		_test_feedback_profiles(feedback_path)
	var fx_src := FileAccess.get_file_as_string("res://scripts/fx.gd")
	var enemy_src := FileAccess.get_file_as_string("res://scripts/enemy.gd")
	var boss_src := FileAccess.get_file_as_string("res://scripts/boss.gd")
	var player_src := FileAccess.get_file_as_string("res://scripts/player.gd")
	var camera_src := FileAccess.get_file_as_string("res://scripts/follow_camera.gd")
	var main_src := FileAccess.get_file_as_string("res://scripts/main.gd")
	var feedback_src := FileAccess.get_file_as_string(feedback_path) if FileAccess.file_exists(feedback_path) else ""
	for marker in ["func combat_impact", "residue", "ring_width", "particle_amount"]:
		_expect(fx_src.contains(marker), "layered impact FX exposes %s" % marker)
	for marker in ["CombatFeedback.material_for_enemy", "CombatFeedback.profile", "Fx.combat_impact"]:
		_expect(enemy_src.contains(marker), "enemy consumes feedback marker %s" % marker)
	_expect(enemy_src.contains("CombatFeedback.play_material_sfx"), "enemy plays material-specific impact audio")
	for marker in ["CombatFeedback.BOSS_RESPONSE_SCALE", "CombatFeedback.profile", "Fx.combat_impact"]:
		_expect(boss_src.contains(marker), "boss bounded response marker %s" % marker)
	_expect(boss_src.contains("CombatFeedback.play_material_sfx"), "boss plays material-specific impact audio")
	for marker in ["CombatFeedback.profile", "CombatFeedback.material_palette", "Fx.combat_impact"]:
		_expect(player_src.contains(marker), "player damage feedback marker %s" % marker)
	_expect(player_src.contains("CombatFeedback.play_material_sfx"), "player hurt uses flesh impact audio")
	_expect(feedback_src.contains("func play_material_sfx"), "feedback helper routes material audio")
	_expect(main_src.contains("pitch_scale"), "main audio player supports pitch variation")
	for marker in ["SHAKE_MERGE_WINDOW", "_merge_timer", "maxf(trauma"]:
		_expect(camera_src.contains(marker), "camera shake merging marker %s" % marker)
	for marker in ["SHOT_13D2", "func _prepare_13d2_capture", '"material_hits"']:
		_expect(main_src.contains(marker), "deterministic 13D.2 capture marker %s" % marker)
	if failures.is_empty():
		print("STAGE_13_D_2_PASS")
		quit(0)
	else:
		for failure in failures:
			push_error("STAGE_13_D_2: " + failure)
		quit(1)

func _test_feedback_profiles(path: String) -> void:
	var feedback = load(path)
	for tier in ["light", "heavy", "armor_break", "finisher"]:
		var profile: Dictionary = feedback.profile(tier)
		_expect(float(profile.get("hitstop", 0.0)) > 0.0, "%s has hitstop" % tier)
		_expect(float(profile.get("shake", 0.0)) <= 18.0, "%s shake is bounded" % tier)
		_expect(float(profile.get("knockback", 0.0)) <= 1.5, "%s knockback is bounded" % tier)
	for material in ["flesh", "metal", "stone", "shield", "void"]:
		var palette: Dictionary = feedback.material_palette(material)
		_expect(palette.has("core") and palette.has("spark") and palette.has("residue") and palette.has("pitch"), "%s material palette is complete" % material)
	_expect(float(feedback.BOSS_RESPONSE_SCALE) > 0.0 and float(feedback.BOSS_RESPONSE_SCALE) < 1.0, "boss response uses a reduced scale")
	_expect(feedback.material_for_enemy("soul_shield", "walker") == "shield", "shield enemy resolves shield material")
	_expect(feedback.material_for_enemy("void_wyvern", "diver") == "void", "void enemy resolves void material")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
