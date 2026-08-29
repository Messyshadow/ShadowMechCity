extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _source(path: String) -> String:
	return FileAccess.get_file_as_string(path)


func _run() -> void:
	var fx_source := _source("res://scripts/summon_fx.gd")
	var robot_source := _source("res://scripts/summon_robot.gd")
	var controller_source := _source("res://scripts/summon_controller.gd")
	var main_source := _source("res://scripts/main.gd")

	for marker in ["MAX_ACTIVE_FX", "projection", "recall", "disabled_burst", "skill_warning", "active_fx_count"]:
		_expect(fx_source.contains(marker), "召唤特效层缺少: " + marker)
	for marker in ["_begin_attack", "_commit_attack", "_windup_remaining", "force_warning_for_qa", "SummonFx.skill_warning"]:
		_expect(robot_source.contains(marker), "伙伴预警协议缺少: " + marker)
	for marker in ["show_fx_for_qa", "performance_snapshot", "peak_fx_count", "SummonFx.projection"]:
		_expect(controller_source.contains(marker), "控制器视觉/性能协议缺少: " + marker)
	for marker in ["SHOT_SUMMON_FX", "SHOT_SUMMON_BOSS", "SHOT_SUMMON_STRESS"]:
		_expect(main_source.contains(marker), "Godot Capture 缺少: " + marker)

	if FileAccess.file_exists("res://scripts/summon_fx.gd"):
		var fx = load("res://scripts/summon_fx.gd")
		_expect(int(fx.MAX_ACTIVE_FX) <= 18, "召唤特效同屏预算不得超过 18")
		_expect(float(fx.warning_duration("striker")) >= 0.18, "近战预警时间过短")
		_expect(float(fx.warning_duration("artillery")) > float(fx.warning_duration("striker")), "远程炮击应比近战更早预警")
		_expect(fx.warning_shape("striker") != fx.warning_shape("artillery"), "近战与炮击预警轮廓不得相同")
		_expect(fx.warning_shape("vanguard") != fx.warning_shape("support"), "盾卫与支援预警轮廓不得相同")

	_expect(ProgressionMigration.CURRENT_VERSION >= 16, "后续阶段不得降低 11.1d 的 v16 存档基线")

	if failures.is_empty():
		print("PASS stage 11.1d summon visual and pressure contracts")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("FAIL stage 11.1d: %d contract(s)" % failures.size())
		quit(1)
