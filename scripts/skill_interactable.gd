class_name SkillInteractable
extends StaticBody2D
## 功能型武器与环境的统一协议。房间只声明 kind，武器只发送 tag。

const KIND_DATA := {
	"relay": {"tags": ["sword_wave"], "color": Color(0.25, 0.86, 1.0), "label": "剑波共鸣"},
	"brittle_wall": {"tags": ["hammer_charge", "bomb"], "color": Color(1.0, 0.55, 0.18), "label": "重击 / 炸弹"},
	"steam_anchor": {"tags": ["cannon_steam"], "color": Color(0.7, 0.94, 1.0), "label": "蒸汽喷射"},
	"grapple_anchor": {"tags": ["dual_grapple"], "color": Color(0.8, 0.35, 1.0), "label": "影索锚点"},
	"drill_wall": {"tags": ["spear_drill"], "color": Color(1.0, 0.78, 0.25), "label": "长枪钻击"},
	"remote_switch": {"tags": ["crossbow_remote"], "color": Color(0.25, 1.0, 0.72), "label": "远程机括"},
}

var kind := "relay"
var allowed_tags: Array = []
var interaction_cooldown := 0.0
var activated := false
var visual_size := Vector2(54, 74)
var accent := Color.CYAN
var prompt: Label

func setup(target_kind: String, size := Vector2(54, 74)) -> void:
	kind = target_kind if KIND_DATA.has(target_kind) else "relay"
	visual_size = size
	var data: Dictionary = KIND_DATA[kind]
	allowed_tags = data.tags.duplicate()
	accent = data.color
	_build_collision()
	_build_prompt(str(data.label))
	add_to_group("skill_interactable")
	if kind == "brittle_wall":
		add_to_group("breakable")
	queue_redraw()

func supports(tag: String) -> bool:
	return tag in allowed_tags

func interaction_distance_from(point: Vector2) -> float:
	if kind not in ["brittle_wall", "drill_wall"]:
		return global_position.distance_to(point)
	var local_point := to_local(point)
	var dx := maxf(absf(local_point.x) - visual_size.x * 0.5, 0.0)
	var dy := maxf(absf(local_point.y) - visual_size.y * 0.5, 0.0)
	return Vector2(dx, dy).length()

func try_skill_interaction(tag: String, actor: Node = null) -> bool:
	if not supports(tag) or interaction_cooldown > 0.0:
		return false
	if activated and kind in ["relay", "remote_switch"]:
		return false
	interaction_cooldown = 1.0
	print("SKILL_INTERACTION_ACCEPT kind=%s tag=%s" % [kind, tag])
	_flash_success()
	match kind:
		"brittle_wall", "drill_wall":
			_break_wall()
		"steam_anchor":
			_apply_steam_impulse(actor)
		"grapple_anchor":
			_apply_grapple_impulse(actor)
		"relay", "remote_switch":
			activated = true
			_spawn_energy_bridge()
	return true

func _physics_process(delta: float) -> void:
	interaction_cooldown = maxf(0.0, interaction_cooldown - delta)
	queue_redraw()

func _build_collision() -> void:
	for child in get_children():
		if child is CollisionShape2D:
			child.queue_free()
	var wall := kind in ["brittle_wall", "drill_wall"]
	collision_layer = 0b00001 if wall else 0
	collision_mask = 0
	if wall:
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = visual_size
		collision.shape = shape
		add_child(collision)

func _build_prompt(text: String) -> void:
	prompt = Label.new()
	prompt.text = text
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.position = Vector2(-80, -visual_size.y * 0.5 - 34)
	prompt.size = Vector2(160, 28)
	prompt.add_theme_font_size_override("font_size", 15)
	prompt.add_theme_color_override("font_color", accent.lightened(0.2))
	prompt.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.04, 0.95))
	prompt.add_theme_constant_override("outline_size", 5)
	add_child(prompt)

func _draw() -> void:
	var pulse := 0.82 + sin(Time.get_ticks_msec() * 0.005) * 0.12
	var color := accent * Color(1, 1, 1, pulse)
	if kind in ["brittle_wall", "drill_wall"]:
		draw_rect(Rect2(-visual_size * 0.5, visual_size), Color(0.08, 0.1, 0.14), true)
		draw_rect(Rect2(-visual_size * 0.5, visual_size), color, false, 4.0)
		var points := PackedVector2Array([Vector2(-8, -visual_size.y * 0.5), Vector2(5, -16), Vector2(-7, 3), Vector2(9, 20), Vector2(-2, visual_size.y * 0.5)])
		draw_polyline(points, color, 4.0)
		if kind == "drill_wall":
			for y in range(int(-visual_size.y * 0.35), int(visual_size.y * 0.36), 18):
				draw_arc(Vector2(0, y), 15, 0, PI, 12, color, 2.0)
	else:
		draw_circle(Vector2.ZERO, 28, Color(accent, 0.12))
		draw_arc(Vector2.ZERO, 28, 0, TAU, 40, color, 4.0)
		draw_arc(Vector2.ZERO, 18, -PI * 0.6, PI * 0.6, 24, color.lightened(0.25), 3.0)
		if kind == "remote_switch":
			draw_line(Vector2(-15, 0), Vector2(15, 0), color, 3.0)
			draw_line(Vector2(0, -15), Vector2(0, 15), color, 3.0)

func _flash_success() -> void:
	if prompt:
		prompt.text = "已响应"
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE * 2.0, 0.08)
	tween.tween_property(self, "modulate", Color.WHITE, 0.22)

func _break_wall() -> void:
	collision_layer = 0
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2(1.4, 0.2), 0.18)
	tween.tween_property(self, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(queue_free)

func _apply_steam_impulse(actor: Node) -> void:
	if actor is CharacterBody2D:
		var facing := float(actor.get("facing")) if actor.get("facing") != null else 1.0
		actor.velocity = Vector2(facing * 270.0, -560.0)

func _apply_grapple_impulse(actor: Node) -> void:
	if actor is CharacterBody2D:
		var direction := signf(global_position.x - actor.global_position.x)
		if direction == 0.0:
			direction = 1.0
		actor.velocity = Vector2(direction * 430.0, -610.0)

func _spawn_energy_bridge() -> void:
	var bridge := StaticBody2D.new()
	bridge.name = "FunctionalSkillBridge"
	bridge.collision_layer = 0b00001
	bridge.position = position + Vector2(115, -70)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(180, 18)
	collision.shape = shape
	bridge.add_child(collision)
	var polygon := Polygon2D.new()
	polygon.polygon = PackedVector2Array([Vector2(-90, -9), Vector2(90, -9), Vector2(90, 9), Vector2(-90, 9)])
	polygon.color = Color(accent, 0.76)
	bridge.add_child(polygon)
	get_parent().call_deferred("add_child", bridge)
