extends SceneTree

const PROFILE := preload("res://scripts/skill_fx_profile.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run() -> void:
	var weapon_ids: Array[String] = [
		"sword", "hammer", "cannon", "dual_blades", "spear", "crossbow"
	]
	var shapes: Dictionary = {}
	for weapon_id in weapon_ids:
		var profile: Dictionary = PROFILE.profile(weapon_id, "burst")
		_expect(not profile.is_empty(), "%s 缺少技能特效配置" % weapon_id)
		for key in ["primary", "secondary", "shape", "particle_budget", "flash_alpha",
				"duration", "z_residue", "z_body", "z_telegraph", "z_impact"]:
			_expect(profile.has(key), "%s 配置缺少 %s" % [weapon_id, key])
		if profile.is_empty():
			continue
		shapes[profile.get("shape", "")] = true
		_expect(int(profile.get("particle_budget", 999)) <= 52,
			"%s 粒子预算超过 52" % weapon_id)
		_expect(float(profile.get("flash_alpha", 1.0)) <= 0.26,
			"%s 全屏闪光超过 0.26" % weapon_id)
		_expect(int(profile.get("z_residue", 0)) < int(profile.get("z_body", 0)),
			"%s 残留层应低于攻击主体" % weapon_id)
		_expect(int(profile.get("z_body", 0)) < int(profile.get("z_telegraph", 0)),
			"%s 预警层应高于攻击主体" % weapon_id)
		_expect(int(profile.get("z_telegraph", 0)) < int(profile.get("z_impact", 0)),
			"%s 命中层应高于预警层" % weapon_id)
	_expect(shapes.size() == weapon_ids.size(), "六武器必须使用六种不同主体形状")

	var normal: Dictionary = PROFILE.profile("sword", "ground")
	var burst: Dictionary = PROFILE.profile("sword", "burst")
	var ultimate: Dictionary = PROFILE.profile("sword", "ultimate")
	_expect(float(normal.get("scale", 99.0)) < float(burst.get("scale", 0.0)),
		"爆发技强度必须高于普通技能")
	_expect(float(burst.get("scale", 99.0)) < float(ultimate.get("scale", 0.0)),
		"终结技强度必须高于爆发技")

	var fx_source := FileAccess.get_file_as_string("res://scripts/fx.gd")
	for method_name in ["skill_telegraph", "skill_body", "skill_residue", "layered_skill"]:
		_expect(fx_source.contains("static func %s" % method_name),
			"Fx 缺少统一入口 %s" % method_name)
	var player_source := FileAccess.get_file_as_string("res://scripts/player.gd")
	_expect(player_source.contains("func _play_layered_skill_fx"),
		"玩家尚未接入统一技能特效入口")
	for cue in ["ground", "upper", "dash_atk", "burst", "ultimate"]:
		_expect(player_source.contains("\"%s\"" % cue), "玩家缺少 %s 特效线索" % cue)
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	_expect(main_source.contains("SHOT_13_4"), "主场景缺少 13.4 确定性抓图入口")

	if failures.is_empty():
		print("PASS stage 13.4 skill FX unification contracts")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("FAIL stage 13.4: %d contract(s)" % failures.size())
		quit(1)
