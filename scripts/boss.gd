extends CharacterBody2D
## 多阶段 Boss: 冲锋 / 跳砸 / 弹幕, 招式带起手预警, 半血狂化.

signal hp_changed(cur: int, maxv: int, phase: int)
signal defeated

const GRAVITY := 1400.0
const PROJ := preload("res://scripts/enemy_projectile.gd")
const ENEMY := preload("res://scripts/enemy.gd")

# 由 main 注入
var boss_name := "蒸汽机甲"
var sprite_name := "golem"
var frame_count := 6
var anim_fps := 8.0
var sprite_scale := 1.7
var max_hp := 160
var body_size := Vector2(120, 130)
var tint := Color(1, 1, 1)
var can_summon := false       # 是否会召唤小怪
var summon_type := "bat"

var hp := 0
var phase := 1
var dir := -1
var state := "intro"
var timer := 1.4
var cd := 0.0
var _next := ""
var _airborne := false
var player: Node2D
var anim: AnimatedSprite2D
var touch: Area2D
var flash_mat: ShaderMaterial

const FLASH_SHADER := """
shader_type canvas_item;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	COLOR = vec4(mix(c.rgb, flash_color.rgb, flash * c.a), c.a);
}
"""

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("boss")
	collision_layer = 0b00100
	collision_mask = 0b00001
	hp = max_hp
	_build()
	hp_changed.emit(hp, max_hp, phase)

func _build() -> void:
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = body_size
	col.shape = shape
	col.position = Vector2(0, -body_size.y * 0.5)
	add_child(col)

	anim = AnimatedSprite2D.new()
	anim.sprite_frames = AnimLoader.build_enemy(sprite_name, frame_count, anim_fps)
	anim.centered = false
	anim.scale = Vector2(sprite_scale, sprite_scale)
	anim.modulate = tint
	var tex := anim.sprite_frames.get_frame_texture("move", 0)
	if tex:
		anim.position = Vector2(-tex.get_width() * sprite_scale * 0.5, -tex.get_height() * sprite_scale)
	flash_mat = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = FLASH_SHADER
	flash_mat.shader = sh
	flash_mat.set_shader_parameter("flash", 0.0)
	anim.material = flash_mat
	anim.play("move")
	add_child(anim)

	touch = Area2D.new()
	touch.collision_layer = 0
	touch.collision_mask = 0b00010
	var ts := CollisionShape2D.new()
	var tsh := RectangleShape2D.new()
	tsh.size = body_size
	ts.shape = tsh
	ts.position = Vector2(0, -body_size.y * 0.5)
	touch.add_child(ts)
	add_child(touch)

func _physics_process(delta: float) -> void:
	player = get_tree().get_first_node_in_group("player") as Node2D
	if state == "dead":
		velocity.y = min(velocity.y + GRAVITY * delta, 700.0)
		velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y = min(velocity.y + GRAVITY * delta, 950.0)
	elif state != "slam_air":
		velocity.y = 0.0

	if player and is_instance_valid(player) and (state == "idle" or state == "tele"):
		dir = -1 if player.global_position.x < global_position.x else 1
		anim.flip_h = dir > 0

	cd = maxf(0.0, cd - delta)

	match state:
		"intro":
			timer -= delta
			velocity.x = 0.0
			if timer <= 0.0:
				state = "idle"; cd = 0.7
		"idle":
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if cd <= 0.0 and player and is_instance_valid(player) and is_on_floor():
				_choose()
		"tele":
			timer -= delta
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			flash_mat.set_shader_parameter("flash", 0.4 + 0.3 * sin(timer * 40.0))
			if timer <= 0.0:
				flash_mat.set_shader_parameter("flash", 0.0)
				_exec()
		"charge":
			timer -= delta
			velocity.x = dir * (430.0 if phase == 1 else 580.0)
			if int(timer * 30.0) % 2 == 0:
				_ghost()
			if timer <= 0.0:
				state = "recover"; timer = 0.5
		"slam_air":
			if not is_on_floor():
				_airborne = true
			elif _airborne:
				_land_slam()
		"recover":
			timer -= delta
			velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
			if timer <= 0.0:
				state = "idle"
				cd = (1.4 if phase == 1 else 0.8)

	move_and_slide()
	_contact()

func _choose() -> void:
	state = "tele"
	timer = (0.5 if phase == 1 else 0.34)
	var opts := ["charge", "slam", "barrage"]
	if can_summon:
		opts.append("summon")
	_next = opts[randi() % opts.size()]
	flash_mat.set_shader_parameter("flash", 0.6)

func _exec() -> void:
	match _next:
		"charge":
			state = "charge"; timer = 0.6
			anim.scale = Vector2(sprite_scale * 1.1, sprite_scale * 0.9)
		"slam":
			state = "slam_air"; _airborne = false
			var tx: float = player.global_position.x if player else global_position.x
			velocity = Vector2(clampf(tx - global_position.x, -260, 260) * 1.4, -760.0)
		"barrage":
			_fire_barrage()
			state = "recover"; timer = 0.6
		"summon":
			_summon()
			state = "recover"; timer = 0.7

func _land_slam() -> void:
	state = "recover"; timer = 0.6
	velocity = Vector2.ZERO
	anim.scale = Vector2(sprite_scale * 1.2, sprite_scale * 0.8)
	anim.create_tween().tween_property(anim, "scale", Vector2(sprite_scale, sprite_scale), 0.25)
	Fx.shockwave(get_parent(), global_position, Color(1.0, 0.6, 0.3))
	Fx.dust(get_parent(), global_position, 0)
	Fx.screen_flash(get_tree(), Color(1.0, 0.6, 0.2, 0.2))
	Game.shake(11.0)
	if player and is_instance_valid(player):
		if absf(player.global_position.x - global_position.x) < 270.0 and player.has_method("take_damage"):
			player.take_damage(2, global_position)

func _fire_barrage() -> void:
	if not player or not is_instance_valid(player):
		return
	var muzzle := global_position + Vector2(0, -body_size.y * 0.6)
	var base := (player.global_position + Vector2(0, -40) - muzzle).normalized()
	var n := 4 if phase == 1 else 6
	for i in range(n):
		var ang := deg_to_rad(lerp(-26.0, 26.0, float(i) / float(n - 1)))
		var p := Area2D.new()
		p.set_script(PROJ)
		p.position = muzzle
		get_parent().add_child(p)
		if p.has_method("setup"):
			p.setup(base.rotated(ang) * 360.0, 1, Color(1.0, 0.55, 0.25))
	Game.shake(4.0)

func _summon() -> void:
	for i in [-1, 1]:
		var e := CharacterBody2D.new()
		e.set_script(ENEMY)
		e.enemy_name = summon_type
		e.frame_count = 4; e.anim_fps = 7.7; e.sprite_scale = 0.6
		e.max_hp = 3; e.move_speed = 95.0; e.body_size = Vector2(46, 48)
		e.behavior = "charger"; e.contact_damage = 1; e.knockback_resist = 0.0
		e.position = global_position + Vector2(i * 80, -20)
		get_parent().add_child(e)
	Fx.popup(get_parent(), global_position + Vector2(0, -body_size.y - 10), "召唤!", Color(1, 0.7, 0.4))
	Game.shake(4.0)

func _ghost() -> void:
	var g := Sprite2D.new()
	g.texture = anim.sprite_frames.get_frame_texture("move", anim.frame)
	g.flip_h = anim.flip_h
	g.scale = anim.scale
	g.global_position = anim.global_position
	g.modulate = Color(1.0, 0.5, 0.3, 0.4)
	g.z_index = -1
	get_parent().add_child(g)
	var tw := g.create_tween()
	tw.tween_property(g, "modulate:a", 0.0, 0.25)
	tw.tween_callback(g.queue_free)

func _contact() -> void:
	if state == "dead":
		return
	for b in touch.get_overlapping_bodies():
		if b.is_in_group("player") and b.has_method("take_damage"):
			b.take_damage(2, global_position)

func take_damage(amount: int, _knockback: Vector2) -> void:
	if state == "dead":
		return
	hp -= amount
	flash_mat.set_shader_parameter("flash", 1.0)
	create_tween().tween_method(
		func(v): flash_mat.set_shader_parameter("flash", v), 1.0, 0.0, 0.15)
	if phase == 1 and hp <= max_hp / 2:
		_enrage()
	hp_changed.emit(maxi(hp, 0), max_hp, phase)
	if hp <= 0:
		_die()

func _enrage() -> void:
	phase = 2
	tint = Color(1.0, 0.6, 0.55)
	anim.modulate = tint
	Fx.screen_flash(get_tree(), Color(1.0, 0.3, 0.2, 0.35))
	Game.shake(10.0)
	Fx.popup(get_parent(), global_position + Vector2(0, -body_size.y - 20), "狂化!", Color(1, 0.3, 0.3))

func _die() -> void:
	state = "dead"
	# set_deferred: 死亡可能在碰撞信号派发期被技能触发, 避免 monitoring 阻塞
	set_deferred("collision_layer", 0)
	touch.set_deferred("monitoring", false)
	defeated.emit()
	Game.hitstop(0.18, 0.04)
	Game.shake(16.0)
	Fx.screen_flash(get_tree(), Color(1, 1, 1, 0.5))
	Fx.death_burst(get_parent(), global_position + Vector2(0, -body_size.y * 0.5), Color(1.0, 0.6, 0.3))
	var tw := create_tween()
	tw.tween_interval(0.4)
	tw.tween_callback(func(): Fx.death_burst(get_parent(), global_position + Vector2(randf_range(-40, 40), -randf_range(20, 80)), Color(1, 0.8, 0.4)))
	tw.tween_interval(0.4)
	tw.tween_property(anim, "modulate:a", 0.0, 0.5)
	tw.tween_callback(queue_free)
