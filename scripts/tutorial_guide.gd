extends CanvasLayer
## 非阻塞情境教学：观察真实输入，逐步提示基础操作并持久化完成状态。

signal tutorial_finished

const STEPS := [
	{"id":"move", "actions":["move_left", "move_right"], "keys":"A / D", "title":"移动", "text":"沿站台左右移动，熟悉角色的起步与停步。"},
	{"id":"jump", "actions":["jump"], "keys":"Space", "title":"跃过断层", "text":"跳上前方平台；提前松开可缩短跳跃高度。"},
	{"id":"attack", "actions":["attack"], "keys":"J / 鼠标左键", "title":"武器攻击", "text":"连续攻击可形成连段，方向键上配合攻击可对空。"},
	{"id":"dash", "actions":["dash"], "keys":"Shift / L / 右键", "title":"蒸汽冲刺", "text":"冲刺可快速调整距离，也能穿过青色能量门。"},
	{"id":"interact", "actions":["interact"], "keys":"E / Enter", "title":"读取与交谈", "text":"靠近 NPC、存档点或机关后使用交互键。"},
	{"id":"map", "actions":["map_menu"], "keys":"M", "title":"世界轨图", "text":"地图会记录房间、能力门与亲自发现的隐藏区域。"},
]

var active := false
var _index := 0
var _panel: PanelContainer
var _step_label: Label
var _title: Label
var _keys: Label
var _body: Label
var _qa_hold := false

func _ready() -> void:
	layer = 14
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false

func begin_if_needed(existing_visited_count: int = 0) -> void:
	var game := _game()
	if game == null: return
	if bool(game.get("story_flags").get("tutorial_complete", false)):
		return
	if existing_visited_count > 2:
		game.set_story_flag("tutorial_complete")
		return
	active = true; visible = true; _index = 0; _show_step()

func force_show_for_qa(step_index: int = 2) -> void:
	active = true; visible = true; _qa_hold = true; _index = clampi(step_index, 0, STEPS.size() - 1); _show_step()

func _input(event: InputEvent) -> void:
	# 使用原始输入观察而不标记 handled：地图/NPC 面板仍会收到同一次按键。
	if not active or _qa_hold or _index >= STEPS.size(): return
	var step: Dictionary = STEPS[_index]
	for action in step["actions"]:
		if event.is_action_pressed(str(action)):
			_complete_step(); return

func _complete_step() -> void:
	var tween := _panel.create_tween()
	tween.tween_property(_panel, "modulate", Color(0.45, 1.0, 0.75, 1.0), 0.12)
	tween.tween_interval(0.16)
	tween.tween_property(_panel, "modulate", Color.WHITE, 0.16)
	_index += 1
	if _index >= STEPS.size():
		active = false; visible = false
		var game := _game()
		if game: game.set_story_flag("tutorial_complete"); game.save_game()
		tutorial_finished.emit()
	else:
		_show_step()

func _show_step() -> void:
	var step: Dictionary = STEPS[_index]
	_step_label.text = "基础同步  %d / %d" % [_index + 1, STEPS.size()]
	_title.text = str(step["title"])
	_keys.text = str(step["keys"])
	_body.text = str(step["text"])

func _build() -> void:
	_panel = PanelContainer.new(); _panel.set_anchors_preset(Control.PRESET_TOP_LEFT); _panel.offset_left = 24; _panel.offset_right = 474; _panel.offset_top = 255; _panel.offset_bottom = 413
	var style := StyleBoxFlat.new(); style.bg_color = Color(0.018, 0.035, 0.06, 0.94); style.border_color = Color(0.25, 0.78, 0.94, 0.9); style.set_border_width_all(2); style.set_corner_radius_all(10); style.content_margin_left = 18; style.content_margin_right = 18; style.content_margin_top = 13; style.content_margin_bottom = 13; _panel.add_theme_stylebox_override("panel", style); add_child(_panel)
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation", 6); _panel.add_child(box)
	_step_label = Label.new(); _step_label.add_theme_font_size_override("font_size", 14); _step_label.add_theme_color_override("font_color", Color(0.95, 0.62, 0.3)); box.add_child(_step_label)
	var row := HBoxContainer.new(); box.add_child(row)
	_title = Label.new(); _title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; _title.add_theme_font_size_override("font_size", 23); _title.add_theme_color_override("font_color", Color(0.68, 0.94, 1.0)); row.add_child(_title)
	_keys = Label.new(); _keys.add_theme_font_size_override("font_size", 16); _keys.add_theme_color_override("font_color", Color(1.0, 0.78, 0.38)); row.add_child(_keys)
	_body = Label.new(); _body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; _body.add_theme_font_size_override("font_size", 16); _body.add_theme_color_override("font_color", Color(0.78, 0.84, 0.91)); box.add_child(_body)

func _game() -> Node:
	return get_node_or_null("/root/Game")
