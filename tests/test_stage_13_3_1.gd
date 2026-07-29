extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run() -> void:
	var shaft := FileAccess.get_file_as_string("res://scripts/shaft_transition.gd")
	var main := FileAccess.get_file_as_string("res://scripts/main.gd")
	var camera := FileAccess.get_file_as_string("res://scripts/follow_camera.gd")

	for marker in [
		"const DOWN_DEPTH := 620.0",
		"const UP_DEPTH := 480.0",
		"const SHAFT_DEPTH := DOWN_DEPTH",
		"func setup(p_theme: String, p_player: CharacterBody2D, p_direction: String = \"down\")",
		"direction = \"up\" if p_direction == \"up\" else \"down\"",
		"func _make_finish_trigger",
		"func spawn_local_position",
	]:
		_expect(shaft.contains(marker), "双向竖井缺少 %s" % marker)
	_expect(shaft.count("_make_wall(") >= 3, "竖井必须生成左右两面连续墙")
	_expect(shaft.count("_make_ledge(") >= 4, "竖井必须生成三处交错踏板")
	_expect(shaft.contains("depth * 0.28") and shaft.contains("depth * 0.54")
		and shaft.contains("depth * 0.79"), "踏板未按方向深度分布")
	_expect(shaft.contains('call_deferred("_emit_finished")'),
		"竖井完成必须离开物理 flush 后发出")
	_expect(shaft.contains("signal cancelled"), "上行超时必须能取消而不是伪装成功")

	_expect(main.contains("func _play_shaft_transition(to_room: String, direction: String = \"down\")"),
		"主场景竖井入口缺少方向参数")
	_expect(main.contains('_play_shaft_transition.call_deferred(d["to"], "down")'),
		"下行入口未显式路由到 down")
	_expect(main.contains('_play_shaft_transition.call_deferred(d["to"], "up")'),
		"上行入口未显式路由到 up")
	_expect(main.contains('not d.get("hidden", false)'),
		"隐藏上行传送门必须保留原逻辑")
	_expect(main.contains("shaft.spawn_local_position()"),
		"玩家未使用竖井方向化出生点")
	_expect(main.contains("await shaft.cancelled"),
		"主场景未处理上行失败返回入口")
	_expect(main.contains("SHOT_SHAFT_DIRECTION"),
		"godot-capture 缺少双向竖井选择")

	_expect(camera.contains("func begin_shaft(target_y: float, direction: String = \"down\")"),
		"相机竖井模式缺少方向参数")
	_expect(camera.contains('y_offset = -72.0 if direction == "up" else 72.0'),
		"相机没有上行反向前瞻")

	if failures.is_empty():
		print("PASS stage 13.3.1 bidirectional shaft contracts")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("FAIL stage 13.3.1: %d contract(s)" % failures.size())
		quit(1)
