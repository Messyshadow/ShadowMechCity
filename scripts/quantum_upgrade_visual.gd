class_name QuantumUpgradeVisual
extends Control
## 卫星储能量子投射演出。完全程序化，状态由升级台驱动。

var visual_state := "idle"
var item_name := "等待装备接入"
var accent := Color("57dcff")
var _phase := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(455, 318)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func set_state(next_state: String, next_item_name: String = "", next_accent: Color = Color("57dcff")) -> void:
	visual_state = next_state
	if next_item_name != "":
		item_name = next_item_name
	accent = next_accent
	queue_redraw()

func _process(delta: float) -> void:
	_phase += delta
	queue_redraw()

func _draw() -> void:
	var size := get_rect().size
	var center := Vector2(size.x * 0.5, size.y * 0.64)
	draw_rect(Rect2(Vector2.ZERO, size), Color("06101c"), true)
	for y in range(20, int(size.y), 28):
		draw_line(Vector2(12, y), Vector2(size.x - 12, y), Color(0.12, 0.33, 0.45, 0.20), 1)
	# 轨道卫星和链路。
	var satellite := Vector2(size.x * 0.5 + sin(_phase * 0.55) * 76.0, 52)
	draw_line(satellite + Vector2(-50, 0), satellite + Vector2(50, 0), Color("445d76"), 6)
	draw_rect(Rect2(satellite - Vector2(18, 12), Vector2(36, 24)), Color("9fb2c5"), true)
	draw_rect(Rect2(satellite - Vector2(54, 9), Vector2(30, 18)), Color("244b67"), true)
	draw_rect(Rect2(satellite + Vector2(24, -9), Vector2(30, 18)), Color("244b67"), true)
	draw_circle(satellite, 5, accent)
	var active := visual_state in ["confirm", "projecting", "success"]
	var beam_alpha := 0.18 if not active else 0.42 + sin(_phase * 8.0) * 0.12
	draw_colored_polygon(PackedVector2Array([
		satellite + Vector2(-7, 12), satellite + Vector2(7, 12),
		center + Vector2(54, 22), center + Vector2(-54, 22)
	]), Color(accent.r, accent.g, accent.b, beam_alpha))
	# 装备数据核心与扫描环。
	for radius: float in [72.0, 53.0, 35.0]:
		var start: float = _phase * (0.8 + radius / 100.0)
		draw_arc(center, radius, start, start + PI * 1.35, 48, Color(accent.r, accent.g, accent.b, 0.45), 2.5)
	var core_color := Color("ff5b78") if visual_state == "rejected" else accent
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0, -29), center + Vector2(29, 0),
		center + Vector2(0, 29), center + Vector2(-29, 0)
	]), Color(core_color.r, core_color.g, core_color.b, 0.2))
	draw_polyline(PackedVector2Array([
		center + Vector2(0, -29), center + Vector2(29, 0), center + Vector2(0, 29),
		center + Vector2(-29, 0), center + Vector2(0, -29)
	]), core_color, 3)
	if visual_state == "projecting":
		for index in range(15):
			var angle := _phase * 4.5 + float(index) * TAU / 15.0
			var distance := 38.0 + fmod(float(index) * 17.0 + _phase * 42.0, 75.0)
			draw_circle(center + Vector2.from_angle(angle) * distance, 2.5, Color(accent.r, accent.g, accent.b, 0.75))
	if visual_state == "success":
		draw_circle(center, 18 + sin(_phase * 5.0) * 3, Color(0.4, 1.0, 0.7, 0.56))
	var state_text: String = str({
		"idle":"链路待机", "confirm":"报价锁定 · 等待授权", "projecting":"卫星投射中",
		"success":"补丁安装完成", "rejected":"投射请求被拒绝",
	}.get(visual_state, "链路待机"))
	draw_string(ThemeDB.fallback_font, Vector2(18, 26), state_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, core_color)
	draw_string(ThemeDB.fallback_font, Vector2(18, size.y - 18), item_name, HORIZONTAL_ALIGNMENT_LEFT, size.x - 36, 16, Color("c8e5f2"))
