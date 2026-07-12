extends Node2D
## 主题化地面竖井口。只负责视觉，不创建碰撞。

var theme := "city"
var width := 180.0
var depth := 240.0
var rim := Color(0.45,0.8,1.0)

func setup(p_theme: String, p_width: float = 180.0, p_depth: float = 240.0) -> void:
	theme = p_theme
	width = p_width
	depth = p_depth
	rim = _theme_color(theme)
	z_index = 3
	queue_redraw()

func _theme_color(value: String) -> Color:
	match value:
		"water": return Color(0.18,0.76,0.82)
		"mine": return Color(0.92,0.38,0.12)
		"temple": return Color(0.82,0.66,0.28)
		"factory": return Color(0.94,0.32,0.10)
		"void": return Color(0.50,0.36,0.96)
		"castle": return Color(0.60,0.34,0.78)
	return Color(0.42,0.78,0.92)

func _draw() -> void:
	var half := width*0.5
	# 多层填充形成深井，不依靠细线表示体积。
	var shaft := PackedVector2Array([Vector2(-half,0),Vector2(half,0),Vector2(half*0.60,depth),Vector2(-half*0.60,depth)])
	draw_colored_polygon(shaft,Color(0.004,0.008,0.018,0.99))
	for i in range(5):
		var inset := 10.0+float(i)*9.0
		var y := float(i)*28.0
		var layer := PackedVector2Array([Vector2(-half+inset,y),Vector2(half-inset,y),Vector2(half*0.60-inset*0.4,depth),Vector2(-half*0.60+inset*0.4,depth)])
		draw_colored_polygon(layer,Color(rim.r*0.055,rim.g*0.075,rim.b*0.11,0.24))
	# 厚实左右井沿与内侧高光。
	var left_plate := PackedVector2Array([Vector2(-half-30,-15),Vector2(-half+5,-15),Vector2(-half+18,22),Vector2(-half+5,44),Vector2(-half-32,28)])
	var right_plate := PackedVector2Array([Vector2(half+30,-15),Vector2(half-5,-15),Vector2(half-18,22),Vector2(half-5,44),Vector2(half+32,28)])
	draw_colored_polygon(left_plate,Color(0.075,0.095,0.12,1))
	draw_colored_polygon(right_plate,Color(0.075,0.095,0.12,1))
	draw_polyline(PackedVector2Array([Vector2(-half-30,-15),Vector2(-half+5,-15),Vector2(-half+18,22),Vector2(-half+5,44)]),rim.darkened(0.12),8,true)
	draw_polyline(PackedVector2Array([Vector2(half+30,-15),Vector2(half-5,-15),Vector2(half-18,22),Vector2(half-5,44)]),rim.darkened(0.12),8,true)
	draw_line(Vector2(-half+4,2),Vector2(half-4,2),Color(0.04,0.055,0.075,1),16,true)
	draw_line(Vector2(-half+8,-2),Vector2(half-8,-2),rim.lightened(0.12),3,true)
	# 井壁梯级和防坠栅残片。
	for y in range(38,int(depth),34):
		draw_line(Vector2(-25,y),Vector2(25,y),Color(0.20,0.24,0.30,0.72),5,true)
	draw_line(Vector2(-30,24),Vector2(-18,depth*0.72),Color(0.16,0.19,0.25,0.85),4,true)
	draw_line(Vector2(30,24),Vector2(18,depth*0.72),Color(0.16,0.19,0.25,0.85),4,true)
	for x in [-half+20,-half+40,-half+60]:
		draw_line(Vector2(x,-7),Vector2(x+25,32),rim.darkened(0.36),4,true)
	# 低矮护栏保留地形阅读，不形成“传送门拱门”。
	for side in [-1.0,1.0]:
		draw_line(Vector2(side*(half+25),18),Vector2(side*(half+25),-64),rim.darkened(0.24),7,true)
		draw_line(Vector2(side*(half+25),-64),Vector2(side*(half-42),-64),rim.darkened(0.24),7,true)
		draw_circle(Vector2(side*(half+25),-65),7,rim.lightened(0.18))
	_draw_lintel(half)
	_draw_support_braces(half)
	_draw_guide_lamps(half)
	_draw_landing_cues(half)
	_draw_theme_detail(half)

func _draw_lintel(half: float) -> void:
	# 厚门楣把洞口读成嵌入地面的机械竖井，而不是一圈发光线。
	var beam := Rect2(-half - 34.0, -96.0, width + 68.0, 24.0)
	draw_rect(beam, Color(0.055, 0.07, 0.095, 1.0), true)
	draw_rect(beam, rim.darkened(0.38), false, 5.0)
	draw_line(Vector2(-half - 20.0, -82.0), Vector2(half + 20.0, -82.0), rim.lightened(0.08), 3.0, true)
	for x in [-half - 18.0, half + 18.0]:
		draw_circle(Vector2(x, -84.0), 5.0, Color(0.38, 0.44, 0.50, 1.0))

func _draw_support_braces(half: float) -> void:
	for side in [-1.0, 1.0]:
		var outer: float = side * (half + 30.0)
		var inner: float = side * (half - 38.0)
		draw_line(Vector2(outer, -74.0), Vector2(inner, -10.0), Color(0.12, 0.15, 0.20, 1.0), 13.0, true)
		draw_line(Vector2(outer, -74.0), Vector2(inner, -10.0), rim.darkened(0.30), 3.0, true)

func _draw_guide_lamps(half: float) -> void:
	for side in [-1.0, 1.0]:
		var p: Vector2 = Vector2(side * (half + 50.0), -48.0)
		draw_circle(p, 14.0, Color(rim.r, rim.g, rim.b, 0.12))
		draw_circle(p, 7.0, rim.lightened(0.28))
		draw_circle(p, 3.0, Color(0.92, 0.98, 1.0, 1.0))
	# 三枚向下灯标明确交互方向。
	for y in [-58.0, -45.0, -32.0]:
		var spread: float = (y + 58.0) * 0.38
		draw_line(Vector2(-spread, y), Vector2(0.0, y + 8.0), rim, 3.0, true)
		draw_line(Vector2(spread, y), Vector2(0.0, y + 8.0), rim, 3.0, true)

func _draw_landing_cues(half: float) -> void:
	# 井口两侧的防滑落脚板与铆钉让玩家看清安全站位。
	for side in [-1.0, 1.0]:
		var start: float = side * (half + 4.0)
		var finish: float = side * (half + 82.0)
		draw_line(Vector2(start, 5.0), Vector2(finish, 5.0), Color(0.10, 0.13, 0.17, 1.0), 18.0, true)
		draw_line(Vector2(start, 0.0), Vector2(finish, 0.0), rim.darkened(0.16), 4.0, true)
		for offset in [20.0, 44.0, 68.0]:
			draw_circle(Vector2(side * (half + offset), 4.0), 2.5, Color(0.55, 0.60, 0.65, 1.0))

func _draw_theme_detail(half: float) -> void:
	match theme:
		"water":
			draw_polyline(PackedVector2Array([Vector2(-half-96,-45),Vector2(-half-48,-45),Vector2(-half-30,-18)]),Color(0.07,0.28,0.31),13,true)
			for x in [-half-68,-half-52]: draw_line(Vector2(x,-35),Vector2(x-5,-5),Color(0.30,0.88,0.92,0.48),2,true)
		"mine":
			draw_polyline(PackedVector2Array([Vector2(half+34,-72),Vector2(half+66,-42),Vector2(half+34,-10),Vector2(half+2,-42),Vector2(half+34,-72)]),Color(0.66,0.28,0.08),6,true)
			draw_line(Vector2(half+34,-10),Vector2(half+16,90),Color(0.18,0.12,0.08),3,true)
		"castle":
			for x in [-half+28,half-28]: draw_line(Vector2(x,-4),Vector2(x*0.72,depth*0.82),Color(0.32,0.20,0.40),4,true)
		"void":
			draw_arc(Vector2.ZERO,half+18,-2.8,-0.34,28,Color(0.48,0.40,1.0,0.58),4,true)
			draw_arc(Vector2.ZERO,half+28,-2.7,-0.44,28,Color(0.74,0.28,1.0,0.30),3,true)
		_:
			draw_line(Vector2(-half-65,-42),Vector2(-half-22,-42),rim.darkened(0.25),8,true)
