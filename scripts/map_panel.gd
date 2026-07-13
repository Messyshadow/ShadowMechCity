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
		draw_string(font, Vector2(38, 62), "世界地图  (M关闭)", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(0.7, 0.95, 1.0))
		_draw_completion(Vector2(38, 105))
		_draw_map(Vector2(vp.x * 0.68, vp.y * 0.48), 56.0, true)

func _draw_completion(origin: Vector2) -> void:
	var stats: Dictionary = Game.completion_snapshot()
	var font := ThemeDB.fallback_font
	var percent: int = stats.get("percent", 0)
	draw_string(font, origin, "世界完成度  %d%%" % percent, HORIZONTAL_ALIGNMENT_LEFT, 300, 25, Color(0.68, 0.94, 1.0))
	_draw_progress_bar(Rect2(origin + Vector2(0, 15), Vector2(300, 10)), percent / 100.0, Color(0.52, 0.72, 1.0))
	var rows := [["rooms","探索房间"],["hidden","隐藏秘室"],["chests","宝箱"],["bosses","Boss"],["weapons","武器"],["collectibles","收藏品"]]
	for i in range(rows.size()):
		var key: String = rows[i][0]; var label: String = rows[i][1]
		var data: Dictionary = stats.get(key, {"done":0,"total":0})
		var y := origin.y + 62.0 + i * 54.0
		draw_string(font, Vector2(origin.x, y), "%s  %d / %d" % [label, data["done"], data["total"]], HORIZONTAL_ALIGNMENT_LEFT, 300, 18, Color(0.78,0.88,1.0))
		var ratio := 0.0 if data["total"] <= 0 else float(data["done"]) / float(data["total"])
		_draw_progress_bar(Rect2(Vector2(origin.x, y + 10), Vector2(280, 7)), ratio, Color(0.52,0.38,0.92) if key == "hidden" else Color(0.30,0.72,0.88))
	draw_string(font, Vector2(origin.x, origin.y + 405), "◆ 紫色菱形：已发现隐藏秘室", HORIZONTAL_ALIGNMENT_LEFT, 320, 15, Color(0.72,0.52,1.0))

func _draw_progress_bar(rect: Rect2, ratio: float, color: Color) -> void:
	draw_rect(rect, Color(0.12,0.18,0.25,0.92), true)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(ratio,0.0,1.0), rect.size.y)), color, true)
	draw_rect(rect, Color(0.48,0.68,0.82,0.65), false, 1.0)

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
		var hidden_room: bool = Rooms.ROOMS[id].get("hidden_room", false)
		var col := Color(0.55, 0.85, 1.0) if id == Game.current_room else (Color(0.38,0.18,0.62) if hidden_room else Color(0.25, 0.4, 0.55))
		draw_rect(Rect2(p - Vector2(cs, cs) * 0.5, Vector2(cs, cs)), col, true)
		var outline := Color(0.82,0.58,1.0,0.92) if hidden_room else Color(0.8, 0.95, 1.0, 0.8)
		draw_rect(Rect2(p - Vector2(cs, cs) * 0.5, Vector2(cs, cs)), outline, false, 2.0)
		if hidden_room:
			draw_rect(Rect2(p - Vector2(cs, cs) * 0.5 + Vector2(4,4), Vector2(cs-8, cs-8)), Color(0.65,0.38,1.0,0.65), false, 1.0)
			var diamond := PackedVector2Array([p+Vector2(0,-9),p+Vector2(9,0),p+Vector2(0,9),p+Vector2(-9,0)])
			draw_colored_polygon(diamond, Color(0.82,0.58,1.0,0.92))
		if full:
			draw_string(font, p + Vector2(-cs * 0.5, cs * 0.5 + 16), Rooms.ROOMS[id]["name"],
				HORIZONTAL_ALIGNMENT_CENTER, cs, 16, Color(0.85, 0.92, 1.0))
