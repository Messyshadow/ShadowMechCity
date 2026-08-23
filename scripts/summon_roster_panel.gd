class_name SummonRosterPanel
extends CanvasLayer
## 11.1c 阵容 UI：三槽解锁、不同型号校验、鼠标/键盘编成与量子超载预览。

const RULES := preload("res://scripts/summon_rules.gd")

var controller: CanvasLayer
var open := false
var selected_slot := 0
var selected_model := 0
var root: Control
var slot_row: HBoxContainer
var roster_row: HBoxContainer
var detail_title: Label
var detail_body: RichTextLabel
var resource_label: Label
var message_label: Label
var overload_bar: ProgressBar


func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("summon_roster"):
		if open or Game.menu_open == 0:
			set_open(not open)
			get_viewport().set_input_as_handled()
		return
	if not open:
		return
	if event.is_action_pressed("ui_cancel"):
		set_open(false)
	elif event.is_action_pressed("ui_left"):
		selected_model = wrapi(selected_model - 1, 0, Game.robot_roster.size())
		refresh()
	elif event.is_action_pressed("ui_right"):
		selected_model = wrapi(selected_model + 1, 0, Game.robot_roster.size())
		refresh()
	elif event.is_action_pressed("ui_up"):
		selected_slot = wrapi(selected_slot - 1, 0, 3)
		refresh()
	elif event.is_action_pressed("ui_down"):
		selected_slot = wrapi(selected_slot + 1, 0, 3)
		refresh()
	elif event.is_action_pressed("ui_accept"):
		assign_selected_model()
	else:
		return
	get_viewport().set_input_as_handled()


func set_open(value: bool) -> void:
	if open == value:
		return
	if value and Game.menu_open != 0:
		return
	open = value
	visible = open
	get_tree().paused = open
	Game.menu_open = maxi(0, Game.menu_open + (1 if open else -1))
	if open:
		message_label.text = "选择一个插槽，再为它配置不同型号的伙伴"
		refresh()


func open_for_qa(slot_level: int = 3, loadout_models: Array = []) -> void:
	Game.ensure_role_roster(false)
	Game.summon_slot_level = clampi(slot_level, 1, 3)
	if not loadout_models.is_empty() and is_instance_valid(controller):
		controller.call("configure_team_for_qa", Game.summon_slot_level, loadout_models)
	Game.skill_points = maxi(Game.skill_points, 6)
	set_open(true)


func unlock_next_slot() -> void:
	var before := Game.summon_slot_level
	var cost := RULES.slot_upgrade_cost(before)
	if Game.upgrade_summon_slots():
		message_label.text = "量子带宽扩容完成：已解锁第 %d 槽" % Game.summon_slot_level
		selected_slot = Game.summon_slot_level - 1
	else:
		message_label.text = "技能点不足（需要 %d）" % cost if cost > 0 else "三个召唤槽已全部解锁"
	refresh()


func assign_selected_model() -> void:
	if selected_slot >= Game.summon_slot_level:
		message_label.text = "该槽尚未解锁，请先扩容量子带宽"
		refresh()
		return
	if selected_model < 0 or selected_model >= Game.robot_roster.size():
		return
	var record: Dictionary = Game.robot_roster[selected_model]
	if Game.assign_summon_slot(selected_slot, str(record["robot_instance_id"])):
		message_label.text = "%s 已接入第 %d 槽" % [RobotData.profile(str(record["model_id"]))["name"], selected_slot + 1]
	else:
		message_label.text = "不同型号限制：同一型号不能重复上阵"
	refresh()


func refresh() -> void:
	if not is_instance_valid(slot_row):
		return
	_clear(slot_row)
	_clear(roster_row)
	resource_label.text = "技能点 %d    已解锁槽位 %d/3" % [Game.skill_points, Game.summon_slot_level]
	for index in range(3):
		var button := Button.new()
		button.custom_minimum_size = Vector2(252, 96)
		button.toggle_mode = true
		button.button_pressed = index == selected_slot
		button.disabled = index >= Game.summon_slot_level
		var robot_name := "未配置"
		if index < Game.summon_loadout.size():
			var record := _record_for(str(Game.summon_loadout[index]))
			robot_name = str(RobotData.profile(str(record.get("model_id", ""))).get("name", "未配置"))
		button.text = ("◇ 插槽 %d · 已锁定\n技能点解锁" % (index + 1)) if button.disabled else ("◆ 插槽 %d · 在线\n%s" % [index + 1, robot_name])
		_style_button(button, Color("65e8ff") if index == selected_slot else Color("35546c"))
		button.pressed.connect(_select_slot.bind(index))
		slot_row.add_child(button)
	for index in range(Game.robot_roster.size()):
		var record: Dictionary = Game.robot_roster[index]
		var profile := RobotData.profile(str(record["model_id"]))
		var button := Button.new()
		button.custom_minimum_size = Vector2(184, 134)
		button.toggle_mode = true
		button.button_pressed = index == selected_model
		button.text = "%s\n%s\nLv.%d" % [profile["name"], profile["role"], int(record.get("level", 1))]
		_style_button(button, profile["accent"] if index == selected_model else Color("33475a"))
		button.pressed.connect(_select_model.bind(index))
		roster_row.add_child(button)
	_show_detail()


func _select_slot(index: int) -> void:
	selected_slot = index
	refresh()


func _select_model(index: int) -> void:
	selected_model = index
	refresh()


func _show_detail() -> void:
	if Game.robot_roster.is_empty():
		return
	var record: Dictionary = Game.robot_roster[clampi(selected_model, 0, Game.robot_roster.size() - 1)]
	var profile := RobotData.profile(str(record["model_id"]))
	detail_title.text = "%s  ·  %s" % [profile["name"], profile["company"]]
	detail_title.add_theme_color_override("font_color", profile["accent"])
	var team_count := maxi(1, Game.summon_loadout.size())
	var overload := RULES.overload_profile(team_count)
	detail_body.text = "[color=#8fa9bd]定位[/color]  %s\n[color=#8fa9bd]参数[/color]  生命 %d · 输出 %d · 重构 %.0fs\n\n[color=#ffcc69]协同协议[/color]\n多机攻击自动错峰；三机持续输出按玩家基准约 35%% 调校。\n\n[color=#ff7897]量子超载[/color]\n%d 台编队每次行动 +%.0f 热量；满载后全队短暂冷却。" % [profile["role"], profile["max_hp"], profile["damage"], profile["rebuild_seconds"], team_count, overload["gain"]]
	overload_bar.value = 34.0 if team_count == 2 else (72.0 if team_count >= 3 else 0.0)


func _build() -> void:
	root = Control.new(); root.set_anchors_preset(Control.PRESET_FULL_RECT); add_child(root)
	var dim := ColorRect.new(); dim.color = Color(0.002, 0.008, 0.018, 0.94); dim.set_anchors_preset(Control.PRESET_FULL_RECT); root.add_child(dim)
	var center := CenterContainer.new(); center.set_anchors_preset(Control.PRESET_FULL_RECT); root.add_child(center)
	var shell := PanelContainer.new(); shell.custom_minimum_size = Vector2(1180, 650); shell.add_theme_stylebox_override("panel", _panel_style(Color("42c9f5"))); center.add_child(shell)
	var outer := VBoxContainer.new(); outer.add_theme_constant_override("separation", 10); shell.add_child(outer)
	var header := HBoxContainer.new(); outer.add_child(header)
	var title := Label.new(); title.text = "量子伙伴阵列 · QUANTUM COMPANION GRID"; title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; title.add_theme_font_size_override("font_size", 28); title.add_theme_color_override("font_color", Color("a6f3ff")); header.add_child(title)
	resource_label = Label.new(); resource_label.add_theme_font_size_override("font_size", 17); resource_label.add_theme_color_override("font_color", Color("ffd66b")); header.add_child(resource_label)
	var slot_header := HBoxContainer.new(); outer.add_child(slot_header)
	var slot_title := Label.new(); slot_title.text = "出战链路 · 选择插槽（↑↓）"; slot_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; slot_title.add_theme_font_size_override("font_size", 17); slot_header.add_child(slot_title)
	var unlock := Button.new(); unlock.text = "扩容量子带宽"; unlock.custom_minimum_size = Vector2(180, 38); _style_button(unlock, Color("d79b42")); unlock.pressed.connect(unlock_next_slot); slot_header.add_child(unlock)
	slot_row = HBoxContainer.new(); slot_row.alignment = BoxContainer.ALIGNMENT_CENTER; slot_row.add_theme_constant_override("separation", 12); outer.add_child(slot_row)
	var body := HBoxContainer.new(); body.add_theme_constant_override("separation", 12); body.size_flags_vertical = Control.SIZE_EXPAND_FILL; outer.add_child(body)
	var roster_panel := PanelContainer.new(); roster_panel.custom_minimum_size = Vector2(790, 360); roster_panel.add_theme_stylebox_override("panel", _panel_style(Color("274e6a"))); body.add_child(roster_panel)
	var roster_v := VBoxContainer.new(); roster_panel.add_child(roster_v)
	var roster_title := Label.new(); roster_title.text = "机器人档案 · ← → 选择 / Enter 接入"; roster_title.add_theme_font_size_override("font_size", 17); roster_v.add_child(roster_title)
	roster_row = HBoxContainer.new(); roster_row.add_theme_constant_override("separation", 8); roster_v.add_child(roster_row)
	message_label = Label.new(); message_label.add_theme_font_size_override("font_size", 15); message_label.add_theme_color_override("font_color", Color("ffe194")); message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; roster_v.add_child(message_label)
	var detail_panel := PanelContainer.new(); detail_panel.custom_minimum_size = Vector2(338, 360); detail_panel.add_theme_stylebox_override("panel", _panel_style(Color("6b3f72"))); body.add_child(detail_panel)
	var detail_v := VBoxContainer.new(); detail_panel.add_child(detail_v)
	detail_title = Label.new(); detail_title.add_theme_font_size_override("font_size", 20); detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; detail_v.add_child(detail_title)
	detail_body = RichTextLabel.new(); detail_body.bbcode_enabled = true; detail_body.fit_content = false; detail_body.custom_minimum_size = Vector2(310, 225); detail_body.add_theme_font_size_override("normal_font_size", 14); detail_v.add_child(detail_body)
	overload_bar = ProgressBar.new(); overload_bar.max_value = 100; overload_bar.show_percentage = false; overload_bar.custom_minimum_size = Vector2(300, 12); detail_v.add_child(overload_bar)
	var footer := Label.new(); footer.text = "[G / Esc] 关闭    鼠标点击也可选择    同一型号不可重复上阵"; footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; footer.add_theme_font_size_override("font_size", 15); footer.add_theme_color_override("font_color", Color("8eaabc")); outer.add_child(footer)


func _record_for(instance_id: String) -> Dictionary:
	for record in Game.robot_roster:
		if str(record.get("robot_instance_id", "")) == instance_id:
			return record
	return {}


func _clear(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _panel_style(border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = Color(0.012, 0.025, 0.045, 0.98); style.border_color = border; style.set_border_width_all(2); style.set_corner_radius_all(10)
	style.content_margin_left = 14; style.content_margin_right = 14; style.content_margin_top = 12; style.content_margin_bottom = 12
	return style


func _style_button(button: Button, border: Color) -> void:
	var normal := StyleBoxFlat.new(); normal.bg_color = Color("101a27"); normal.border_color = border; normal.set_border_width_all(2); normal.set_corner_radius_all(8)
	var hover := normal.duplicate(); hover.bg_color = Color("173146"); hover.border_color = Color("70e9ff")
	var pressed := normal.duplicate(); pressed.bg_color = Color("183a50"); pressed.border_color = Color("b9f7ff"); pressed.set_border_width_all(3)
	button.add_theme_stylebox_override("normal", normal); button.add_theme_stylebox_override("hover", hover); button.add_theme_stylebox_override("pressed", pressed); button.add_theme_stylebox_override("focus", pressed); button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_font_size_override("font_size", 15)
