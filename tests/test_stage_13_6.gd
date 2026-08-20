extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run() -> void:
	var audio := FileAccess.get_file_as_string("res://scripts/region_audio_controller.gd")
	var main := FileAccess.get_file_as_string("res://scripts/main.gd")

	for marker in [
		"class_name RegionAudioController",
		"const REGION_PROFILES :=",
		"func transition_to",
		"func set_intensity",
		"func debug_snapshot",
		"AudioStreamGenerator",
		"AudioStreamGeneratorPlayback",
		"create_tween",
	]:
		_expect(audio.contains(marker), "区域音频控制器缺少 %s" % marker)

	for theme in ["city", "mine", "factory", "water", "temple", "void", "castle"]:
		_expect(audio.contains('"%s"' % theme), "缺少 %s 音频配置" % theme)

	for ambient in ["rail_hum", "mine_pulse", "steam_engine", "water_cistern", "rune_chime", "void_wind", "castle_organ"]:
		_expect(audio.contains(ambient), "缺少环境音身份 %s" % ambient)

	_expect(main.contains("REGION_AUDIO_SCRIPT"), "主场景未预加载区域音频控制器")
	_expect(main.contains("region_audio.transition_to"), "房间切换没有同步音乐")
	_expect(main.contains("SHOT_REGION_AUDIO"), "godot-capture 缺少音频状态验收入口")
	_expect(not main.contains('bgm.name = "BGM"'), "旧单曲直播放逻辑仍在运行")

	if failures.is_empty():
		print("PASS stage 13.6 regional audio contracts")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("FAIL stage 13.6: %d contract(s)" % failures.size())
		quit(1)
