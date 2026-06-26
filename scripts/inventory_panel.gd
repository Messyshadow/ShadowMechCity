extends CanvasLayer
## 背包/装备面板 (U/I). 左:装备槽  中:物品网格  右:详情. 暂停游戏.

var open := false
var coins_label: Label
var slot_box: VBoxContainer
var grid_box: VBoxContainer
var detail_box: VBoxContainer
# 选中
var sel_kind := ""    # "inv" / "equip"
var sel_inv := -1
var sel_slot := ""

func _ready() -> void:
	layer = 22
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false
	Game.gear_changed.connect(func(): if open: _refresh())
	Game.progression_changed.connect(func(): if open: _refresh())

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0.02, 0.85)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(900, 600)
	center.add_child(panel)
	var outer := VBoxContainer.new()
	panel.add_child(outer)

	var header := HBoxContainer.new()
	var title := Label.new()
	title.text = "背包 / 装备"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.7, 0.95, 1.0))
	header.add_child(title)
	coins_label = Label.new()
	coins_label.add_theme_font_size_override("font_size", 22)
	coins_label.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	coins_label.custom_minimum_size = Vector2(560, 0)
	coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(coins_label)
	outer.add_child(header)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 16)
	outer.add_child(cols)

	# 左: 装备槽
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(240, 0)
	var lt := Label.new(); lt.text = "装备"; lt.add_theme_font_size_override("font_size", 20)
	lt.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0)); left.add_child(lt)
	slot_box = VBoxContainer.new(); slot_box.add_theme_constant_override("separation", 4)
	left.add_child(slot_box)
	cols.add_child(left)

	# 中: 物品网格
	var mid := VBoxContainer.new()
	mid.custom_minimum_size = Vector2(330, 0)
	var mt := Label.new(); mt.text = "物品"; mt.add_theme_font_size_override("font_size", 20)
	mt.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0)); mid.add_child(mt)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(330, 470)
	grid_box = VBoxContainer.new(); grid_box.add_theme_constant_override("separation", 3)
	grid_box.custom_minimum_size = Vector2(310, 0)
	scroll.add_child(grid_box); mid.add_child(scroll)
	cols.add_child(mid)

	# 右: 详情
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(290, 0)
	var rt := Label.new(); rt.text = "详情"; rt.add_theme_font_size_override("font_size", 20)
	rt.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0)); right.add_child(rt)
	detail_box = VBoxContainer.new(); detail_box.add_theme_constant_override("separation", 6)
	right.add_child(detail_box)
	cols.add_child(right)

	var hint := Label.new()
	hint.text = "U/I 或 Esc 关闭  ·  点物品装备  ·  点装备槽卸下/强化"
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	outer.add_child(hint)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inv_menu"):
		if open or Game.menu_open == 0:
			_toggle()
	elif open and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_toggle()

func _toggle() -> void:
	open = not open
	visible = open
	get_tree().paused = open
	Game.menu_open += (1 if open else -1)
	if open:
		_refresh()

func _rarity_btn(text: String, color: Color, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_color_override("font_color", color)
	b.add_theme_font_size_override("font_size", 16)
	b.pressed.connect(cb)
	return b

func _refresh() -> void:
	coins_label.text = "金币 %d" % Game.coins
	# 装备槽
	for c in slot_box.get_children():
		c.queue_free()
	for slot in ItemsData.SLOT_ORDER:
		var sname: String = ItemsData.SLOTS[slot]["name"]
		var txt: String
		var col := Color(0.6, 0.65, 0.72)
		if Game.equipped.has(slot):
			var it: Dictionary = Game.equipped[slot]
			txt = "%s: %s+%d" % [sname, it["name"], int(it.get("lv", 0))]
			col = ItemsData.rarity_color(int(it["rarity"]))
		else:
			txt = "%s: —" % sname
		slot_box.add_child(_rarity_btn(txt, col, func(): _select_equip(slot)))
	# 物品列表
	for c in grid_box.get_children():
		c.queue_free()
	if Game.inventory.is_empty():
		var e := Label.new(); e.text = "(空)"; e.add_theme_color_override("font_color", Color(0.6, 0.65, 0.72))
		grid_box.add_child(e)
	for i in range(Game.inventory.size()):
		var it: Dictionary = Game.inventory[i]
		var col := ItemsData.rarity_color(int(it["rarity"]))
		var idx := i
		grid_box.add_child(_rarity_btn("%s+%d" % [it["name"], int(it.get("lv", 0))], col, func(): _select_inv(idx)))
	_refresh_detail()

func _select_inv(i: int) -> void:
	sel_kind = "inv"; sel_inv = i; sel_slot = ""
	_refresh_detail()

func _select_equip(slot: String) -> void:
	if not Game.equipped.has(slot):
		return
	sel_kind = "equip"; sel_slot = slot; sel_inv = -1
	_refresh_detail()

func _current_item() -> Dictionary:
	if sel_kind == "inv" and sel_inv >= 0 and sel_inv < Game.inventory.size():
		return Game.inventory[sel_inv]
	if sel_kind == "equip" and Game.equipped.has(sel_slot):
		return Game.equipped[sel_slot]
	return {}

func _refresh_detail() -> void:
	for c in detail_box.get_children():
		c.queue_free()
	var it := _current_item()
	if it.is_empty():
		var l := Label.new(); l.text = "选择一件装备查看"; l.add_theme_color_override("font_color", Color(0.6, 0.65, 0.72))
		detail_box.add_child(l)
		return
	var rd: Dictionary = ItemsData.RARITY[int(it["rarity"])]
	var name_l := Label.new()
	name_l.text = "%s +%d" % [it["name"], int(it.get("lv", 0))]
	name_l.add_theme_font_size_override("font_size", 22)
	name_l.add_theme_color_override("font_color", ItemsData.rarity_color(int(it["rarity"])))
	detail_box.add_child(name_l)
	var r_l := Label.new()
	r_l.text = "%s · %s" % [rd["name"], ItemsData.SLOTS[it["slot"]]["name"]]
	r_l.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	detail_box.add_child(r_l)
	for stat in ["atk", "def", "hp", "crit", "ls", "spd"]:
		var v := ItemsData.value(it, stat)
		if v > 0.0:
			var sl := Label.new()
			sl.text = ItemsData.stat_text(stat, v)
			sl.add_theme_font_size_override("font_size", 17)
			sl.add_theme_color_override("font_color", Color(0.7, 1.0, 0.8))
			detail_box.add_child(sl)
	# 操作按钮
	var sp := Control.new(); sp.custom_minimum_size = Vector2(0, 10); detail_box.add_child(sp)
	if sel_kind == "inv":
		var eb := Button.new(); eb.text = "装备"; eb.custom_minimum_size = Vector2(0, 40)
		eb.pressed.connect(func(): Game.equip_item(sel_inv); sel_kind = ""; _refresh())
		detail_box.add_child(eb)
	else:
		var ub := Button.new(); ub.text = "卸下"; ub.custom_minimum_size = Vector2(0, 40)
		ub.pressed.connect(func(): Game.unequip(sel_slot); sel_kind = ""; _refresh())
		detail_box.add_child(ub)
	var cost := ItemsData.enhance_cost(it)
	var hb := Button.new()
	hb.text = "强化 +%d  (花费%d金币)" % [int(it.get("lv", 0)) + 1, cost]
	hb.custom_minimum_size = Vector2(0, 40)
	hb.disabled = Game.coins < cost
	hb.pressed.connect(func(): Game.enhance(it); _refresh())
	detail_box.add_child(hb)
