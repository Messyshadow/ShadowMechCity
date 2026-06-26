extends CharacterBody2D
## 投掷炸弹: 落地弹跳两下后引爆; 砸到敌人/墙面/可破坏墙 直接引爆.

var damage := 4
var fuse := 2.2          # 兜底最长存活
var bounces := 0
var _age := 0.0
const MAX_BOUNCES := 2
const GRAV := 1300.0
var _core: Polygon2D

func setup(v: Vector2, dmg: int) -> void:
	velocity = v
	damage = dmg

func _ready() -> void:
	z_index = 12
	collision_layer = 0
	collision_mask = 0b00001   # 只与世界(地面/墙)碰撞反弹
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 9.0
	cs.shape = sh
	add_child(cs)
	var pts := PackedVector2Array()
	for i in range(14):
		var a := TAU * i / 14.0
		pts.append(Vector2(cos(a), sin(a)) * 11.0)
	var body := Polygon2D.new()
	body.polygon = pts
	body.color = Color(0.12, 0.13, 0.16)
	add_child(body)
	_core = Polygon2D.new()
	_core.polygon = pts
	_core.scale = Vector2(0.5, 0.5)
	_core.color = Color(1.0, 0.5, 0.2)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_core.material = mat
	add_child(_core)

func _physics_process(delta: float) -> void:
	velocity.y += GRAV * delta
	velocity.x = move_toward(velocity.x, 0.0, 55.0 * delta)
	var prev_vy := velocity.y
	move_and_slide()
	_age += delta
	fuse -= delta

	# 砸到墙面(含可破坏墙) -> 直接引爆
	if _age > 0.05 and is_on_wall():
		_explode(); return
	# 落地反弹
	if is_on_floor() and prev_vy > 90.0:
		velocity.y = -prev_vy * 0.48
		velocity.x *= 0.7
		bounces += 1
		Fx.dust(get_parent(), global_position + Vector2(0, 9), 0.0)
		if bounces >= MAX_BOUNCES:
			_explode(); return
	# 贴近敌人/可破坏墙 -> 直接引爆
	if _age > 0.1:
		for e in get_tree().get_nodes_in_group("enemy"):
			if is_instance_valid(e) and e.global_position.distance_to(global_position) < 58.0:
				_explode(); return
		for w in get_tree().get_nodes_in_group("breakable"):
			if is_instance_valid(w) and absf(global_position.x - w.global_position.x) < 52.0:
				_explode(); return
	# 兜底: 引信结束 或 已弹过且基本停下
	if fuse <= 0.0 or (bounces > 0 and is_on_floor() and absf(velocity.x) < 8.0):
		_explode()

	# 临爆闪烁
	var blink := 0.5 + 0.5 * sin(_age * 22.0 + float(bounces) * 6.0)
	if _core:
		_core.scale = Vector2(0.4 + blink * 0.5, 0.4 + blink * 0.5)
		_core.modulate = Color(1, 1, 1) if fuse > 0.5 else Color(1, 0.4, 0.3)

func _explode() -> void:
	var p := global_position
	var parent := get_parent()
	Fx.explosion(parent, p, 175.0)
	Fx.screen_flash(get_tree(), Color(1.0, 0.65, 0.25, 0.3))
	Game.hitstop(0.05, 0.06)
	Game.shake(13.0)
	var m := get_node_or_null("/root/Main")
	if m and m.has_method("play_sfx"):
		m.play_sfx("hit", 0.0)
	for e in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(e) and e.global_position.distance_to(p) < 175.0 and e.has_method("take_damage"):
			var kd := signf(e.global_position.x - p.x)
			if kd == 0.0:
				kd = 1.0
			e.take_damage(damage, Vector2(kd * 340.0, -280.0))
	for w in get_tree().get_nodes_in_group("breakable"):
		if is_instance_valid(w) and w.global_position.distance_to(p) < 225.0:
			Fx.death_burst(parent, w.global_position, Color(0.7, 0.55, 0.4))
			Fx.popup(parent, w.global_position + Vector2(0, -20), "墙壁破裂!", Color(1, 0.8, 0.4))
			w.queue_free()
	queue_free()
