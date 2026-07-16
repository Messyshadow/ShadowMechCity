extends CanvasLayer
## 阶段 12.2 任务日志：N 键、鼠标及键盘导航，数据来自纯 QuestRuntime。

signal open_changed(is_open: bool)

const QuestData = preload("res://scripts/quest_data.gd")
const QuestRuntime = preload("res://scripts/quest_runtime.gd")

var open := false
var selected_id := ""
var page := "main"
var _tabs: Dictionary = {}
var _chapter_box: VBoxContainer
var _title: Label
var _status: Label
var _summary: Label
var _giver: Label
var _objectives: VBoxContainer
var _track_button: Button
var _chapter_buttons: Array[Button] = []
var _states: Dictionary = {}

func _ready() -> void:
	layer = 26
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false
	var game: Node = _game()
	if game:
		game.quest_changed.connect(_on_quest_changed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("quest_menu"):
		var game: Node = _game()
		if open or (game and int(game.get("menu_open")) == 0):
			set_open(not open)
		get_viewport().set_input_as_handled()
	elif open and event.is_action_pressed("ui_cancel"):
		set_open(false)
		get_viewport().set_input_as_handled()

func set_open(value: bool) -> void:
	if value == open:
		return
	var game: Node = _game()
	if game == null or (value and int(game.get("menu_open")) != 0):
		return
	open = value
	visible = value
	game.set("menu_open", maxi(0, int(game.get("menu_open")) + (1 if value else -1)))
	if value:
		_refresh()
		if not _chapter_buttons.is_empty():
			_chapter_buttons[0].grab_focus()
	open_changed.emit(value)

func force_open_for_qa() -> void:
	set_open(true)

func force_page_for_qa(target: String) -> void:
	page = target
	set_open(true)
	_refresh()

func _build() -> void:
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.005, 0.01, 0.025, 0.88)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_top = 14
	center.offset_bottom = -14
	add_child(center)

	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(1080, 650)
	frame.add_theme_stylebox_override("panel", _panel_style(Color(0.04, 0.065, 0.095, 0.98), Color(0.25, 0.75, 0.92, 0.9), 2, 12))
	center.add_child(frame)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 12)
	frame.add_child(outer)

	var header := HBoxContainer.new()
	outer.add_child(header)
	var heading := Label.new()
	heading.text = "任务日志  ·  MISSION ARCHIVE"
	heading.add_theme_font_size_override("font_size", 30)
	heading.add_theme_color_override("font_color", Color(0.64, 0.94, 1.0))
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var count := Label.new()
	count.name = "QuestCount"
	count.add_theme_font_size_override("font_size", 17)
	count.add_theme_color_override("font_color", Color(0.95, 0.68, 0.35))
	header.add_child(count)

	var line := ColorRect.new()
	line.custom_minimum_size = Vector2(0, 2)
	line.color = Color(0.22, 0.7, 0.88, 0.72)
	outer.add_child(line)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	outer.add_child(tabs)
	for tab_data in [["main", "主线"], ["side", "支线"], ["collectibles", "收藏"]]:
		var tab := Button.new()
		tab.text = str(tab_data[1])
		tab.custom_minimum_size = Vector2(150, 38)
		tab.pressed.connect(_switch_page.bind(str(tab_data[0])))
		tabs.add_child(tab)
		_tabs[str(tab_data[0])] = tab

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 18)
	outer.add_child(columns)

	var left_panel := PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(335, 0)
	left_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.02, 0.035, 0.055, 0.9), Color(0.18, 0.34, 0.45, 0.9), 1, 8))
	columns.add_child(left_panel)
	_chapter_box = VBoxContainer.new()
	_chapter_box.add_theme_constant_override("separation", 9)
	left_panel.add_child(_chapter_box)

	var right_panel := PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.045, 0.07, 0.94), Color(0.18, 0.42, 0.55, 0.85), 1, 8))
	columns.add_child(right_panel)
	var detail := VBoxContainer.new()
	detail.add_theme_constant_override("separation", 10)
	right_panel.add_child(detail)

	var title_row := HBoxContainer.new()
	detail.add_child(title_row)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 29)
	_title.add_theme_color_override("font_color", Color(0.76, 0.95, 1.0))
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(_title)
	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 18)
	title_row.add_child(_status)

	_giver = Label.new()
	_giver.add_theme_font_size_override("font_size", 16)
	_giver.add_theme_color_override("font_color", Color(0.95, 0.68, 0.36))
	detail.add_child(_giver)
	_summary = Label.new()
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary.custom_minimum_size = Vector2(0, 92)
	_summary.add_theme_font_size_override("font_size", 18)
	_summary.add_theme_color_override("font_color", Color(0.78, 0.84, 0.92))
	detail.add_child(_summary)

	var objective_heading := Label.new()
	objective_heading.text = "任务目标"
	objective_heading.add_theme_font_size_override("font_size", 20)
	objective_heading.add_theme_color_override("font_color", Color(0.55, 0.88, 1.0))
	detail.add_child(objective_heading)
	_objectives = VBoxContainer.new()
	_objectives.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_objectives.add_theme_constant_override("separation", 8)
	detail.add_child(_objectives)
	_track_button = Button.new()
	_track_button.text = "设为追踪任务"
	_track_button.custom_minimum_size = Vector2(0, 44)
	_track_button.pressed.connect(_track_selected)
	detail.add_child(_track_button)

	var hint := Label.new()
	hint.text = "N / Esc 关闭  ·  W/S / ↑↓ 选择  ·  Enter 确认  ·  鼠标可操作"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(0.6, 0.73, 0.84))
	outer.add_child(hint)

func _refresh() -> void:
	var game: Node = _game()
	if game == null:
		return
	_states = QuestRuntime.new().evaluate_all(game.quest_snapshot(), game.get("quest_flags")) if page == "main" else QuestRuntime.new().evaluate_side(game.quest_snapshot(), game.get("quest_flags"))
	if page == "collectibles":
		_states = {}
		for collectible_id in QuestData.COLLECTIBLE_ORDER:
			var entry: Dictionary = QuestData.COLLECTIBLES.get(collectible_id, {}).duplicate(true)
			entry["id"] = collectible_id
			entry["found"] = game.is_collected(collectible_id)
			_states[collectible_id] = entry
	for tab_id in _tabs:
		var tab: Button = _tabs[tab_id]
		tab.disabled = tab_id == page
	if selected_id == "" or not _states.has(selected_id):
		selected_id = str(game.get("tracked_quest_id")) if page == "main" else ""
	if selected_id == "" or not _states.has(selected_id):
		var order: Array = _page_order()
		selected_id = str(order[0]) if not order.is_empty() else ""
	_rebuild_chapters()
	_refresh_detail()
	var completed := 0
	for quest_id in _states:
		if _states[quest_id].get("status", "") == "complete" or bool(_states[quest_id].get("found", false)):
			completed += 1
	var count_label := find_child("QuestCount", true, false) as Label
	if count_label:
		var labels := {"main":"主线完成", "side":"支线完成", "collectibles":"档案同步"}
		count_label.text = "%s  %d / %d" % [labels.get(page, "完成"), completed, _page_order().size()]

func _switch_page(target: String) -> void:
	page = target
	selected_id = ""
	_refresh()
	if not _chapter_buttons.is_empty(): _chapter_buttons[0].grab_focus()

func _page_order() -> Array:
	if page == "side": return QuestData.SIDE_ORDER
	if page == "collectibles": return QuestData.COLLECTIBLE_ORDER
	return QuestData.MAIN_ORDER

func _rebuild_chapters() -> void:
	var game: Node = _game()
	for child in _chapter_box.get_children():
		child.queue_free()
	_chapter_buttons.clear()
	for quest_id in _page_order():
		var state: Dictionary = _states.get(quest_id, {})
		if page == "collectibles":
			var found := bool(state.get("found", false))
			var archive_button := Button.new()
			archive_button.text = "%s  %s\n     %s" % ["◉" if found else "○", state.get("title", "未知记忆") if found else "未同步档案", state.get("region", "未知区域")]
			archive_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			archive_button.custom_minimum_size = Vector2(0, 64)
			archive_button.add_theme_font_size_override("font_size", 17)
			archive_button.pressed.connect(_select.bind(str(quest_id)))
			_chapter_box.add_child(archive_button); _chapter_buttons.append(archive_button)
			continue
		var status := str(state.get("status", "locked"))
		var prefix := "◆" if game and str(game.get("tracked_quest_id")) == quest_id else ("✓" if status == "complete" else ("●" if status == "active" else "◇"))
		var button := Button.new()
		var chapter := "第%s章  " % state.get("chapter", "") if page == "main" else ""
		button.text = "%s  %s%s\n     %d / %d" % [prefix, chapter, state.get("title", ""), state.get("done", 0), state.get("total", 0)]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 82)
		button.disabled = status == "locked"
		button.add_theme_font_size_override("font_size", 18)
		button.add_theme_color_override("font_color", _status_color(status))
		button.pressed.connect(_select.bind(str(quest_id)))
		_chapter_box.add_child(button)
		_chapter_buttons.append(button)

func _select(quest_id: String) -> void:
	selected_id = quest_id
	_refresh_detail()

func _refresh_detail() -> void:
	var game: Node = _game()
	var state: Dictionary = _states.get(selected_id, {})
	if page == "collectibles":
		var found := bool(state.get("found", false))
		_title.text = str(state.get("title", "未知记忆")) if found else "加密记忆 · 尚未同步"
		_status.text = "已归档" if found else "未发现"
		_status.add_theme_color_override("font_color", Color(0.45, 0.9, 0.75) if found else Color(0.45, 0.5, 0.58))
		_giver.text = "来源区域：" + str(state.get("region", "未知"))
		_summary.text = str(state.get("lore", "")) if found else "该记录仍被区域干扰遮蔽。探索能力门后的秘室，寻找悬浮的记忆核心。"
		for child in _objectives.get_children(): child.queue_free()
		var archive_hint := Label.new(); archive_hint.text = "◆  七份档案彼此校验，收齐后可复原机械城覆灭前的最后证词。"; archive_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; archive_hint.add_theme_font_size_override("font_size", 18); _objectives.add_child(archive_hint)
		_track_button.visible = false
		return
	_track_button.visible = true
	var status := str(state.get("status", "locked"))
	_title.text = ("第%s章 · " % state.get("chapter", "") if page == "main" else "支线 · ") + str(state.get("title", ""))
	_status.text = {"active":"进行中", "complete":"已完成", "locked":"未解锁"}.get(status, status)
	_status.add_theme_color_override("font_color", _status_color(status))
	_giver.text = "委托记录：" + str(state.get("giver", "—"))
	_summary.text = str(state.get("summary", ""))
	for child in _objectives.get_children():
		child.queue_free()
	for objective in state.get("objectives", []):
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.06, 0.085, 0.82), Color(0.12, 0.26, 0.34, 0.8), 1, 5))
		var label := Label.new()
		var done := bool(objective.get("done", false))
		var progress := "  (%d/%d)" % [objective.get("current", 0), objective.get("target", 0)] if objective.has("target") else ""
		label.text = "%s  %s%s\n      %s" % ["✓" if done else "○", objective.get("text", ""), progress, objective.get("hint", "")]
		label.add_theme_font_size_override("font_size", 17)
		label.add_theme_color_override("font_color", Color(0.48, 0.9, 0.72) if done else Color(0.83, 0.88, 0.95))
		row.add_child(label)
		_objectives.add_child(row)
	var tracked := str(game.get("tracked_quest_id")) if game else ""
	_track_button.disabled = status == "locked" or tracked == selected_id
	_track_button.text = "正在追踪" if tracked == selected_id else "设为追踪任务"

func _track_selected() -> void:
	var game: Node = _game()
	if game and game.set_tracked_quest(selected_id):
		game.save_game()
		_refresh()

func _on_quest_changed(_states_update: Dictionary) -> void:
	if open:
		_refresh()

func _status_color(status: String) -> Color:
	match status:
		"complete": return Color(0.45, 0.9, 0.67)
		"active": return Color(0.42, 0.88, 1.0)
		_: return Color(0.4, 0.46, 0.54)

func _panel_style(bg: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style

func _game() -> Node:
	return get_node_or_null("/root/Game")
