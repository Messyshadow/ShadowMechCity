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
		# 发布包从标题场景启动；房间 QA 必须先进入主场景，不能在只读 PCK 上截标题页后退出。
		if _qa_option("SHOT_ROOM") != "":
			get_tree().change_scene_to_file.call_deferred("res://main.tscn")
		else:
			_auto_shot()

func _auto_shot() -> void:
	await get_tree().create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	var shot_output := _qa_option("SHOT_OUTPUT")
	if shot_output == "":
		shot_output = ProjectSettings.globalize_path("res://_shot.png")
	var save_error := get_viewport().get_texture().get_image().save_png(shot_output)
	if save_error != OK:
		push_error("Failed to save title QA screenshot to %s: %s" % [shot_output, error_string(save_error)])
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()

func _qa_option(env_name: String) -> String:
	var value := OS.get_environment(env_name)
	if value != "":
		return value
	var prefix := "--%s=" % env_name.to_lower().replace("_", "-")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	for arg in OS.get_cmdline_args():
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return ""

func _build_bg() -> void:
	var fallback := ColorRect.new()
	fallback.color = Color(0.012, 0.022, 0.04)
	fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fallback)
	var hero_path := "res://assets/bg/title/shadow_mech_city_title.png"
	if ResourceLoader.exists(hero_path):
		var hero := TextureRect.new()
		hero.texture = load(hero_path)
		hero.set_anchors_preset(Control.PRESET_FULL_RECT)
		hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		hero.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(hero)
	var dim := ColorRect.new()
	dim.color = Color(0.005, 0.012, 0.03, 0.14)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var left_veil := ColorRect.new()
	left_veil.color = Color(0.004, 0.01, 0.025, 0.42)
	left_veil.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	left_veil.offset_right = 590
	add_child(left_veil)
	# 上下电影遮幅兼作暗角，避免标题与背景高光互相争抢。
	for top in [true, false]:
		var band := ColorRect.new()
		band.color = Color(0.002, 0.006, 0.018, 0.58)
		band.set_anchors_preset(Control.PRESET_TOP_WIDE if top else Control.PRESET_BOTTOM_WIDE)
		if top:
			band.offset_bottom = 34
		else:
			band.offset_top = -30
		add_child(band)

func _build_menu() -> void:
	var plate := PanelContainer.new()
	plate.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	plate.offset_left = 66
	plate.offset_right = 516
	plate.offset_top = -306
	plate.offset_bottom = 306
	var plate_style := StyleBoxFlat.new()
	plate_style.bg_color = Color(0.018, 0.035, 0.06, 0.84)
	plate_style.border_color = Color(0.24, 0.7, 0.88, 0.72)
	plate_style.set_border_width_all(1)
	plate_style.set_corner_radius_all(12)
	plate_style.content_margin_left = 34
	plate_style.content_margin_right = 34
	plate_style.content_margin_top = 24
	plate_style.content_margin_bottom = 24
	plate.add_theme_stylebox_override("panel", plate_style)
	add_child(plate)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 13)
	plate.add_child(vb)

	var build_marker := Label.new()
	build_marker.text = "阶段 12.2  ·  主线任务系统"
	build_marker.add_theme_font_size_override("font_size", 16)
	build_marker.add_theme_color_override("font_color", Color(0.95, 0.62, 0.32))
	build_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(build_marker)

	var title := Label.new()
	title.text = "暗影机械城"
	title.add_theme_font_size_override("font_size", 58)
	title.add_theme_color_override("font_color", Color(0.7, 0.95, 1.0))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	title.add_theme_constant_override("outline_size", 10)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)

	var sub := Label.new()
	sub.text = "SHADOW MECH CITY\n暗黑机械 · 虚空侵蚀 · 横版动作"
	sub.add_theme_font_size_override("font_size", 17)
	sub.add_theme_color_override("font_color", Color(1, 0.6, 0.3))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 18)
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
	b.custom_minimum_size = Vector2(0, 50)
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
