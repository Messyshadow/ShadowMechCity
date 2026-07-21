extends StaticBody2D
class_name DashGate
## 冲刺相位屏障：保留 bit6 碰撞规则，同时提供方向、按键和失败反馈。

const TUTORIAL_FLAG := "dash_gate_taught"

var gate_size := Vector2(44, 600)
var direction := 1
var player: CharacterBody2D
var prompt: Label
var core: ColorRect
var reject_cd := 0.0
var was_near := false
var start_side := 0
var saw_dash := false
var arrow_phase := 0.0

func setup(size: Vector2, travel_direction: int, target: CharacterBody2D) -> void:
	gate_size = size
	direction = 1 if travel_direction >= 0 else -1
	player = target
	collision_layer = 0b100000
	collision_mask = 0
	_build_gate()

func direction_arrow() -> String:
	return "→" if direction > 0 else "←"

func _build_gate() -> void:
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = gate_size
	collision.shape = shape
	add_child(collision)

	core = ColorRect.new()
	core.mouse_filter = Control.MOUSE_FILTER_IGNORE
	core.color = Color(0.18, 0.78, 1.0, 0.30)
	core.size = gate_size
	core.position = -gate_size * 0.5
	core.z_index = -1
	add_child(core)

	for side in [-1.0, 1.0]:
		var edge := Line2D.new()
		edge.width = 4.0
		edge.default_color = Color(0.58, 0.96, 1.0, 0.95)
		edge.points = PackedVector2Array([
			Vector2(side * gate_size.x * 0.5, -gate_size.y * 0.5),
			Vector2(side * gate_size.x * 0.5, gate_size.y * 0.5),
		])
		add_child(edge)

	prompt = Label.new()
	prompt.text = "%s  [Shift] 冲刺穿越相位屏障" % direction_arrow()
	prompt.position = Vector2(-178, -minf(gate_size.y * 0.5, 255.0))
	prompt.custom_minimum_size = Vector2(356, 48)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 22)
	prompt.add_theme_color_override("font_color", Color(0.78, 0.98, 1.0))
	prompt.add_theme_color_override("font_outline_color", Color(0.01, 0.03, 0.06))
	prompt.add_theme_constant_override("outline_size", 8)
	prompt.visible = false
	add_child(prompt)

	var pulse := create_tween().set_loops()
	pulse.tween_property(core, "color:a", 0.15, 0.55)
	pulse.tween_property(core, "color:a", 0.38, 0.55)
	queue_redraw()

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	reject_cd = maxf(0.0, reject_cd - delta)
	arrow_phase = fmod(arrow_phase + delta * 1.8, 1.0)
	queue_redraw()

	var offset := player.global_position - global_position
	var vertical_ok := absf(offset.y) <= gate_size.y * 0.5 + 30.0
	var distance_x := absf(offset.x)
	var near := vertical_ok and distance_x <= 260.0
	if near:
		direction = 1 if offset.x < 0.0 else -1
		var taught := bool(Game.story_flags.get(TUTORIAL_FLAG, false))
		prompt.text = ("%s  [Shift] 冲刺穿越相位屏障" if not taught else "%s  [Shift] 冲刺") % direction_arrow()
		prompt.visible = not taught or distance_x <= 150.0
		if not was_near:
			start_side = 1 if offset.x > 0.0 else -1
			saw_dash = false
		was_near = true
		if (player.collision_mask & 0b100000) == 0:
			saw_dash = true
		var current_side := 1 if offset.x > 0.0 else -1
		if saw_dash and current_side != start_side and distance_x > gate_size.x * 0.5:
			Game.set_story_flag(TUTORIAL_FLAG)
			prompt.text = "%s  相位穿越成功" % direction_arrow()
		if distance_x <= gate_size.x * 0.5 + 34.0 and (player.collision_mask & 0b100000) != 0 and absf(player.velocity.x) > 15.0:
			_reject_player()
	else:
		prompt.visible = false
		was_near = false
		saw_dash = false

func _reject_player() -> void:
	if reject_cd > 0.0:
		return
	reject_cd = 1.0
	Fx.popup(get_parent(), player.global_position + Vector2(0, -90), "普通移动无法穿越 · 按 Shift 冲刺", Color(1.0, 0.42, 0.32))
	var flash := create_tween()
	flash.tween_property(core, "color", Color(1.0, 0.18, 0.12, 0.52), 0.08)
	flash.tween_property(core, "color", Color(0.18, 0.78, 1.0, 0.30), 0.22)
	Game.shake(3.0)

func _draw() -> void:
	var center_y := clampf(player.global_position.y - global_position.y if is_instance_valid(player) else 0.0,
		-gate_size.y * 0.5 + 70.0, gate_size.y * 0.5 - 70.0)
	for index in range(3):
		var travel := fmod(arrow_phase + float(index) / 3.0, 1.0)
		var x := lerpf(-14.0, 14.0, travel) * float(direction)
		var alpha := 0.35 + 0.6 * sin(travel * PI)
		var tip := Vector2(x + 10.0 * direction, center_y + (index - 1) * 30.0)
		draw_polyline(PackedVector2Array([
			tip + Vector2(-12.0 * direction, -10.0),
			tip,
			tip + Vector2(-12.0 * direction, 10.0),
		]), Color(0.72, 0.98, 1.0, alpha), 4.0, true)
