extends CanvasLayer
## 可复用开场/结局演出层：程序化剪影、字幕、推进/跳过与结局去向。

signal opened(mode: String)
signal closed(mode: String)
signal sequence_finished(mode: String)
signal return_title_requested

var is_open := false
var mode := ""
var _beats: Array = []
var _index := 0
var _qa_hold := false
var _veil: ColorRect
var _eyebrow: Label
var _title: Label
var _body: Label
var _counter: Label
var _glyph: Label
var _accent: ColorRect
var _continue: Label
var _actions: HBoxContainer
var _skip: Button
var _skyline: Control

func _ready() -> void:
	layer = 72
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false

func play(beats: Array, sequence_mode: String, start_index: int = 0, qa_hold: bool = false) -> void:
	if beats.is_empty(): return
	_beats = beats.duplicate(true)
	mode = sequence_mode
	_index = clampi(start_index, 0, _beats.size() - 1)
	_qa_hold = qa_hold
	is_open = true
	visible = true
	_actions.visible = false
	opened.emit(mode)
	_show_beat(false)

func close_sequence(completed: bool = false) -> void:
	if not is_open: return
	var closed_mode := mode
	is_open = false
	visible = false
	closed.emit(closed_mode)
	if completed: sequence_finished.emit(closed_mode)

func _unhandled_input(event: InputEvent) -> void:
	if not is_open or _qa_hold: return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("jump") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		_advance()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_finish_or_reveal_actions()
		get_viewport().set_input_as_handled()

func _advance() -> void:
	if mode == "ending" and _index == _beats.size() - 1:
		_actions.visible = true
		_continue.text = "选择城市此后的道路"
		return
	if _index < _beats.size() - 1:
		_index += 1
		_show_beat(true)
	else:
		close_sequence(true)

func _finish_or_reveal_actions() -> void:
	if mode == "ending":
		_index = _beats.size() - 1
		_show_beat(false)
		_actions.visible = true
	else:
		close_sequence(true)

func _show_beat(animate: bool) -> void:
	var beat: Dictionary = _beats[_index]
	var accent: Color = beat.get("accent", Color(0.4, 0.9, 1.0))
	_eyebrow.text = str(beat.get("eyebrow", ""))
	_title.text = str(beat.get("title", ""))
	_body.text = str(beat.get("text", ""))
	_glyph.text = str(beat.get("glyph", ""))
	_counter.text = "%02d  /  %02d" % [_index + 1, _beats.size()]
	_accent.color = accent
	_title.add_theme_color_override("font_color", accent.lightened(0.2))
	_glyph.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 0.42))
	_skip.text = "跳过序章  Esc" if mode == "intro" else "直达终幕  Esc"
	_actions.visible = mode == "ending" and _index == _beats.size() - 1
	_continue.text = "Enter / 空格 / 鼠标左键  继续" if not _actions.visible else "选择城市此后的道路"
	if animate:
		var card := _title.get_parent() as Control
		card.modulate.a = 0.0
		card.position.x += 22
		var tween := create_tween().set_parallel(true)
		tween.tween_property(card, "modulate:a", 1.0, 0.25)
		tween.tween_property(card, "position:x", card.position.x - 22, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _build() -> void:
	_veil = ColorRect.new(); _veil.set_anchors_preset(Control.PRESET_FULL_RECT); _veil.color = Color(0.005, 0.008, 0.022, 0.96); add_child(_veil)
	# 程序化远景：不同高度的机械塔与光窗，避免纯黑字幕页。
	_skyline = Control.new(); _skyline.set_anchors_preset(Control.PRESET_FULL_RECT); _skyline.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(_skyline)
	for i in range(14):
		var tower := ColorRect.new(); var h := 100 + (i * 47) % 250; tower.color = Color(0.025, 0.055, 0.09, 0.86); tower.position = Vector2(i * 104 - 20, 720 - h); tower.size = Vector2(82 + (i % 3) * 13, h); _skyline.add_child(tower)
		for w in range(3):
			var light := ColorRect.new(); light.color = Color(0.18, 0.65, 0.82, 0.18 + 0.08 * ((i + w) % 2)); light.position = Vector2(14 + w * 20, 18 + ((i * 23 + w * 49) % maxi(30, h - 40))); light.size = Vector2(7, 15); tower.add_child(light)
	for i in range(18):
		var mote := Label.new(); mote.text = "◆" if i % 3 == 0 else "·"; mote.position = Vector2(620 + (i * 73) % 650, 55 + (i * 97) % 500); mote.add_theme_font_size_override("font_size", 11 + i % 4); mote.add_theme_color_override("font_color", Color(0.62, 0.3, 1.0, 0.28)); _skyline.add_child(mote)
	for top in [true, false]:
		var band := ColorRect.new(); band.color = Color(0, 0, 0, 0.98); band.set_anchors_preset(Control.PRESET_TOP_WIDE if top else Control.PRESET_BOTTOM_WIDE); band.offset_bottom = 58 if top else 0; band.offset_top = 0 if top else -58; add_child(band)
	var card := VBoxContainer.new(); card.position = Vector2(118, 152); card.size = Vector2(720, 420); card.add_theme_constant_override("separation", 13); add_child(card)
	_eyebrow = Label.new(); _eyebrow.add_theme_font_size_override("font_size", 17); _eyebrow.add_theme_color_override("font_color", Color(0.9, 0.62, 0.32)); card.add_child(_eyebrow)
	_title = Label.new(); _title.add_theme_font_size_override("font_size", 48); _title.add_theme_color_override("font_outline_color", Color(0,0,0)); _title.add_theme_constant_override("outline_size", 8); card.add_child(_title)
	_accent = ColorRect.new(); _accent.custom_minimum_size = Vector2(450, 3); card.add_child(_accent)
	_body = Label.new(); _body.custom_minimum_size = Vector2(700, 125); _body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; _body.add_theme_font_size_override("font_size", 22); _body.add_theme_color_override("font_color", Color(0.82, 0.87, 0.93)); _body.add_theme_constant_override("line_spacing", 8); card.add_child(_body)
	_glyph = Label.new(); _glyph.add_theme_font_size_override("font_size", 18); card.add_child(_glyph)
	_counter = Label.new(); _counter.add_theme_font_size_override("font_size", 16); _counter.add_theme_color_override("font_color", Color(0.58, 0.68, 0.78)); card.add_child(_counter)
	_skip = Button.new(); _skip.set_anchors_preset(Control.PRESET_TOP_RIGHT); _skip.position = Vector2(-220, 76); _skip.size = Vector2(190, 42); _skip.pressed.connect(_finish_or_reveal_actions); add_child(_skip)
	_continue = Label.new(); _continue.set_anchors_preset(Control.PRESET_BOTTOM_WIDE); _continue.offset_top = -105; _continue.offset_bottom = -72; _continue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; _continue.add_theme_font_size_override("font_size", 16); _continue.add_theme_color_override("font_color", Color(0.62, 0.78, 0.9)); add_child(_continue)
	_actions = HBoxContainer.new(); _actions.set_anchors_preset(Control.PRESET_BOTTOM_WIDE); _actions.offset_left = 375; _actions.offset_right = -375; _actions.offset_top = -158; _actions.offset_bottom = -108; _actions.add_theme_constant_override("separation", 16); add_child(_actions)
	var explore := Button.new(); explore.text = "继续探索"; explore.custom_minimum_size = Vector2(250, 50); explore.pressed.connect(func(): close_sequence(true)); _actions.add_child(explore)
	var title_button := Button.new(); title_button.text = "返回标题"; title_button.custom_minimum_size = Vector2(250, 50); title_button.pressed.connect(func(): return_title_requested.emit()); _actions.add_child(title_button)
