extends Camera2D
## 平滑跟随 + 速度前瞻 + trauma 屏幕震动

var target: Node2D
var look_ahead := 0.34       # 速度前瞻系数
var smooth := 7.0
var y_offset := -36.0

var trauma := 0.0
var trauma_decay := 1.4
var max_offset := Vector2(26, 18)
var max_roll := 0.05

func _ready() -> void:
	add_to_group("camera")
	make_current()

func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount / 12.0, 0.0, 1.0)

func _process(delta: float) -> void:
	if target and is_instance_valid(target):
		var vx: float = clampf(target.velocity.x, -320.0, 320.0)
		var desired := target.global_position + Vector2(vx * look_ahead, y_offset)
		global_position = global_position.lerp(desired, 1.0 - exp(-smooth * delta))

	var amt := trauma * trauma
	trauma = maxf(0.0, trauma - trauma_decay * delta)
	offset = Vector2(
		max_offset.x * amt * (randf() * 2.0 - 1.0),
		max_offset.y * amt * (randf() * 2.0 - 1.0))
	rotation = max_roll * amt * (randf() * 2.0 - 1.0)
