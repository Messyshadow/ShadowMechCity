extends CanvasLayer
## 技能树面板 (T 打开/关闭). 暂停游戏, 点击加点.

var root: Control
var info_label: Label
var rows: Array = []          # [{node, lv_label, btn}]
var open := false

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false
	Game.skills_changed.connect(_refresh)
	Game.progression_changed.connect(_refresh)

func _build() -> void:
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0.02, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(720, 600)
	center.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	panel.add_child(vb)

	var title := Label.new()
	title.text = "技能树  ·  SKILL TREE"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.7, 0.95, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)

	info_label = Label.new()
	info_label.add_theme_font_size_override("font_size", 20)
	info_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(info_label)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(700, 480)
	vb.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	list.custom_minimum_size = Vector2(680, 0)
	scroll.add_child(list)

	var branches := SkillsData.by_branch()
	var colors := {"基础": Color(0.5, 0.8, 1.0), "移动": Color(0.5, 1.0, 0.6),
		"战斗": Color(1.0, 0.5, 0.5), "探索": Color(1.0, 0.85, 0.4), "终极": Color(0.8, 0.6, 1.0)}
	for branch in ["基础", "移动", "战斗", "探索", "终极"]:
		if not branches.has(branch):
			continue
		var head := Label.new()
		head.text = "【%s】" % branch
		head.add_theme_font_size_override("font_size", 20)
		head.add_theme_color_override("font_color", colors.get(branch, Color.WHITE))
		list.add_child(head)
		for node in branches[branch]:
			list.add_child(_make_row(node))

	var hint := Label.new()
	hint.text = "T / Esc 关闭   ·   点击「升级」消耗技能点"
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(hint)

func _make_row(node: Dictionary) -> Control:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	var name_l := Label.new()
	name_l.text = node["name"]
	name_l.custom_minimum_size = Vector2(110, 0)
	name_l.add_theme_font_size_override("font_size", 18)
	hb.add_child(name_l)
	var desc_l := Label.new()
	desc_l.text = node["desc"]
	desc_l.custom_minimum_size = Vector2(330, 0)
	desc_l.add_theme_font_size_override("font_size", 15)
	desc_l.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	hb.add_child(desc_l)
	var lv_l := Label.new()
	lv_l.custom_minimum_size = Vector2(70, 0)
	lv_l.add_theme_font_size_override("font_size", 16)
	hb.add_child(lv_l)
	var btn := Button.new()
	btn.text = "升级"
	btn.custom_minimum_size = Vector2(110, 0)
	btn.pressed.connect(func(): _on_upgrade(node))
	hb.add_child(btn)
	UI.style_button(btn)
	rows.append({"node": node, "lv": lv_l, "btn": btn})
	return hb

func _on_upgrade(node: Dictionary) -> void:
	Game.upgrade_skill(node)

func _refresh() -> void:
	info_label.text = "等级 %d    技能点 %d    金币 %d    (经验 %d/%d)" % [
		Game.level, Game.skill_points, Game.coins, Game.xp, Game.xp_needed()]
	for r in rows:
		var node: Dictionary = r["node"]
		var lv: int = Game.skill_lv(node["id"])
		r["lv"].text = "%d / %d" % [lv, node["max"]]
		if lv >= node["max"]:
			r["btn"].text = "已满"
			r["btn"].disabled = true
		elif Game.can_upgrade(node):
			r["btn"].text = "升级 (%d点)" % node["cost"]
			r["btn"].disabled = false
		else:
			r["btn"].text = "升级 (%d点)" % node["cost"]
			r["btn"].disabled = true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("skill_menu"):
		if open or Game.menu_open == 0:
			_toggle()

func _toggle() -> void:
	open = not open
	visible = open
	get_tree().paused = open
	Game.menu_open += (1 if open else -1)
	if open:
		_refresh()
		if rows.size() > 0:
			rows[0]["btn"].grab_focus()
