class_name SkillPreviewEffect
extends Node2D
## 技能面板专用的纯视觉演示层。没有碰撞、伤害、资源消耗或存档写入。

var pattern := "passive"
var primary := Color.CYAN
var secondary := Color.WHITE
var intensity := "basic"
var phase := 0
var progress := 0.0


func configure(data: Dictionary) -> void:
	pattern = str(data.get("pattern", "passive"))
	primary = data.get("primary", Color.CYAN)
	secondary = data.get("secondary", Color.WHITE)
	intensity = str(data.get("intensity", "basic"))
	phase = 0
	progress = 0.0
	queue_redraw()


func set_phase(value: int, value_progress: float = 0.0) -> void:
	phase = clampi(value, 0, 4)
	progress = clampf(value_progress, 0.0, 1.0)
	queue_redraw()


func animate_progress(value: float, phase_value: int) -> void:
	set_phase(phase_value, value)


func _draw() -> void:
	var strength := 1.0 if intensity == "basic" else 1.22
	if intensity == "ultimate":
		strength = 1.5
	var reveal := ease(clampf(progress, 0.05, 1.0), 0.72)
	var alpha := minf(0.92, (0.28 + 0.64 * reveal) * (1.0 if phase < 4 else 1.0 - progress))
	var main := Color(primary, primary.a * alpha)
	var glow := Color(secondary, secondary.a * alpha * 0.74)
	var radius := (38.0 + 12.0 * reveal) * strength

	if phase == 0:
		_draw_telegraph(radius, main, glow)
		return
	match pattern:
		"slash_spin":
			_draw_slash_spin(radius, main, glow)
		"ground_smash":
			_draw_ground_smash(radius, main, glow)
		"pressure_jet":
			_draw_pressure_jet(radius, main, glow)
		"pressure_beam":
			_draw_pressure_beam(radius, main, glow)
		"cross_slash":
			_draw_cross_slash(radius, main, glow)
		"shadow_dash":
			_draw_shadow_dash(radius, main, glow)
		"spear_rise":
			_draw_spear_rise(radius, main, glow)
		"spear_drill":
			_draw_spear_drill(radius, main, glow)
		"arrow_rain":
			_draw_arrow_rain(radius, main, glow)
		"reticle_burst":
			_draw_reticle_burst(radius, main, glow)
		_:
			_draw_passive(radius, main, glow)
	if phase == 2:
		draw_circle(Vector2(78, -10), 12.0 + 12.0 * reveal, Color(glow, 0.25 * alpha))
		draw_arc(Vector2(78, -10), 18.0 + 8.0 * reveal, 0.0, TAU, 24, main, 3.0)
	elif phase == 3:
		for index in range(3):
			var residue_alpha := alpha * (0.22 - index * 0.05)
			draw_arc(Vector2(45, 8), radius + index * 10.0, PI * 0.15, PI * 1.85, 28,
				Color(main, residue_alpha), 2.0)


func _draw_telegraph(radius: float, main: Color, glow: Color) -> void:
	var pulse := 0.72 + progress * 0.28
	draw_arc(Vector2(55, 4), radius * pulse, 0.0, TAU, 36, Color(main, 0.48), 2.0)
	draw_arc(Vector2(55, 4), radius * 0.68 * pulse, 0.0, TAU, 30, Color(glow, 0.34), 1.0)
	for index in range(4):
		var angle := index * PI * 0.5 + progress * 0.25
		var outer := Vector2(55, 4) + Vector2.from_angle(angle) * radius
		draw_line(outer, outer + Vector2.from_angle(angle) * 9.0, main, 3.0)


func _draw_slash_spin(radius: float, main: Color, glow: Color) -> void:
	for index in range(3):
		var start := -PI * 0.7 + index * 0.5 + progress * 0.7
		draw_arc(Vector2(38, 0), radius + index * 9.0, start, start + PI * 1.25,
			28, Color(main if index == 1 else glow, 0.86 - index * 0.12), 5.0 - index)
	draw_circle(Vector2(38, 0), 10.0, Color(glow, 0.22))


func _draw_ground_smash(radius: float, main: Color, glow: Color) -> void:
	var ground_y := 28.0
	draw_circle(Vector2(24, ground_y), radius * 0.45, Color(main, 0.18))
	draw_line(Vector2(-12, ground_y), Vector2(114, ground_y), main, 5.0)
	for index in range(7):
		var x := -4.0 + index * 18.0
		var height := (18.0 + (index % 3) * 8.0) * progress
		draw_polyline(PackedVector2Array([
			Vector2(x, ground_y), Vector2(x + 7, ground_y - height),
			Vector2(x + 12, ground_y - height * 0.42)
		]), glow, 3.0)


func _draw_pressure_jet(radius: float, main: Color, glow: Color) -> void:
	var width := 18.0 + 14.0 * progress
	var plume := PackedVector2Array([
		Vector2(-width * 0.35, 12), Vector2(width * 0.35, 12),
		Vector2(width, 54), Vector2(0, 72 + radius * 0.25), Vector2(-width, 54)
	])
	draw_colored_polygon(plume, Color(main, 0.34))
	for index in range(4):
		var x := -15.0 + index * 10.0
		draw_line(Vector2(x, 20), Vector2(x * 1.8, 60 + index * 3), glow, 3.0)


func _draw_pressure_beam(radius: float, main: Color, glow: Color) -> void:
	var length := 65.0 + 92.0 * progress
	draw_line(Vector2(-18, 0), Vector2(length, 0), Color(glow, 0.3), 18.0)
	draw_line(Vector2(-18, 0), Vector2(length, 0), main, 8.0)
	draw_line(Vector2(-18, 0), Vector2(length, 0), secondary, 2.0)
	draw_circle(Vector2(length, 0), radius * 0.32, Color(main, 0.3))


func _draw_cross_slash(radius: float, main: Color, glow: Color) -> void:
	var span := radius * (0.8 + progress * 0.4)
	for offset in [-8.0, 8.0]:
		draw_line(Vector2(18 - span, -span + offset), Vector2(18 + span, span + offset),
			Color(glow, 0.48), 8.0)
		draw_line(Vector2(18 - span, span + offset), Vector2(18 + span, -span + offset),
			main, 4.0)


func _draw_shadow_dash(radius: float, main: Color, glow: Color) -> void:
	var length := 62.0 + 82.0 * progress
	for index in range(4):
		var y := -18.0 + index * 12.0
		draw_line(Vector2(-28, y), Vector2(length - index * 14.0, y - 8.0),
			Color(main if index == 1 else glow, 0.72 - index * 0.1), 6.0 - index)
	draw_arc(Vector2(length, -8), radius * 0.55, -PI * 0.55, PI * 0.55, 18, main, 4.0)


func _draw_spear_rise(radius: float, main: Color, glow: Color) -> void:
	var top := -42.0 - 42.0 * progress
	draw_line(Vector2(18, 28), Vector2(18, top), Color(glow, 0.35), 16.0)
	draw_line(Vector2(18, 28), Vector2(18, top), main, 5.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(18, top - 16), Vector2(8, top + 4), Vector2(28, top + 4)
	]), glow)
	draw_arc(Vector2(18, -6), radius * 0.55, -PI * 0.2, PI * 1.2, 18, main, 3.0)


func _draw_spear_drill(radius: float, main: Color, glow: Color) -> void:
	var length := 52.0 + 72.0 * progress
	var spiral := PackedVector2Array()
	for index in range(24):
		var t := index / 23.0
		spiral.append(Vector2(-15.0 + length * t, sin(t * TAU * 3.0) * radius * (1.0 - t) * 0.34))
	draw_polyline(spiral, main, 5.0)
	draw_line(Vector2(-18, 0), Vector2(length + 18, 0), glow, 3.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(length + 22, 0), Vector2(length, -12), Vector2(length, 12)
	]), main)


func _draw_arrow_rain(radius: float, main: Color, glow: Color) -> void:
	for index in range(7):
		var x := -18.0 + index * 23.0
		var y := -58.0 + ((index * 17) % 24) + progress * 68.0
		draw_line(Vector2(x, y), Vector2(x - 8, y + 22), main, 3.0)
		draw_line(Vector2(x - 8, y + 22), Vector2(x - 3, y + 16), glow, 2.0)
	draw_arc(Vector2(48, 32), radius, PI, TAU, 24, Color(main, 0.35), 3.0)


func _draw_reticle_burst(radius: float, main: Color, glow: Color) -> void:
	var center := Vector2(68, -6)
	draw_arc(center, radius * 0.72, 0.0, TAU, 36, main, 4.0)
	draw_arc(center, radius * 0.38, 0.0, TAU, 28, glow, 2.0)
	for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
		var inner := center + Vector2.from_angle(angle) * radius * 0.46
		var outer := center + Vector2.from_angle(angle) * radius
		draw_line(inner, outer, main, 3.0)
	draw_circle(center, 7.0 + progress * 8.0, Color(glow, 0.52))


func _draw_passive(radius: float, main: Color, glow: Color) -> void:
	draw_arc(Vector2(42, 0), radius * 0.72, 0.0, TAU, 30, main, 3.0)
	draw_arc(Vector2(42, 0), radius * 0.48, -PI * 0.4, PI * 1.3, 24, glow, 5.0)
	draw_circle(Vector2(42, 0), 8.0, Color(main, 0.34))
