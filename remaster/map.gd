extends Control
const World=preload("res://remaster/world_data.gd")
## Full names and explicit room graph; zoom around cursor, drag to pan.
var game: Node3D
var zoom := .7
var pan := Vector2(35,65)
var dragging := false
var nodes: Dictionary = {}
const THEMES := ["city","temple","mine","water","factory","void","castle","dawn"]
const NAMES := ["机械中枢","遗迹神殿","废铁矿坑","腐化水道","蒸汽铸造厂","虚空要塞","暗影王城","晨曦温室"]
var font: Font

func _ready() -> void:
	clip_contents=true;mouse_filter=Control.MOUSE_FILTER_STOP
	font=ThemeDB.fallback_font
	var rows:Dictionary={}
	for id in World.ROOMS:
		var d:Dictionary=World.ROOMS[id]
		var col:=THEMES.find(str(d.theme));var row:int=rows.get(d.theme,0);rows[d.theme]=row+1
		nodes[id]=Vector2(col*340,row*100)
	center_player()

func center_player() -> void:
	if nodes.has(game.room_id):
		pan=size*.5-(nodes[game.room_id]+Vector2(140,30))*zoom
		pan.x=clampf(pan.x,minf(20,size.x-2672*zoom-20),20)
		pan.y=clampf(pan.y,minf(55,size.y-800*zoom-15),55)
	queue_redraw()

func fit_all() -> void:
	zoom=minf((size.x-40)/2672.0,(size.y-75)/800.0);pan=Vector2(20,50);queue_redraw()

func set_zoom(value: float, anchor := Vector2(-1,-1)) -> void:
	if anchor.x<0:anchor=size*.5
	var before:Vector2=(anchor-pan)/zoom
	zoom=clampf(value,.32,1.7);pan=anchor-before*zoom;queue_redraw()

func clamp_pan() -> void:
	pan.x=clampf(pan.x,minf(20,size.x-2672*zoom-20),20)
	pan.y=clampf(pan.y,minf(55,size.y-800*zoom-15),55)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP and event.pressed:set_zoom(zoom*1.13,event.position);accept_event()
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN and event.pressed:set_zoom(zoom/1.13,event.position);accept_event()
		if event.button_index==MOUSE_BUTTON_LEFT:dragging=event.pressed;accept_event()
	if event is InputEventMouseMotion and dragging:pan+=event.relative;queue_redraw();accept_event()

func _draw() -> void:
	if font==null:return
	draw_rect(Rect2(Vector2.ZERO,size),Color(.026,.043,.063))
	for x in range(0,int(size.x),40):draw_line(Vector2(x,0),Vector2(x,size.y),Color(.065,.09,.11))
	for y in range(0,int(size.y),40):draw_line(Vector2(0,y),Vector2(size.x,y),Color(.065,.09,.11))
	draw_set_transform(pan,0,Vector2.ONE*zoom)
	for id in nodes:
		for door in World.ROOMS[id].get("doors",[]):
			if not nodes.has(str(door.to)):continue
			var start:Vector2=nodes[id]+Vector2(145,33);var end:Vector2=nodes[str(door.to)]+Vector2(145,33)
			draw_line(start,end,Color(.2,.31,.38,.7),2,true)
	for i in range(THEMES.size()):draw_string(font,Vector2(i*340,-30),NAMES[i],HORIZONTAL_ALIGNMENT_LEFT,-1,26,game.REGION_COLORS[THEMES[i]])
	for id in nodes:
		var d:Dictionary=World.ROOMS[id];var visited:bool=Reforged.visited.has(id)
		var color:Color=game.REGION_COLORS[d.theme]
		var rect:=Rect2(nodes[id],Vector2(292,68))
		draw_style_box(style(Color(.055,.085,.115) if visited else Color(.035,.046,.062),color if id==game.room_id else color.darkened(.62)),rect)
		var name_color:=Color(.85,.91,.94) if visited else Color(.45,.53,.6)
		draw_string(font,nodes[id]+Vector2(12,28),str(d.name),HORIZONTAL_ALIGNMENT_LEFT,-1,18,name_color)
		var tag:="已探索" if visited else "未探索"
		if d.has("boss"):tag="核心已回收" if Reforged.bosses.has(id) else "BOSS · 核心守卫"
		if d.get("hidden_room",false):tag="秘室 · 稀有战利品"
		if id=="hub":tag="赫克 · 商人 / 莉娅 · 委托"
		if id=="dawn_beacon":tag="引航灯 · "+("已重启" if Reforged.story.get("beacon_online",false) else "委托目标")
		if id==Reforged.checkpoint_room:tag+="  ◇ 存档点"
		if id==game.room_id:tag="▶ 你在这里  ·  "+tag
		draw_string(font,nodes[id]+Vector2(12,53),tag,HORIZONTAL_ALIGNMENT_LEFT,-1,14,color)

func style(bg: Color, border: Color) -> StyleBoxFlat:
	var s:=StyleBoxFlat.new();s.bg_color=bg;s.border_color=border;s.set_border_width_all(2);s.set_corner_radius_all(5);return s
