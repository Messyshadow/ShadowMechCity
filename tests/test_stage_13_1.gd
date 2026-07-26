extends SceneTree

const PROFILE := preload("res://scripts/player_visual_profile.gd")

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
	for weapon_id in weapon_ids:
		var pose: Dictionary = PROFILE.pose(weapon_id)
		_expect(not pose.is_empty(), "%s 缺少主角视觉姿态" % weapon_id)
		for key in [
			"hand", "sprite_offset", "visual_scale", "rest_rot",
			"swing_from", "swing_to", "upper_from", "upper_to",
			"offhand", "recoil", "visible_during_attack",
		]:
			_expect(pose.has(key), "%s 姿态缺少 %s" % [weapon_id, key])
	_expect(bool(PROFILE.pose("dual_blades").get("offhand", false)),
		"双刀必须显示实体副手武器")
	_expect(bool(PROFILE.pose("cannon").get("visible_during_attack", false)),
		"蒸汽炮开火时必须保持可见")
	_expect(bool(PROFILE.pose("crossbow").get("visible_during_attack", false)),
		"弓弩开火时必须保持可见")

	var player_source := FileAccess.get_file_as_string("res://scripts/player.gd")
	for symbol in [
		"visual_root", "ground_shadow", "core_glow",
		"offhand_pivot", "offhand_weapon_sprite",
	]:
		_expect(player_source.contains(symbol), "玩家视觉骨架缺少 %s" % symbol)
	_expect(player_source.contains("visual_root.scale ="),
		"挤压拉伸尚未作用于统一视觉根")
	_expect(not player_source.contains("anim.scale = sprite_scale_base * mult"),
		"挤压拉伸仍只作用于角色精灵")
	_expect(player_source.contains("visible_during_attack"),
		"玩家未应用远程武器持续可见配置")

	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	_expect(main_source.contains("SHOT_13_1"), "主场景缺少 13.1 确定性抓图入口")
	_expect(main_source.contains("_prepare_13_1_capture"),
		"主场景缺少 13.1 抓图准备函数")

	if failures.is_empty():
		print("PASS stage 13.1 player visual unification contracts")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("FAIL stage 13.1: %d contract(s)" % failures.size())
		quit(1)
