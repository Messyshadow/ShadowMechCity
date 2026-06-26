extends CanvasLayer
## 暂停菜单 (Esc). 继续 / 存档 / 设置 / 回主菜单.

var is_open := false
var settings: CanvasLayer    # 由 main 注入
var main_ref: Node           # 由 main 注入 (提供 save_now)
var save_msg: Label
var first_btn: Button

func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0.02, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	center.add_child(vb)

	var title := Label.new()
	title.text = "暂停"
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(0.7, 0.95, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)

	first_btn = _btn(vb, "继续", _resume)
	_btn(vb, "存档", _on_save)
	_btn(vb, "设置", _on_settings)
	_btn(vb, "回主菜单", _on_title)

	save_msg = Label.new()
	save_msg.add_theme_font_size_override("font_size", 18)
	save_msg.add_theme_color_override("font_color", Color(0.5, 1, 0.7))
	save_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(save_msg)

func _btn(parent: Node, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(260, 46)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(cb)
	parent.add_child(b)
	UI.style_button(b)
	return b

func _unhandled_input(event: InputEvent) -> void:
	if settings and settings.is_open:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if is_open:
			_resume()
		elif Game.menu_open == 0:
			_open()

func _open() -> void:
	is_open = true
	visible = true
	get_tree().paused = true
	Game.menu_open += 1
	save_msg.text = ""
	if first_btn:
		first_btn.grab_focus()

func _resume() -> void:
	is_open = false
	visible = false
	get_tree().paused = false
	Game.menu_open = maxi(0, Game.menu_open - 1)

func _on_save() -> void:
	if main_ref and main_ref.has_method("save_now"):
		main_ref.save_now()
	save_msg.text = "已存档!"

func _on_settings() -> void:
	if settings:
		settings.open_panel()

func _on_title() -> void:
	get_tree().paused = false
	Game.menu_open = 0
	get_tree().change_scene_to_file("res://title.tscn")
