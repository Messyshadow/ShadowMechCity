extends CharacterBody2D
## 敌人: 多行为 (walker 巡逻 / flyer 飞行追击 / charger 冲锋 / brute 重装)
## + 受击闪白/击退 + 死亡 + 接触伤害

# 由 main 在实例化后、加入场景树前设置
var enemy_name := "mushroom"
var behavior := "walker"
var frame_count := 8
var anim_fps := 6.0
var sprite_scale := 0.5
var max_hp := 4
var move_speed := 60.0
var contact_damage := 1
var body_size := Vector2(46, 46)
var tint := Color(1, 1, 1)
var knockback_resist := 0.0   # 0~1, brute 较高

const GRAVITY := 1400.0
const PROJ := preload("res://scripts/enemy_projectile.gd")
var _shoot_cd := 0.0
var _special_cd := 1.0
var _hit_count := 0

var hp: int
var dir := -1
var dead := false
var flash_mat: ShaderMaterial
var _t := 0.0
var _base_y := 0.0
var _charge_cd := 0.0
var _charging := 0.0
# 近身攻击(起手预警+扑击)
var _atk_state := 0      # 0 无 / 1 起手 / 2 扑击
var _atk_timer := 0.0
var _atk_cd := 0.0
const ATTACK_RANGE := 86.0

var anim: AnimatedSprite2D
var touch: Area2D
var floor_ray: RayCast2D
var wall_ray: RayCast2D
var player: Node2D

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
	hp = max_hp
	collision_layer = 0b00100   # enemy
	collision_mask = 0b00001    # world
	_base_y = global_position.y
	_build()

func _build() -> void:
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = body_size
	col.shape = shape
	col.position = Vector2(0, -body_size.y * 0.5)
	add_child(col)

	anim = AnimatedSprite2D.new()
	anim.sprite_frames = AnimLoader.build_enemy(enemy_name, frame_count, anim_fps)
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
	_add_void_silhouette()
	_add_theme_role_visual()

	touch = Area2D.new()
	touch.collision_layer = 0
	touch.collision_mask = 0b00010   # player
	var ts := CollisionShape2D.new()
	var tsh := RectangleShape2D.new()
	tsh.size = body_size + Vector2(8, 8)
	ts.shape = tsh
	ts.position = Vector2(0, -body_size.y * 0.5)
	touch.add_child(ts)
	add_child(touch)

	floor_ray = RayCast2D.new()
	floor_ray.target_position = Vector2(0, 28)
	floor_ray.position = Vector2(dir * body_size.x * 0.5, -2)
	floor_ray.collision_mask = 0b00001
	add_child(floor_ray)
	wall_ray = RayCast2D.new()
	wall_ray.target_position = Vector2(dir * 22, 0)
	wall_ray.position = Vector2(0, -body_size.y * 0.5)
	wall_ray.collision_mask = 0b00001
	add_child(wall_ray)

func _add_void_silhouette() -> void:
	if behavior in ["diver", "teleflyer"]:
		for side in [-1, 1]:
			var wing := Polygon2D.new()
			wing.polygon = PackedVector2Array([Vector2(0, -body_size.y * 0.65), Vector2(side * body_size.x * 0.95, -body_size.y), Vector2(side * body_size.x * 0.62, -body_size.y * 0.28)])
			wing.color = Color(tint.r, tint.g, tint.b, 0.72); wing.z_index = -1; add_child(wing)
	elif behavior == "storm_mage":
		var halo := Line2D.new(); halo.width = 4.0; halo.closed = true; halo.default_color = Color(0.55, 0.75, 1.0, 0.9)
		var pts := PackedVector2Array()
		for i in range(20):
			var a := TAU * i / 20.0; pts.append(Vector2(cos(a) * 34.0, sin(a) * 12.0 - body_size.y - 12.0))
		halo.points = pts; add_child(halo)

func _add_theme_role_visual() -> void:
	match enemy_name:
		"soul_shield":
			var shield := Polygon2D.new()
			shield.polygon = PackedVector2Array([Vector2(-body_size.x*0.82,-body_size.y*0.92),Vector2(-body_size.x*0.32,-body_size.y*1.10),Vector2(-body_size.x*0.20,-body_size.y*0.18),Vector2(-body_size.x*0.72,4)])
			shield.color = Color(0.22,0.48,0.82,0.88); shield.z_index = 2; add_child(shield)
			var hub := Polygon2D.new(); hub.polygon = PackedVector2Array([Vector2(-52,-72),Vector2(-42,-82),Vector2(-32,-72),Vector2(-42,-62)]); hub.color=Color(0.72,0.92,1.0,0.95); hub.z_index=3; add_child(hub)
		"soul_spear":
			var spear := Line2D.new(); spear.width=7.0; spear.default_color=Color(0.92,0.28,0.62,0.92); spear.z_index=2
			spear.points=PackedVector2Array([Vector2(-body_size.x*0.82,-body_size.y*0.94),Vector2(body_size.x*1.08,-body_size.y*0.40)]); add_child(spear)
			var blade := Polygon2D.new(); blade.polygon=PackedVector2Array([Vector2(body_size.x*1.18,-body_size.y*0.37),Vector2(body_size.x*0.82,-body_size.y*0.55),Vector2(body_size.x*0.93,-body_size.y*0.26)]); blade.color=Color(1.0,0.50,0.82,0.94); blade.z_index=3; add_child(blade)
		"soul_cannon":
			var cannon := Polygon2D.new(); cannon.polygon=PackedVector2Array([Vector2(-body_size.x*0.58,-body_size.y*1.12),Vector2(body_size.x*0.62,-body_size.y*1.12),Vector2(body_size.x*0.82,-body_size.y*0.78),Vector2(-body_size.x*0.42,-body_size.y*0.70)]); cannon.color=Color(0.34,0.22,0.72,0.90); cannon.z_index=2; add_child(cannon)
			var barrel := Line2D.new(); barrel.width=12.0; barrel.default_color=Color(0.62,0.40,1.0,0.95); barrel.points=PackedVector2Array([Vector2(8,-body_size.y),Vector2(body_size.x*1.06,-body_size.y)]); barrel.z_index=3; add_child(barrel)
			var core := Polygon2D.new(); core.polygon=PackedVector2Array([Vector2(-10,-body_size.y-10),Vector2(0,-body_size.y-20),Vector2(10,-body_size.y-10),Vector2(0,-body_size.y)]); core.color=Color(0.82,0.68,1.0,0.98); core.z_index=4; add_child(core)
		"storm_mage":
			var cloak := Polygon2D.new(); cloak.polygon=PackedVector2Array([Vector2(-body_size.x*0.72,-body_size.y*0.70),Vector2(0,-body_size.y*1.18),Vector2(body_size.x*0.72,-body_size.y*0.70),Vector2(body_size.x*0.54,0),Vector2(-body_size.x*0.54,0)]); cloak.color=Color(0.20,0.24,0.65,0.54); cloak.z_index=-2; add_child(cloak)
			var staff := Line2D.new(); staff.width=5.0; staff.default_color=Color(0.52,0.72,1.0,0.86); staff.points=PackedVector2Array([Vector2(body_size.x*0.48,-body_size.y*1.06),Vector2(body_size.x*0.72,2)]); add_child(staff)
			var orb := Polygon2D.new(); orb.polygon=PackedVector2Array([Vector2(body_size.x*0.48-8,-body_size.y*1.10),Vector2(body_size.x*0.48,-body_size.y*1.20),Vector2(body_size.x*0.48+8,-body_size.y*1.10),Vector2(body_size.x*0.48,-body_size.y)]); orb.color=Color(0.52,0.78,1.0,0.92); add_child(orb)

func _physics_process(delta: float) -> void:
	_t += delta
	player = get_tree().get_first_node_in_group("player") as Node2D
	if dead:
		velocity.y = min(velocity.y + GRAVITY * delta, 700.0)
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		move_and_slide()
		return

	_atk_cd = maxf(0.0, _atk_cd - delta)
	# 攻击中: 执行起手/扑击
	if _atk_state != 0:
		_do_attack(delta)
		move_and_slide()
		_damage_player()
		return
	# 玩家贴近 -> 发动近身攻击(带起手预警)
	if player and is_instance_valid(player) and _atk_cd <= 0.0:
		var dx: float = player.global_position.x - global_position.x
		var dy: float = absf(player.global_position.y - global_position.y)
		if absf(dx) < ATTACK_RANGE and dy < 64.0 and (is_on_floor() or _is_flying_behavior()):
			_start_attack(signf(dx))
			move_and_slide()
			_damage_player()
			return

	match behavior:
		"flyer":   _b_flyer(delta)
		"diver": _b_diver(delta)
		"teleflyer": _b_teleflyer(delta)
		"storm_mage": _b_storm_mage(delta)
		"charger": _b_charger(delta)
		"shooter": _b_shooter(delta)
		_:         _b_walker(delta)   # walker / brute 共用

	move_and_slide()
	_damage_player()

# 远程射手: 巡逻 + 远距离向玩家发射弹幕
func _b_shooter(delta: float) -> void:
	_b_walker(delta)   # 复用地面巡逻
	_shoot_cd = maxf(0.0, _shoot_cd - delta)
	if _shoot_cd > 0.0 or not (player and is_instance_valid(player)):
		return
	var to: Vector2 = player.global_position + Vector2(0, -40) - (global_position + Vector2(0, -body_size.y * 0.5))
	if to.length() < 560.0 and absf(to.y) < 200.0:
		var p := Area2D.new()
		p.set_script(PROJ)
		p.position = global_position + Vector2(dir * 10, -body_size.y * 0.6)
		get_parent().add_child(p)
		if p.has_method("setup"):
			p.setup(to.normalized() * 300.0, contact_damage, Color(0.7, 1.0, 0.5))
		_shoot_cd = 1.6
		dir = 1 if to.x > 0 else -1
		anim.flip_h = dir > 0

func _is_flying_behavior() -> bool:
	return behavior in ["flyer", "diver", "teleflyer", "storm_mage"]

func _b_diver(delta: float) -> void:
	_special_cd -= delta
	if not player or not is_instance_valid(player):
		_b_flyer(delta)
		return
	dir = 1 if player.global_position.x > global_position.x else -1
	if _special_cd <= 0.0 and absf(player.global_position.x - global_position.x) < 460.0:
		velocity = (player.global_position + Vector2(0, -20) - global_position).normalized() * move_speed * 3.0
		_special_cd = 2.2
		_ghost()
	else:
		var perch := player.global_position + Vector2(-dir * 170.0, -190.0)
		velocity = velocity.move_toward((perch - global_position).normalized() * move_speed, 260.0 * delta)
	anim.flip_h = dir > 0

func _b_teleflyer(delta: float) -> void:
	_special_cd -= delta
	_b_flyer(delta)
	if _special_cd <= 0.0 and player and is_instance_valid(player):
		for i in range(3):
			_ghost()
		global_position = player.global_position + Vector2(randf_range(-220.0, 220.0), randf_range(-190.0, -90.0))
		_base_y = global_position.y
		_special_cd = 2.8
		Fx.screen_flash(get_tree(), Color(0.55, 0.3, 1.0, 0.15))

func _b_storm_mage(delta: float) -> void:
	velocity = velocity.move_toward(Vector2(0, sin(_t * 2.0) * 45.0), 150.0 * delta)
	_shoot_cd -= delta
	if _shoot_cd > 0.0 or not player or not is_instance_valid(player):
		return
	var origin := global_position + Vector2(0, -body_size.y * 0.5)
	var aim := (player.global_position + Vector2(0, -35) - origin).normalized()
	var spread := [-0.24, 0.0, 0.24] if (_hit_count / 3) % 2 == 1 else [0.0]
	for angle in spread:
		var p := Area2D.new()
		p.set_script(PROJ); p.position = origin; get_parent().add_child(p)
		p.setup(aim.rotated(angle) * 340.0, contact_damage, Color(0.55, 0.45, 1.0))
	_shoot_cd = 1.25
	Fx.shockwave(get_parent(), origin, Color(0.55, 0.45, 1.0))

# --------------------------------------------------- 近身攻击
func _start_attack(face: float) -> void:
	_atk_state = 1
	_atk_timer = 0.34
	if face != 0.0:
		dir = int(face)
	anim.flip_h = dir > 0
	velocity.x = 0.0
	# 起手预警: 闪白 + 后仰蓄力
	flash_mat.set_shader_parameter("flash", 0.7)
	var s := anim.scale
	anim.scale = s * Vector2(0.85, 1.15)
	anim.create_tween().tween_property(anim, "scale", s, 0.34)

func _do_attack(delta: float) -> void:
	if not is_on_floor() and not _is_flying_behavior():
		velocity.y = min(velocity.y + GRAVITY * delta, 700.0)
	if _atk_state == 1:
		# 起手: 原地蓄力, 闪白渐隐
		velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
		flash_mat.set_shader_parameter("flash", maxf(0.0, _atk_timer / 0.34) * 0.7)
		_atk_timer -= delta
		if _atk_timer <= 0.0:
			_atk_state = 2
			_atk_timer = 0.26
			velocity.x = dir * (move_speed * 4.0 + 160.0)   # 扑击突进
			if _is_flying_behavior():
				velocity.y = -60.0
	else:
		# 扑击中
		_atk_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
		if _atk_timer <= 0.0:
			_atk_state = 0
			_atk_cd = 1.5
			if _is_flying_behavior():
				_base_y = global_position.y

# --------------------------------------------------- 行为
func _b_walker(delta: float) -> void:
	if not is_on_floor():
		velocity.y = min(velocity.y + GRAVITY * delta, 700.0)
	else:
		velocity.y = 0.0
	floor_ray.position.x = dir * body_size.x * 0.5
	wall_ray.target_position.x = dir * 22
	floor_ray.force_raycast_update()
	wall_ray.force_raycast_update()
	if is_on_floor() and (not floor_ray.is_colliding() or wall_ray.is_colliding()):
		dir = -dir
	velocity.x = dir * move_speed
	anim.flip_h = dir > 0

func _b_charger(delta: float) -> void:
	if not is_on_floor():
		velocity.y = min(velocity.y + GRAVITY * delta, 700.0)
	else:
		velocity.y = 0.0
	_charge_cd = max(0.0, _charge_cd - delta)

	if _charging > 0.0:
		_charging -= delta
		velocity.x = dir * move_speed * 3.4
		if int(_charging * 30.0) % 2 == 0:
			_ghost()
	else:
		# 巡逻并探测玩家
		floor_ray.position.x = dir * body_size.x * 0.5
		wall_ray.target_position.x = dir * 22
		floor_ray.force_raycast_update()
		wall_ray.force_raycast_update()
		if is_on_floor() and (not floor_ray.is_colliding() or wall_ray.is_colliding()):
			dir = -dir
		velocity.x = dir * move_speed
		if player and is_instance_valid(player) and _charge_cd <= 0.0:
			var dx: float = player.global_position.x - global_position.x
			var dy: float = absf(player.global_position.y - global_position.y)
			if dy < 70.0 and absf(dx) < 340.0 and signf(dx) == float(dir):
				_charging = 0.55
				_charge_cd = 2.2
				flash_mat.set_shader_parameter("flash", 0.6)
				create_tween().tween_method(
					func(v): flash_mat.set_shader_parameter("flash", v), 0.6, 0.0, 0.3)
	anim.flip_h = dir > 0

func _b_flyer(delta: float) -> void:
	# 无重力, 上下浮动 + 缓慢逼近玩家
	var ty := _base_y + sin(_t * 2.2) * 38.0
	velocity.y = (ty - global_position.y) * 3.0
	if player and is_instance_valid(player):
		dir = 1 if player.global_position.x > global_position.x else -1
		var dx: float = player.global_position.x - global_position.x
		velocity.x = clampf(dx, -1.0, 1.0) * move_speed
	anim.flip_h = dir > 0

func _ghost() -> void:
	var g := Sprite2D.new()
	g.texture = anim.sprite_frames.get_frame_texture("move", anim.frame)
	g.flip_h = anim.flip_h
	g.scale = anim.scale
	g.global_position = anim.global_position
	g.modulate = Color(1, 0.5, 0.3, 0.45)
	g.z_index = -1
	get_parent().add_child(g)
	var tw := g.create_tween()
	tw.tween_property(g, "modulate:a", 0.0, 0.22)
	tw.tween_callback(g.queue_free)

func _damage_player() -> void:
	for b in touch.get_overlapping_bodies():
		if b.is_in_group("player") and b.has_method("take_damage"):
			b.take_damage(contact_damage, global_position)

# --------------------------------------------------- 受击 / 死亡
func take_damage(amount: int, knockback: Vector2) -> void:
	if dead:
		return
	hp -= amount
	_hit_count += 1
	velocity = knockback * (1.0 - knockback_resist)
	if _is_flying_behavior():
		_base_y = global_position.y   # 飞行敌被击退后更新基准高度
	_flash()
	Fx.hit_ring(get_parent(), global_position + Vector2(0, -body_size.y * 0.5), Color(1, 0.92, 0.6))
	# 受击中断起手攻击, 反馈更明确
	if _atk_state != 0:
		_atk_state = 0
		_atk_cd = 0.6
	Fx.popup(get_parent(), global_position + Vector2(0, -body_size.y - 10), str(amount), Color(1, 0.95, 0.5))
	if hp <= 0:
		_die()

func _flash() -> void:
	flash_mat.set_shader_parameter("flash", 1.0)
	create_tween().tween_method(
		func(v): flash_mat.set_shader_parameter("flash", v), 1.0, 0.0, 0.18)
	var s := anim.scale
	anim.scale = s * Vector2(1.15, 0.85)
	anim.create_tween().tween_property(anim, "scale", s, 0.15)

func _die() -> void:
	dead = true
	Game.add_kill()
	Game.hitstop(0.08, 0.04)
	Game.shake(6.0)
	Fx.death_burst(get_parent(), global_position + Vector2(0, -body_size.y * 0.5), tint)
	# 掉落: 经验 + 金币 + 概率生命碎片
	var drop_pos := global_position + Vector2(0, -body_size.y * 0.5)
	Game.add_xp(2 + max_hp / 3)
	var coins := 1 + max_hp / 4
	for i in range(coins):
		Pickup.spawn(get_parent(), drop_pos, "coin", 1 + randi() % 2, true)
	Pickup.spawn(get_parent(), drop_pos, "orb", 1, true)
	if randf() < 0.18:
		Pickup.spawn(get_parent(), drop_pos, "shard", 1, true)
	if randf() < 0.22:
		Pickup.spawn_gear(get_parent(), drop_pos, ItemsData.generate())
	# 死亡可能发生在物理碰撞信号派发期(突进/大招冲过多敌), 用 set_deferred 避免
	# "Function blocked during in/out signal" 阻塞导致接触碰撞没及时关、死亡敌仍擦伤玩家
	set_deferred("collision_layer", 0)
	touch.set_deferred("monitoring", false)
	velocity = Vector2(dir * -120.0, -260.0)
	var tw := create_tween()
	tw.tween_interval(0.25)
	tw.tween_property(anim, "modulate:a", 0.0, 0.35)
	tw.tween_callback(queue_free)
