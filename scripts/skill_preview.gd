class_name SkillPreview
extends SubViewportContainer
## 独立技能教学预览：只播放表现，不生成 Area2D 或消耗 Game 资源。

const PREVIEW_SIZE := Vector2i(410, 190)

var viewport: SubViewport
var actor: AnimatedSprite2D
var weapon_sprite: Sprite2D
var current_tween: Tween
var training_dummy: Node2D
var environment_target: Node2D
var stage_caption: Label
var input_caption: Label
var effect: SkillPreviewEffect
var flash_overlay: ColorRect

func _ready() -> void:
	custom_minimum_size = Vector2(PREVIEW_SIZE)
	stretch = true
	_build_preview()

func _build_preview() -> void:
	viewport = SubViewport.new()
	viewport.name = "SkillPreviewViewport"
	viewport.size = PREVIEW_SIZE
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.018, 0.035, 0.06, 1.0)
	backdrop.position = Vector2.ZERO
	backdrop.size = Vector2(PREVIEW_SIZE)
	viewport.add_child(backdrop)
	for index in range(6):
		var line := Line2D.new()
		line.width = 1.0
		line.default_color = Color(0.16, 0.48, 0.62, 0.24)
		line.points = PackedVector2Array([Vector2(18 + index * 74, 18), Vector2(66 + index * 74, 168)])
		viewport.add_child(line)
	var floor_line := Line2D.new()
	floor_line.width = 3.0
	floor_line.default_color = Color(0.22, 0.82, 0.98, 0.55)
	floor_line.points = PackedVector2Array([Vector2(20, 156), Vector2(390, 156)])
	viewport.add_child(floor_line)
	effect = SkillPreviewEffect.new()
	effect.name = "SkillPreviewEffect"
	effect.position = Vector2(142, 123)
	effect.z_index = 4
	viewport.add_child(effect)
	training_dummy = Node2D.new()
	training_dummy.name = "TrainingDummy"
	training_dummy.position = Vector2(302, 126)
	training_dummy.z_index = 3
	var dummy_body := Polygon2D.new()
	dummy_body.polygon = PackedVector2Array([Vector2(-14, -22), Vector2(14, -22), Vector2(18, 25), Vector2(-18, 25)])
	dummy_body.color = Color(0.32, 0.38, 0.46)
	training_dummy.add_child(dummy_body)
	var dummy_core := Polygon2D.new()
	dummy_core.polygon = PackedVector2Array([Vector2(-7, -8), Vector2(7, -8), Vector2(7, 8), Vector2(-7, 8)])
	dummy_core.color = Color(1.0, 0.46, 0.22)
	training_dummy.add_child(dummy_core)
	viewport.add_child(training_dummy)
	environment_target = Node2D.new()
	environment_target.name = "EnvironmentTarget"
	environment_target.position = Vector2(365, 126)
	environment_target.z_index = 3
	var target_ring := Line2D.new()
	target_ring.width = 4.0
	target_ring.default_color = Color(0.3, 0.92, 1.0)
	var ring_points := PackedVector2Array()
	for point_index in range(33):
		var angle := TAU * point_index / 32.0
		ring_points.append(Vector2.from_angle(angle) * 24.0)
	target_ring.points = ring_points
	environment_target.add_child(target_ring)
	var target_core := Polygon2D.new()
	target_core.polygon = PackedVector2Array([Vector2(0, -11), Vector2(11, 0), Vector2(0, 11), Vector2(-11, 0)])
	target_core.color = Color(0.42, 0.9, 1.0, 0.7)
	environment_target.add_child(target_core)
	viewport.add_child(environment_target)
	stage_caption = Label.new()
	stage_caption.name = "StageCaption"
	stage_caption.position = Vector2(18, 8)
	stage_caption.size = Vector2(374, 26)
	stage_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_caption.add_theme_font_size_override("font_size", 14)
	stage_caption.add_theme_color_override("font_color", Color(0.68, 0.92, 1.0))
	stage_caption.add_theme_color_override("font_outline_color", Color(0.0, 0.01, 0.03))
	stage_caption.add_theme_constant_override("outline_size", 4)
	stage_caption.z_index = 12
	viewport.add_child(stage_caption)
	input_caption = Label.new()
	input_caption.name = "InputCaption"
	input_caption.position = Vector2(18, 162)
	input_caption.size = Vector2(374, 24)
	input_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	input_caption.add_theme_font_size_override("font_size", 13)
	input_caption.add_theme_color_override("font_color", Color(1.0, 0.82, 0.36))
	input_caption.add_theme_color_override("font_outline_color", Color(0.0, 0.01, 0.03))
	input_caption.add_theme_constant_override("outline_size", 4)
	input_caption.z_index = 12
	viewport.add_child(input_caption)
	actor = AnimatedSprite2D.new()
	actor.sprite_frames = AnimLoader.build_player()
	actor.position = Vector2(78, 141)
	actor.scale = Vector2(1.55, 1.55)
	actor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	actor.z_index = 5
	viewport.add_child(actor)
	weapon_sprite = Sprite2D.new()
	weapon_sprite.position = Vector2(133, 116)
	weapon_sprite.scale = Vector2(0.72, 0.72)
	weapon_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	weapon_sprite.z_index = 6
	viewport.add_child(weapon_sprite)
	flash_overlay = ColorRect.new()
	flash_overlay.name = "ImpactFlash"
	flash_overlay.position = Vector2.ZERO
	flash_overlay.size = Vector2(PREVIEW_SIZE)
	flash_overlay.color = Color(0.66, 0.94, 1.0, 0.0)
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_overlay.z_index = 9
	viewport.add_child(flash_overlay)
	actor.play("idle")

func play_node(node: Dictionary, weapon: Dictionary = {}) -> void:
	if actor == null:
		return
	if current_tween and current_tween.is_valid():
		current_tween.kill()
	actor.position = Vector2(78, 141)
	actor.rotation = 0.0
	actor.modulate = Color.WHITE
	training_dummy.position = Vector2(302, 126)
	training_dummy.scale = Vector2.ONE
	training_dummy.modulate = Color.WHITE
	environment_target.scale = Vector2.ONE
	environment_target.modulate = Color.WHITE
	flash_overlay.color.a = 0.0
	weapon_sprite.rotation = float(weapon.get("rest_rot", -0.5))
	weapon_sprite.texture = load(str(weapon.get("sprite", ""))) if str(weapon.get("sprite", "")) != "" else null
	var preview := str(node.get("preview", "idle_guard"))
	var animation := "idle"
	if preview in ["run"]:
		animation = "run"
	elif preview in ["jump", "glide", "climb", "swim"]:
		animation = "jump"
	elif preview in ["dash"]:
		animation = "dash"
	elif preview in ["attack_1", "hammer_attack", "cannon_attack", "dual_attack", "spear_attack", "crossbow_attack"]:
		animation = "attack1"
	elif preview in ["attack_2", "spin", "skill_wave", "dual_heavy", "spear_heavy", "crossbow_heavy"]:
		animation = "attack2"
	elif preview in ["ultimate", "skill_cast", "bomb", "dual_combo", "spear_combo", "crossbow_combo"]:
		animation = "attack3"
	actor.play(animation)
	var interaction_tags: Array = node.get("interaction_tags", [])
	environment_target.visible = not interaction_tags.is_empty()
	var passive := str(node.get("type", "")).contains("被动")
	training_dummy.visible = not passive
	input_caption.text = "触发：%s" % str(node.get("input", "自动生效"))
	var weapon_id := str(node.get("weapon_required", weapon.get("id", "sword")))
	var pattern := str(node.get("preview_pattern", "passive" if passive else _fallback_pattern(weapon_id)))
	var intensity := str(node.get("preview_intensity", "basic" if passive else "signature"))
	effect.configure(SkillFxProfile.preview_profile(weapon_id, pattern, intensity))
	if not interaction_tags.is_empty():
		_set_target_style(str(interaction_tags[0]))
	if passive:
		_play_passive_preview()
	else:
		_play_showcase_preview(not interaction_tags.is_empty())

func _play_showcase_preview(has_environment_target: bool) -> void:
	current_tween = create_tween().set_loops()
	current_tween.tween_callback(_enter_phase.bind(0, "① 起手预警"))
	current_tween.tween_method(effect.animate_progress.bind(0), 0.0, 1.0, 0.32)
	current_tween.tween_callback(_enter_phase.bind(1, "② 技能释放"))
	current_tween.tween_property(actor, "position:x", 118.0, 0.28).set_trans(Tween.TRANS_QUAD)
	current_tween.parallel().tween_method(effect.animate_progress.bind(1), 0.0, 1.0, 0.28)
	current_tween.tween_callback(_enter_phase.bind(2, "③ 命中反馈"))
	current_tween.tween_property(training_dummy, "modulate", Color(1.0, 0.32, 0.22), 0.12)
	current_tween.parallel().tween_property(training_dummy, "position:x", 312.0, 0.12)
	current_tween.parallel().tween_property(flash_overlay, "color:a", 0.16, 0.05)
	current_tween.tween_property(training_dummy, "modulate", Color.WHITE, 0.14)
	current_tween.parallel().tween_property(training_dummy, "position:x", 302.0, 0.14)
	current_tween.parallel().tween_property(flash_overlay, "color:a", 0.0, 0.14)
	current_tween.tween_callback(_enter_phase.bind(3, "④ 残留效果"))
	current_tween.tween_method(effect.animate_progress.bind(3), 0.0, 1.0, 0.34)
	if has_environment_target:
		current_tween.parallel().tween_property(environment_target, "scale", Vector2(1.28, 1.28), 0.18)
	current_tween.tween_callback(_enter_phase.bind(4, "⑤ 收招复位"))
	current_tween.tween_property(actor, "position:x", 78.0, 0.3)
	current_tween.tween_property(environment_target, "scale", Vector2.ONE, 0.1)
	current_tween.tween_property(environment_target, "modulate", Color.WHITE, 0.1)
	current_tween.tween_interval(0.24)

func _play_passive_preview() -> void:
	current_tween = create_tween().set_loops()
	for item in [
		[0, "① 触发条件"], [1, "② 自动生效"], [2, "③ 数值反馈"],
		[3, "④ 持续状态"], [4, "⑤ 循环复位"],
	]:
		var phase_index := int(item[0])
		current_tween.tween_callback(_enter_phase.bind(phase_index, str(item[1])))
		current_tween.tween_method(effect.animate_progress.bind(phase_index), 0.0, 1.0, 0.3)
		if phase_index == 2:
			current_tween.parallel().tween_property(actor, "modulate", Color(0.55, 1.0, 0.78), 0.2)
	current_tween.tween_property(actor, "modulate", Color.WHITE, 0.24)
	current_tween.tween_interval(0.18)

func _enter_phase(phase_index: int, label: String) -> void:
	stage_caption.text = label
	effect.set_phase(phase_index, 0.0)

func _fallback_pattern(weapon_id: String) -> String:
	return {
		"sword": "slash_spin",
		"hammer": "ground_smash",
		"cannon": "pressure_beam",
		"dual_blades": "cross_slash",
		"spear": "spear_drill",
		"crossbow": "reticle_burst",
	}.get(weapon_id, "passive")

func _set_target_style(tag: String) -> void:
	var colors := {
		"sword_wave": Color(0.25, 0.86, 1.0), "hammer_charge": Color(1.0, 0.55, 0.18),
		"cannon_steam": Color(0.72, 0.95, 1.0), "dual_grapple": Color(0.8, 0.35, 1.0),
		"spear_drill": Color(1.0, 0.78, 0.25), "crossbow_remote": Color(0.25, 1.0, 0.72),
	}
	var color: Color = colors.get(tag, Color.CYAN)
	for child in environment_target.get_children():
		if child is Line2D:
			child.default_color = color
		elif child is Polygon2D:
			child.color = Color(color, 0.72)

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and viewport:
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if is_visible_in_tree() else SubViewport.UPDATE_DISABLED
