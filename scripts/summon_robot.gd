class_name SummonRobot
extends CharacterBody2D
## 11.1a 初始地面伙伴：跟随、近距离护卫、独立 HP 与损毁回调。

signal health_changed(current: int, maximum: int)
signal disabled(robot: SummonRobot)

const GRAVITY := 1400.0

var record: Dictionary = {}
var profile: Dictionary = {}
var owner_player: Node2D
var hp := 1
var max_hp := 1
var target: Node2D
var _attack_cd := 0.0
var _invulnerable := 0.0
var _flash := 0.0
var _attack_glow := 0.0
var _phase := 0.0
var _disabled := false


func setup(robot_record: Dictionary, player: Node2D) -> void:
	record = robot_record.duplicate(true)
	profile = RobotData.profile(str(record.get("model_id", "scrap_hound_mk1")))
	owner_player = player
	max_hp = int(profile["max_hp"]) + maxi(0, int(record.get("level", 1)) - 1) * 2
	hp = max_hp


func _ready() -> void:
	add_to_group("summon_ally")
	name = "Summon_%s" % str(record.get("robot_instance_id", "unknown"))
	collision_layer = 0b01000
	collision_mask = 0b00001
	z_index = 8
	var body := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(62, 42)
	body.shape = shape
	body.position = Vector2(0, -22)
	add_child(body)
	scale = Vector2(0.12, 0.12)
	modulate.a = 0.0
	var deploy := create_tween().set_parallel(true)
	deploy.tween_property(self, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	deploy.tween_property(self, "modulate:a", 1.0, 0.18)
	health_changed.emit(hp, max_hp)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _disabled or not is_instance_valid(owner_player):
		return
	_phase += delta
	_attack_cd = maxf(0.0, _attack_cd - delta)
	_invulnerable = maxf(0.0, _invulnerable - delta)
	_flash = maxf(0.0, _flash - delta * 5.0)
	_attack_glow = maxf(0.0, _attack_glow - delta * 3.0)
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, 780.0)
	else:
		velocity.y = 0.0
	if global_position.distance_to(owner_player.global_position) > 760.0:
		global_position = owner_player.global_position + Vector2(-96.0, -30.0)
		velocity = Vector2.ZERO
	_find_target()
	if is_instance_valid(target):
		var distance := global_position.distance_to(target.global_position)
		if distance <= float(profile["attack_range"]):
			velocity.x = move_toward(velocity.x, 0.0, 720.0 * delta)
			if _attack_cd <= 0.0:
				_attack_target()
		else:
			velocity.x = move_toward(velocity.x, signf(target.global_position.x - global_position.x) * float(profile["move_speed"]), 620.0 * delta)
	else:
		var facing := float(owner_player.get("facing")) if owner_player.get("facing") != null else 1.0
		var follow_x := owner_player.global_position.x - facing * 112.0
		var gap := follow_x - global_position.x
		velocity.x = move_toward(velocity.x, clampf(gap * 3.0, -float(profile["move_speed"]), float(profile["move_speed"])), 520.0 * delta)
	move_and_slide()
	queue_redraw()


func _find_target() -> void:
	if is_instance_valid(target) and not bool(target.get("dead")) and global_position.distance_to(target.global_position) < 500.0:
		return
	target = null
	var best := 470.0
	for candidate in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(candidate) or bool(candidate.get("dead")) or not candidate.has_method("take_damage"):
			continue
		var distance := global_position.distance_to(candidate.global_position)
		if distance < best and absf(candidate.global_position.y - global_position.y) < 190.0:
			best = distance
			target = candidate


func _attack_target() -> void:
	if not is_instance_valid(target):
		return
	_attack_cd = float(profile["attack_cooldown"])
	_attack_glow = 1.0
	var direction := signf(target.global_position.x - global_position.x)
	target.take_damage(int(profile["damage"]), Vector2(direction * 165.0, -52.0))
	var beam := Line2D.new()
	beam.width = 7.0
	beam.default_color = Color(0.35, 0.95, 1.0, 0.95)
	beam.points = PackedVector2Array([Vector2(24.0 * direction, -38.0), to_local(target.global_position + Vector2(0, -28))])
	beam.z_index = 12
	add_child(beam)
	var beam_tween := beam.create_tween()
	beam_tween.tween_property(beam, "modulate:a", 0.0, 0.20)
	beam_tween.tween_callback(beam.queue_free)
	Fx.hit_spark(get_parent(), target.global_position + Vector2(0, -28))
	Game.shake(1.2)


func take_damage(amount: int, from_position: Vector2) -> void:
	if _disabled or _invulnerable > 0.0:
		return
	_invulnerable = 0.42
	hp = maxi(0, hp - maxi(1, amount))
	_flash = 1.0
	velocity.x = signf(global_position.x - from_position.x) * 150.0
	health_changed.emit(hp, max_hp)
	Fx.popup(get_parent(), global_position + Vector2(0, -78), str(amount), Color(0.45, 0.95, 1.0))
	if hp <= 0:
		_disable()


func recall() -> void:
	if _disabled:
		return
	_disabled = true
	collision_layer = 0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.12, 0.12), 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.16)
	tween.chain().tween_callback(queue_free)


func _disable() -> void:
	_disabled = true
	collision_layer = 0
	Fx.death_burst(get_parent(), global_position + Vector2(0, -24), Color(0.25, 0.9, 1.0))
	disabled.emit(self)
	queue_free()


func _draw() -> void:
	var accent: Color = profile.get("accent", Color("53e6ff"))
	var pulse := 0.75 + sin(_phase * 5.0) * 0.18
	# 贴地阴影与双履带
	draw_colored_polygon(PackedVector2Array([Vector2(-45,-4),Vector2(45,-4),Vector2(34,5),Vector2(-34,5)]), Color(0,0,0,0.42))
	for x in [-27.0, 27.0]:
		draw_circle(Vector2(x,-8), 14.0, Color("132431"))
		draw_circle(Vector2(x,-8), 9.0, Color("426274"))
		draw_circle(Vector2(x,-8), 4.0, accent * 0.8)
	# 暗钢装甲车身
	draw_colored_polygon(PackedVector2Array([Vector2(-40,-18),Vector2(-30,-50),Vector2(10,-58),Vector2(39,-40),Vector2(42,-16),Vector2(20,-8),Vector2(-28,-8)]), Color("1b2a36"))
	draw_polyline(PackedVector2Array([Vector2(-40,-18),Vector2(-30,-50),Vector2(10,-58),Vector2(39,-40),Vector2(42,-16)]), Color("718b9c"), 3.0)
	# 前部护甲嘴与感应天线
	draw_colored_polygon(PackedVector2Array([Vector2(18,-48),Vector2(47,-40),Vector2(54,-25),Vector2(35,-20),Vector2(20,-28)]), Color("263f4d"))
	draw_line(Vector2(-18,-52), Vector2(-25,-72), Color("8eb4c8"), 3.0)
	draw_circle(Vector2(-26,-74), 4.0 + pulse, accent)
	# 量子核与攻击能量槽
	draw_circle(Vector2(5,-34), 13.0 + _attack_glow * 5.0, Color(accent.r,accent.g,accent.b,0.22 + _attack_glow*0.28))
	draw_circle(Vector2(5,-34), 7.0 + pulse, accent if _flash <= 0.0 else Color.WHITE)
	draw_line(Vector2(-18,-23), Vector2(23,-23), Color(accent.r,accent.g,accent.b,0.75), 4.0)
	# 世界内紧凑生命条
	draw_rect(Rect2(Vector2(-38,-88), Vector2(76,6)), Color(0.02,0.05,0.08,0.90), true)
	draw_rect(Rect2(Vector2(-37,-87), Vector2(74.0 * float(hp) / float(maxi(1,max_hp)),4)), accent, true)

