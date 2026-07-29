extends Camera2D
## 平滑跟随 + 速度前瞻 + trauma 屏幕震动

var target: Node2D
var look_ahead := 0.34       # 速度前瞻系数
var smooth := 7.0
var y_offset := -36.0
var dialogue_focus := Vector2.ZERO

var trauma := 0.0
var trauma_decay := 1.4
var max_offset := Vector2(26, 18)
var max_roll := 0.05
var _normal_smooth := 7.0
var _normal_y_offset := -36.0
var _normal_limit_top := -10000000
var _normal_limit_bottom := 10000000
const SHAKE_MERGE_WINDOW := 0.09
var _merge_timer := 0.0

func _ready() -> void:
	add_to_group("camera")
	make_current()

func add_trauma(amount: float) -> void:
	var incoming := clampf(amount / 15.0, 0.0, 1.0)
	if _merge_timer > 0.0:
		trauma = maxf(trauma, incoming)
	else:
		trauma = clampf(trauma + incoming, 0.0, 1.0)
	_merge_timer = SHAKE_MERGE_WINDOW

func begin_shaft(target_y: float, direction: String = "down") -> void:
	_normal_smooth = smooth
	_normal_y_offset = y_offset
	_normal_limit_top = limit_top
	_normal_limit_bottom = limit_bottom
	smooth = 3.2
	y_offset = -72.0 if direction == "up" else 72.0
	# 两种方向的过场井都位于入口地面下方；上行从井底起步，也必须临时放宽下边界。
	limit_bottom = int(target_y + 110.0)

func end_shaft() -> void:
	smooth = _normal_smooth
	y_offset = _normal_y_offset
	limit_top = _normal_limit_top
	limit_bottom = _normal_limit_bottom

func _process(delta: float) -> void:
	_merge_timer = maxf(0.0, _merge_timer - delta)
	if target and is_instance_valid(target):
		var vx: float = clampf(target.velocity.x, -320.0, 320.0)
		var desired := target.global_position + Vector2(vx * look_ahead, y_offset) + dialogue_focus
		global_position = global_position.lerp(desired, 1.0 - exp(-smooth * delta))

	var amt := trauma * trauma
	trauma = maxf(0.0, trauma - trauma_decay * delta)
	offset = Vector2(
		max_offset.x * amt * (randf() * 2.0 - 1.0),
		max_offset.y * amt * (randf() * 2.0 - 1.0))
	rotation = max_roll * amt * (randf() * 2.0 - 1.0)
