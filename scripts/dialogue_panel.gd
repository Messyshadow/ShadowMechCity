class_name DialoguePanel
extends CanvasLayer
## 底部叙事对话框：逐字文本、键鼠推进、方向选择与机械圆环高亮。

signal conversation_closed
signal flags_emitted(flags: Array[String])

const NPC_DATA := preload("res://scripts/npc_data.gd")
const RUNNER_SCRIPT := preload("res://scripts/dialogue_runner.gd")

var _runner
var _root: Control
var _panel: PanelContainer
var _portrait: PanelContainer
var _emblem: Label
var _name_label: Label
var _role_label: Label
var _body: RichTextLabel
var _choices: VBoxContainer
var _footer: Label
var _accent_strip: ColorRect
var _current_node: Dictionary = {}
var _accent := Color(0.35, 0.8, 1.0)
var _choice_index := 0
var _typing := false
var _type_accum := 0.0
var _accept_lock := 0.0

func _ready() -> void:
	layer = 72
	_build_ui()
	_root.visible = false
	set_process_input(true)

func open_conversation(npc_id: String, snapshot: Dictionary, flags: Dictionary) -> void:
	var npc: Dictionary = NPC_DATA.NPCS.get(npc_id, {})
	if npc.is_empty():
		push_error("Dialogue requested for unknown NPC: " + npc_id)
		return
	_runner = RUNNER_SCRIPT.new()
	_apply_identity(npc)
	_root.visible = true
	_accept_lock = 0.22
	show_node(_runner.begin(str(npc.get("route", npc_id)), snapshot, flags))
	_animate_open()

func open_specific(npc_id: String, node_id: String) -> void:
	var npc: Dictionary = NPC_DATA.NPCS.get(npc_id, {})
	if npc.is_empty():
		push_error("Dialogue QA requested for unknown NPC: " + npc_id)
		return
	_runner = RUNNER_SCRIPT.new()
	_apply_identity(npc)
	_root.visible = true
	_accept_lock = 0.12
	show_node(_runner.begin_at(str(npc.get("route", npc_id)), node_id))
	_animate_open()

func close_conversation() -> void:
	if not is_open():
		return
	_root.visible = false
	_current_node = {}
	_runner = null
	conversation_closed.emit()

func is_open() -> bool:
	return is_instance_valid(_root) and _root.visible

func show_node(node: Dictionary) -> void:
	_current_node = node
	if node.is_empty():
		close_conversation()
		return
	_body.text = str(node.get("text", "通讯记录损坏。"))
	_body.visible_characters = 0
	_type_accum = 0.0
	_typing = true
	_choice_index = 0
	_rebuild_choices(node.get("choices", []))
	_footer.text = "E / Enter / 左键  继续     Esc  结束"
	var event_flags: Array[String] = _runner.set_flags_from(node)
	if not event_flags.is_empty():
		flags_emitted.emit(event_flags)

func _process(delta: float) -> void:
	if _accept_lock > 0.0:
		_accept_lock -= delta
	if not is_open() or not _typing:
		return
	_type_accum += delta * 62.0
	_body.visible_characters = mini(int(_type_accum), _body.get_total_character_count())
	if _body.visible_characters >= _body.get_total_character_count():
		_typing = false
		_body.visible_characters = -1

func _input(event: InputEvent) -> void:
	if not is_open() or _accept_lock > 0.0:
		return
	if event.is_action_pressed("ui_cancel"):
		close_conversation()
		get_viewport().set_input_as_handled()
		return
	var choice_count: int = _current_node.get("choices", []).size()
	if choice_count > 0 and event.is_action_pressed("ui_up"):
		_choice_index = wrapi(_choice_index - 1, 0, choice_count)
		_update_choice_highlight()
		get_viewport().set_input_as_handled()
		return
	if choice_count > 0 and event.is_action_pressed("ui_down"):
		_choice_index = wrapi(_choice_index + 1, 0, choice_count)
		_update_choice_highlight()
		get_viewport().set_input_as_handled()
		return
	var mouse_accept: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact") or mouse_accept:
		_accept_or_advance()
		get_viewport().set_input_as_handled()

func _accept_or_advance() -> void:
	if _typing:
		_typing = false
		_body.visible_characters = -1
		return
	var choices: Array = _current_node.get("choices", [])
	var next_node: Dictionary = _runner.advance(_choice_index if not choices.is_empty() else -1)
	if next_node.is_empty():
		close_conversation()
	else:
		show_node(next_node)

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_root)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.01, 0.025, 0.30)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = 42
	_panel.offset_right = -42
	# 双选项节点也必须完整留在 720p 安全区内，避免内容最小高度把底框挤出画面。
	_panel.offset_top = -282
	_panel.offset_bottom = -18
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color(0.025, 0.045, 0.07, 0.97)
	frame.border_color = Color(0.24, 0.56, 0.70, 0.92)
	frame.set_border_width_all(3)
	frame.set_corner_radius_all(14)
	frame.shadow_color = Color(0, 0, 0, 0.72)
	frame.shadow_size = 16
	_panel.add_theme_stylebox_override("panel", frame)
	_root.add_child(_panel)

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 18)
	_panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	margin.add_child(row)

	_portrait = PanelContainer.new()
	_portrait.custom_minimum_size = Vector2(150, 184)
	row.add_child(_portrait)
	var portrait_style := StyleBoxFlat.new()
	portrait_style.bg_color = Color(0.055, 0.08, 0.11, 1.0)
	portrait_style.border_color = Color(0.35, 0.75, 0.88, 0.8)
	portrait_style.set_border_width_all(2)
	portrait_style.set_corner_radius_all(10)
	_portrait.add_theme_stylebox_override("panel", portrait_style)
	var portrait_box := VBoxContainer.new()
	portrait_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_portrait.add_child(portrait_box)
	_emblem = Label.new()
	_emblem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_emblem.add_theme_font_size_override("font_size", 60)
	portrait_box.add_child(_emblem)
	var portrait_caption := Label.new()
	portrait_caption.text = "机械城通讯"
	portrait_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_caption.add_theme_font_size_override("font_size", 14)
	portrait_caption.add_theme_color_override("font_color", Color(0.55, 0.68, 0.76))
	portrait_box.add_child(portrait_caption)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 4)
	row.add_child(text_col)
	var title_row := HBoxContainer.new()
	text_col.add_child(title_row)
	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 26)
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(_name_label)
	_role_label = Label.new()
	_role_label.add_theme_font_size_override("font_size", 15)
	_role_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_row.add_child(_role_label)
	_accent_strip = ColorRect.new()
	_accent_strip.custom_minimum_size = Vector2(0, 3)
	text_col.add_child(_accent_strip)
	_body = RichTextLabel.new()
	_body.bbcode_enabled = false
	_body.fit_content = false
	_body.scroll_active = false
	_body.custom_minimum_size = Vector2(0, 78)
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_theme_font_size_override("normal_font_size", 21)
	_body.add_theme_color_override("default_color", Color(0.88, 0.94, 0.98))
	text_col.add_child(_body)
	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 4)
	text_col.add_child(_choices)
	_footer = Label.new()
	_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_footer.add_theme_font_size_override("font_size", 14)
	_footer.add_theme_color_override("font_color", Color(0.50, 0.67, 0.76))
	text_col.add_child(_footer)

func _apply_identity(npc: Dictionary) -> void:
	_accent = npc.get("accent", Color(0.35, 0.8, 1.0))
	_name_label.text = str(npc.get("name", "未知通讯"))
	_role_label.text = str(npc.get("role", ""))
	_name_label.add_theme_color_override("font_color", _accent.lightened(0.24))
	_role_label.add_theme_color_override("font_color", _accent)
	_accent_strip.color = Color(_accent.r, _accent.g, _accent.b, 0.72)
	var emblem_map := {"hammer":"⚒", "flask":"⚗", "map":"⌁", "memory":"◆", "target":"◎"}
	_emblem.text = emblem_map.get(str(npc.get("emblem", "")), "◇")
	_emblem.add_theme_color_override("font_color", _accent.lightened(0.18))
	var style: StyleBoxFlat = _portrait.get_theme_stylebox("panel").duplicate()
	style.border_color = Color(_accent.r, _accent.g, _accent.b, 0.86)
	_portrait.add_theme_stylebox_override("panel", style)

func _rebuild_choices(choices: Array) -> void:
	for child in _choices.get_children():
		child.queue_free()
	for i in choices.size():
		var button := Button.new()
		button.text = "○  " + str(choices[i].get("text", ""))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 17)
		button.mouse_entered.connect(func(): _choice_index = i; _update_choice_highlight())
		button.pressed.connect(func(): _choice_index = i; _accept_or_advance())
		_choices.add_child(button)
	_update_choice_highlight.call_deferred()

func _update_choice_highlight() -> void:
	var buttons := _choices.get_children()
	for i in buttons.size():
		var button: Button = buttons[i]
		var text := str(_current_node.get("choices", [])[i].get("text", ""))
		button.text = ("◉  " if i == _choice_index else "○  ") + text
		button.add_theme_color_override("font_color", _accent.lightened(0.28) if i == _choice_index else Color(0.70, 0.78, 0.84))

func _animate_open() -> void:
	_panel.modulate.a = 0.0
	_panel.position.y += 16.0
	var tween := _panel.create_tween().set_parallel(true)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.16)
	tween.tween_property(_panel, "position:y", _panel.position.y - 16.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
