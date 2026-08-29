class_name EquipmentUpgradeTerminal
extends Node2D
## 11.2b 中央车站量子装备升级终端：世界实体、近场提示与独立交互事件。

signal interaction_requested

var player_near := false
var _prompt: Label
var _phase := 0.0

func setup(_player: Node = null) -> void:
	name = "QuantumEquipmentTerminal"
	_build_interaction_area()
	_build_labels()
	queue_redraw()

func _process(delta: float) -> void:
	_phase += delta
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if player_near and event.is_action_pressed("interact"):
		interaction_requested.emit()
		get_viewport().set_input_as_handled()

func force_prompt_visible(value: bool) -> void:
	player_near = value
	if is_instance_valid(_prompt):
		_prompt.visible = value

func _build_interaction_area() -> void:
	var area := Area2D.new()
	area.name = "InteractionArea"
	area.collision_layer = 0
	area.collision_mask = 0b00010
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(190, 150)
	shape_node.shape = shape
	shape_node.position = Vector2(0, -68)
	area.add_child(shape_node)
	area.body_entered.connect(func(body: Node):
		if body.is_in_group("player"): force_prompt_visible(true))
	area.body_exited.connect(func(body: Node):
		if body.is_in_group("player"): force_prompt_visible(false))
	add_child(area)

func _build_labels() -> void:
	var placard := Label.new()
	placard.text = "轨道量子升级台"
	placard.position = Vector2(-105, -172)
	placard.size = Vector2(210, 28)
	placard.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placard.add_theme_font_size_override("font_size", 17)
	placard.add_theme_color_override("font_color", Color("8deaff"))
	placard.add_theme_color_override("font_outline_color", Color("030914"))
	placard.add_theme_constant_override("outline_size", 6)
	add_child(placard)
	_prompt = Label.new()
	_prompt.text = "  E  量子升级  "
	_prompt.position = Vector2(-82, -212)
	_prompt.size = Vector2(164, 34)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 19)
	_prompt.add_theme_color_override("font_color", Color("f6d66e"))
	_prompt.add_theme_color_override("font_outline_color", Color("02050d"))
	_prompt.add_theme_constant_override("outline_size", 8)
	_prompt.visible = false
	add_child(_prompt)

func _draw() -> void:
	var pulse := 0.65 + sin(_phase * 2.8) * 0.18
	# 地面基座与投射环。
	draw_colored_polygon(PackedVector2Array([
		Vector2(-92, -8), Vector2(-70, -32), Vector2(70, -32), Vector2(92, -8)
	]), Color("111a27"))
	draw_line(Vector2(-92, -8), Vector2(92, -8), Color("48677d"), 4)
	draw_arc(Vector2.ZERO, 67, PI, TAU, 32, Color(0.28, 0.88, 1.0, pulse), 5)
	draw_arc(Vector2.ZERO, 50, PI, TAU, 28, Color(0.8, 0.58, 1.0, 0.42), 2)
	# 两侧机械臂与中央控制核。
	for side in [-1.0, 1.0]:
		draw_rect(Rect2(side * 74 - 9, -106, 18, 78), Color("172333"), true)
		draw_line(Vector2(side * 74, -104), Vector2(side * 46, -76), Color("536a7d"), 8)
		draw_circle(Vector2(side * 45, -76), 11, Color("26384b"))
		draw_circle(Vector2(side * 45, -76), 5, Color(0.25, 0.88, 1.0, pulse))
	draw_rect(Rect2(-36, -92, 72, 56), Color("08131f"), true)
	draw_rect(Rect2(-31, -87, 62, 46), Color("102b3a"), true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -79), Vector2(20, -64), Vector2(0, -49), Vector2(-20, -64)
	]), Color(0.38, 0.91, 1.0, pulse))
	# 从卫星链路落下的扫描光束。
	draw_line(Vector2(0, -144), Vector2(0, -92), Color(0.42, 0.94, 1.0, 0.22 + pulse * 0.35), 7)
	draw_circle(Vector2(0, -145), 7 + pulse * 2, Color(0.7, 0.95, 1.0, 0.72))
