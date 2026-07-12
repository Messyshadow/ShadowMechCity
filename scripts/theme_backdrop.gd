extends Node2D
## 王城/虚空专用世界背景。使用世界坐标完整覆盖房间，避免视差贴图边缘露出默认灰底。

var theme := ""
var bounds: Array = []

func setup(p_theme: String, p_bounds: Array) -> void:
	theme = p_theme
	bounds = p_bounds
	z_index = -50
	queue_redraw()

func _draw() -> void:
	if bounds.size() < 4: return
	match theme:
		"castle": _draw_castle()
		"void": _draw_void()

func _room_rect() -> Rect2:
	return Rect2(bounds[0] - 420, bounds[1] - 420, bounds[2] - bounds[0] + 840, bounds[3] - bounds[1] + 840)

func _draw_gradient_bands(colors: Array[Color]) -> void:
	var rect := _room_rect()
	var band_h := rect.size.y / colors.size()
	for i in range(colors.size()):
		draw_rect(Rect2(rect.position.x, rect.position.y + band_h * i, rect.size.x, band_h + 2), colors[i])

func _draw_castle() -> void:
	_draw_gradient_bands([
		Color("090817"), Color("0d0a21"), Color("120d2a"), Color("171033"),
		Color("1b1238"), Color("1b1235"), Color("15102b"), Color("0d0b1c")
	])
	var l: float = bounds[0] - 180.0
	var r: float = bounds[2] + 180.0
	var floor_y: float = bounds[3] - 36.0
	# 远处城堡塔楼、垛口和暖色窄窗。
	for x in range(int(l), int(r), 330):
		var tower_h := 245.0 + float(posmod(x, 4)) * 34.0
		var tw := 145.0
		draw_rect(Rect2(x, floor_y - tower_h, tw, tower_h), Color(0.045,0.035,0.09,0.98))
		var roof := PackedVector2Array([Vector2(x-18,floor_y-tower_h),Vector2(x+tw*0.5,floor_y-tower_h-92),Vector2(x+tw+18,floor_y-tower_h)])
		draw_colored_polygon(roof, Color(0.035,0.025,0.075,1.0))
		for wx in [x+34.0, x+96.0]:
			draw_rect(Rect2(wx, floor_y-tower_h+76, 13, 46), Color(0.58,0.28,0.72,0.68))
			draw_circle(Vector2(wx+6.5,floor_y-tower_h+76),6.5,Color(0.76,0.48,0.88,0.7))
	# 中层哥特拱廊，轮廓比实心柱更轻，不抢平台和敌人。
	for x in range(int(l)+80, int(r), 280):
		var pts := PackedVector2Array([Vector2(x,floor_y),Vector2(x,floor_y-180)])
		for j in range(9):
			var a := PI + PI * float(j) / 8.0
			pts.append(Vector2(x+70+cos(a)*70, floor_y-180+sin(a)*76))
		pts.append(Vector2(x+140,floor_y))
		draw_polyline(pts,Color(0.18,0.12,0.28,0.72),11.0,true)
	# 悬链、玫瑰窗与尘光。
	for x in range(int(l)+210, int(r), 520):
		draw_line(Vector2(x,bounds[1]-80),Vector2(x+18,bounds[1]+220),Color(0.23,0.16,0.31,0.55),3.0,true)
		for y in range(int(bounds[1])+15, int(bounds[1])+210, 24):
			draw_circle(Vector2(x+float(y%17),y),5.0,Color(0.20,0.14,0.27,0.68))
	var rose := Vector2((bounds[0]+bounds[2])*0.5,bounds[1]+150)
	draw_circle(rose,64,Color(0.09,0.055,0.16,0.92))
	draw_arc(rose,64,0,TAU,32,Color(0.56,0.30,0.72,0.72),7,true)
	for i in range(8):
		var a := TAU*float(i)/8.0
		draw_line(rose,rose+Vector2(cos(a),sin(a))*55,Color(0.45,0.24,0.62,0.65),3,true)

func _draw_void() -> void:
	_draw_gradient_bands([
		Color("040716"), Color("071027"), Color("0a1634"), Color("0c183c"),
		Color("10163d"), Color("141036"), Color("100b28"), Color("080817")
	])
	var l: float = bounds[0] - 220.0
	var r: float = bounds[2] + 220.0
	var floor_y: float = bounds[3] - 28.0
	# 星尘与远处舰体灯点，固定公式保证每次截图一致。
	for i in range(72):
		var sx: float = l + fmod(float(i*137), r-l)
		var sy: float = float(bounds[1])-120.0 + fmod(float(i*83), maxf(220.0,floor_y-float(bounds[1])))
		var radius: float = 1.0 + float(i%3)
		draw_circle(Vector2(sx,sy),radius,Color(0.44,0.68,1.0,0.30+float(i%4)*0.09))
	# 核心裂隙：多层暗环、能量轮廓和放射裂纹。
	var core := Vector2((bounds[0]+bounds[2])*0.52,bounds[1]+230)
	for rr in [150.0,128.0,104.0,76.0]:
		draw_circle(core,rr,Color(0.12+rr/900.0,0.06,0.28+rr/700.0,0.36))
	draw_circle(core,60,Color(0.015,0.02,0.08,0.96))
	draw_arc(core,118,-2.7,2.4,40,Color(0.40,0.48,1.0,0.76),8,true)
	draw_arc(core,92,0.2,5.7,36,Color(0.70,0.30,1.0,0.72),5,true)
	for i in range(10):
		var a := TAU*float(i)/10.0+0.13
		var p1 := core+Vector2(cos(a),sin(a))*128
		var p2 := core+Vector2(cos(a+0.08),sin(a+0.08))*(175+float(i%3)*28)
		draw_line(p1,p2,Color(0.42,0.38,1.0,0.42),3,true)
	# 舰体肋骨和悬浮甲板剪影。
	for x in range(int(l),int(r),360):
		var rib := PackedVector2Array([Vector2(x,floor_y),Vector2(x+38,floor_y-238),Vector2(x+112,floor_y-292),Vector2(x+176,floor_y-238),Vector2(x+214,floor_y)])
		draw_polyline(rib,Color(0.075,0.10,0.22,0.90),24,true)
		draw_line(Vector2(x+34,floor_y-82),Vector2(x+180,floor_y-82),Color(0.20,0.22,0.52,0.46),5,true)
		for j in range(3):
			draw_rect(Rect2(x+68+j*34,floor_y-190,11,22),Color(0.30,0.54,0.94,0.55))
