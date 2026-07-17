extends Node2D
## 程序化传送阵视觉：普通入口为青蓝机械环，隐藏入口为断裂紫色符文。

var is_hidden := false
var is_locked := false
var portal_side := "up"
var focused := false
var _phase := 0.0
var _focus_mix := 0.0
var _particles: CPUParticles2D

func setup(hidden: bool, locked: bool, side: String) -> void:
	is_hidden = hidden
	is_locked = locked
	portal_side = side
	z_index = 8
	_build_particles()
	queue_redraw()

func set_focused(value: bool) -> void:
	focused = value

func _process(delta: float) -> void:
	_phase = fmod(_phase + delta * (1.7 if focused else 0.65), TAU)
	_focus_mix = move_toward(_focus_mix, 1.0 if focused else 0.0, delta * 3.5)
	if is_instance_valid(_particles):
		_particles.amount = 20 if focused else 11
	queue_redraw()

func _draw() -> void:
	var center := Vector2(0, 30) if portal_side == "down" else Vector2.ZERO
	var radii := _radii()
	var energy := Color(0.28, 0.88, 1.0, 0.14 + _focus_mix * 0.12)
	var primary := Color(0.38, 0.9, 1.0, 0.72 + _focus_mix * 0.24)
	var secondary := Color(0.12, 0.48, 0.7, 0.62 + _focus_mix * 0.25)
	if is_hidden:
		energy = Color(0.5, 0.18, 0.92, 0.16 + _focus_mix * 0.15)
		primary = Color(0.78, 0.42, 1.0, 0.72 + _focus_mix * 0.25)
		secondary = Color(0.36, 0.14, 0.72, 0.68 + _focus_mix * 0.22)
	if is_locked:
		primary = primary.darkened(0.32)
		secondary = secondary.darkened(0.28)
	if portal_side == "down":
		draw_rect(Rect2(center.x - radii.x - 24, center.y - 8, (radii.x + 24) * 2.0, 19), Color(0.035, 0.055, 0.09, 0.96))
		draw_line(Vector2(center.x-radii.x-26, center.y-9), Vector2(center.x+radii.x+26, center.y-9), primary, 4.0, true)
	draw_colored_polygon(_ellipse_points(center, radii * 0.72, 40), energy)
	_draw_ring(center, radii, primary, 5.5, 0.0)
	_draw_ring(center, radii * 0.78, secondary, 2.5, -_phase * 0.4)
	_draw_ticks(center, radii * 1.16, primary)
	var core_r := 7.0 + _focus_mix * 3.0
	draw_circle(center, core_r, Color(primary.r, primary.g, primary.b, 0.45))
	draw_circle(center, core_r * 0.45, Color(0.85, 0.97, 1.0, 0.9))

func _draw_ring(center: Vector2, radii: Vector2, color: Color, width: float, phase: float) -> void:
	if is_hidden and is_locked:
		for segment in [[0.12, 1.18], [1.72, 2.72], [3.22, 4.18], [4.76, 5.72]]:
			draw_polyline(_arc_points(center, radii, float(segment[0]) + phase, float(segment[1]) + phase, 12), color, width, true)
	else:
		draw_polyline(_arc_points(center, radii, phase, phase + TAU, 48), color, width, true)

func _draw_ticks(center: Vector2, radii: Vector2, color: Color) -> void:
	var count := 10 if is_hidden else 14
	for i in range(count):
		if is_hidden and is_locked and i % 3 == 1:
			continue
		var angle := TAU * float(i) / float(count) + _phase
		var outer := center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y)
		var inner := center + Vector2(cos(angle) * radii.x * 0.88, sin(angle) * radii.y * 0.88)
		draw_line(inner, outer, color, 2.0, true)

func _radii() -> Vector2:
	match portal_side:
		"left", "right": return Vector2(42, 76)
		"down": return Vector2(108, 27)
		_: return Vector2(76, 31)

func _ellipse_points(center: Vector2, radii: Vector2, count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(count):
		var angle := TAU * float(i) / float(count)
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points

func _arc_points(center: Vector2, radii: Vector2, start: float, finish: float, count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(count + 1):
		var t := float(i) / float(count)
		var angle := lerpf(start, finish, t)
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points

func _build_particles() -> void:
	if is_instance_valid(_particles):
		_particles.queue_free()
	_particles = CPUParticles2D.new()
	_particles.position = Vector2(0, 30) if portal_side == "down" else Vector2.ZERO
	_particles.amount = 11
	_particles.lifetime = 1.35
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_particles.emission_rect_extents = _radii() * Vector2(0.72, 0.55)
	_particles.gravity = Vector2.ZERO
	_particles.direction = Vector2(0, -1)
	_particles.spread = 180.0
	_particles.initial_velocity_min = 4.0
	_particles.initial_velocity_max = 15.0
	_particles.color = Color(0.72, 0.42, 1.0, 0.62) if is_hidden else Color(0.42, 0.92, 1.0, 0.58)
	add_child(_particles)
