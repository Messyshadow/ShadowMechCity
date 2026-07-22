extends Area2D
class_name BossRetreatConsole
## 测试版 Boss 战紧急撤离装置。长按避免误触，暂停菜单提供同一出口。

var player: CharacterBody2D
var main_ref: Node
var hold_time := 1.0
var held := 0.0
var progress: Label
var prompt: Label
var triggered := false

func setup(target: CharacterBody2D, owner_main: Node) -> void:
	player = target
	main_ref = owner_main
	_build_visual()

func _build_visual() -> void:
	z_index = 5
	var pedestal := Polygon2D.new()
	pedestal.polygon = PackedVector2Array([
		Vector2(-28, 18), Vector2(-22, -22), Vector2(-12, -36),
		Vector2(12, -36), Vector2(22, -22), Vector2(28, 18),
	])
	pedestal.color = Color(0.08, 0.16, 0.19, 0.96)
	add_child(pedestal)
	var rim := Line2D.new()
	rim.width = 4.0
	rim.default_color = Color(0.42, 0.96, 0.88)
	rim.closed = true
	rim.points = pedestal.polygon
	add_child(rim)
	var beacon := PointLight2D.new()
	beacon.energy = 0.65
	beacon.color = Color(0.25, 1.0, 0.82)
	beacon.texture_scale = 1.3
	add_child(beacon)

	prompt = Label.new()
	prompt.text = "紧急撤离装置\n长按 B 撤离 Boss 战"
	prompt.position = Vector2(-170, -132)
	prompt.custom_minimum_size = Vector2(340, 76)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 22)
	prompt.add_theme_color_override("font_color", Color(0.66, 1.0, 0.9))
	prompt.add_theme_color_override("font_outline_color", Color(0.01, 0.03, 0.04))
	prompt.add_theme_constant_override("outline_size", 5)
	var prompt_plate := StyleBoxFlat.new()
	prompt_plate.bg_color = Color(0.015, 0.07, 0.07, 0.94)
	prompt_plate.border_color = Color(0.35, 1.0, 0.82, 0.95)
	prompt_plate.set_border_width_all(2)
	prompt_plate.set_corner_radius_all(10)
	prompt_plate.content_margin_left = 14.0
	prompt_plate.content_margin_right = 14.0
	prompt_plate.content_margin_top = 8.0
	prompt_plate.content_margin_bottom = 8.0
	prompt.add_theme_stylebox_override("normal", prompt_plate)
	prompt.visible = false
	add_child(prompt)

	progress = Label.new()
	progress.text = "○○○○○○○○○○"
	progress.position = Vector2(-100, -50)
	progress.custom_minimum_size = Vector2(200, 30)
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress.add_theme_font_size_override("font_size", 18)
	progress.add_theme_color_override("font_color", Color(0.45, 1.0, 0.82))
	progress.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	progress.add_theme_constant_override("outline_size", 5)
	progress.visible = false
	add_child(progress)

	var pulse := create_tween().set_loops()
	pulse.tween_property(rim, "modulate", Color(0.45, 1.0, 0.86, 0.55), 0.6)
	pulse.tween_property(rim, "modulate", Color.WHITE, 0.6)

func _process(delta: float) -> void:
	if triggered or not is_instance_valid(player) or not is_instance_valid(main_ref):
		return
	var close := player.global_position.distance_to(global_position) <= 155.0
	prompt.visible = close
	progress.visible = close
	if not close:
		held = 0.0
		_update_progress()
		return
	if Input.is_action_pressed("retreat"):
		held = minf(hold_time, held + delta)
		_update_progress()
		if held >= hold_time:
			triggered = true
			main_ref.retreat_from_boss()
	else:
		held = maxf(0.0, held - delta * 2.5)
		_update_progress()

func _update_progress() -> void:
	if not is_instance_valid(progress):
		return
	var filled := clampi(int(ceil(10.0 * held / hold_time)), 0, 10)
	progress.text = "●".repeat(filled) + "○".repeat(10 - filled)
