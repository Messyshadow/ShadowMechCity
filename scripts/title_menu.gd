extends Control
## 开始菜单: 新游戏 / 继续 / 设置 / 退出

var settings: CanvasLayer

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_bg()
	_build_menu()
	# 设置面板
	settings = CanvasLayer.new()
	settings.set_script(load("res://scripts/settings_panel.gd"))
	add_child(settings)
	if "--shot" in OS.get_cmdline_args() or "--shot" in OS.get_cmdline_user_args():
		_auto_shot()

func _auto_shot() -> void:
	await get_tree().create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://_shot.png"))
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()

func _build_bg() -> void:
	var sky := TextureRect.new()
	sky.texture = load("res://assets/bg/city/sky.png")
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(sky)
	var hills := TextureRect.new()
	hills.texture = load("res://assets/bg/city/near.png")
	hills.set_anchors_preset(Control.PRESET_FULL_RECT)
	hills.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hills.stretch_mode = TextureRect.STRETCH_SCALE
	hills.modulate = Color(1, 1, 1, 0.85)
	add_child(hills)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0.03, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

func _build_menu() -> void:
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_CENTER)
	vb.position = Vector2(-160, -170)
	vb.custom_minimum_size = Vector2(320, 0)
	vb.add_theme_constant_override("separation", 16)
	add_child(vb)

	var title := Label.new()
	title.text = "暗影机械城"
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.7, 0.95, 1.0))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	title.add_theme_constant_override("outline_size", 10)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)

	var sub := Label.new()
	sub.text = "SHADOW MECH CITY  ·  横版动作"
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", Color(1, 0.6, 0.3))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	vb.add_child(spacer)

	var newb := _btn(vb, "新游戏", _new_game)
	var cont := _btn(vb, "继续", _continue)
	cont.disabled = not Game.has_save()
	_btn(vb, "设置", _open_settings)
	_btn(vb, "退出", func(): get_tree().quit())
	newb.grab_focus()

func _btn(parent: Node, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(320, 50)
	b.add_theme_font_size_override("font_size", 24)
	b.pressed.connect(cb)
	parent.add_child(b)
	UI.style_button(b)
	return b

func _new_game() -> void:
	Game.reset()
	Game.menu_open = 0
	get_tree().change_scene_to_file("res://main.tscn")

func _continue() -> void:
	if Game.load_save():
		Game.menu_open = 0
		get_tree().change_scene_to_file("res://main.tscn")

func _open_settings() -> void:
	settings.open_panel()
