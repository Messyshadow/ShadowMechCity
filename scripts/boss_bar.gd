extends CanvasLayer
## 顶部 Boss 血条 (名字 + 阶段).

var name_label: Label
var bar: ProgressBar
var root: Control

func _ready() -> void:
	layer = 12
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_TOP_WIDE)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	name_label = Label.new()
	name_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	name_label.position = Vector2(0, 40)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.4))
	name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	name_label.add_theme_constant_override("outline_size", 6)
	root.add_child(name_label)

	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.1, 0.05, 0.05, 0.7)
	bar_bg.set_anchors_preset(Control.PRESET_CENTER_TOP)
	bar_bg.position = Vector2(-360, 70)
	bar_bg.size = Vector2(720, 22)
	root.add_child(bar_bg)

	bar = ProgressBar.new()
	bar.position = Vector2(-356, 72)
	bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	bar.custom_minimum_size = Vector2(712, 18)
	bar.size = Vector2(712, 18)
	bar.show_percentage = false
	bar.min_value = 0
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.95, 0.25, 0.2)
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.2, 0.1, 0.1, 0.0)
	bar.add_theme_stylebox_override("background", bg)
	root.add_child(bar)

	visible = false

func show_boss(bname: String) -> void:
	name_label.text = bname
	visible = true
	root.modulate.a = 0.0
	root.create_tween().tween_property(root, "modulate:a", 1.0, 0.5)

func set_hp(cur: int, maxv: int, phase: int) -> void:
	bar.max_value = maxv
	bar.value = cur
	var fill := bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill:
		fill.bg_color = Color(0.95, 0.25, 0.2) if phase == 1 else Color(1.0, 0.45, 0.15)
	name_label.text = name_label.text.split("  ")[0] + ("  ·  第2阶段·狂化" if phase >= 2 else "")

func hide_boss() -> void:
	var tw := create_tween()
	tw.tween_property(root, "modulate:a", 0.0, 0.6)
	tw.tween_callback(func(): visible = false)
