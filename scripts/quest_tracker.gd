extends CanvasLayer
## HUD 任务追踪器：右上区域名下方，仅显示当前任务与两个未完成目标。

const QuestRuntime = preload("res://scripts/quest_runtime.gd")

var _panel: PanelContainer
var _title: Label
var _objectives: Label

func _ready() -> void:
	layer = 11
	_build()
	var game: Node = _game()
	if game:
		game.quest_changed.connect(_refresh.unbind(1))
	call_deferred("_refresh")

func _build() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_panel.offset_left = -390
	_panel.offset_right = -24
	_panel.offset_top = 64
	_panel.offset_bottom = 182
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.03, 0.055, 0.82)
	style.border_color = Color(0.25, 0.66, 0.82, 0.72)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	_panel.add_child(box)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 18)
	_title.add_theme_color_override("font_color", Color(0.55, 0.91, 1.0))
	box.add_child(_title)
	_objectives = Label.new()
	_objectives.add_theme_font_size_override("font_size", 14)
	_objectives.add_theme_color_override("font_color", Color(0.79, 0.86, 0.94))
	_objectives.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_objectives)

func _refresh() -> void:
	var game: Node = _game()
	if game == null:
		_panel.visible = false
		return
	var states: Dictionary = QuestRuntime.new().evaluate_all(game.quest_snapshot(), game.get("quest_flags"))
	var state: Dictionary = states.get(str(game.get("tracked_quest_id")), {})
	if state.is_empty():
		_panel.visible = false
		return
	_panel.visible = true
	var status := str(state.get("status", "active"))
	_title.text = "◆ %s  [%s]" % [state.get("title", ""), "完成" if status == "complete" else "N 任务"]
	var rows: Array[String] = []
	for objective in state.get("objectives", []):
		if not bool(objective.get("done", false)):
			rows.append("○ " + str(objective.get("text", "")))
			if rows.size() >= 2:
				break
	if rows.is_empty():
		rows.append("✓ 本章目标已完成")
	_objectives.text = "\n".join(rows)

func _game() -> Node:
	return get_node_or_null("/root/Game")
