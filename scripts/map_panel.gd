extends Control
## 机械城战术图集：常驻小地图 + 七区域商业化全屏地图。

const REGION_NAMES := {
	"city": "机械中枢", "mine": "废铁矿坑", "factory": "蒸汽铸造厂",
	"water": "腐化水道", "temple": "遗迹神殿", "void": "虚空要塞", "castle": "暗影王城",
}
const REGION_CODES := {"city":"C-00","mine":"M-17","factory":"F-09","water":"W-04","temple":"R-22","void":"V-Ω","castle":"S-EX"}
const REGION_OFFSETS := {
	"city": Vector2i.ZERO, "temple": Vector2i.ZERO, "mine": Vector2i.ZERO,
	"water": Vector2i.ZERO, "void": Vector2i.ZERO,
	"factory": Vector2i(4, 0), "castle": Vector2i(6, 0),
}
const THEME_COLORS := {
	"city": Color("55d9ff"), "mine": Color("ff7b3e"), "factory": Color("ffb347"),
	"water": Color("42e0d0"), "temple": Color("c59aff"), "void": Color("777dff"), "castle": Color("d85fe8"),
}
const REGION_LABEL_POS := {
	"temple": Vector2(-2.35,-0.72), "void": Vector2(1.9,-2.23), "city": Vector2(0.0,0.72),
	"mine": Vector2(2.6,0.72), "factory": Vector2(6.7,0.72), "water": Vector2(2.2,3.18), "castle": Vector2(9.0,2.75),
}

var open := false
var debug_reveal_all := false
var selected_room_id := ""
var _full_origin := Vector2(480, 250)
var _full_step := Vector2(51, 62)
var _node_screen_positions := {}
var _pulse := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.map_changed.connect(_on_map_changed)
	set_process(true)


func _process(delta: float) -> void:
	_pulse += delta
	if open:
		queue_redraw()


func _on_map_changed() -> void:
	if selected_room_id.is_empty() or not Rooms.ROOMS.has(selected_room_id):
		selected_room_id = Game.current_room
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("map_menu"):
		if not open and Game.menu_open != 0:
			return
		_set_open(not open)
		get_viewport().set_input_as_handled()
		return
	if not open:
		return
	if event.is_action_pressed("ui_cancel"):
		_set_open(false)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion:
		var hovered := _room_at_screen(event.position)
		if hovered != "":
			selected_room_id = hovered
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var clicked := _room_at_screen(event.position)
		if clicked != "":
			selected_room_id = clicked
			queue_redraw()
	elif event.is_action_pressed("ui_left"):
		_select_direction(Vector2.LEFT)
	elif event.is_action_pressed("ui_right"):
		_select_direction(Vector2.RIGHT)
	elif event.is_action_pressed("ui_up"):
		_select_direction(Vector2.UP)
	elif event.is_action_pressed("ui_down"):
		_select_direction(Vector2.DOWN)


func force_open_for_qa(reveal_all: bool = true) -> void:
	debug_reveal_all = reveal_all
	selected_room_id = Game.current_room if Rooms.ROOMS.has(Game.current_room) else Rooms.START
	open = true
	queue_redraw()


func _set_open(value: bool) -> void:
	open = value
	if open:
		selected_room_id = Game.current_room
	get_tree().paused = open
	Game.menu_open = maxi(0, Game.menu_open + (1 if open else -1))
	queue_redraw()


func _draw() -> void:
	var vp := get_viewport_rect().size
	_draw_minimap(Vector2(vp.x - 118, 250), 15.0)
	if open:
		_draw_full_map(vp)


func _draw_minimap(center: Vector2, cell: float) -> void:
	if Game.current_room == "" or not Rooms.ROOMS.has(Game.current_room):
		return
	var current := _atlas_position(Game.current_room)
	draw_circle(center, 48.0, Color(0.01,0.03,0.06,0.72))
	draw_arc(center, 48.0, 0, TAU, 28, Color(0.28,0.78,0.92,0.42), 1.5)
	for id in Rooms.ROOMS:
		if not Game.visited.has(id):
			continue
		var delta: Vector2i = _atlas_position(id) - current
		if absi(delta.x) > 3 or absi(delta.y) > 3:
			continue
		var p := center + Vector2(delta.x, delta.y) * cell
		for door in Rooms.ROOMS[id].get("doors", []):
			var target := str(door.get("to", ""))
			if Game.visited.has(target):
				var td: Vector2i = _atlas_position(target) - current
				draw_line(p, center + Vector2(td.x,td.y)*cell, Color(0.26,0.58,0.72,0.66), 1.5)
		var color: Color = THEME_COLORS.get(str(Rooms.ROOMS[id].get("theme","city")), Color.WHITE)
		if bool(Rooms.ROOMS[id].get("hidden_room", false)):
			_draw_diamond(p, 4.5, color)
		else:
			draw_rect(Rect2(p-Vector2(3.5,3.5),Vector2(7,7)), color * (1.0 if id == Game.current_room else 0.56), true)
	if Game.current_room != "":
		draw_arc(center, 7.5 + sin(_pulse*4.0)*1.5, 0, TAU, 16, Color("eaffff"), 2.0)


func _draw_full_map(vp: Vector2) -> void:
	_node_screen_positions.clear()
	# 背板、暗角与机械框
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.005,0.01,0.025,0.965), true)
	for i in range(8):
		var alpha := 0.07 - float(i)*0.006
		draw_arc(vp*0.54, 130.0+float(i)*55.0, 0, TAU, 64, Color(0.12,0.52,0.72,alpha), 1.0)
	var outer := Rect2(24,22,vp.x-48,vp.y-44)
	draw_rect(outer, Color("102333"), false, 3.0)
	draw_line(Vector2(42,92),Vector2(vp.x-42,92),Color(0.20,0.64,0.82,0.58),2.0)
	_draw_corner(Vector2(outer.position.x,outer.position.y),Vector2(1,1))
	_draw_corner(Vector2(outer.end.x,outer.position.y),Vector2(-1,1))
	_draw_corner(Vector2(outer.position.x,outer.end.y),Vector2(1,-1))
	_draw_corner(outer.end,Vector2(-1,-1))
	var font := ThemeDB.fallback_font
	draw_string(font,Vector2(48,68),"暗影机械城·全域战术图集",HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("b8f4ff"))
	draw_string(font,Vector2(48,87),"SHADOW MECH CITY  //  QUANTUM CARTOGRAPHY NETWORK",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color(0.38,0.68,0.78))
	draw_string(font,Vector2(vp.x-330,66),"[M / Esc] 关闭   [WASD / 方向] 选择",HORIZONTAL_ALIGNMENT_LEFT,285,14,Color(0.72,0.82,0.92))
	_draw_completion_panel(Rect2(44,116,236,vp.y-166))
	_draw_atlas(Rect2(300,112,vp.x-602,vp.y-166))
	_draw_room_details(Rect2(vp.x-282,116,238,vp.y-166))


func _draw_completion_panel(rect: Rect2) -> void:
	_panel(rect, Color("17384a"))
	var font := ThemeDB.fallback_font
	var stats: Dictionary = Game.completion_snapshot()
	var percent := int(stats.get("percent",0))
	draw_string(font,rect.position+Vector2(18,32),"探索同步率",HORIZONTAL_ALIGNMENT_LEFT,140,17,Color("8defff"))
	draw_string(font,rect.position+Vector2(164,34),"%d%%"%percent,HORIZONTAL_ALIGNMENT_RIGHT,50,24,Color("ffd66b"))
	_draw_progress_bar(Rect2(rect.position+Vector2(18,46),Vector2(rect.size.x-36,9)),percent/100.0,Color("3fd6ed"))
	var rows := [["rooms","已探索房间"],["hidden","隐藏秘室"],["chests","回收宝箱"],["bosses","区域 BOSS"],["weapons","武器档案"],["collectibles","记忆核心"]]
	for i in range(rows.size()):
		var data: Dictionary = stats.get(rows[i][0],{"done":0,"total":0})
		var y := rect.position.y+91.0+float(i)*59.0
		draw_string(font,Vector2(rect.position.x+18,y),str(rows[i][1]),HORIZONTAL_ALIGNMENT_LEFT,135,15,Color(0.72,0.84,0.92))
		draw_string(font,Vector2(rect.end.x-72,y),"%d / %d"%[data["done"],data["total"]],HORIZONTAL_ALIGNMENT_RIGHT,52,15,Color(0.90,0.94,1.0))
		var ratio := 0.0 if int(data["total"])<=0 else float(data["done"])/float(data["total"])
		_draw_progress_bar(Rect2(Vector2(rect.position.x+18,y+10),Vector2(rect.size.x-36,5)),ratio,Color("a66cff") if rows[i][0]=="hidden" else Color("318ca8"))
	var legend_y := rect.end.y-92
	draw_string(font,Vector2(rect.position.x+18,legend_y),"图例",HORIZONTAL_ALIGNMENT_LEFT,80,14,Color("ffd66b"))
	draw_circle(Vector2(rect.position.x+24,legend_y+22),5,Color("57dff5")); draw_string(font,Vector2(rect.position.x+36,legend_y+27),"当前 / 存档",HORIZONTAL_ALIGNMENT_LEFT,86,12,Color(0.68,0.80,0.88))
	_draw_diamond(Vector2(rect.position.x+135,legend_y+22),6,Color("c77bff")); draw_string(font,Vector2(rect.position.x+147,legend_y+27),"秘室",HORIZONTAL_ALIGNMENT_LEFT,54,12,Color(0.68,0.80,0.88))


func _draw_atlas(rect: Rect2) -> void:
	_panel(rect, Color("17384a"))
	# 细密网格和区域光晕
	for x in range(int(rect.position.x)+18,int(rect.end.x)-10,34):
		draw_line(Vector2(x,rect.position.y+12),Vector2(x,rect.end.y-12),Color(0.10,0.30,0.40,0.18),1.0)
	for y in range(int(rect.position.y)+18,int(rect.end.y)-10,34):
		draw_line(Vector2(rect.position.x+12,y),Vector2(rect.end.x-12,y),Color(0.10,0.30,0.40,0.18),1.0)
	for theme in REGION_LABEL_POS:
		var center: Vector2 = _full_origin + Vector2(REGION_LABEL_POS[theme]) * _full_step
		var color: Color = THEME_COLORS[theme]
		draw_circle(center,52.0,Color(color.r,color.g,color.b,0.035))
		draw_arc(center,52.0,0,TAU,36,Color(color.r,color.g,color.b,0.12),1.0)
	# 先画门线，再画节点
	var drawn := {}
	for id in Rooms.ROOMS:
		var room: Dictionary = Rooms.ROOMS[id]
		var p: Vector2 = _screen_position(str(id))
		_node_screen_positions[id] = p
		for door in room.get("doors",[]):
			var to := str(door.get("to",""))
			if not Rooms.ROOMS.has(to): continue
			var id_string := str(id)
			var edge: String = id_string+">"+to if id_string<to else to+">"+id_string
			if drawn.has(edge): continue
			drawn[edge]=true
			var revealed := _is_revealed(id) and _is_revealed(to)
			var hidden_edge := bool(door.get("hidden",false)) or bool(room.get("hidden_room",false))
			var line_color := Color(0.46,0.24,0.68,0.55) if hidden_edge else Color(0.18,0.53,0.67,0.68)
			if not revealed: line_color=Color(0.13,0.22,0.29,0.32)
			if hidden_edge:
				draw_dashed_line(p, _screen_position(to), line_color, 2.0, 5.0)
			else:
				draw_line(p, _screen_position(to), line_color, 2.0)
	for id in Rooms.ROOMS:
		_draw_room_node(id,_screen_position(id))
	var font:=ThemeDB.fallback_font
	for theme in REGION_LABEL_POS:
		var p: Vector2 = _full_origin + Vector2(REGION_LABEL_POS[theme]) * _full_step
		var color:Color=THEME_COLORS[theme]
		draw_string(font,p+Vector2(-60,-60),REGION_NAMES[theme],HORIZONTAL_ALIGNMENT_CENTER,120,15,Color(color.r,color.g,color.b,0.82))
		draw_string(font,p+Vector2(-60,-44),REGION_CODES[theme],HORIZONTAL_ALIGNMENT_CENTER,120,10,Color(color.r,color.g,color.b,0.42))


func _draw_room_node(id: String, p: Vector2) -> void:
	var room: Dictionary = Rooms.ROOMS[id]
	var revealed := _is_revealed(id)
	var theme := str(room.get("theme","city"))
	var color: Color = THEME_COLORS.get(theme,Color.WHITE)
	if not revealed:
		draw_circle(p,4.0,Color(0.18,0.27,0.34,0.42))
		return
	var selected := id==selected_room_id
	var current := id==Game.current_room
	if bool(room.get("hidden_room",false)):
		_draw_diamond(p,8.0 if selected else 6.0,color)
	elif room.has("boss"):
		_draw_hex(p,9.0 if selected else 7.0,Color("ff526d") if not Game.has_item("boss_"+id) else color)
	elif room.has("save"):
		draw_circle(p,7.0 if selected else 5.5,Color(0.02,0.08,0.11,1))
		draw_arc(p,7.0 if selected else 5.5,0,TAU,16,color,2.0)
		draw_line(p+Vector2(-3,0),p+Vector2(3,0),color,2.0);draw_line(p+Vector2(0,-3),p+Vector2(0,3),color,2.0)
	else:
		draw_rect(Rect2(p-Vector2(5,5),Vector2(10,10)),Color(color.r*0.32,color.g*0.32,color.b*0.32,0.95),true)
		draw_rect(Rect2(p-Vector2(5,5),Vector2(10,10)),color,false,1.5)
	if selected:
		draw_arc(p,13.0+sin(_pulse*4.0),0,TAU,24,Color("e6fbff"),2.0)
	if current:
		draw_arc(p,18.0+sin(_pulse*5.0)*2.0,0,TAU,24,Color(color.r,color.g,color.b,0.72),2.0)


func _draw_room_details(rect: Rect2) -> void:
	_panel(rect,Color("17384a"))
	var font:=ThemeDB.fallback_font
	if selected_room_id.is_empty() or not Rooms.ROOMS.has(selected_room_id) or not _is_revealed(selected_room_id):
		draw_string(font,rect.position+Vector2(20,38),"未解析坐标",HORIZONTAL_ALIGNMENT_LEFT,rect.size.x-40,20,Color(0.52,0.64,0.72))
		return
	var room:Dictionary=Rooms.ROOMS[selected_room_id]
	var theme:=str(room.get("theme","city"));var color:Color=THEME_COLORS[theme]
	draw_string(font,rect.position+Vector2(18,28),REGION_NAMES[theme],HORIZONTAL_ALIGNMENT_LEFT,rect.size.x-36,13,color)
	draw_string(font,rect.position+Vector2(18,58),str(room["name"]),HORIZONTAL_ALIGNMENT_LEFT,rect.size.x-36,20,Color("e2f8ff"))
	draw_line(rect.position+Vector2(18,72),Vector2(rect.end.x-18,rect.position.y+72),Color(color.r,color.g,color.b,0.48),2.0)
	var status := "当前位置" if selected_room_id==Game.current_room else "已探索"
	if bool(room.get("hidden_room",false)): status="隐藏秘室·已定位"
	elif room.has("boss"): status="BOSS 已清除" if Game.has_item("boss_"+selected_room_id) else "BOSS 信号·高危"
	draw_string(font,rect.position+Vector2(18,103),status,HORIZONTAL_ALIGNMENT_LEFT,rect.size.x-36,15,Color("ffd66b") if room.has("boss") else Color(0.68,0.86,0.94))
	var tags:Array[String]=[]
	if room.has("save"): tags.append("存档塔")
	if room.has("boss"): tags.append("区域首领")
	if bool(room.get("hidden_room",false)): tags.append("秘密档案")
	if not room.get("secrets",[]).is_empty(): tags.append("收藏品")
	if not room.get("abilities",[]).is_empty(): tags.append("探索能力")
	if tags.is_empty(): tags.append("战术通道")
	draw_string(font,rect.position+Vector2(18,132),"  ·  ".join(tags),HORIZONTAL_ALIGNMENT_LEFT,rect.size.x-36,13,Color(0.54,0.72,0.82))
	draw_string(font,rect.position+Vector2(18,174),"连接通道",HORIZONTAL_ALIGNMENT_LEFT,rect.size.x-36,14,color)
	var y:=198.0
	for door in room.get("doors",[]):
		var to:=str(door.get("to",""));if not Rooms.ROOMS.has(to):continue
		var destination:="未探索区域"
		if _is_revealed(to): destination=str(Rooms.ROOMS[to]["name"])
		var prefix:="◇" if bool(door.get("hidden",false)) else "▸"
		draw_string(font,rect.position+Vector2(18,y),"%s %s"%[prefix,destination],HORIZONTAL_ALIGNMENT_LEFT,rect.size.x-36,12,Color(0.70,0.82,0.90))
		y+=25.0
	var danger:=clampi(room.get("enemies",[]).size()*18+(35 if room.has("boss") else 0),0,100)
	draw_string(font,Vector2(rect.position.x+18,rect.end.y-85),"威胁评估  %d%%"%danger,HORIZONTAL_ALIGNMENT_LEFT,rect.size.x-36,13,Color(0.70,0.82,0.90))
	_draw_progress_bar(Rect2(Vector2(rect.position.x+18,rect.end.y-70),Vector2(rect.size.x-36,7)),danger/100.0,Color("ff526d") if danger>55 else color)
	draw_string(font,Vector2(rect.position.x+18,rect.end.y-34),"鼠标悬停 / 方向键切换坐标",HORIZONTAL_ALIGNMENT_LEFT,rect.size.x-36,11,Color(0.42,0.60,0.70))


func _atlas_position(id: String) -> Vector2i:
	var room:Dictionary=Rooms.ROOMS[id]
	return Vector2i(room["map"])+Vector2i(REGION_OFFSETS.get(str(room.get("theme","city")),Vector2i.ZERO))


func _screen_position(id: String) -> Vector2:
	var atlas:=_atlas_position(id)
	return _full_origin+Vector2(atlas.x,atlas.y)*_full_step


func _is_revealed(id:String)->bool:
	return debug_reveal_all or Game.visited.has(id)


func _room_at_screen(point:Vector2)->String:
	var best:="";var distance:=15.0
	for id in _node_screen_positions:
		if not _is_revealed(id):continue
		var d:float=point.distance_to(_node_screen_positions[id])
		if d<distance:distance=d;best=id
	return best


func _select_direction(direction:Vector2)->void:
	if selected_room_id.is_empty() or not Rooms.ROOMS.has(selected_room_id):selected_room_id=Game.current_room
	var origin:=Vector2(_atlas_position(selected_room_id));var best:="";var score:=INF
	for id in Rooms.ROOMS:
		if id==selected_room_id or not _is_revealed(id):continue
		var delta:=Vector2(_atlas_position(id))-origin
		if delta.dot(direction)<=0.0:continue
		var candidate:=delta.length()+absf(delta.normalized().cross(direction))*4.0
		if candidate<score:score=candidate;best=id
	if best!="":selected_room_id=best;queue_redraw()


func _panel(rect:Rect2,border:Color)->void:
	draw_rect(rect,Color(0.015,0.035,0.055,0.88),true)
	draw_rect(rect,border,false,2.0)
	draw_line(rect.position+Vector2(8,8),rect.position+Vector2(38,8),Color(border.r*1.6,border.g*1.6,border.b*1.6,0.7),2.0)


func _draw_corner(at:Vector2,direction:Vector2)->void:
	draw_line(at,at+Vector2(direction.x*42,0),Color("55d9ff"),4.0)
	draw_line(at,at+Vector2(0,direction.y*42),Color("55d9ff"),4.0)


func _draw_progress_bar(rect:Rect2,ratio:float,color:Color)->void:
	draw_rect(rect,Color(0.07,0.13,0.18,0.95),true)
	draw_rect(Rect2(rect.position,Vector2(rect.size.x*clampf(ratio,0.0,1.0),rect.size.y)),color,true)
	draw_rect(rect,Color(0.34,0.58,0.68,0.48),false,1.0)


func _draw_diamond(center:Vector2,radius:float,color:Color)->void:
	draw_colored_polygon(PackedVector2Array([center+Vector2(0,-radius),center+Vector2(radius,0),center+Vector2(0,radius),center+Vector2(-radius,0)]),color)


func _draw_hex(center:Vector2,radius:float,color:Color)->void:
	var points:=PackedVector2Array()
	for i in range(6):
		var a:=TAU*float(i)/6.0-PI/2.0;points.append(center+Vector2(cos(a),sin(a))*radius)
	draw_colored_polygon(points,Color(color.r*0.42,color.g*0.42,color.b*0.42,0.95))
	draw_polyline(points+PackedVector2Array([points[0]]),color,2.0)
