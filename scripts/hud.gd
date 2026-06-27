extends CanvasLayer
## 抬头显示: 血量 / 击杀 / 当前武器 / 区域 / 操作提示

var hearts: Label
var kills_label: Label
var weapon_label: Label
var area_label: Label
var level_label: Label
var sp_label: Label
var xp_bar: ProgressBar
var mp_bar: ProgressBar
var rage_bar: ProgressBar
var hint: Label

func _ready() -> void:
	layer = 10
	hearts = _make_label(Vector2(24, 16), 34, Color(1, 0.3, 0.35))
	hearts.text = "♥♥♥♥♥"
	kills_label = _make_label(Vector2(24, 62), 22, Color(1, 0.9, 0.5))
	kills_label.text = "击杀: 0"
	weapon_label = _make_label(Vector2(24, 92), 22, Color(0.6, 0.95, 1.0))
	weapon_label.text = "武器: 铁剑"

	level_label = _make_label(Vector2(24, 124), 20, Color(0.8, 0.9, 1.0))
	level_label.text = "Lv.1"
	# 经验条
	xp_bar = ProgressBar.new()
	xp_bar.position = Vector2(24, 154)
	xp_bar.custom_minimum_size = Vector2(230, 14)
	xp_bar.size = Vector2(230, 14)
	xp_bar.min_value = 0
	xp_bar.max_value = 1
	xp_bar.value = 0
	xp_bar.show_percentage = false
	add_child(xp_bar)
	sp_label = _make_label(Vector2(24, 196), 18, Color(1.0, 0.85, 0.3))
	sp_label.text = ""
	# 技力(蓝) / 怒气(橙) 资源条
	mp_bar = _make_bar(174, Color(0.35, 0.7, 1.0), Color(0.05, 0.1, 0.2, 0.7))
	rage_bar = _make_bar(186, Color(1.0, 0.55, 0.2), Color(0.18, 0.08, 0.04, 0.7))
	rage_bar.value = 0

	# 区域名(右上)
	area_label = Label.new()
	area_label.add_theme_font_size_override("font_size", 24)
	area_label.add_theme_color_override("font_color", Color(0.7, 0.95, 1.0))
	area_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	area_label.add_theme_constant_override("outline_size", 6)
	area_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	area_label.position = Vector2(-360, 18)
	area_label.size = Vector2(330, 30)
	area_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(area_label)

	_build_control_chips()

# 底部半透明 控制/技能 图标栏
func _build_control_chips() -> void:
	# 左下: 移动键
	var move_box := HBoxContainer.new()
	move_box.add_theme_constant_override("separation", 6)
	move_box.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	move_box.offset_left = 20; move_box.offset_top = -64; move_box.offset_bottom = -16
	add_child(move_box)
	_chip(move_box, "A", "◀", Color(0.6, 0.9, 1.0))
	_chip(move_box, "D", "▶", Color(0.6, 0.9, 1.0))
	_chip(move_box, "␣", "跳", Color(0.7, 1.0, 0.8))
	_chip(move_box, "⇧", "冲刺", Color(0.8, 0.85, 1.0))
	move_box.modulate.a = 0.6

	# 右下: 技能键
	var skill_box := HBoxContainer.new()
	skill_box.add_theme_constant_override("separation", 6)
	skill_box.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	skill_box.offset_right = -20; skill_box.offset_left = -560
	skill_box.offset_top = -64; skill_box.offset_bottom = -16
	skill_box.alignment = BoxContainer.ALIGNMENT_END
	add_child(skill_box)
	_chip(skill_box, "J", "普攻", Color(0.7, 0.95, 1.0))
	_chip(skill_box, "K", "技能 上/→→变招", Color(1.0, 0.7, 0.4))
	_chip(skill_box, "V", "大招", Color(1.0, 0.6, 0.3))
	_chip(skill_box, "Q", "换武器", Color(0.9, 0.8, 1.0))
	_chip(skill_box, "T", "加点", Color(1.0, 0.85, 0.4))
	_chip(skill_box, "U", "背包", Color(0.7, 0.9, 0.7))
	skill_box.modulate.a = 0.6

# 单个按键图标(半透明)
func _chip(parent: Node, key: String, action: String, color: Color) -> void:
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.12, 0.18, 0.55)
	sb.border_color = Color(color.r, color.g, color.b, 0.8)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(7)
	sb.content_margin_left = 9; sb.content_margin_right = 9
	sb.content_margin_top = 3; sb.content_margin_bottom = 3
	pc.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	pc.add_child(vb)
	var kl := Label.new()
	kl.text = key
	kl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kl.add_theme_font_size_override("font_size", 22)
	kl.add_theme_color_override("font_color", color)
	vb.add_child(kl)
	var al := Label.new()
	al.text = action
	al.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	al.add_theme_font_size_override("font_size", 13)
	al.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	vb.add_child(al)
	parent.add_child(pc)

func _make_bar(y: float, fill_col: Color, bg_col: Color) -> ProgressBar:
	var b := ProgressBar.new()
	b.position = Vector2(24, y)
	b.custom_minimum_size = Vector2(230, 10)
	b.size = Vector2(230, 10)
	b.min_value = 0
	b.max_value = 100
	b.value = 100
	b.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = bg_col
	bg.set_corner_radius_all(4)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill_col
	fg.set_corner_radius_all(4)
	b.add_theme_stylebox_override("background", bg)
	b.add_theme_stylebox_override("fill", fg)
	add_child(b)
	return b

func set_resources(cur_mp: float, max_mp: float, cur_rage: float, max_rage: float) -> void:
	mp_bar.max_value = max_mp
	mp_bar.value = cur_mp
	rage_bar.max_value = max_rage
	rage_bar.value = cur_rage
	# 怒气满: 高亮提示可放大招
	var ready: bool = cur_rage >= max_rage
	rage_bar.modulate = Color(1.4, 1.2, 0.6) if ready else Color(1, 1, 1)

func _make_label(pos: Vector2, size: int, color: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 6)
	add_child(l)
	return l

func set_health(cur: int, maxv: int) -> void:
	var s := ""
	for i in range(maxv):
		s += "♥" if i < cur else "♡"
	hearts.text = s

func set_kills(n: int) -> void:
	kills_label.text = "击杀: %d" % n

func set_weapon(name: String, color: Color) -> void:
	weapon_label.text = "武器: " + name
	weapon_label.add_theme_color_override("font_color", color)

func set_area(text: String) -> void:
	area_label.text = "区域 " + text

func set_progress() -> void:
	level_label.text = "Lv.%d    金币 %d" % [Game.level, Game.coins]
	xp_bar.max_value = Game.xp_needed()
	xp_bar.value = Game.xp
	if Game.skill_points > 0:
		sp_label.text = "技能点 %d  ·  按 T 加点!" % Game.skill_points
	else:
		sp_label.text = ""
