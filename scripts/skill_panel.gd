extends CanvasLayer
## 13A 圆形技能树：四页面、武器家族、空间键盘导航与 SubViewportContainer 教学预览。

const PANEL_SIZE := Vector2(1180, 650)
const PAGE_COLORS := {
	"基础": Color(0.35, 0.78, 1.0),
	"身法": Color(0.35, 1.0, 0.62),
	"战斗": Color(1.0, 0.43, 0.43),
	"探索": Color(1.0, 0.78, 0.28),
}

var root: Control
var info_label: Label
var page_row: HBoxContainer
var family_row: HBoxContainer
var graph_canvas: Control
var detail_title: Label
var detail_type: Label
var detail_body: RichTextLabel
var upgrade_button: Button
var preview: SubViewportContainer
var open := false
var current_page := "基础"
var current_family := "刀剑"
var selected_id := ""
var visible_nodes: Array = []
var node_controls: Dictionary = {}
var page_buttons: Dictionary = {}
var family_buttons: Dictionary = {}

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false
	Game.skills_changed.connect(_refresh)
	Game.progression_changed.connect(_refresh)
	Game.gear_changed.connect(_refresh)

func _panel_style(color: Color, radius: int = 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.045, 0.075, 0.98)
	style.border_color = color
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func _build() -> void:
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.005, 0.008, 0.018, 0.91)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = PANEL_SIZE
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.22, 0.72, 0.92), 14))
	center.add_child(panel)
	var main_v := VBoxContainer.new()
	main_v.add_theme_constant_override("separation", 6)
	panel.add_child(main_v)
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 48
	main_v.add_child(header)
	var title := Label.new()
	title.text = "技能矩阵  ·  SKILL MATRIX"
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Color(0.68, 0.95, 1.0))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	info_label = Label.new()
	info_label.add_theme_font_size_override("font_size", 17)
	info_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42))
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(info_label)
	page_row = HBoxContainer.new()
	page_row.alignment = BoxContainer.ALIGNMENT_CENTER
	page_row.add_theme_constant_override("separation", 10)
	main_v.add_child(page_row)
	for page in SkillsData.PAGES:
		var button := Button.new()
		button.text = page
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(126, 34)
		button.pressed.connect(_select_page.bind(page))
		UI.style_button(button)
		page_row.add_child(button)
		page_buttons[page] = button
	family_row = HBoxContainer.new()
	family_row.alignment = BoxContainer.ALIGNMENT_CENTER
	family_row.add_theme_constant_override("separation", 5)
	main_v.add_child(family_row)
	for family in SkillsData.FAMILIES:
		var button := Button.new()
		button.text = family
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(104, 28)
		button.pressed.connect(_select_family.bind(family))
		UI.style_button(button)
		family_row.add_child(button)
		family_buttons[family] = button
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_v.add_child(content)
	var graph_panel := PanelContainer.new()
	graph_panel.custom_minimum_size = Vector2(714, 490)
	graph_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.12, 0.34, 0.5, 0.9), 8))
	content.add_child(graph_panel)
	graph_canvas = Control.new()
	graph_canvas.custom_minimum_size = Vector2(688, 458)
	graph_canvas.clip_contents = true
	graph_canvas.mouse_filter = Control.MOUSE_FILTER_PASS
	graph_panel.add_child(graph_canvas)
	var detail_panel := PanelContainer.new()
	detail_panel.custom_minimum_size = Vector2(418, 490)
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.3, 0.48, 0.64, 0.9), 8))
	content.add_child(detail_panel)
	var detail_v := VBoxContainer.new()
	detail_v.add_theme_constant_override("separation", 6)
	detail_panel.add_child(detail_v)
	preview = SkillPreview.new()
	detail_v.add_child(preview)
	detail_title = Label.new()
	detail_title.add_theme_font_size_override("font_size", 24)
	detail_title.add_theme_color_override("font_color", Color(0.75, 0.95, 1.0))
	detail_v.add_child(detail_title)
	detail_type = Label.new()
	detail_type.add_theme_font_size_override("font_size", 15)
	detail_type.add_theme_color_override("font_color", Color(1.0, 0.72, 0.34))
	detail_v.add_child(detail_type)
	detail_body = RichTextLabel.new()
	detail_body.bbcode_enabled = true
	detail_body.fit_content = false
	detail_body.custom_minimum_size = Vector2(390, 165)
	detail_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_body.add_theme_font_size_override("normal_font_size", 14)
	detail_v.add_child(detail_body)
	upgrade_button = Button.new()
	upgrade_button.custom_minimum_size.y = 38
	upgrade_button.pressed.connect(_upgrade_selected)
	UI.style_button(upgrade_button)
	detail_v.add_child(upgrade_button)
	var hint := Label.new()
	hint.text = "T / Esc 关闭   ·   WASD / 方向键选择   ·   Enter / 点击升级"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(0.65, 0.75, 0.86))
	main_v.add_child(hint)
	_select_page("基础")

func _select_page(page: String) -> void:
	if not SkillsData.PAGES.has(page):
		return
	current_page = page
	family_row.visible = page == "战斗"
	for page_name in page_buttons:
		page_buttons[page_name].button_pressed = page_name == current_page
	_rebuild_graph()

func _select_family(family: String) -> void:
	if not SkillsData.FAMILIES.has(family):
		return
	current_family = family
	for family_name in family_buttons:
		family_buttons[family_name].button_pressed = family_name == current_family
	if current_page == "战斗":
		_rebuild_graph()

func _rebuild_graph() -> void:
	for child in graph_canvas.get_children():
		child.queue_free()
	node_controls.clear()
	visible_nodes = SkillsData.nodes_for(current_page, current_family)
	var by_id := {}
	for node in visible_nodes:
		by_id[node["id"]] = node
	for node in visible_nodes:
		for req in node.get("req", []):
			if not by_id.has(req):
				continue
			var line := Line2D.new()
			line.width = 3.0
			line.default_color = Color(PAGE_COLORS[current_page], 0.38)
			line.points = PackedVector2Array([_graph_position(by_id[req]) + Vector2(37,37), _graph_position(node) + Vector2(37,37)])
			graph_canvas.add_child(line)
	for node in visible_nodes:
		var control := SkillNodeControl.new()
		control.position = _graph_position(node)
		graph_canvas.add_child(control)
		control.setup(node, Game.skill_lv(str(node["id"])), Game.can_upgrade(node))
		control.chosen.connect(_on_node_chosen)
		control.hovered.connect(_select_node)
		node_controls[node["id"]] = control
	if selected_id == "" or not node_controls.has(selected_id):
		selected_id = str(visible_nodes[0]["id"]) if not visible_nodes.is_empty() else ""
	_select_node(selected_id)

func _graph_position(node: Dictionary) -> Vector2:
	var authored := Vector2(node["pos"])
	return Vector2(clampf(authored.x, 8.0, 600.0), clampf(authored.y, 8.0, 380.0))

func _on_node_chosen(id: String) -> void:
	_select_node(id)
	_upgrade_selected()

func _select_node(id: String) -> void:
	if not node_controls.has(id):
		return
	selected_id = id
	for node_id in node_controls:
		node_controls[node_id].set_selected(node_id == id)
	_refresh_detail()

func _selected_node() -> Dictionary:
	for node in visible_nodes:
		if str(node["id"]) == selected_id:
			return node
	return {}

func _refresh_detail() -> void:
	var node := _selected_node()
	if node.is_empty():
		detail_title.text = "暂无技能"
		detail_type.text = "该分支将在后续阶段开放"
		detail_body.text = ""
		upgrade_button.disabled = true
		upgrade_button.text = "尚未开放"
		return
	var level := Game.skill_lv(str(node["id"]))
	var max_level := int(node.get("max", 0))
	detail_title.text = str(node["name"])
	detail_type.text = "%s   ·   等级 %d / %d" % [node["type"], level, max_level]
	var req_names: Array[String] = []
	for req in node.get("req", []):
		for candidate in SkillsData.TREE:
			if candidate["id"] == req:
				req_names.append(str(candidate["name"]))
	detail_body.text = "[color=#78dfff]按键 / 触发[/color]\n%s\n[color=#ffd56a]如何使用[/color]\n%s\n[color=#a9b9ca]效果[/color]\n%s\n[color=#8de8ae]成长：%s[/color]\n[color=#8395a8]前置：%s[/color]" % [
		node.get("input", "自动生效"), node.get("usage", ""), node.get("desc", ""),
		_effect_progress(node, level),
		"无" if req_names.is_empty() else "、".join(req_names),
	]
	var weapon := Weapons.get_weapon(Game.weapon_index)
	(preview as SkillPreview).play_node(node, weapon)
	if max_level <= 0:
		upgrade_button.text = "分支入口 · 后续开放"
		upgrade_button.disabled = true
	elif level >= max_level:
		upgrade_button.text = "已掌握"
		upgrade_button.disabled = true
	else:
		upgrade_button.text = "升级至 %d 级  ·  消耗 %d 技能点" % [level + 1, int(node["cost"])]
		upgrade_button.disabled = not Game.can_upgrade(node)

func _effect_progress(node: Dictionary, level: int) -> String:
	var max_level := int(node.get("max", 0))
	if max_level <= 0:
		var ability := str(node.get("ability_required", ""))
		var weapon_id := str(node.get("weapon_required", ""))
		var unlocked := Game.has_ability(ability) if ability != "" else Game.is_weapon_unlocked(weapon_id)
		return "已获取 · 等待分支" if unlocked else "未获取 · 分支锁定"
	if level >= max_level:
		return "已达到最高等级"
	return "%d级 → %d级：%s" % [level, level + 1, node.get("desc", "解锁效果")]

func _upgrade_selected() -> void:
	var node := _selected_node()
	if not node.is_empty():
		Game.upgrade_skill(node)

func _refresh() -> void:
	if info_label == null:
		return
	info_label.text = "Lv.%d   技能点 %d   金币 %d   经验 %d/%d" % [Game.level, Game.skill_points, Game.coins, Game.xp, Game.xp_needed()]
	for node in visible_nodes:
		if node_controls.has(node["id"]):
			node_controls[node["id"]].refresh(Game.skill_lv(str(node["id"])), Game.can_upgrade(node))
	_refresh_detail()

func _move_selection(direction: Vector2) -> void:
	var next_id := SkillGraph.nearest_in_direction(selected_id, direction, visible_nodes)
	if next_id != "":
		_select_node(next_id)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("skill_menu"):
		if open or Game.menu_open == 0:
			_toggle()
		get_viewport().set_input_as_handled()
		return
	if not open:
		return
	if event.is_action_pressed("ui_cancel"):
		_toggle()
	elif event.is_action_pressed("ui_left") or (event is InputEventKey and event.pressed and event.physical_keycode == KEY_A):
		_move_selection(Vector2.LEFT)
	elif event.is_action_pressed("ui_right") or (event is InputEventKey and event.pressed and event.physical_keycode == KEY_D):
		_move_selection(Vector2.RIGHT)
	elif event.is_action_pressed("ui_up"):
		_move_selection(Vector2.UP)
	elif event.is_action_pressed("ui_down"):
		_move_selection(Vector2.DOWN)
	elif event.is_action_pressed("ui_accept"):
		_upgrade_selected()
	else:
		return
	get_viewport().set_input_as_handled()

func _toggle() -> void:
	open = not open
	visible = open
	get_tree().paused = open
	Game.menu_open = maxi(0, Game.menu_open + (1 if open else -1))
	if open:
		_refresh()
		_select_node(selected_id)

func open_for_qa(page: String, family: String, node_id: String) -> void:
	if not open:
		_toggle()
	_select_page(page)
	if page == "战斗":
		_select_family(family)
	_select_node(node_id)
