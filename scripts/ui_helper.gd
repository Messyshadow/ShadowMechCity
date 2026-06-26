class_name UI
extends RefCounted
## 菜单按钮统一处理: 键盘导航焦点高亮 + 鼠标悬停同步焦点

static func style_button(b: Button) -> void:
	b.focus_mode = Control.FOCUS_ALL
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0.22, 0.52, 0.78, 0.95)
	focus.set_border_width_all(3)
	focus.border_color = Color(0.7, 0.97, 1.0)
	focus.set_corner_radius_all(6)
	b.add_theme_stylebox_override("focus", focus)
	b.add_theme_stylebox_override("hover", focus.duplicate())
	# 鼠标移到按钮上 = 取得键盘焦点(鼠标/键盘一致)
	b.mouse_entered.connect(func(): b.grab_focus())
