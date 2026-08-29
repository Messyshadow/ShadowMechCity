class_name SummonFx
extends RefCounted
## 11.1d 量子伙伴视觉层。每个根特效计为一个预算单位，避免三机战斗淹没敌方预警。

const MAX_ACTIVE_FX := 18


static func warning_duration(style: String) -> float:
	match style:
		"artillery": return 0.42
		"vanguard": return 0.32
		"support": return 0.38
		_: return 0.24


static func warning_shape(style: String) -> String:
	match style:
		"artillery": return "target_laser"
		"vanguard": return "impact_wedge"
		"support": return "repair_orbit"
		_: return "strike_arc"


static func active_fx_count(tree: SceneTree) -> int:
	return tree.get_nodes_in_group("summon_fx").size() if tree != null else 0


static func _root(parent: Node, pos: Vector2, name_text: String) -> Node2D:
	if parent == null or not is_instance_valid(parent) or parent.get_tree() == null:
		return null
	if active_fx_count(parent.get_tree()) >= MAX_ACTIVE_FX:
		return null
	var root := Node2D.new()
	root.name = name_text
	root.position = pos
	root.z_index = 16
	root.add_to_group("summon_fx")
	parent.add_child(root)
	return root


static func _material() -> CanvasItemMaterial:
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return material


static func _circle(radius: float, count: int = 32, stretch := Vector2.ONE) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(count + 1):
		var angle := TAU * float(i) / float(count)
		points.append(Vector2(cos(angle) * radius * stretch.x, sin(angle) * radius * stretch.y))
	return points


static func _line(root: Node2D, points: PackedVector2Array, width: float, color: Color) -> Line2D:
	var line := Line2D.new()
	line.points = points
	line.width = width
	line.default_color = color
	line.antialiased = true
	line.material = _material()
	root.add_child(line)
	return line


static func _finish(root: Node2D, duration: float, scale_to := Vector2.ONE) -> void:
	var tween := root.create_tween().set_parallel(true)
	tween.tween_property(root, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(root, "scale", scale_to, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(root.queue_free)


static func _particles(root: Node2D, color: Color, amount: int, direction := Vector2(0, -1)) -> void:
	var particles := CPUParticles2D.new()
	particles.one_shot = true
	particles.emitting = true
	particles.explosiveness = 0.82
	particles.amount = amount
	particles.lifetime = 0.46
	particles.direction = direction
	particles.spread = 52.0
	particles.initial_velocity_min = 65.0
	particles.initial_velocity_max = 180.0
	particles.scale_amount_min = 1.6
	particles.scale_amount_max = 3.8
	particles.color = color
	particles.material = _material()
	root.add_child(particles)


static func projection(parent: Node, pos: Vector2, accent: Color, slot_index: int = 0) -> Node2D:
	var root := _root(parent, pos, "SummonProjection")
	if root == null:
		return null
	root.scale = Vector2(0.72, 0.72)
	var beam := Polygon2D.new()
	beam.polygon = PackedVector2Array([Vector2(-34, 8), Vector2(-17, -150), Vector2(17, -150), Vector2(34, 8)])
	beam.color = Color(accent.r, accent.g, accent.b, 0.16)
	beam.material = _material()
	root.add_child(beam)
	_line(root, _circle(47.0, 36, Vector2(1.0, 0.28)), 5.0, Color(accent.r, accent.g, accent.b, 0.9))
	_line(root, _circle(30.0, 28, Vector2(1.0, 0.28)), 2.0, Color(0.8, 0.98, 1.0, 0.75))
	for x in [-24.0, 0.0, 24.0]:
		_line(root, PackedVector2Array([Vector2(x, 0), Vector2(x * 0.3, -138)]), 2.0, Color(accent.r, accent.g, accent.b, 0.52))
	var glyph := Label.new()
	glyph.text = "0%d" % (slot_index + 1)
	glyph.position = Vector2(-12, -98)
	glyph.add_theme_font_size_override("font_size", 18)
	glyph.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 0.92))
	root.add_child(glyph)
	_particles(root, accent, 12)
	_finish(root, 0.62, Vector2(1.18, 1.18))
	return root


static func recall(parent: Node, pos: Vector2, accent: Color) -> Node2D:
	var root := _root(parent, pos, "SummonRecall")
	if root == null:
		return null
	root.scale = Vector2(1.18, 1.18)
	_line(root, _circle(52.0, 36, Vector2(1.0, 0.3)), 5.0, Color(accent.r, accent.g, accent.b, 0.92))
	_line(root, _circle(35.0, 28, Vector2(1.0, 0.3)), 2.0, Color(0.78, 0.96, 1.0, 0.72))
	for x in [-28.0, -9.0, 9.0, 28.0]:
		_line(root, PackedVector2Array([Vector2(x, 6), Vector2(x * 0.18, -128)]), 2.5, Color(accent.r, accent.g, accent.b, 0.62))
	_particles(root, accent, 10, Vector2(0, -1))
	_finish(root, 0.48, Vector2(0.28, 0.7))
	return root


static func disabled_burst(parent: Node, pos: Vector2, accent: Color) -> Node2D:
	var root := _root(parent, pos, "SummonDisabledBurst")
	if root == null:
		return null
	_line(root, _circle(28.0), 7.0, Color(1.0, 0.3, 0.45, 0.9))
	_line(root, _circle(46.0), 3.0, Color(accent.r, accent.g, accent.b, 0.62))
	for i in range(8):
		var angle := float(i) * TAU / 8.0
		var direction := Vector2.from_angle(angle)
		_line(root, PackedVector2Array([direction * 18.0, direction * (52.0 + float(i % 3) * 8.0)]), 4.0, Color(1.0, 0.55, 0.32, 0.9))
	_particles(root, Color("ff6b45"), 18, Vector2(0, -1))
	_finish(root, 0.58, Vector2(1.45, 1.45))
	return root


static func skill_warning(parent: Node, origin: Vector2, target_pos: Vector2,
		style: String, accent: Color) -> Node2D:
	var root := _root(parent, origin, "SummonSkillWarning_%s" % warning_shape(style))
	if root == null:
		return null
	var local_target := target_pos - origin
	var direction := local_target.normalized() if local_target.length() > 1.0 else Vector2.RIGHT
	var warning := Color(accent.r, accent.g, accent.b, 0.78)
	match warning_shape(style):
		"target_laser":
			_line(root, PackedVector2Array([Vector2.ZERO, local_target]), 3.0, warning)
			var reticle := Node2D.new(); reticle.position = local_target; root.add_child(reticle)
			_line(reticle, _circle(30.0), 4.0, warning)
			_line(reticle, PackedVector2Array([Vector2(-42, 0), Vector2(42, 0)]), 2.0, warning)
			_line(reticle, PackedVector2Array([Vector2(0, -42), Vector2(0, 42)]), 2.0, warning)
		"impact_wedge":
			var normal := Vector2(-direction.y, direction.x)
			_line(root, PackedVector2Array([normal * 25.0, direction * 104.0, -normal * 25.0]), 6.0, warning)
			_line(root, _circle(46.0, 28, Vector2(1.0, 0.35)), 3.0, warning)
		"repair_orbit":
			_line(root, _circle(72.0, 36, Vector2(1.0, 0.62)), 5.0, warning)
			_line(root, _circle(45.0, 28, Vector2(1.0, 0.62)), 2.0, Color(0.8, 1.0, 0.9, 0.72))
			_line(root, PackedVector2Array([Vector2(-18, 0), Vector2(18, 0)]), 5.0, warning)
			_line(root, PackedVector2Array([Vector2(0, -18), Vector2(0, 18)]), 5.0, warning)
		_:
			var points := PackedVector2Array()
			var angle := direction.angle()
			for i in range(18):
				var t := float(i) / 17.0
				points.append(Vector2.from_angle(angle + lerpf(-0.78, 0.78, t)) * 82.0)
			_line(root, points, 6.0, warning)
			_line(root, PackedVector2Array([direction * 22.0, direction * 112.0]), 2.0, warning)
	root.modulate.a = 0.25
	var duration := warning_duration(style)
	var tween := root.create_tween()
	tween.tween_property(root, "modulate:a", 1.0, duration * 0.58).set_trans(Tween.TRANS_SINE)
	tween.tween_property(root, "modulate:a", 0.0, duration * 0.42)
	tween.tween_callback(root.queue_free)
	return root
