extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run() -> void:
	var backdrop := FileAccess.get_file_as_string("res://scripts/theme_backdrop.gd")
	var main := FileAccess.get_file_as_string("res://scripts/main.gd")

	for theme in ["city", "mine", "factory", "water", "temple", "void", "castle"]:
		_expect(backdrop.contains('"%s"' % theme), "缺少 %s 区域背景定义" % theme)
		_expect(backdrop.contains("func _draw_%s" % theme), "缺少 %s 程序化地标绘制" % theme)

	for marker in [
		"const THEME_PROFILES :=",
		"func atmosphere_profile() -> Dictionary",
		"landmark",
		"far_color",
		"mid_color",
		"accent",
	]:
		_expect(backdrop.contains(marker), "区域背景缺少统一配置：%s" % marker)

	_expect(not main.contains('if theme != "castle" and theme != "void": return'),
		"世界背景仍只为王城与虚空生成")
	_expect(main.contains("backdrop.atmosphere_profile()"),
		"房间空气层没有读取区域背景配置")
	_expect(main.contains("_apply_camera_atmosphere"),
		"相机粒子没有随区域切换")
	_expect(main.contains("SHOT_REGION_ATMOSPHERE"),
		"godot-capture 缺少七区域批量取景入口")
	_expect(main.contains('"water":"water_grotto"'),
		"水道截图必须进入真实存在的腐化水道房间")
	_expect(main.contains("SHOT_ROOM not found"),
		"无效截图房间必须明确报错，不能静默拍摄初始房")

	if failures.is_empty():
		print("PASS stage 13.3.2 regional atmosphere contracts")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("FAIL stage 13.3.2: %d contract(s)" % failures.size())
		quit(1)
