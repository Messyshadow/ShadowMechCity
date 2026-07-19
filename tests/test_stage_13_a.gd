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
