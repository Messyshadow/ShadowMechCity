extends CharacterBody2D
## 虚空天龙机甲：阶段一空中横穿/弹幕，半血坠地后切换近战机甲。

signal hp_changed(cur: int, maxv: int, phase: int)
signal defeated

const PROJ := preload("res://scripts/enemy_projectile.gd")
const GRAVITY := 1500.0

var boss_name := "虚空天龙机甲"
var sprite_name := "bat"
var frame_count := 4
var anim_fps := 8.0
var sprite_scale := 2.3
var max_hp := 320
var body_size := Vector2(150, 110)
var tint := Color(0.65, 0.4, 1.0)
var can_summon := false
var summon_type := "void_eagle"

var hp := 0
var phase := 1
var state := "intro"
var timer := 1.0
var cd := 0.8
var dir := -1
var player: Node2D
var anim: AnimatedSprite2D
var touch: Area2D
var body_col: CollisionShape2D
var _base_y := 260.0
var _airborne := true

func _ready() -> void:
	add_to_group("enemy"); add_to_group("boss")
	collision_layer = 0b00100; collision_mask = 0b00001
	hp = max_hp
	_build()
	hp_changed.emit(hp, max_hp, phase)

func _build() -> void:
	body_col = CollisionShape2D.new(); var shape := RectangleShape2D.new()
	shape.size = body_size; body_col.shape = shape; body_col.position = Vector2(0, -body_size.y * 0.5); add_child(body_col)
	anim = AnimatedSprite2D.new(); anim.sprite_frames = AnimLoader.build_enemy(sprite_name, frame_count, anim_fps)
	anim.centered = false; anim.scale = Vector2(sprite_scale, sprite_scale); anim.modulate = tint
	var tex := anim.sprite_frames.get_frame_texture("move", 0)
	if tex: anim.position = Vector2(-tex.get_width() * sprite_scale * 0.5, -tex.get_height() * sprite_scale)
	anim.play("move"); add_child(anim)
	touch = Area2D.new(); touch.collision_layer = 0; touch.collision_mask = 0b00010
	var tc := CollisionShape2D.new(); var ts := RectangleShape2D.new(); ts.size = body_size; tc.shape = ts
	tc.position = Vector2(0, -body_size.y * 0.5); touch.add_child(tc); add_child(touch)
	_add_wings()

func _add_wings() -> void:
	for side in [-1, 1]:
		var wing := Polygon2D.new()
		wing.polygon = PackedVector2Array([Vector2(0, -60), Vector2(side * 115, -105), Vector2(side * 78, -25), Vector2(side * 28, -5)])
		wing.color = Color(0.48, 0.22, 1.0, 0.65); wing.z_index = -1; add_child(wing)

func _physics_process(delta: float) -> void:
	player = get_tree().get_first_node_in_group("player") as Node2D
	if state == "dead":
		velocity.y = minf(velocity.y + GRAVITY * delta, 800.0); move_and_slide(); return
	cd -= delta; timer -= delta
	if phase == 1:
		_phase_air(delta)
	else:
		_phase_ground(delta)
	move_and_slide(); _contact()

func _phase_air(delta: float) -> void:
	if state == "intro":
		velocity = Vector2(0, sin(Time.get_ticks_msec() * 0.004) * 35.0)
		if timer <= 0.0: state = "air_idle"
	elif state == "air_cross":
		velocity = Vector2(dir * 620.0, sin(timer * 12.0) * 55.0)
		if timer <= 0.0: state = "air_idle"; cd = 0.65
	else:
		velocity = velocity.move_toward(Vector2(0, (_base_y - global_position.y) * 2.0), 420.0 * delta)
		if cd <= 0.0 and player:
			dir = 1 if player.global_position.x > global_position.x else -1
			if randi() % 2 == 0:
				state = "air_cross"; timer = 1.0; _ghost()
			else:
				_fire_fan(5, 330.0); cd = 1.2
	anim.flip_h = dir > 0

func _phase_ground(delta: float) -> void:
	if state == "fall":
		velocity.y = minf(velocity.y + GRAVITY * delta, 980.0)
		if is_on_floor():
			state = "ground_idle"; cd = 0.5; Fx.shockwave(get_parent(), global_position, Color(0.65, 0.35, 1.0)); Game.shake(14.0)
	elif state == "charge":
		velocity.x = dir * 560.0
		if timer <= 0.0: state = "ground_idle"; cd = 0.6
	elif state == "slam":
		velocity.y = minf(velocity.y + GRAVITY * delta, 980.0)
		if is_on_floor() and _airborne:
			_airborne = false; state = "ground_idle"; cd = 0.75; _lightning(); Game.shake(12.0)
		elif not is_on_floor(): _airborne = true
	else:
		velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
		if cd <= 0.0 and player:
			dir = 1 if player.global_position.x > global_position.x else -1
			match randi() % 3:
				0: state = "charge"; timer = 0.75; _ghost()
				1: state = "slam"; _airborne = false; velocity = Vector2(dir * 240.0, -720.0)
				_: _fire_fan(7, 420.0); _lightning(); cd = 1.0
	anim.flip_h = dir > 0

func _fire_fan(count: int, speed: float) -> void:
	if not player: return
	var origin := global_position + Vector2(0, -55); var aim := (player.global_position + Vector2(0, -35) - origin).normalized()
	for i in range(count):
		var angle := deg_to_rad(lerp(-34.0, 34.0, float(i) / float(count - 1)))
		var p := Area2D.new(); p.set_script(PROJ); p.position = origin; get_parent().add_child(p)
		p.setup(aim.rotated(angle) * speed, 2, Color(0.65, 0.35, 1.0))
	Game.shake(5.0)

func _lightning() -> void:
	if not player: return
	for offset in [-160.0, 0.0, 160.0]:
		var x: float = player.global_position.x + float(offset)
		_strike_at.call_deferred(x)

func _strike_at(x: float) -> void:
	var warning := Line2D.new()
	warning.width = 5.0; warning.default_color = Color(0.55, 0.75, 1.0, 0.75)
	warning.points = PackedVector2Array([Vector2(x, 80), Vector2(x, 690)])
	get_parent().add_child(warning)
	var tw := warning.create_tween().set_loops(3)
	tw.tween_property(warning, "modulate:a", 0.15, 0.08)
	tw.tween_property(warning, "modulate:a", 1.0, 0.08)
	await get_tree().create_timer(0.5).timeout
	if not is_instance_valid(warning): return
	warning.queue_free()
	Fx.shockwave(get_parent(), Vector2(x, 650), Color(0.55, 0.75, 1.0))
	if player and is_instance_valid(player) and absf(player.global_position.x - x) < 55.0 and player.has_method("take_damage"):
		player.take_damage(2, Vector2(x, player.global_position.y))

func _ghost() -> void:
	var g := Sprite2D.new(); g.texture = anim.sprite_frames.get_frame_texture("move", anim.frame)
	g.scale = anim.scale; g.global_position = anim.global_position; g.modulate = Color(0.6, 0.3, 1.0, 0.4); get_parent().add_child(g)
	var tw := g.create_tween(); tw.tween_property(g, "modulate:a", 0.0, 0.3); tw.tween_callback(g.queue_free)

func _contact() -> void:
	for body in touch.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"): body.take_damage(2, global_position)

func take_damage(amount: int, _knockback: Vector2) -> void:
	if state == "dead": return
	hp -= amount
	anim.modulate = Color.WHITE; anim.create_tween().tween_property(anim, "modulate", tint if phase == 1 else Color(1.0, 0.35, 0.75), 0.14)
	if phase == 1 and hp <= max_hp / 2: _transform()
	hp_changed.emit(maxi(hp, 0), max_hp, phase)
	if hp <= 0: _die()

func _transform() -> void:
	phase = 2; state = "fall"; body_size = Vector2(128, 150); tint = Color(1.0, 0.35, 0.75)
	body_col.shape.size = body_size; body_col.position = Vector2(0, -body_size.y * 0.5)
	anim.modulate = tint; anim.rotation = PI * 0.5; anim.create_tween().tween_property(anim, "rotation", 0.0, 0.55)
	velocity = Vector2(0, 120.0); Fx.screen_flash(get_tree(), Color(0.7, 0.25, 1.0, 0.45)); Game.shake(15.0)

func _die() -> void:
	state = "dead"; set_deferred("collision_layer", 0); touch.set_deferred("monitoring", false); defeated.emit()
	Game.hitstop(0.2, 0.04); Game.shake(18.0); Fx.death_burst(get_parent(), global_position, Color(0.65, 0.35, 1.0))
	var tw := create_tween(); tw.tween_property(anim, "modulate:a", 0.0, 0.8); tw.tween_callback(queue_free)
