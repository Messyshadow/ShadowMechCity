extends Node2D
## 七区域程序化世界背景。远景地标使用低对比形状构成，不遮挡平台、敌人和交互提示。

const THEME_PROFILES := {
	"city": {"landmark":"中央钟塔与列车穹顶", "far_color":Color("101a2a"), "mid_color":Color("18273a"), "accent":Color("55d9ff"), "haze":Color(0.08,0.22,0.30,0.14), "particle":Color(0.42,0.82,1.0,0.22), "particle_dir":Vector2(-0.18,-1.0)},
	"mine": {"landmark":"矿脉深井与绞盘骨架", "far_color":Color("211008"), "mid_color":Color("32170b"), "accent":Color("ff7138"), "haze":Color(0.32,0.07,0.015,0.13), "particle":Color(1.0,0.36,0.10,0.28), "particle_dir":Vector2(0,-1)},
	"factory": {"landmark":"巨型炉群与活塞管网", "far_color":Color("251009"), "mid_color":Color("3b170c"), "accent":Color("ff9b38"), "haze":Color(0.36,0.10,0.02,0.14), "particle":Color(1.0,0.52,0.18,0.30), "particle_dir":Vector2(0,-1)},
	"water": {"landmark":"沉没蓄水塔与排污拱廊", "far_color":Color("08252a"), "mid_color":Color("0b3940"), "accent":Color("54e8e8"), "haze":Color(0.01,0.24,0.27,0.15), "particle":Color(0.28,0.88,1.0,0.26), "particle_dir":Vector2(0,1)},
	"temple": {"landmark":"星轮祭坛与符文巨像", "far_color":Color("171126"), "mid_color":Color("271b3c"), "accent":Color("d6a8ff"), "haze":Color(0.18,0.10,0.30,0.13), "particle":Color(0.76,0.56,1.0,0.24), "particle_dir":Vector2(0,-1)},
	"void": {"landmark":"虚空裂隙与浮空舰骨", "far_color":Color("08112d"), "mid_color":Color("111b49"), "accent":Color("8b82ff"), "haze":Color(0.08,0.08,0.34,0.14), "particle":Color(0.48,0.56,1.0,0.28), "particle_dir":Vector2(-0.35,-1)},
	"castle": {"landmark":"王座尖塔与机械玫瑰窗", "far_color":Color("130c25"), "mid_color":Color("241238"), "accent":Color("c765da"), "haze":Color(0.20,0.06,0.28,0.14), "particle":Color(0.70,0.32,0.84,0.24), "particle_dir":Vector2(0,-1)},
}

var theme := ""
var bounds: Array = []

func setup(p_theme: String, p_bounds: Array) -> void:
	theme = p_theme
	bounds = p_bounds
	z_index = -50
	queue_redraw()

func atmosphere_profile() -> Dictionary:
	return Dictionary(THEME_PROFILES.get(theme, THEME_PROFILES["city"])).duplicate(true)

func _draw() -> void:
	if bounds.size() < 4: return
	match theme:
		"city": _draw_city()
		"mine": _draw_mine()
		"factory": _draw_factory()
		"water": _draw_water()
		"temple": _draw_temple()
		"castle": _draw_castle()
		"void": _draw_void()

func _room_rect() -> Rect2:
	return Rect2(bounds[0] - 420, bounds[1] - 420, bounds[2] - bounds[0] + 840, bounds[3] - bounds[1] + 840)

func _draw_gradient_bands(colors: Array[Color]) -> void:
	var rect := _room_rect()
	var band_h := rect.size.y / colors.size()
	for i in range(colors.size()):
		draw_rect(Rect2(rect.position.x, rect.position.y + band_h * i, rect.size.x, band_h + 2), colors[i])

func _profile_gradient() -> void:
	var profile := atmosphere_profile()
	var far_color: Color = profile["far_color"]
	var mid_color: Color = profile["mid_color"]
	_draw_gradient_bands([far_color.darkened(0.55), far_color.darkened(0.30), far_color, mid_color.darkened(0.18), mid_color, mid_color.darkened(0.12), far_color])

func _span() -> Array[float]:
	return [float(bounds[0]) - 220.0, float(bounds[2]) + 220.0, float(bounds[3]) - 30.0]

func _draw_city() -> void:
	_profile_gradient()
	var span := _span(); var l := span[0]; var r := span[1]; var floor_y := span[2]
	# 远层错落机械楼群与冷色窗格。
	for x in range(int(l), int(r), 190):
		var h := 170.0 + float(posmod(x / 10, 7)) * 27.0
		draw_rect(Rect2(x, floor_y-h, 132, h), Color(0.035,0.075,0.12,0.94))
		for wy in range(int(floor_y-h+34), int(floor_y-24), 42):
			draw_rect(Rect2(x+24,wy,12,18),Color(0.28,0.62,0.88,0.48))
			draw_rect(Rect2(x+76,wy,12,18),Color(0.28,0.62,0.88,0.32))
	# 中央车站钟塔、穹顶轨道和悬挂信号灯。
	var center := (float(bounds[0])+float(bounds[2]))*0.5
	draw_rect(Rect2(center-58,floor_y-390,116,360),Color(0.055,0.10,0.16,0.98))
	draw_circle(Vector2(center,floor_y-310),48,Color(0.02,0.04,0.08,0.95))
	draw_arc(Vector2(center,floor_y-310),48,0,TAU,36,Color(0.32,0.82,1.0,0.76),6,true)
	draw_line(Vector2(center,floor_y-310),Vector2(center+4,floor_y-345),Color(0.65,0.94,1.0,0.9),4,true)
	draw_line(Vector2(center,floor_y-310),Vector2(center+29,floor_y-298),Color(0.65,0.94,1.0,0.9),3,true)
	for x in range(int(l),int(r),430):
		draw_arc(Vector2(x+215,floor_y-38),215,PI,TAU,30,Color(0.12,0.28,0.38,0.60),12,true)

func _draw_mine() -> void:
	_profile_gradient()
	var span := _span(); var l := span[0]; var r := span[1]; var floor_y := span[2]
	# 不规则矿脉剪影与纵深洞口。
	for x in range(int(l),int(r),260):
		var ridge := PackedVector2Array([Vector2(x,floor_y),Vector2(x+38,floor_y-210),Vector2(x+105,floor_y-285),Vector2(x+170,floor_y-165),Vector2(x+260,floor_y)])
		draw_colored_polygon(ridge,Color(0.075,0.035,0.018,0.96))
		draw_line(Vector2(x+30,floor_y-40),Vector2(x+112,floor_y-250),Color(0.34,0.12,0.035,0.5),8,true)
	# 三角支架、绞盘与垂直矿井索。
	for x in range(int(l)+90,int(r),360):
		draw_polyline(PackedVector2Array([Vector2(x,floor_y),Vector2(x+75,floor_y-260),Vector2(x+150,floor_y)]),Color(0.24,0.105,0.04,0.9),18,true)
		draw_circle(Vector2(x+75,floor_y-245),30,Color(0.08,0.04,0.02,0.95))
		draw_arc(Vector2(x+75,floor_y-245),30,0,TAU,20,Color(0.82,0.28,0.07,0.62),5,true)
		draw_line(Vector2(x+75,floor_y-215),Vector2(x+75,floor_y-55),Color(0.22,0.14,0.09,0.85),4,true)

func _draw_factory() -> void:
	_profile_gradient()
	var span := _span(); var l := span[0]; var r := span[1]; var floor_y := span[2]
	# 炉群烟囱、压力罐与交错管线。
	for x in range(int(l),int(r),310):
		draw_rect(Rect2(x+32,floor_y-310,66,310),Color(0.09,0.035,0.015,0.98))
		draw_rect(Rect2(x+18,floor_y-330,94,26),Color(0.18,0.07,0.025,0.96))
		draw_circle(Vector2(x+205,floor_y-150),76,Color(0.12,0.045,0.018,0.96))
		draw_arc(Vector2(x+205,floor_y-150),76,0,TAU,28,Color(0.58,0.20,0.04,0.6),9,true)
		draw_line(Vector2(x+98,floor_y-230),Vector2(x+205,floor_y-230),Color(0.32,0.105,0.025,0.82),16,true)
		draw_line(Vector2(x+205,floor_y-230),Vector2(x+205,floor_y-214),Color(0.32,0.105,0.025,0.82),16,true)
	# 活塞梁让房间横向运动方向更明显。
	for y in [floor_y-360.0,floor_y-86.0]:
		draw_line(Vector2(l,y),Vector2(r,y),Color(0.22,0.07,0.02,0.55),12,true)

func _draw_water() -> void:
	_profile_gradient()
	var span := _span(); var l := span[0]; var r := span[1]; var floor_y := span[2]
	# 巨型蓄水拱廊与水位反光。
	for x in range(int(l),int(r),300):
		draw_arc(Vector2(x+150,floor_y-115),124,PI,TAU,28,Color(0.055,0.22,0.24,0.92),20,true)
		draw_line(Vector2(x+26,floor_y-115),Vector2(x+26,floor_y),Color(0.055,0.22,0.24,0.92),20,true)
		draw_line(Vector2(x+274,floor_y-115),Vector2(x+274,floor_y),Color(0.055,0.22,0.24,0.92),20,true)
	for y in range(int(floor_y-160),int(floor_y),28):
		draw_line(Vector2(l,y),Vector2(r,y),Color(0.18,0.72,0.74,0.07+float(posmod(y,3))*0.02),2,true)
	# 远处过滤塔与检修灯。
	var center := (float(bounds[0])+float(bounds[2]))*0.52
	draw_rect(Rect2(center-90,floor_y-365,180,260),Color(0.025,0.12,0.14,0.92))
	draw_arc(Vector2(center,floor_y-365),90,PI,TAU,24,Color(0.10,0.38,0.40,0.8),12,true)
	for yy in range(int(floor_y-320),int(floor_y-125),48): draw_circle(Vector2(center+62,yy),6,Color(0.35,0.95,0.90,0.58))

func _draw_temple() -> void:
	_profile_gradient()
	var span := _span(); var l := span[0]; var r := span[1]; var floor_y := span[2]
	# 古代机械石柱和断裂横梁。
	for x in range(int(l),int(r),280):
		draw_rect(Rect2(x+38,floor_y-300,62,300),Color(0.075,0.055,0.105,0.97))
		draw_rect(Rect2(x+18,floor_y-315,102,24),Color(0.15,0.105,0.19,0.85))
		for yy in range(int(floor_y-270),int(floor_y-40),56):
			draw_circle(Vector2(x+69,yy),8,Color(0.46,0.30,0.68,0.42))
	# 星轮地标与轨道符文。
	var core := Vector2((float(bounds[0])+float(bounds[2]))*0.5,float(bounds[1])+205)
	for rr in [118.0,88.0,54.0]:
		draw_arc(core,rr,-2.8,2.8,42,Color(0.62,0.42,0.84,0.48+rr/700.0),5,true)
	for i in range(8):
		var a := TAU*float(i)/8.0
		draw_circle(core+Vector2(cos(a),sin(a))*88,7,Color(0.86,0.68,1.0,0.7))

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
