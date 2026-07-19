extends CanvasLayer
## 13A 分类背包：左侧角色装备、中部稳定索引网格、右侧属性对比。

const PANEL_SIZE := Vector2(1200, 650)
const SORT_MODES := ["稀有度", "等级", "名称"]

var open := false
var current_category := "防具"
var sort_mode := "稀有度"
var filtered_entries: Array = [] # {source_index, item}
var selected_kind := ""
var selected_source_index := -1
var selected_slot := ""
var category_buttons: Dictionary = {}

var coins_label: Label
var grid: GridContainer
var empty_label: Label
var detail_title: Label
var detail_meta: Label
var detail_text: RichTextLabel
var action_box: VBoxContainer
var preview: CharacterEquipmentPreview
var sort_select: OptionButton

func _ready() -> void:
	layer = 22
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false
	Game.gear_changed.connect(_on_data_changed)
	Game.progression_changed.connect(_on_data_changed)

func _panel_style(border: Color, background: Color = Color(0.022, 0.038, 0.062, 0.98)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	return style

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.004, 0.007, 0.015, 0.92)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = PANEL_SIZE
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.42, 0.65, 0.78)))
	center.add_child(panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 6)
	panel.add_child(outer)
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 42
	outer.add_child(header)
	var title := Label.new()
	title.text = "机械工坊 · 装备仓库"
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Color(0.7, 0.95, 1.0))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	sort_select = OptionButton.new()
	sort_select.custom_minimum_size = Vector2(130, 34)
	for mode in SORT_MODES:
		sort_select.add_item("排序 · " + mode)
	sort_select.item_selected.connect(_on_sort_selected)
	header.add_child(sort_select)
	coins_label = Label.new()
	coins_label.custom_minimum_size = Vector2(220, 0)
	coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	coins_label.add_theme_font_size_override("font_size", 17)
	coins_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.38))
	header.add_child(coins_label)
	var category_row := HBoxContainer.new()
	category_row.alignment = BoxContainer.ALIGNMENT_CENTER
	category_row.add_theme_constant_override("separation", 7)
	outer.add_child(category_row)
	for category_name in ItemsData.CATEGORIES:
		var button := Button.new()
		button.text = category_name
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(112, 34)
		button.pressed.connect(_select_category.bind(category_name))
		UI.style_button(button)
		category_row.add_child(button)
		category_buttons[category_name] = button
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 9)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(columns)
	var left_panel := PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(326, 500)
	left_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.2, 0.48, 0.63, 0.8)))
	columns.add_child(left_panel)
	var left_v := VBoxContainer.new()
	left_panel.add_child(left_v)
	var left_title := Label.new()
	left_title.text = "装备投影 · EQUIPMENT"
	left_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left_title.add_theme_font_size_override("font_size", 18)
	left_title.add_theme_color_override("font_color", Color(0.62, 0.9, 1.0))
	left_v.add_child(left_title)
	preview = CharacterEquipmentPreview.new()
	preview.slot_selected.connect(_select_equipped)
	left_v.add_child(preview)
	var equipment_hint := RichTextLabel.new()
	equipment_hint.bbcode_enabled = true
	equipment_hint.fit_content = true
	equipment_hint.text = "[color=#6f8497]点击六个槽位查看已装备物；角色模型仅显示真实武器，护甲以槽位与色调标记。[/color]"
	equipment_hint.add_theme_font_size_override("normal_font_size", 14)
	left_v.add_child(equipment_hint)
	var quick_title := Label.new()
	quick_title.text = "快捷消耗栏 · 预留"
	quick_title.add_theme_font_size_override("font_size", 15)
	left_v.add_child(quick_title)
	var quick_row := HBoxContainer.new()
	quick_row.alignment = BoxContainer.ALIGNMENT_CENTER
	for index in range(4):
		var quick := Button.new()
		quick.text = "%d\n—" % [index + 1]
		quick.disabled = true
		quick.custom_minimum_size = Vector2(62, 48)
		quick_row.add_child(quick)
	left_v.add_child(quick_row)
	var middle_panel := PanelContainer.new()
	middle_panel.custom_minimum_size = Vector2(482, 500)
	middle_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.22, 0.46, 0.58, 0.8)))
	columns.add_child(middle_panel)
	var middle_v := VBoxContainer.new()
	middle_panel.add_child(middle_v)
	var inventory_title := Label.new()
	inventory_title.text = "库存网格 · INVENTORY"
	inventory_title.add_theme_font_size_override("font_size", 18)
	inventory_title.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	middle_v.add_child(inventory_title)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(456, 430)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle_v.add_child(scroll)
	grid = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	grid.custom_minimum_size.x = 440
	scroll.add_child(grid)
	empty_label = Label.new()
	empty_label.custom_minimum_size = Vector2(440, 320)
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	empty_label.add_theme_font_size_override("font_size", 18)
	empty_label.add_theme_color_override("font_color", Color(0.48, 0.6, 0.7))
	grid.add_child(empty_label)
	var right_panel := PanelContainer.new()
	right_panel.custom_minimum_size = Vector2(350, 500)
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.42, 0.5, 0.64, 0.85)))
	columns.add_child(right_panel)
	var right_v := VBoxContainer.new()
	right_v.add_theme_constant_override("separation", 5)
	right_panel.add_child(right_v)
	detail_title = Label.new()
	detail_title.add_theme_font_size_override("font_size", 22)
	detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_v.add_child(detail_title)
	detail_meta = Label.new()
	detail_meta.add_theme_font_size_override("font_size", 14)
	detail_meta.add_theme_color_override("font_color", Color(0.68, 0.76, 0.86))
	right_v.add_child(detail_meta)
	detail_text = RichTextLabel.new()
	detail_text.bbcode_enabled = true
	detail_text.custom_minimum_size = Vector2(320, 320)
	detail_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_text.add_theme_font_size_override("normal_font_size", 15)
	right_v.add_child(detail_text)
	action_box = VBoxContainer.new()
	action_box.add_theme_constant_override("separation", 5)
	right_v.add_child(action_box)
	var hint := Label.new()
	hint.text = "U / I / Esc 关闭   ·   鼠标或方向键选择   ·   Enter 确认"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.62, 0.72, 0.82))
	outer.add_child(hint)
	_select_category(current_category)

func _on_data_changed() -> void:
	if open:
		_refresh()

func _on_sort_selected(index: int) -> void:
	sort_mode = SORT_MODES[clampi(index, 0, SORT_MODES.size() - 1)]
	_refresh_grid()

func _select_category(category_name: String) -> void:
	if not ItemsData.CATEGORIES.has(category_name):
		return
	current_category = category_name
	selected_kind = ""
	selected_source_index = -1
	selected_slot = ""
	for name in category_buttons:
		category_buttons[name].button_pressed = name == current_category
	_refresh_grid()

func _sort_filtered() -> void:
	filtered_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ai: Dictionary = a["item"]
		var bi: Dictionary = b["item"]
		if sort_mode == "等级":
			return int(ai.get("lv", 0)) > int(bi.get("lv", 0))
		if sort_mode == "名称":
			return str(ai.get("name", "")) < str(bi.get("name", ""))
		var rarity_a := int(ai.get("rarity", 0))
		var rarity_b := int(bi.get("rarity", 0))
		if rarity_a == rarity_b:
			return int(a["source_index"]) < int(b["source_index"])
		return rarity_a > rarity_b
	)

func _refresh() -> void:
	coins_label.text = "金币 %d   ·   容量 %d / 100" % [Game.coins, Game.inventory.size()]
	preview.refresh()
	_refresh_grid()

func _refresh_grid() -> void:
	if grid == null:
		return
	for child in grid.get_children():
		child.queue_free()
	filtered_entries.clear()
	for source_index in range(Game.inventory.size()):
		var item: Dictionary = Game.inventory[source_index]
		if ItemsData.category(item) == current_category:
			filtered_entries.append({"source_index": source_index, "item": item})
	_sort_filtered()
	if filtered_entries.is_empty():
		empty_label = Label.new()
		empty_label.custom_minimum_size = Vector2(440, 320)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.text = _empty_message(current_category)
		empty_label.add_theme_font_size_override("font_size", 18)
		empty_label.add_theme_color_override("font_color", Color(0.48, 0.6, 0.7))
		grid.add_child(empty_label)
	else:
		for entry in filtered_entries:
			grid.add_child(_item_button(entry))
	if selected_kind == "inventory" and _entry_for_source(selected_source_index).is_empty():
		selected_kind = ""
		selected_source_index = -1
	_refresh_detail()

func _item_button(entry: Dictionary) -> Button:
	var item: Dictionary = entry["item"]
	var source_index := int(entry["source_index"])
	var button := Button.new()
	button.custom_minimum_size = Vector2(82, 82)
	button.text = "%s\n%s\n+%d" % [_item_glyph(item), str(item.get("name", "未命名")).left(7), int(item.get("lv", 0))]
	button.tooltip_text = str(item.get("name", "物品"))
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", ItemsData.rarity_color(int(item.get("rarity", 0))))
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color(0.035, 0.055, 0.085, 0.98)
	frame.border_color = ItemsData.rarity_color(int(item.get("rarity", 0)))
	frame.set_border_width_all(2)
	frame.set_corner_radius_all(7)
	button.add_theme_stylebox_override("normal", frame)
	button.pressed.connect(_select_inventory.bind(source_index))
	UI.style_button(button)
	return button

func _item_glyph(item: Dictionary) -> String:
	match ItemsData.category(item):
		"武器": return "⚔"
		"饰品": return "◆"
		"消耗品": return "◉"
		"材料": return "⬡"
		"任务": return "✦"
	return "▣"

func _empty_message(category_name: String) -> String:
	var messages := {
		"武器":"武器由角色装备栏管理。\n双刀、长枪与弓弩将在 13B 加入掉落。",
		"消耗品":"暂未携带消耗品。\n快捷栏已为后续战斗药剂预留。",
		"材料":"尚未取得强化材料。\n探索精英房与隐藏区域可获得。",
		"任务":"当前没有可放入仓库的任务道具。",
	}
	return messages.get(category_name, "该分类目前为空。\n继续探索机械城可获得对应物品。")

func _entry_for_source(source_index: int) -> Dictionary:
	for entry in filtered_entries:
		if int(entry["source_index"]) == source_index:
			return entry
	return {}

func _select_inventory(source_index: int) -> void:
	if source_index < 0 or source_index >= Game.inventory.size():
		return
	selected_kind = "inventory"
	selected_source_index = source_index
	selected_slot = ""
	_refresh_detail()

func _select_equipped(slot: String) -> void:
	if not Game.equipped.has(slot):
		return
	selected_kind = "equipped"
	selected_slot = slot
	selected_source_index = -1
	_refresh_detail()

func _current_item() -> Dictionary:
	if selected_kind == "inventory" and selected_source_index >= 0 and selected_source_index < Game.inventory.size():
		return Game.inventory[selected_source_index]
	if selected_kind == "equipped" and Game.equipped.has(selected_slot):
		return Game.equipped[selected_slot]
	return {}

func _comparison_item(item: Dictionary) -> Dictionary:
	var slot := str(item.get("slot", ""))
	return Game.equipped.get(slot, {}) if slot != "" else {}

func _refresh_detail() -> void:
	for child in action_box.get_children():
		child.queue_free()
	var item := _current_item()
	if item.is_empty():
		detail_title.text = "选择物品"
		detail_title.add_theme_color_override("font_color", Color(0.65, 0.78, 0.86))
		detail_meta.text = "查看属性、来源与装备对比"
		detail_text.text = "[color=#72879a]物品详情会在这里显示。\n\n不同颜色代表稀有度；所有增减同时显示带符号数值，不只依赖颜色。[/color]"
		return
	var rarity := int(item.get("rarity", 0))
	detail_title.text = "%s  +%d" % [str(item.get("name", "未命名物品")), int(item.get("lv", 0))]
	detail_title.add_theme_color_override("font_color", ItemsData.rarity_color(rarity))
	var slot_name: String = str(ItemsData.SLOTS.get(str(item.get("slot", "")), {}).get("name", ItemsData.category(item)))
	detail_meta.text = "%s · %s   |   来源：%s" % [ItemsData.RARITY[clampi(rarity, 0, 3)]["name"], slot_name, item.get("source", "机械城探索")]
	var comparison := _comparison_item(item)
	var lines: Array[String] = ["[color=#8eeaff]属性与装备对比[/color]"]
	var has_stats := false
	for row in ItemCompare.compare(item, comparison):
		if is_zero_approx(float(row["candidate"])) and is_zero_approx(float(row["current"])):
			continue
		has_stats = true
		var key := str(row["key"])
		var delta := float(row["delta"])
		var tone_color := "#73e6a2" if delta > 0.0 else ("#ff7b7b" if delta < 0.0 else "#a8b7c5")
		var value_text := _format_stat_value(key, float(row["candidate"]))
		var delta_text := _format_delta(key, delta)
		lines.append("%s  %s   [color=%s]%s[/color]" % [row["label"], value_text, tone_color, delta_text])
	if not has_stats:
		lines.append("[color=#718596]暂无战斗属性[/color]")
	lines.append("\n[color=#ffd36e]说明[/color]\n%s" % item.get("description", "可装备并强化的机械城遗物。"))
	detail_text.text = "\n".join(lines)
	if selected_kind == "inventory" and item.has("slot"):
		var equip_button := Button.new()
		equip_button.text = "装备到 %s" % slot_name
		equip_button.custom_minimum_size.y = 38
		equip_button.pressed.connect(_equip_selected)
		UI.style_button(equip_button)
		action_box.add_child(equip_button)
	elif selected_kind == "equipped":
		var unequip_button := Button.new()
		unequip_button.text = "卸下 %s" % slot_name
		unequip_button.custom_minimum_size.y = 38
		unequip_button.pressed.connect(_unequip_selected)
		UI.style_button(unequip_button)
		action_box.add_child(unequip_button)
	if item.has("rarity") and item.has("slot"):
		var cost := ItemsData.enhance_cost(item)
		var enhance_button := Button.new()
		enhance_button.text = "强化至 +%d   ·   %d 金币" % [int(item.get("lv", 0)) + 1, cost]
		enhance_button.disabled = Game.coins < cost
		enhance_button.custom_minimum_size.y = 36
		enhance_button.pressed.connect(_enhance_selected)
		UI.style_button(enhance_button)
		action_box.add_child(enhance_button)

func _format_stat_value(key: String, value: float) -> String:
	if key in ["crit", "spd"]:
		return "%d%%" % int(round(value * 100.0))
	return "%d" % int(round(value))

func _format_delta(key: String, delta: float) -> String:
	if is_zero_approx(delta):
		return "±0"
	if key in ["crit", "spd"]:
		return "%+d%%" % int(round(delta * 100.0))
	return "%+d" % int(round(delta))

func _equip_selected() -> void:
	var source_index := selected_source_index
	selected_kind = ""
	selected_source_index = -1
	Game.equip_item(source_index)
	_refresh()

func _unequip_selected() -> void:
	var slot := selected_slot
	selected_kind = ""
	selected_slot = ""
	Game.unequip(slot)
	_refresh()

func _enhance_selected() -> void:
	var item := _current_item()
	if not item.is_empty():
		Game.enhance(item)
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inv_menu"):
		if open or Game.menu_open == 0:
			_toggle()
		get_viewport().set_input_as_handled()
	elif open and event.is_action_pressed("ui_cancel"):
		_toggle()
		get_viewport().set_input_as_handled()

func _toggle() -> void:
	open = not open
	visible = open
	get_tree().paused = open
	Game.menu_open = maxi(0, Game.menu_open + (1 if open else -1))
	if open:
		_refresh()

func open_for_qa(category: String, index: int) -> void:
	if not open:
		_toggle()
	_select_category(category)
	if index >= 0 and index < filtered_entries.size():
		_select_inventory(int(filtered_entries[index]["source_index"]))
