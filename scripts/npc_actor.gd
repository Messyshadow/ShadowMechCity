class_name NpcActor
extends Node2D
## 程序化枢纽 NPC：独立剪影、工位、待机动画和近距离交互提示。

signal interaction_requested(npc_id: String, actor: Node2D)

const NPC_DATA := preload("res://scripts/npc_data.gd")

var npc_id := ""
var data: Dictionary = {}
var player_near := false
var _prompt: Label
var _phase := 0.0

func setup(id: String) -> void:
	npc_id = id
	data = NPC_DATA.NPCS.get(id, {})
	if data.is_empty():
		push_error("Unknown NPC id: " + id)
		return
	name = "NPC_" + id
	_build_interaction_area()
	_build_labels()
	queue_redraw()

func _process(delta: float) -> void:
	_phase += delta
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if player_near and event.is_action_pressed("interact"):
		interaction_requested.emit(npc_id, self)
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
	var shape := CircleShape2D.new()
	shape.radius = 92.0
	shape_node.shape = shape
	shape_node.position = Vector2(0, -48)
	area.add_child(shape_node)
	area.body_entered.connect(func(body: Node):
		if body.is_in_group("player"): force_prompt_visible(true))
	area.body_exited.connect(func(body: Node):
		if body.is_in_group("player"): force_prompt_visible(false))
	add_child(area)

func _build_labels() -> void:
	var placard := Label.new()
	placard.text = str(data.get("role", "NPC"))
	placard.position = Vector2(-72, -142)
	placard.size = Vector2(144, 24)
	placard.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placard.add_theme_font_size_override("font_size", 14)
	placard.add_theme_color_override("font_color", data.get("accent", Color.WHITE).lightened(0.28))
	placard.add_theme_color_override("font_outline_color", Color(0.01, 0.015, 0.025, 0.95))
	placard.add_theme_constant_override("outline_size", 5)
	add_child(placard)

	_prompt = Label.new()
	_prompt.text = "  E  交谈  "
	_prompt.position = Vector2(-58, -184)
	_prompt.size = Vector2(116, 32)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 18)
	_prompt.add_theme_color_override("font_color", Color(0.88, 0.98, 1.0))
	_prompt.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.05))
	_prompt.add_theme_constant_override("outline_size", 7)
	_prompt.visible = false
	add_child(_prompt)

func _draw() -> void:
	if data.is_empty():
		return
	var accent: Color = data["accent"]
	var bob := sin(_phase * 1.7) * 1.5
	_draw_workstation(accent)
	# Ground shadow and illuminated station ring.
	_draw_flat_ellipse(Vector2(0, -2), Vector2(44, 9), Color(0.0, 0.0, 0.02, 0.62))
	draw_arc(Vector2(0, -4), 34, PI, TAU, 24, Color(accent.r, accent.g, accent.b, 0.42), 3.0)
	match str(data.get("build", "light")):
		"heavy": _draw_smith(accent, bob)
		"slender": _draw_alchemist(accent, bob)
		"robed": _draw_collector(accent, bob)
		"hunter": _draw_bounty(accent, bob)
		_: _draw_cartographer(accent, bob)

func _draw_flat_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 24:
		var a := TAU * float(i) / 24.0
		points.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_colored_polygon(points, color)

func _draw_workstation(accent: Color) -> void:
	match npc_id:
		"smith":
			draw_rect(Rect2(-82, -47, 48, 43), Color(0.10, 0.075, 0.055), true)
			draw_rect(Rect2(-78, -43, 40, 8), accent.darkened(0.25), true)
			for x in [-70.0, -52.0]: draw_line(Vector2(x, -35), Vector2(x, -8), Color(0.33, 0.25, 0.18), 4)
		"alchemist":
			for x in [-68.0, -49.0, -30.0]:
				draw_line(Vector2(x, -48), Vector2(x, -16), Color(0.28, 0.36, 0.36), 4)
				draw_circle(Vector2(x, -12), 9, Color(accent.r, accent.g, accent.b, 0.36))
		"cartographer":
			draw_arc(Vector2(-54, -58), 29, 0, TAU, 32, Color(accent.r, accent.g, accent.b, 0.45), 3)
			draw_line(Vector2(-82, -58), Vector2(-26, -58), accent, 2)
			draw_line(Vector2(-54, -86), Vector2(-54, -30), accent, 2)
		"collector":
			draw_rect(Rect2(-78, -72, 38, 67), Color(0.075, 0.055, 0.11), true)
			for y in [-62.0, -45.0, -28.0]: draw_line(Vector2(-74, y), Vector2(-44, y), accent.darkened(0.15), 3)
		"bounty":
			draw_rect(Rect2(-84, -83, 47, 76), Color(0.08, 0.04, 0.055), true)
			draw_arc(Vector2(-60, -58), 14, 0, TAU, 24, accent, 3)
			draw_line(Vector2(-60, -75), Vector2(-60, -41), accent, 2)
			draw_line(Vector2(-77, -58), Vector2(-43, -58), accent, 2)

func _draw_head(pos: Vector2, accent: Color, radius := 16.0) -> void:
	draw_circle(pos, radius + 4, Color(0.025, 0.035, 0.055))
	draw_circle(pos, radius, Color(0.18, 0.22, 0.28))
	draw_line(pos + Vector2(-8, 2), pos + Vector2(8, 2), accent, 4)
	draw_circle(pos + Vector2(8, 2), 3.2, accent.lightened(0.35))

func _draw_smith(accent: Color, bob: float) -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-35,-30),Vector2(-31,-93+bob),Vector2(31,-93+bob),Vector2(38,-30)]), Color(0.12,0.15,0.19))
	draw_rect(Rect2(-43, -81+bob, 17, 48), Color(0.21,0.18,0.16), true)
	draw_rect(Rect2(27, -81+bob, 20, 48), accent.darkened(0.45), true)
	_draw_head(Vector2(0, -111+bob), accent, 18)
	draw_line(Vector2(38,-62+bob), Vector2(58,-18), accent.darkened(0.25), 9)
	draw_rect(Rect2(48,-23,28,9), Color(0.25,0.27,0.3), true)

func _draw_alchemist(accent: Color, bob: float) -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-25,-28),Vector2(-20,-91+bob),Vector2(21,-91+bob),Vector2(31,-28)]), Color(0.075,0.14,0.15))
	_draw_head(Vector2(0,-110+bob), accent, 15)
	draw_line(Vector2(-13,-108+bob), Vector2(16,-99+bob), Color(0.31,0.37,0.38), 7)
	draw_circle(Vector2(22,-65+bob), 10, Color(accent.r,accent.g,accent.b,0.3))
	draw_circle(Vector2(22,-65+bob), 4, accent.lightened(0.3))

func _draw_cartographer(accent: Color, bob: float) -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-28,-28),Vector2(-24,-88+bob),Vector2(25,-88+bob),Vector2(32,-28)]), Color(0.09,0.14,0.20))
	_draw_head(Vector2(0,-107+bob), accent, 15)
	draw_arc(Vector2(30,-69+bob), 18, 0, TAU, 24, accent, 3)
	draw_line(Vector2(14,-69+bob), Vector2(46,-69+bob), accent.lightened(0.2), 2)

func _draw_collector(accent: Color, bob: float) -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-42,-28),Vector2(-22,-93+bob),Vector2(22,-93+bob),Vector2(44,-28)]), Color(0.095,0.065,0.15))
	_draw_head(Vector2(0,-110+bob), accent, 16)
	draw_circle(Vector2(35,-76+bob), 12, Color(accent.r,accent.g,accent.b,0.18))
	draw_colored_polygon(PackedVector2Array([Vector2(35,-86+bob),Vector2(45,-76+bob),Vector2(35,-66+bob),Vector2(25,-76+bob)]), accent)

func _draw_bounty(accent: Color, bob: float) -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-34,-28),Vector2(-26,-91+bob),Vector2(24,-91+bob),Vector2(38,-28)]), Color(0.12,0.10,0.13))
	draw_colored_polygon(PackedVector2Array([Vector2(-22,-88+bob),Vector2(-55,-48),Vector2(-25,-34)]), Color(0.17,0.055,0.065))
	_draw_head(Vector2(0,-109+bob), accent, 16)
	draw_line(Vector2(29,-92+bob), Vector2(56,-8), Color(0.30,0.32,0.36), 5)
	draw_line(Vector2(24,-72+bob), Vector2(53,-83+bob), accent.darkened(0.3), 6)
