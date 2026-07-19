class_name SkillNodeControl
extends Control

signal chosen(id: String)
signal hovered(id: String)

var node_data: Dictionary = {}
var level := 0
var available := false
var selected := false

func _ready() -> void:
	custom_minimum_size = Vector2(74, 74)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	mouse_entered.connect(_on_mouse_entered)
	queue_redraw()

func setup(data: Dictionary, current_level: int, can_learn: bool) -> void:
	node_data = data
	tooltip_text = "%s\n%s" % [data.get("name", "技能"), data.get("usage", "")]
	refresh(current_level, can_learn)

func refresh(current_level: int, can_learn: bool) -> void:
	level = current_level
	available = can_learn
	queue_redraw()

func set_selected(value: bool) -> void:
	selected = value
	if selected:
		grab_focus()
	queue_redraw()

func _on_mouse_entered() -> void:
	if not node_data.is_empty():
		hovered.emit(str(node_data.get("id", "")))

func _gui_input(event: InputEvent) -> void:
	var activate: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	activate = activate or (event is InputEventKey and event.pressed and event.is_action("ui_accept"))
	if activate and not node_data.is_empty():
		chosen.emit(str(node_data.get("id", "")))
		accept_event()

func _draw() -> void:
	var center := size * 0.5
	var max_level := int(node_data.get("max", 0))
	var locked := max_level <= 0
	var learned := level > 0
	var ring := Color(0.28, 0.38, 0.5)
	if learned:
		ring = Color(0.35, 0.92, 1.0)
	elif available:
		ring = Color(0.95, 0.72, 0.28)
	if locked:
		ring = Color(0.42, 0.32, 0.52)
	draw_circle(center, 34.0, Color(0.025, 0.045, 0.075, 0.98))
	draw_arc(center, 33.0, 0.0, TAU, 64, ring, 4.0, true)
	draw_arc(center, 27.0, 0.0, TAU, 64, Color(ring, 0.34), 2.0, true)
	if selected:
		draw_arc(center, 38.0, 0.0, TAU, 64, Color(0.65, 0.97, 1.0), 3.0, true)
		draw_arc(center, 42.0, 0.0, TAU, 64, Color(0.28, 0.72, 1.0, 0.55), 2.0, true)
	var glyph := "◆"
	match str(node_data.get("type", "")):
		"被动": glyph = "◇"
		"组合": glyph = "刃"
		"终结": glyph = "V"
		"主动能力": glyph = "跃"
		"能力根": glyph = "锁"
		"家族根": glyph = "武"
	var font := ThemeDB.fallback_font
	var glyph_size := 21
	var glyph_width := font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, glyph_size).x
	draw_string(font, center + Vector2(-glyph_width * 0.5, 7), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, glyph_size, Color(0.88, 0.96, 1.0))
	if max_level > 0:
		var span := minf(36.0, float(max_level - 1) * 10.0)
		for index in range(max_level):
			var x := center.x - span * 0.5 + (span / maxf(1.0, float(max_level - 1))) * index
			draw_circle(Vector2(x, 65), 3.0, Color(0.45, 0.9, 1.0) if index < level else Color(0.22, 0.29, 0.38))
	if locked:
		draw_line(center + Vector2(-19, 20), center + Vector2(19, -20), Color(0.75, 0.4, 0.82, 0.85), 3.0)
