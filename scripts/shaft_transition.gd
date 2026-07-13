extends Node2D
## 可操作下行竖井：保留真实 Player 物理，让墙滑/墙跳直接复用现有手感。

signal finished

const SHAFT_DEPTH := 620.0
const SHAFT_WIDTH := 180.0
const TIMEOUT_SECONDS := 8.0

var theme := "city"
var player: CharacterBody2D
var elapsed := 0.0
var completed := false
var accent := Color(0.35, 0.85, 1.0)

func setup(p_theme: String, p_player: CharacterBody2D) -> void:
	theme = p_theme
	player = p_player
	accent = _theme_color(theme)
	z_index = -1
	_make_wall(-SHAFT_WIDTH * 0.5 - 18.0)
	_make_wall(SHAFT_WIDTH * 0.5 + 18.0)
	_make_ledge(-52.0, 175.0)
	_make_ledge(52.0, 335.0)
	_make_ledge(-52.0, 490.0)
	_make_bottom_trigger()
	_make_particles()
	queue_redraw()

func _physics_process(delta: float) -> void:
	if completed:
		return
	elapsed += delta
	if elapsed >= TIMEOUT_SECONDS or (is_instance_valid(player) and player.global_position.y >= global_position.y + SHAFT_DEPTH - 35.0):
		_complete()

func _make_wall(local_x: float) -> void:
	var wall := StaticBody2D.new()
	wall.collision_layer = 0b00001
	wall.position = Vector2(local_x, SHAFT_DEPTH * 0.5)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(36.0, SHAFT_DEPTH + 120.0)
	collision.shape = shape
	wall.add_child(collision)
	add_child(wall)

func _make_ledge(local_x: float, local_y: float) -> void:
	var ledge := StaticBody2D.new()
	ledge.collision_layer = 0b00001
	ledge.position = Vector2(local_x, local_y)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(50.0, 12.0)
	collision.shape = shape
	collision.one_way_collision = true
	ledge.add_child(collision)
	add_child(ledge)

func _make_bottom_trigger() -> void:
	var trigger := Area2D.new()
	trigger.collision_layer = 0
	trigger.collision_mask = 0b00010
	trigger.position = Vector2(0.0, SHAFT_DEPTH - 24.0)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(SHAFT_WIDTH - 20.0, 56.0)
	collision.shape = shape
	trigger.add_child(collision)
	trigger.body_entered.connect(func(body: Node) -> void:
		if body == player:
			_complete())
	add_child(trigger)

func _make_particles() -> void:
	var mist := CPUParticles2D.new()
	mist.position = Vector2(0.0, SHAFT_DEPTH * 0.55)
	mist.amount = 42
	mist.lifetime = 2.6
	mist.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	mist.emission_rect_extents = Vector2(SHAFT_WIDTH * 0.42, SHAFT_DEPTH * 0.45)
	mist.direction = Vector2(0.0, -1.0)
	mist.spread = 14.0
	mist.initial_velocity_min = 24.0
	mist.initial_velocity_max = 70.0
	mist.gravity = Vector2(0.0, -14.0)
	mist.color = Color(accent.r, accent.g, accent.b, 0.24)
	add_child(mist)

func _complete() -> void:
	if completed:
		return
	completed = true
	call_deferred("_emit_finished")

func _emit_finished() -> void:
	finished.emit()

func _theme_color(value: String) -> Color:
	match value:
		"mine": return Color(1.0, 0.36, 0.10)
		"water": return Color(0.10, 0.82, 0.88)
		"temple": return Color(0.92, 0.72, 0.22)
		"factory": return Color(1.0, 0.30, 0.08)
		"void": return Color(0.58, 0.34, 1.0)
		"castle": return Color(0.72, 0.30, 0.88)
	return Color(0.35, 0.85, 1.0)

func _draw() -> void:
	var half := SHAFT_WIDTH * 0.5
	draw_rect(Rect2(-half, 0.0, SHAFT_WIDTH, SHAFT_DEPTH), Color(0.004, 0.007, 0.014, 1.0), true)
	for i in range(8):
		var y := float(i) * 78.0
		var shade := 0.075 + float(i) * 0.007
		draw_rect(Rect2(-half + 8.0, y + 5.0, SHAFT_WIDTH - 16.0, 68.0), Color(shade, shade * 1.12, shade * 1.35, 0.92), true)
		draw_line(Vector2(-half + 8.0, y + 5.0), Vector2(half - 8.0, y + 5.0), accent.darkened(0.58), 3.0)
	for side in [-1.0, 1.0]:
		draw_rect(Rect2(side * half - (32.0 if side > 0.0 else 0.0), -20.0, 32.0, SHAFT_DEPTH + 70.0), Color(0.055, 0.07, 0.095, 1.0), true)
		for y in range(30, 610, 120):
			draw_line(Vector2(side * (half - 8.0), float(y)), Vector2(side * 18.0, float(y + 78)), accent.darkened(0.50), 7.0, true)
		draw_line(Vector2(side * (half - 20.0), 0.0), Vector2(side * (half - 20.0), SHAFT_DEPTH), Color(0.16, 0.20, 0.27, 1.0), 7.0, true)
	for y in [72.0, 222.0, 372.0, 522.0]:
		draw_circle(Vector2(-half + 18.0, y), 10.0, Color(accent.r, accent.g, accent.b, 0.18))
		draw_circle(Vector2(-half + 18.0, y), 4.0, accent.lightened(0.28))
	for data in [[-52.0, 175.0], [52.0, 335.0], [-52.0, 490.0]]:
		var x: float = data[0]
		var y: float = data[1]
		draw_line(Vector2(x - 25.0, y), Vector2(x + 25.0, y), Color(0.11, 0.15, 0.20), 13.0, true)
		draw_line(Vector2(x - 23.0, y - 5.0), Vector2(x + 23.0, y - 5.0), accent, 3.0, true)
	draw_colored_polygon(PackedVector2Array([Vector2(-58.0, SHAFT_DEPTH), Vector2(58.0, SHAFT_DEPTH), Vector2(34.0, SHAFT_DEPTH - 82.0), Vector2(-34.0, SHAFT_DEPTH - 82.0)]), Color(accent.r, accent.g, accent.b, 0.13))
	draw_line(Vector2(-half + 8.0, SHAFT_DEPTH - 4.0), Vector2(half - 8.0, SHAFT_DEPTH - 4.0), accent, 5.0, true)
