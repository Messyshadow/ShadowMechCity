extends CanvasLayer
## 设置面板: 主音量 + 全屏切换. 设置持久化到 user://settings.cfg
## open_panel()/关闭按钮 控制显示; 可被 title 和 pause 复用.

signal closed

const CFG := "user://settings.cfg"
var is_open := false
var vol_slider: HSlider
var fs_check: CheckButton
var _close_btn: Button

func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false
	_load_cfg()

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0.02, 0.8)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(440, 320)
	center.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 18)
	panel.add_child(vb)

	var title := Label.new()
	title.text = "设置"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.7, 0.95, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)

	var vrow := HBoxContainer.new()
	vrow.add_theme_constant_override("separation", 14)
	var vl := Label.new(); vl.text = "主音量"; vl.custom_minimum_size = Vector2(90, 0)
	vl.add_theme_font_size_override("font_size", 20)
	vrow.add_child(vl)
	vol_slider = HSlider.new()
	vol_slider.min_value = 0; vol_slider.max_value = 100; vol_slider.value = 80
	vol_slider.custom_minimum_size = Vector2(260, 0)
	vol_slider.value_changed.connect(_on_volume)
	vrow.add_child(vol_slider)
	vb.add_child(vrow)

	var frow := HBoxContainer.new()
	frow.add_theme_constant_override("separation", 14)
	var fl := Label.new(); fl.text = "全屏"; fl.custom_minimum_size = Vector2(90, 0)
	fl.add_theme_font_size_override("font_size", 20)
	frow.add_child(fl)
	fs_check = CheckButton.new()
	fs_check.toggled.connect(_on_fullscreen)
	frow.add_child(fs_check)
	vb.add_child(frow)

	var close := Button.new()
	close.text = "关闭"
	close.custom_minimum_size = Vector2(0, 44)
	close.pressed.connect(_close)
	vb.add_child(close)
	UI.style_button(close)
	_close_btn = close

func open_panel() -> void:
	is_open = true
	visible = true
	Game.menu_open += 1
	if _close_btn:
		_close_btn.grab_focus()

func _close() -> void:
	is_open = false
	visible = false
	Game.menu_open = maxi(0, Game.menu_open - 1)
	_save_cfg()
	closed.emit()

func _on_volume(v: float) -> void:
	var db := linear_to_db(maxf(v / 100.0, 0.0001))
	AudioServer.set_bus_volume_db(0, db)

func _on_fullscreen(on: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)

func _load_cfg() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CFG) == OK:
		var v: float = cfg.get_value("audio", "volume", 80.0)
		var fs: bool = cfg.get_value("video", "fullscreen", false)
		vol_slider.value = v
		fs_check.button_pressed = fs
		_on_volume(v)
		_on_fullscreen(fs)
	else:
		_on_volume(80.0)

func _save_cfg() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "volume", vol_slider.value)
	cfg.set_value("video", "fullscreen", fs_check.button_pressed)
	cfg.save(CFG)
