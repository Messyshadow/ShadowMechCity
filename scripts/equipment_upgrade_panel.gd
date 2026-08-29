class_name EquipmentUpgradePanel
extends CanvasLayer
## 11.2b 量子装备升级台：分类选择、属性报价、二次确认、投射演出和持久化。

signal open_changed(value: bool)

const EquipmentPatchData = preload("res://scripts/equipment_patch_data.gd")
const QuantumUpgradeVisualScript = preload("res://scripts/quantum_upgrade_visual.gd")
const CATEGORIES := ["全部装备", "防具", "饰品"]
const DEFENSE_SLOTS := ["helmet", "armor", "gloves", "boots"]
const ACCESSORY_SLOTS := ["ring", "amulet"]
const STAT_NAMES := {"atk":"攻击", "def":"防御", "hp":"生命", "crit":"暴击", "ls":"吸血", "spd":"速度"}

var is_open := false
var current_category := "全部装备"
var selected_item_id := ""
var entries: Array[Dictionary] = []
var category_buttons := {}
var item_list: VBoxContainer
var coins_label: Label
var detail_title: Label
var detail_meta: Label
var detail_stats: RichTextLabel
var status_label: Label
var request_button: Button
var confirm_box: VBoxContainer
var visual: QuantumUpgradeVisual
var _projecting := false

func _ready() -> void:
	layer = 28
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false
	Game.gear_changed.connect(_refresh)
	Game.progression_changed.connect(_refresh)

func _panel_style(border: Color, background := Color(0.018, 0.032, 0.055, 0.985), width := 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(10)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.002, 0.006, 0.014, 0.94)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1210, 680)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("39c8f4"), Color("07111f"), 3))
	center.add_child(panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 7)
	panel.add_child(outer)
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 45
	outer.add_child(header)
	var title := Label.new()
	title.text = "轨道量子升级台 · ORBITAL PATCH BAY"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Color("a9efff"))
	header.add_child(title)
	coins_label = Label.new()
	coins_label.custom_minimum_size.x = 250
	coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	coins_label.add_theme_font_size_override("font_size", 19)
	coins_label.add_theme_color_override("font_color", Color("ffd85e"))
	header.add_child(coins_label)
	var categories := HBoxContainer.new()
	categories.alignment = BoxContainer.ALIGNMENT_CENTER
	categories.add_theme_constant_override("separation", 9)
	outer.add_child(categories)
	for category in CATEGORIES:
		var button := Button.new()
		button.text = category
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(150, 38)
		button.pressed.connect(_select_category.bind(category))
		UI.style_button(button)
		categories.add_child(button)
		category_buttons[category] = button
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 9)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(columns)
	# 左列：按稳定实例 ID 选择装备。
	var left := PanelContainer.new()
	left.custom_minimum_size = Vector2(300, 535)
	left.add_theme_stylebox_override("panel", _panel_style(Color("24597a")))
	columns.add_child(left)
	var left_v := VBoxContainer.new()
	left_v.add_theme_constant_override("separation", 6)
	left.add_child(left_v)
	var left_title := Label.new()
	left_title.text = "装备链路 · HARDWARE"
	left_title.add_theme_font_size_override("font_size", 18)
	left_title.add_theme_color_override("font_color", Color("75ddff"))
	left_v.add_child(left_title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_v.add_child(scroll)
	item_list = VBoxContainer.new()
	item_list.custom_minimum_size.x = 266
	item_list.add_theme_constant_override("separation", 5)
	scroll.add_child(item_list)
	# 中列：投射演出。
	var middle := PanelContainer.new()
	middle.custom_minimum_size = Vector2(475, 535)
	middle.add_theme_stylebox_override("panel", _panel_style(Color("277da2")))
	columns.add_child(middle)
	var middle_v := VBoxContainer.new()
	middle.add_child(middle_v)
	var visual_title := Label.new()
	visual_title.text = "卫星储能量子投射"
	visual_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	visual_title.add_theme_font_size_override("font_size", 18)
	visual_title.add_theme_color_override("font_color", Color("a6f2ff"))
	middle_v.add_child(visual_title)
	visual = QuantumUpgradeVisualScript.new()
	visual.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle_v.add_child(visual)
	var protocol := RichTextLabel.new()
	protocol.bbcode_enabled = true
	protocol.fit_content = true
	protocol.text = "[color=#6c8fa5]轨道链路[/color]  ONLINE  ·  [color=#6c8fa5]硬件沙箱[/color]  ISOLATED\n升级不会改变装备身份；确认后立即扣款并写入存档。"
	protocol.add_theme_font_size_override("normal_font_size", 14)
	middle_v.add_child(protocol)
	# 右列：报价和确认状态机。
	var right := PanelContainer.new()
	right.custom_minimum_size = Vector2(390, 535)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_stylebox_override("panel", _panel_style(Color("536c8c")))
	columns.add_child(right)
	var right_v := VBoxContainer.new()
	right_v.add_theme_constant_override("separation", 7)
	right.add_child(right_v)
	detail_title = Label.new()
	detail_title.add_theme_font_size_override("font_size", 23)
	detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_v.add_child(detail_title)
	detail_meta = Label.new()
	detail_meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_meta.add_theme_font_size_override("font_size", 15)
	detail_meta.add_theme_color_override("font_color", Color("90a8bb"))
	right_v.add_child(detail_meta)
	detail_stats = RichTextLabel.new()
	detail_stats.bbcode_enabled = true
	detail_stats.custom_minimum_size = Vector2(350, 258)
	detail_stats.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_stats.add_theme_font_size_override("normal_font_size", 16)
	right_v.add_child(detail_stats)
	status_label = Label.new()
	status_label.custom_minimum_size.y = 50
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 16)
	right_v.add_child(status_label)
	request_button = Button.new()
	request_button.text = "请求卫星投射"
	request_button.custom_minimum_size.y = 43
	request_button.pressed.connect(_request_projection)
	UI.style_button(request_button)
	right_v.add_child(request_button)
	confirm_box = VBoxContainer.new()
	confirm_box.add_theme_constant_override("separation", 6)
	right_v.add_child(confirm_box)
	var confirm_hint := Label.new()
	confirm_hint.text = "高能投射不可撤销，是否确认升级？"
	confirm_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_hint.add_theme_color_override("font_color", Color("ffd47a"))
	confirm_box.add_child(confirm_hint)
	var confirm_row := HBoxContainer.new()
	confirm_row.alignment = BoxContainer.ALIGNMENT_CENTER
	confirm_box.add_child(confirm_row)
	var confirm := Button.new()
	confirm.text = "确认升级"
	confirm.custom_minimum_size = Vector2(150, 40)
	confirm.pressed.connect(_confirm_projection)
	UI.style_button(confirm)
	confirm_row.add_child(confirm)
	var cancel := Button.new()
	cancel.text = "取消"
	cancel.custom_minimum_size = Vector2(120, 40)
	cancel.pressed.connect(_cancel_confirmation)
	UI.style_button(cancel)
	confirm_row.add_child(cancel)
	confirm_box.visible = false
	var footer := Label.new()
	footer.text = "Esc 关闭  ·  鼠标/方向键选择  ·  Enter 确认"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 14)
	footer.add_theme_color_override("font_color", Color("7690a5"))
	outer.add_child(footer)

func _unhandled_input(event: InputEvent) -> void:
	if is_open and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("inventory")):
		close_panel()
		get_viewport().set_input_as_handled()

func open_panel() -> void:
	if is_open:
		return
	is_open = true
	visible = true
	Game.menu_open += 1
	_refresh()
	open_changed.emit(true)

func close_panel() -> void:
	if not is_open or _projecting:
		return
	is_open = false
	visible = false
	confirm_box.visible = false
	Game.menu_open = maxi(0, Game.menu_open - 1)
	open_changed.emit(false)

func _select_category(category: String) -> void:
	if not CATEGORIES.has(category):
		return
	current_category = category
	for key in category_buttons:
		category_buttons[key].button_pressed = key == category
	selected_item_id = ""
	_refresh()

func _matches_category(item: Dictionary) -> bool:
	var slot := str(item.get("slot", ""))
	if current_category == "防具": return DEFENSE_SLOTS.has(slot)
	if current_category == "饰品": return ACCESSORY_SLOTS.has(slot)
	return true

func _collect_entries() -> void:
	entries.clear()
	for slot in Game.equipped:
		var item = Game.equipped[slot]
		if item is Dictionary and EquipmentPatchData.is_equipment(item) and _matches_category(item):
			entries.append({"item": item, "equipped": true, "slot": str(slot)})
	for item in Game.inventory:
		if item is Dictionary and EquipmentPatchData.is_equipment(item) and _matches_category(item):
			entries.append({"item": item, "equipped": false, "slot": str(item.get("slot", ""))})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if bool(a["equipped"]) != bool(b["equipped"]): return bool(a["equipped"])
		return int(a["item"].get("rarity", 0)) > int(b["item"].get("rarity", 0)))

func _refresh() -> void:
	if not is_instance_valid(item_list):
		return
	coins_label.text = "金币 %d  ·  安全链路 ONLINE" % Game.coins
	_collect_entries()
	for child in item_list.get_children():
		child.queue_free()
	if entries.is_empty():
		var empty := Label.new()
		empty.text = "此分类没有可升级装备\n请先探索或装备战利品"
		empty.custom_minimum_size = Vector2(260, 150)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color", Color("647b8d"))
		item_list.add_child(empty)
		selected_item_id = ""
	else:
		var found_selected := false
		for entry in entries:
			var item: Dictionary = entry["item"]
			var item_instance_id := str(item.get("item_instance_id", ""))
			if item_instance_id == selected_item_id: found_selected = true
			var button := Button.new()
			var prefix := "◆ 装备中  " if bool(entry["equipped"]) else "◇ 库存    "
			button.text = "%s%s\n   %s · PATCH %d" % [prefix, item.get("name", "未命名装备"), EquipmentPatchData.QUALITY_NAMES.get(str(item.get("quality", "standard")), "标准"), int(item.get("patch_level", 0))]
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.custom_minimum_size = Vector2(264, 63)
			button.pressed.connect(_select_item.bind(item_instance_id))
			UI.style_button(button)
			item_list.add_child(button)
		if not found_selected:
			selected_item_id = str(entries[0]["item"].get("item_instance_id", ""))
	_refresh_detail()

func _select_item(item_instance_id: String) -> void:
	selected_item_id = item_instance_id
	confirm_box.visible = false
	request_button.visible = true
	_refresh_detail()

func _selected_item() -> Dictionary:
	return Game.find_equipment_by_id(selected_item_id)

func _refresh_detail() -> void:
	coins_label.text = "金币 %d  ·  安全链路 ONLINE" % Game.coins
	var item := _selected_item()
	request_button.disabled = item.is_empty() or _projecting
	if item.is_empty():
		detail_title.text = "未选择硬件"
		detail_meta.text = "选择左侧装备以建立量子链路"
		detail_stats.text = "[color=#637789]等待稳定装备 ID…[/color]"
		status_label.text = ""
		visual.set_state("idle", "等待装备接入")
		return
	var quote := EquipmentPatchData.upgrade_quote(item)
	var preview := EquipmentPatchData.attribute_preview(item)
	var brand: Dictionary = EquipmentPatchData.BRANDS.get(str(item.get("brand_id", "")), {})
	var accent: Color = brand.get("accent", Color("57dcff"))
	detail_title.text = str(item.get("name", "未命名装备"))
	detail_title.add_theme_color_override("font_color", accent.lightened(0.2))
	detail_meta.text = "%s · %s\n实例 %s" % [brand.get("name", "未知厂商"), brand.get("focus", "通用协议"), selected_item_id]
	var lines := PackedStringArray(["[color=#9db4c7]属性增益预览[/color]"])
	var before: Dictionary = preview["before"]
	var after: Dictionary = preview["after"]
	for stat in EquipmentPatchData.STAT_KEYS:
		var old_value := float(before.get(stat, 0.0))
		var new_value := float(after.get(stat, 0.0))
		if old_value != 0.0 or new_value != 0.0:
			lines.append("%s  %.2f  [color=#69f3b0]→ %.2f[/color]" % [STAT_NAMES.get(stat, stat), old_value, new_value])
	lines.append("\n[color=#ffd45f]PATCH %d → %d[/color]" % [quote["from_level"], quote["to_level"]])
	lines.append("本次投射费用  [color=#ffd45f]%d 金币[/color]" % int(quote["cost"]))
	detail_stats.text = "\n".join(lines)
	status_label.text = "余额充足，可请求轨道卫星锁定。" if Game.coins >= int(quote["cost"]) else "余额不足：还需 %d 金币" % (int(quote["cost"]) - Game.coins)
	status_label.add_theme_color_override("font_color", Color("7ee9af") if Game.coins >= int(quote["cost"]) else Color("ff7186"))
	visual.set_state("idle", str(item.get("name", "装备")), accent)

func _request_projection() -> void:
	var item := _selected_item()
	if item.is_empty(): return
	var quote := EquipmentPatchData.upgrade_quote(item)
	var brand: Dictionary = EquipmentPatchData.BRANDS.get(str(item.get("brand_id", "")), {})
	var accent: Color = brand.get("accent", Color("57dcff"))
	if Game.coins < int(quote["cost"]):
		confirm_box.visible = false
		request_button.visible = true
		status_label.text = "余额不足 · 投射请求已拒绝（需要 %d 金币）" % int(quote["cost"])
		status_label.add_theme_color_override("font_color", Color("ff7186"))
		visual.set_state("rejected", str(item.get("name", "装备")), accent)
		return
	confirm_box.visible = true
	request_button.visible = false
	status_label.text = "报价已锁定：%d 金币。请进行第二次确认。" % int(quote["cost"])
	status_label.add_theme_color_override("font_color", Color("ffd47a"))
	visual.set_state("confirm", str(item.get("name", "装备")), accent)

func _cancel_confirmation() -> void:
	confirm_box.visible = false
	request_button.visible = true
	status_label.text = "已取消，本次报价未扣款。"
	_refresh_detail()

func _confirm_projection() -> void:
	if _projecting or _selected_item().is_empty(): return
	_projecting = true
	confirm_box.visible = false
	request_button.visible = false
	request_button.disabled = true
	var item := _selected_item()
	var brand: Dictionary = EquipmentPatchData.BRANDS.get(str(item.get("brand_id", "")), {})
	var accent: Color = brand.get("accent", Color("57dcff"))
	status_label.text = "卫星储能已释放 · 正在写入核心补丁…"
	status_label.add_theme_color_override("font_color", Color("72e9ff"))
	visual.set_state("projecting", str(item.get("name", "装备")), accent)
	await get_tree().create_timer(0.85, true).timeout
	var result := Game.apply_equipment_patch(selected_item_id)
	_projecting = false
	if bool(result.get("ok", false)):
		status_label.text = "升级完成 · 补丁已持久化，剩余金币 %d" % Game.coins
		status_label.add_theme_color_override("font_color", Color("70f3aa"))
		visual.set_state("success", str(item.get("name", "装备")), accent)
	else:
		status_label.text = "升级失败：%s" % str(result.get("reason", "unknown"))
		status_label.add_theme_color_override("font_color", Color("ff7186"))
		visual.set_state("rejected", str(item.get("name", "装备")), accent)
	request_button.disabled = false
	request_button.visible = true
	coins_label.text = "金币 %d  ·  安全链路 ONLINE" % Game.coins

func open_for_qa(state: String = "preview") -> void:
	open_panel()
	if entries.is_empty(): return
	var item := _selected_item()
	if state == "confirm":
		_request_projection()
	elif state == "insufficient":
		Game.coins = 0
		_refresh_detail()
		_request_projection()
	elif state == "projecting":
		_projecting = true
		request_button.disabled = true
		status_label.text = "卫星储能已释放 · 正在写入核心补丁…"
		status_label.add_theme_color_override("font_color", Color("72e9ff"))
		visual.set_state("projecting", str(item.get("name", "装备")))
	elif state == "success":
		status_label.text = "升级完成 · 补丁已持久化，硬件状态稳定"
		status_label.add_theme_color_override("font_color", Color("70f3aa"))
		visual.set_state("success", str(item.get("name", "装备")))
