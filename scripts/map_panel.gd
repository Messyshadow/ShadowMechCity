extends Control
## 地图: 常驻小地图(右上) + M 键全屏大地图. 迷雾(未访问不显示), 当前房间高亮.

var open := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.map_changed.connect(queue_redraw)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("map_menu"):
		if not open and Game.menu_open != 0:
			return
		open = not open
		get_tree().paused = open
		Game.menu_open += (1 if open else -1)
		queue_redraw()

func _draw() -> void:
	# 小地图(右上角)
	var vp := get_viewport_rect().size
	_draw_map(Vector2(vp.x - 120, 230), 15.0, false)
	# 全屏大地图
	if open:
		draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0.02, 0.85), true)
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(vp.x * 0.5 - 80, 70), "世界地图  (M关闭)", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(0.7, 0.95, 1.0))
		# 收集度统计
		var rooms_done := Game.visited.size()
		var hearts := "生命碎片  %d / %d" % [Game.heart_pieces, Game.HEART_TOTAL]
		var hcol := Color(1.0, 0.55, 0.6) if Game.heart_pieces < Game.HEART_TOTAL else Color(1.0, 0.85, 0.4)
		draw_string(font, Vector2(vp.x * 0.5 - 80, 104), "已探索区域  %d / %d" % [rooms_done, Rooms.ROOMS.size()],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color(0.6, 0.85, 1.0))
		draw_string(font, Vector2(vp.x * 0.5 - 80, 130), hearts, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, hcol)
		_draw_map(vp * 0.5, 64.0, true)

func _draw_map(center: Vector2, cell: float, full: bool) -> void:
	if Game.current_room == "" or not Rooms.ROOMS.has(Game.current_room):
		return
	var cur: Vector2i = Rooms.ROOMS[Game.current_room]["map"]
	var font := ThemeDB.fallback_font
	# 连线
	for id in Rooms.ROOMS:
		if not Game.visited.has(id):
			continue
		var m: Vector2i = Rooms.ROOMS[id]["map"]
		var p := center + Vector2((m.x - cur.x) * cell, (m.y - cur.y) * cell)
		for d in Rooms.ROOMS[id]["doors"]:
			if Game.visited.has(d["to"]):
				var m2: Vector2i = Rooms.ROOMS[d["to"]]["map"]
				var p2 := center + Vector2((m2.x - cur.x) * cell, (m2.y - cur.y) * cell)
				draw_line(p, p2, Color(0.35, 0.55, 0.75, 0.9), 2.0)
	# 房间格
	var cs := cell * 0.62
	for id in Rooms.ROOMS:
		if not Game.visited.has(id):
			continue
		var m: Vector2i = Rooms.ROOMS[id]["map"]
		var p := center + Vector2((m.x - cur.x) * cell, (m.y - cur.y) * cell)
		var col := Color(0.55, 0.85, 1.0) if id == Game.current_room else Color(0.25, 0.4, 0.55)
		draw_rect(Rect2(p - Vector2(cs, cs) * 0.5, Vector2(cs, cs)), col, true)
		draw_rect(Rect2(p - Vector2(cs, cs) * 0.5, Vector2(cs, cs)), Color(0.8, 0.95, 1.0, 0.8), false, 2.0)
		if full:
			draw_string(font, p + Vector2(-cs * 0.5, cs * 0.5 + 16), Rooms.ROOMS[id]["name"],
				HORIZONTAL_ALIGNMENT_CENTER, cs, 16, Color(0.85, 0.92, 1.0))
