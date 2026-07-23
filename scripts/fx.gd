class_name Fx
extends RefCounted

const SKILL_FX_PROFILE := preload("res://scripts/skill_fx_profile.gd")

static func _additive_material() -> CanvasItemMaterial:
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return material

static func _circle_points(radius: float, count: int = 24, stretch := Vector2.ONE) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(count):
		var angle := TAU * float(i) / float(count)
		points.append(Vector2(cos(angle) * radius * stretch.x, sin(angle) * radius * stretch.y))
	return points

static func _arc_points(radius: float, start_angle: float, end_angle: float, count: int = 18) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(count):
		var weight := float(i) / float(maxi(1, count - 1))
		var angle := lerpf(start_angle, end_angle, weight)
		points.append(Vector2.from_angle(angle) * radius)
	return points

static func _fx_line(parent: Node, points: PackedVector2Array, width: float,
		color: Color, z_index: int, additive := true) -> Line2D:
	var line := Line2D.new()
	line.points = points
	line.width = width
	line.default_color = color
	line.z_index = z_index
	line.antialiased = true
	if additive:
		line.material = _additive_material()
	parent.add_child(line)
	return line

static func _fade_and_free(item: CanvasItem, duration: float, grow := Vector2.ONE) -> void:
	var tween := item.create_tween()
	tween.set_parallel(true)
	if grow != Vector2.ONE:
		tween.tween_property(item, "scale", grow, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(item, "modulate:a", 0.0, duration)
	tween.chain().tween_callback(item.queue_free)

## 主动技能预警层：范围/方向先读，始终位于攻击主体之上。
static func skill_telegraph(parent: Node, pos: Vector2, facing: float,
		profile: Dictionary) -> CanvasItem:
	if parent == null or not is_instance_valid(parent):
		return null
	var root := Node2D.new()
	root.name = "SkillTelegraph"
	root.position = pos
	root.scale = Vector2(float(profile["scale"]), float(profile["scale"]))
	root.z_index = int(profile["z_telegraph"])
	root.set_meta("skill_fx_layer", "telegraph")
	parent.add_child(root)
	var color: Color = profile["secondary"]
	color.a = minf(color.a, 0.58)
	var shape := String(profile["shape"])
	match shape:
		"arc":
			_fx_line(root, _arc_points(82.0, -1.0, 1.0), 3.0, color, 0)
		"block":
			_fx_line(root, PackedVector2Array([
				Vector2(-54, 10), Vector2(-54, -24), Vector2(72, -24),
				Vector2(72, 10), Vector2(-54, 10),
			]), 3.0, color, 0)
		"steam_beam":
			_fx_line(root, PackedVector2Array([Vector2(6, -15), Vector2(170, -15)]), 3.0, color, 0)
			_fx_line(root, PackedVector2Array([Vector2(6, 15), Vector2(170, 15)]), 3.0, color, 0)
		"cross":
			_fx_line(root, _circle_points(72.0, 24, Vector2(1.0, 0.62)), 3.0, color, 0)
		"lance":
			_fx_line(root, PackedVector2Array([
				Vector2(8, 0), Vector2(128, -18), Vector2(184, 0),
				Vector2(128, 18), Vector2(8, 0),
			]), 3.0, color, 0)
		"reticle":
			_fx_line(root, _circle_points(48.0), 3.0, color, 0)
			_fx_line(root, PackedVector2Array([Vector2(48, 0), Vector2(174, 0)]), 2.0, color, 0)
	root.scale.x *= facing
	_fade_and_free(root, minf(0.28, float(profile["duration"]) * 0.55),
		Vector2(root.scale.x * 1.06, root.scale.y * 1.06))
	return root

## 主动技能主体层：六种武器使用六种轮廓，而不是仅替换颜色。
static func skill_body(parent: Node, pos: Vector2, facing: float,
		profile: Dictionary) -> CanvasItem:
	if parent == null or not is_instance_valid(parent):
		return null
	var root := Node2D.new()
	root.name = "SkillBody"
	root.position = pos
	root.scale = Vector2(float(profile["scale"]) * facing, float(profile["scale"]))
	root.z_index = int(profile["z_body"])
	root.set_meta("skill_fx_layer", "body")
	parent.add_child(root)
	var primary: Color = profile["primary"]
	var secondary: Color = profile["secondary"]
	match String(profile["shape"]):
		"arc":
			_fx_line(root, _arc_points(72.0, -1.18, 1.12), 9.0, primary, 0)
			_fx_line(root, _arc_points(88.0, -1.05, 0.95), 3.0, secondary, 0)
		"block":
			var block := Polygon2D.new()
			block.polygon = PackedVector2Array([
				Vector2(-28, 4), Vector2(-10, -38), Vector2(34, -38),
				Vector2(68, 2), Vector2(34, 18), Vector2(-8, 18),
			])
			block.color = Color(primary.r, primary.g, primary.b, 0.5)
			block.material = _additive_material()
			root.add_child(block)
			for crack_x in [-20.0, 10.0, 40.0]:
				_fx_line(root, PackedVector2Array([
					Vector2(crack_x, 10), Vector2(crack_x + 12, 30), Vector2(crack_x + 5, 52),
				]), 4.0, secondary, 1)
		"steam_beam":
			var beam := Polygon2D.new()
			beam.polygon = PackedVector2Array([
				Vector2(0, -10), Vector2(190, -24), Vector2(228, 0),
				Vector2(190, 24), Vector2(0, 10),
			])
			beam.color = Color(primary.r, primary.g, primary.b, 0.42)
			beam.material = _additive_material()
			root.add_child(beam)
			_fx_line(root, PackedVector2Array([Vector2(0, 0), Vector2(224, 0)]), 6.0, secondary, 1)
		"cross":
			_fx_line(root, PackedVector2Array([Vector2(-54, -48), Vector2(68, 50)]), 8.0, primary, 0)
			_fx_line(root, PackedVector2Array([Vector2(-54, 48), Vector2(68, -50)]), 8.0, secondary, 1)
			_fx_line(root, _circle_points(62.0, 20, Vector2(1.0, 0.7)), 3.0, primary, 0)
		"lance":
			var lance := Polygon2D.new()
			lance.polygon = PackedVector2Array([
				Vector2(-20, 0), Vector2(40, -9), Vector2(188, -4),
				Vector2(238, 0), Vector2(188, 4), Vector2(40, 9),
			])
			lance.color = Color(primary.r, primary.g, primary.b, 0.72)
			lance.material = _additive_material()
			root.add_child(lance)
			_fx_line(root, PackedVector2Array([Vector2(-12, 0), Vector2(226, 0)]), 3.0, secondary, 1)
		"reticle":
			_fx_line(root, _circle_points(42.0), 5.0, primary, 0)
			_fx_line(root, PackedVector2Array([Vector2(-58, 0), Vector2(58, 0)]), 3.0, secondary, 1)
			_fx_line(root, PackedVector2Array([Vector2(0, -58), Vector2(0, 58)]), 3.0, secondary, 1)
			for offset_y in [-12.0, 0.0, 12.0]:
				_fx_line(root, PackedVector2Array([Vector2(50, offset_y), Vector2(198, offset_y * 1.7)]), 2.5, primary, 0)
	_fade_and_free(root, minf(0.5, float(profile["duration"]) * 0.72),
		Vector2(root.scale.x * 1.14, root.scale.y * 1.08))
	return root

## 主动技能残留层：低亮度、短生命周期，保持场景和敌方预警可读。
static func skill_residue(parent: Node, pos: Vector2, facing: float,
		profile: Dictionary) -> CanvasItem:
	if parent == null or not is_instance_valid(parent):
		return null
	var root := Node2D.new()
	root.name = "SkillResidue"
	root.position = pos
	root.scale = Vector2(float(profile["scale"]) * facing, float(profile["scale"]))
	root.z_index = int(profile["z_residue"])
	root.set_meta("skill_fx_layer", "residue")
	parent.add_child(root)
	var color: Color = profile["primary"]
	color.a = 0.24
	var length := 110.0
	if String(profile["shape"]) in ["steam_beam", "lance", "reticle"]:
		length = 210.0
	for offset in [-12.0, 0.0, 12.0]:
		_fx_line(root, PackedVector2Array([
			Vector2(-20, offset), Vector2(length, offset * 0.35),
		]), 2.0 if offset != 0.0 else 3.0, color, 0, false)
	_fade_and_free(root, float(profile["duration"]))
	return root

## 统一主动技能入口。真实命中层由 combat_impact 在伤害生效时生成。
static func layered_skill(parent: Node, pos: Vector2, facing: float,
		weapon_id: String, cue: String) -> Array[CanvasItem]:
	var profile: Dictionary = SKILL_FX_PROFILE.profile(weapon_id, cue)
	var layers: Array[CanvasItem] = []
	var telegraph := skill_telegraph(parent, pos, facing, profile)
	var body := skill_body(parent, pos, facing, profile)
	var residue := skill_residue(parent, pos, facing, profile)
	for layer in [telegraph, body, residue]:
		if layer != null:
			layers.append(layer)
	var flash_alpha := float(profile["flash_alpha"])
	if flash_alpha > 0.0 and parent != null and parent.get_tree() != null:
		var primary: Color = profile["primary"]
		screen_flash(parent.get_tree(), Color(primary.r, primary.g, primary.b, flash_alpha))
	return layers
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

## 分层命中特效：方向火花、核心闪光、冲击环与短暂残留。
## profile / palette 来自 CombatFeedback，危险预警使用更高 z_index，不会被装饰粒子遮挡。
static func combat_impact(parent: Node, pos: Vector2, direction: Vector2,
		profile: Dictionary, palette: Dictionary) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var aim := direction.normalized() if direction.length_squared() > 0.01 else Vector2.RIGHT
	var particle_amount := int(profile.get("particle_amount", 12))
	var ring_width := float(profile.get("ring_width", 4.0))
	var core_color: Color = palette.get("core", Color.WHITE)
	var spark_color: Color = palette.get("spark", Color(1.0, 0.75, 0.3))
	var residue_color: Color = palette.get("residue", Color(0.2, 0.45, 0.7, 0.7))
	_burst(parent, pos, particle_amount, spark_color, 250.0 + ring_width * 16.0,
		38.0, aim, 0.28, 1.8, 3.8 + ring_width * 0.22, 95.0)
	var core := Polygon2D.new()
	core.polygon = PackedVector2Array([
		Vector2(-10, 0), Vector2(0, -7), Vector2(18, 0), Vector2(0, 7),
	])
	core.position = pos
	core.rotation = aim.angle()
	core.color = core_color
	core.z_index = 31
	var add_mat := CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	core.material = add_mat
	parent.add_child(core)
	var core_tween := core.create_tween()
	core_tween.set_parallel(true)
	core_tween.tween_property(core, "scale", Vector2(2.2, 1.4), 0.11)
	core_tween.tween_property(core, "modulate:a", 0.0, 0.14)
	core_tween.chain().tween_callback(core.queue_free)
	var ring := Line2D.new()
	ring.width = ring_width
	ring.default_color = spark_color
	ring.closed = true
	var ring_points := PackedVector2Array()
	for i in range(18):
		var angle := TAU * float(i) / 18.0
		ring_points.append(Vector2(cos(angle) * 13.0, sin(angle) * 8.0))
	ring.points = ring_points
	ring.position = pos
	ring.rotation = aim.angle()
	ring.z_index = 30
	ring.material = add_mat
	parent.add_child(ring)
	var ring_tween := ring.create_tween()
	ring_tween.set_parallel(true)
	ring_tween.tween_property(ring, "scale", Vector2(2.6, 2.0), 0.2)
	ring_tween.tween_property(ring, "modulate:a", 0.0, 0.2)
	ring_tween.chain().tween_callback(ring.queue_free)
	var residue := Line2D.new()
	residue.width = maxf(2.0, ring_width * 0.5)
	residue.default_color = residue_color
	residue.points = PackedVector2Array([pos - aim * 34.0, pos + aim * 12.0])
	residue.z_index = 18
	parent.add_child(residue)
	var residue_tween := residue.create_tween()
	residue_tween.tween_property(residue, "modulate:a", 0.0, 0.34)
	residue_tween.tween_callback(residue.queue_free)

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

static func weapon_switch(parent: Node, pos: Vector2, color: Color, weapon_kind: String) -> void:
	if parent == null: return
	for radius in [18.0, 34.0]:
		var ring := Line2D.new(); ring.width = 4.0; ring.closed = true; ring.default_color = color
		var pts := PackedVector2Array()
		for i in range(24):
			var a := TAU * i / 24.0; pts.append(Vector2(cos(a), sin(a)) * radius)
		ring.points = pts; ring.position = pos; ring.z_index = 30; parent.add_child(ring)
		var tw := ring.create_tween(); tw.tween_property(ring, "scale", Vector2(0.2, 0.2), 0.52); tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.52); tw.tween_callback(ring.queue_free)
	var flare := Line2D.new(); flare.width = 6.0 if weapon_kind == "hammer" else 3.0; flare.default_color = color
	flare.points = PackedVector2Array([pos + Vector2(0, -54), pos + Vector2(0, 42)]); flare.z_index = 31; parent.add_child(flare)
	var ft := flare.create_tween(); ft.tween_property(flare, "modulate:a", 0.0, 0.42); ft.tween_callback(flare.queue_free)

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
