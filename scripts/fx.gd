class_name Fx
extends RefCounted
## 程序化粒子/特效辅助 (无需 .tres 资源)

static func _burst(parent: Node, pos: Vector2, count: int, color: Color,
		speed: float, spread: float, dir: Vector2, lifetime: float,
		scale_min: float, scale_max: float, gravity: float) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var p := CPUParticles2D.new()
	p.position = pos
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 0.9
	p.amount = count
	p.lifetime = lifetime
	p.direction = dir
	p.spread = spread
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, gravity)
	p.scale_amount_min = scale_min
	p.scale_amount_max = scale_max
	p.damping_min = 40.0
	p.damping_max = 80.0
	p.color = color
	parent.add_child(p)
	# 生命周期结束后自毁
	var t := parent.get_tree().create_timer(lifetime + 0.3)
	t.timeout.connect(func():
		if is_instance_valid(p):
			p.queue_free())

## 落地/跑动 尘土
static func dust(parent: Node, pos: Vector2, dir_x: float = 0.0) -> void:
	var dir := Vector2(dir_x, -0.3).normalized() if dir_x != 0.0 else Vector2(0, -1)
	_burst(parent, pos, 10, Color(0.85, 0.82, 0.7, 0.9), 140.0, 70.0, dir, 0.45, 2.0, 4.0, 200.0)

## 冲刺 拖尾尘
static func dash_dust(parent: Node, pos: Vector2, dir_x: float) -> void:
	_burst(parent, pos, 14, Color(0.6, 0.85, 1.0, 0.9), 200.0, 30.0,
		Vector2(-dir_x, -0.1).normalized(), 0.4, 2.0, 5.0, 60.0)

## 命中爆点 (橙黄火花)
static func hit_spark(parent: Node, pos: Vector2) -> void:
	_burst(parent, pos, 18, Color(1.0, 0.85, 0.4, 1.0), 320.0, 180.0, Vector2(0, -1), 0.35, 2.0, 5.0, 120.0)
	_burst(parent, pos, 10, Color(1.0, 0.5, 0.2, 1.0), 220.0, 180.0, Vector2(0, -1), 0.4, 2.0, 4.0, 100.0)

## 死亡爆裂
static func death_burst(parent: Node, pos: Vector2, tint: Color) -> void:
	_burst(parent, pos, 30, tint, 360.0, 180.0, Vector2(0, -1), 0.6, 3.0, 7.0, 300.0)
	_burst(parent, pos, 16, Color(1, 1, 1, 0.9), 260.0, 180.0, Vector2(0, -1), 0.5, 2.0, 5.0, 120.0)

## 飘字 (伤害/提示)
static func popup(parent: Node, pos: Vector2, text: String, color: Color = Color.WHITE) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var l := Label.new()
	l.text = text
	l.position = pos
	l.z_index = 100
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", 26)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 6)
	l.pivot_offset = Vector2(20, 16)
	l.scale = Vector2(1.6, 1.6)
	parent.add_child(l)
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "position:y", pos.y - 42, 0.6)
	tw.tween_property(l, "modulate:a", 0.0, 0.6).set_delay(0.25)
	tw.chain().tween_callback(l.queue_free)

## 爆炸 (炸弹/重击): 火球 + 白核 + 碎裂粒子 + 冲击波环
static func explosion(parent: Node, pos: Vector2, radius: float = 150.0) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var add_mat := CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var ring := func(rad: float) -> PackedVector2Array:
		var p := PackedVector2Array()
		for i in range(20):
			var a := TAU * i / 20.0
			p.append(Vector2(cos(a), sin(a)) * rad)
		return p
	# 外层橙色火球
	var fire := Polygon2D.new()
	fire.polygon = ring.call(16.0)
	fire.color = Color(1.0, 0.55, 0.15)
	fire.position = pos; fire.scale = Vector2(0.3, 0.3); fire.z_index = 20
	fire.material = add_mat
	parent.add_child(fire)
	var tw := fire.create_tween()
	tw.set_parallel(true)
	tw.tween_property(fire, "scale", Vector2(radius / 16.0, radius / 16.0), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(fire, "modulate:a", 0.0, 0.32)
	tw.chain().tween_callback(fire.queue_free)
	# 内层白核
	var core := Polygon2D.new()
	core.polygon = ring.call(14.0)
	core.color = Color(1.0, 0.95, 0.8)
	core.position = pos; core.scale = Vector2(0.25, 0.25); core.z_index = 21
	core.material = add_mat
	parent.add_child(core)
	var tw2 := core.create_tween()
	tw2.set_parallel(true)
	tw2.tween_property(core, "scale", Vector2(radius / 22.0, radius / 22.0), 0.18)
	tw2.tween_property(core, "modulate:a", 0.0, 0.2)
	tw2.chain().tween_callback(core.queue_free)
	# 碎裂粒子(三层)
	_burst(parent, pos, 26, Color(1.0, 0.8, 0.3), 420.0, 180.0, Vector2(0, -1), 0.5, 2.0, 6.0, 240.0)
	_burst(parent, pos, 18, Color(1.0, 0.5, 0.2), 320.0, 180.0, Vector2(0, -1), 0.55, 2.0, 5.0, 200.0)
	_burst(parent, pos, 12, Color(0.3, 0.3, 0.32), 200.0, 180.0, Vector2(0, -1), 0.7, 2.0, 5.0, 320.0)
	shockwave(parent, pos, Color(1.0, 0.7, 0.35))
	hit_ring(parent, pos, Color(1.0, 0.85, 0.5))

## 命中冲击环 (打击点快速扩散环, 增强打击感)
static func hit_ring(parent: Node, pos: Vector2, color: Color = Color(1, 1, 1)) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var ring := Line2D.new()
	ring.width = 4.0
	ring.default_color = color
	ring.closed = true
	var pts := PackedVector2Array()
	for i in range(16):
		var a := TAU * i / 16.0
		pts.append(Vector2(cos(a), sin(a)) * 12.0)
	ring.points = pts
	ring.position = pos
	ring.z_index = 22
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	ring.material = mat
	parent.add_child(ring)
	var tw := ring.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector2(3.0, 3.0), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(ring, "modulate:a", 0.0, 0.22)
	tw.chain().tween_callback(ring.queue_free)

## 全屏闪光 (重击/技能命中)
static func screen_flash(tree: SceneTree, color: Color = Color(1, 1, 1, 0.35)) -> void:
	if tree == null:
		return
	var cl := CanvasLayer.new()
	cl.layer = 50
	var rect := ColorRect.new()
	rect.color = color
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(rect)
	tree.root.add_child(cl)
	var tw := rect.create_tween()
	tw.tween_property(rect, "color:a", 0.0, 0.22)
	tw.tween_callback(cl.queue_free)

## 冲击波环 (落地砸地/AoE)
static func shockwave(parent: Node, pos: Vector2, color: Color = Color(0.6, 0.85, 1.0)) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var ring := Line2D.new()
	ring.width = 6.0
	ring.default_color = color
	ring.closed = true
	var pts := PackedVector2Array()
	for i in range(24):
		var a := TAU * i / 24.0
		pts.append(Vector2(cos(a), sin(a)) * 10.0)
	ring.points = pts
	ring.position = pos
	ring.z_index = 15
	parent.add_child(ring)
	var tw := ring.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector2(7, 4), 0.35)
	tw.tween_property(ring, "modulate:a", 0.0, 0.35)
	tw.chain().tween_callback(ring.queue_free)

## 技能起手: 能量核闪 + 扩散环 + 火花 (让"放技能"那一下更有仪式感)
static func cast_ring(parent: Node, pos: Vector2, color: Color) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var add_mat := CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	# 中心核闪
	var core := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in range(16):
		var a := TAU * i / 16.0
		pts.append(Vector2(cos(a), sin(a)) * 18.0)
	core.polygon = pts
	core.color = color
	core.position = pos
	core.scale = Vector2(0.2, 0.2)
	core.z_index = 23
	core.material = add_mat
	parent.add_child(core)
	var tw := core.create_tween()
	tw.set_parallel(true)
	tw.tween_property(core, "scale", Vector2(1.4, 1.4), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(core, "modulate:a", 0.0, 0.2)
	tw.chain().tween_callback(core.queue_free)
	hit_ring(parent, pos, color)
	_burst(parent, pos, 12, color, 240.0, 180.0, Vector2(0, -1), 0.35, 2.0, 4.0, 60.0)

## 冲刺速度线 (横向能量条纹, 强调位移冲击)
static func speed_lines(parent: Node, pos: Vector2, dir_x: float, color: Color) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var add_mat := CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for i in range(5):
		var off := Vector2(randf_range(-20, 20), randf_range(-55, 5))
		var ln := Line2D.new()
		ln.width = randf_range(2.0, 4.0)
		ln.default_color = color
		ln.points = PackedVector2Array([pos + off, pos + off - Vector2(dir_x * randf_range(50, 90), 0)])
		ln.z_index = 19
		ln.material = add_mat
		parent.add_child(ln)
		var tw := ln.create_tween()
		tw.set_parallel(true)
		tw.tween_property(ln, "position:x", -dir_x * 60.0, 0.22)
		tw.tween_property(ln, "modulate:a", 0.0, 0.22)
		tw.chain().tween_callback(ln.queue_free)

## 一次性播放的特效动画 (如斩击), additive 发光
static func play_slash(parent: Node, pos: Vector2, facing: float, frames: SpriteFrames,
		scale: float = 0.9, tint: Color = Color(1, 1, 1)) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var a := AnimatedSprite2D.new()
	a.sprite_frames = frames
	a.position = pos
	a.flip_h = facing < 0
	a.scale = Vector2(scale, scale)
	a.modulate = tint
	a.z_index = 20
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	a.material = mat
	parent.add_child(a)
	a.play("swing")
	a.animation_finished.connect(func():
		if is_instance_valid(a):
			a.queue_free())
