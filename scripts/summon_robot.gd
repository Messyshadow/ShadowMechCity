class_name SummonRobot
extends CharacterBody2D
## 11.1b 四定位伙伴：地面追击/盾卫、空中炮击/修复，并带安全量子归位。

signal health_changed(current: int, maximum: int)
signal disabled(robot: SummonRobot)
signal attack_committed(robot: SummonRobot)

const GRAVITY := 1400.0
const FORMATION_RULES := preload("res://scripts/summon_rules.gd")
const SUMMON_FX := preload("res://scripts/summon_fx.gd")

var record: Dictionary = {}
var profile: Dictionary = {}
var owner_player: Node2D
var hp := 1
var max_hp := 1
var target: Node2D
var _attack_cd := 0.0
var _support_cd := 0.0
var _invulnerable := 0.0
var _flash := 0.0
var _attack_glow := 0.0
var _phase := 0.0
var _disabled := false
var _unstuck_timer := 0.0
var _last_position := Vector2.ZERO
var formation_index := 0
var formation_count := 1
var formation_offset := Vector2(-92, -30)
var power_scale := 1.0
var overload_lock := 0.0
var _windup_remaining := 0.0
var _pending_target: Node2D
var _pending_action := ""


func setup(robot_record: Dictionary, player: Node2D) -> void:
	record = robot_record.duplicate(true)
	profile = RobotData.profile(str(record.get("model_id", "scrap_hound_mk1")))
	owner_player = player
	max_hp = int(profile["max_hp"]) + maxi(0, int(record.get("level", 1)) - 1) * 2
	hp = max_hp
	_support_cd = float(profile.get("support_cooldown", 0.0)) * 0.45


func configure_formation(index: int, count: int, damage_scale: float, initial_delay: float) -> void:
	formation_index = index
	formation_count = clampi(count, 1, 3)
	power_scale = clampf(damage_scale, 0.5, 1.0)
	formation_offset = FORMATION_RULES.formation_offset(index, formation_count, str(profile.get("mobility", "ground")))
	_attack_cd = maxf(_attack_cd, initial_delay)


func apply_overload_lock(seconds: float) -> void:
	overload_lock = maxf(overload_lock, seconds)
	_attack_cd = maxf(_attack_cd, seconds)
	_support_cd = maxf(_support_cd, seconds)
	_attack_glow = 1.0
	queue_redraw()


func _ready() -> void:
	add_to_group("summon_ally")
	name = "Summon_%s" % str(record.get("robot_instance_id", "unknown"))
	collision_layer = 0b01000
	collision_mask = 0 if _is_air() else 0b00001
	z_index = 10 if _is_air() else 8
	var body := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(52, 38) if _is_air() else Vector2(62, 42)
	body.shape = shape
	body.position = Vector2(0, -20)
	add_child(body)
	_last_position = global_position
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
	_support_cd = maxf(0.0, _support_cd - delta)
	_invulnerable = maxf(0.0, _invulnerable - delta)
	_flash = maxf(0.0, _flash - delta * 5.0)
	_attack_glow = maxf(0.0, _attack_glow - delta * 3.0)
	overload_lock = maxf(0.0, overload_lock - delta)
	var had_windup := _windup_remaining > 0.0
	_windup_remaining = maxf(0.0, _windup_remaining - delta)
	if had_windup and _windup_remaining <= 0.0:
		if _pending_action == "attack":
			_commit_attack()
		elif _pending_action == "support":
			_commit_support()
		_pending_action = ""
	if global_position.distance_to(owner_player.global_position) > 760.0:
		_quantum_reposition()
	_find_target()
	if _is_air():
		_tick_air(delta)
	else:
		_tick_ground(delta)
	if str(profile.get("combat_style", "")) == "support" and _support_cd <= 0.0:
		_support_pulse()
	_last_position = global_position
	queue_redraw()


func _tick_ground(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, 780.0)
	else:
		velocity.y = 0.0
	var desired_speed := 0.0
	if is_instance_valid(target):
		var distance := global_position.distance_to(target.global_position)
		if distance <= float(profile["attack_range"]):
			if _attack_cd <= 0.0:
				_attack_target()
		else:
			desired_speed = signf(target.global_position.x - global_position.x) * float(profile["move_speed"])
	else:
		var facing := float(owner_player.get("facing")) if owner_player.get("facing") != null else 1.0
		var follow_x := owner_player.global_position.x + formation_offset.x * facing
		desired_speed = clampf((follow_x - global_position.x) * 3.0, -float(profile["move_speed"]), float(profile["move_speed"]))
	velocity.x = move_toward(velocity.x, desired_speed, 620.0 * delta)
	move_and_slide()
	var intended_motion := absf(desired_speed) > 45.0
	var actual_motion := absf(global_position.x - _last_position.x)
	_unstuck_timer = _unstuck_timer + delta if intended_motion and actual_motion < 0.8 else 0.0
	if _unstuck_timer > 1.15:
		_quantum_reposition()


func _tick_air(delta: float) -> void:
	var facing := float(owner_player.get("facing")) if owner_player.get("facing") != null else 1.0
	var desired := owner_player.global_position + Vector2(formation_offset.x * facing, formation_offset.y + sin(_phase * 2.3 + formation_index) * 10.0)
	if is_instance_valid(target) and str(profile.get("combat_style", "")) != "support":
		var side := signf(global_position.x - target.global_position.x)
		if side == 0.0:
			side = -1.0
		desired = target.global_position + Vector2(side * minf(245.0, float(profile["attack_range"]) * 0.72), -118.0)
		if global_position.distance_to(target.global_position) <= float(profile["attack_range"]) and _attack_cd <= 0.0:
			_attack_target()
	elif is_instance_valid(target) and global_position.distance_to(target.global_position) <= float(profile["attack_range"]) and _attack_cd <= 0.0:
		_attack_target()
	var desired_velocity := (desired - global_position) * 3.2
	desired_velocity = desired_velocity.limit_length(float(profile["move_speed"]))
	velocity = velocity.move_toward(desired_velocity, 520.0 * delta)
	global_position += velocity * delta


func _find_target() -> void:
	if is_instance_valid(target) and not _is_target_dead(target):
		if target.global_position.distance_to(owner_player.global_position) < 520.0:
			return
	target = null
	var best := 500.0
	for candidate in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(candidate) or _is_target_dead(candidate) or not candidate.has_method("take_damage"):
			continue
		var enemy := candidate as Node2D
		if not is_instance_valid(enemy):
			continue
		var owner_distance: float = enemy.global_position.distance_to(owner_player.global_position)
		if owner_distance > 480.0:
			continue
		if not _is_air() and absf(enemy.global_position.y - global_position.y) > 190.0:
			continue
		var distance: float = global_position.distance_to(enemy.global_position)
		if distance < best:
			best = distance
			target = enemy


func _attack_target() -> void:
	_begin_attack()


func _begin_attack() -> void:
	if not is_instance_valid(target) or overload_lock > 0.0 or _pending_action != "":
		return
	var style := str(profile.get("combat_style", "striker"))
	_windup_remaining = SUMMON_FX.warning_duration(style)
	_attack_cd = float(profile["attack_cooldown"]) + _windup_remaining
	_pending_target = target
	_pending_action = "attack"
	var accent: Color = profile.get("accent", Color("53e6ff"))
	SummonFx.skill_warning(get_parent(), global_position + Vector2(0, -28), target.global_position + Vector2(0, -28), style, accent)
	_attack_glow = 0.55


func _commit_attack() -> void:
	var attack_target := _pending_target
	_pending_target = null
	if not is_instance_valid(attack_target) or _is_target_dead(attack_target):
		return
	_attack_glow = 1.0
	var style := str(profile.get("combat_style", "striker"))
	var direction := signf(attack_target.global_position.x - global_position.x)
	var knockback := Vector2(direction * (285.0 if style == "vanguard" else 165.0), -62.0)
	attack_target.take_damage(maxi(1, roundi(float(profile["damage"]) * power_scale)), knockback)
	if style == "artillery":
		for candidate in get_tree().get_nodes_in_group("enemy"):
			if candidate != attack_target and is_instance_valid(candidate) and candidate.has_method("take_damage"):
				var splash_target := candidate as Node2D
				if is_instance_valid(splash_target) and splash_target.global_position.distance_to(attack_target.global_position) <= 82.0:
					candidate.take_damage(1, Vector2(direction * 90.0, -35.0))
	var beam := Line2D.new()
	beam.width = 9.0 if style == "artillery" else (5.0 if style == "support" else 7.0)
	var accent: Color = profile.get("accent", Color("53e6ff"))
	beam.default_color = Color(accent.r, accent.g, accent.b, 0.96)
	beam.points = PackedVector2Array([Vector2(24.0 * direction, -38.0), to_local(attack_target.global_position + Vector2(0, -28))])
	beam.z_index = 12
	add_child(beam)
	var beam_tween := beam.create_tween()
	beam_tween.tween_property(beam, "width", 1.0, 0.16)
	beam_tween.parallel().tween_property(beam, "modulate:a", 0.0, 0.20)
	beam_tween.tween_callback(beam.queue_free)
	Fx.hit_spark(get_parent(), attack_target.global_position + Vector2(0, -28))
	Game.shake(1.8 if style == "artillery" else 1.2)
	attack_committed.emit(self)


func _is_target_dead(candidate: Node) -> bool:
	if not is_instance_valid(candidate):
		return true
	var dead_value = candidate.get("dead")
	if dead_value != null:
		return dead_value == true
	var state_value = candidate.get("state")
	return state_value != null and str(state_value) == "dead"


func _support_pulse() -> void:
	if overload_lock > 0.0 or _pending_action != "":
		return
	_windup_remaining = SUMMON_FX.warning_duration("support")
	_support_cd = float(profile.get("support_cooldown", 5.0)) + _windup_remaining
	_pending_action = "support"
	var accent: Color = profile.get("accent", Color("75ffb5"))
	SummonFx.skill_warning(get_parent(), global_position + Vector2(0, -30), owner_player.global_position + Vector2(0, -30), "support", accent)


func _commit_support() -> void:
	var healed := false
	if owner_player.has_method("max_hp") and int(owner_player.get("health")) < int(owner_player.call("max_hp")):
		owner_player.call("heal", 1)
		Fx.popup(get_parent(), owner_player.global_position + Vector2(0, -84), "修复 +1", Color("75ffb5"))
		healed = true
	elif hp < max_hp:
		hp = mini(max_hp, hp + 1)
		health_changed.emit(hp, max_hp)
		healed = true
	if healed:
		_attack_glow = 1.0
		attack_committed.emit(self)


func force_support_pulse_for_qa() -> void:
	_support_cd = 0.0
	var accent: Color = profile.get("accent", Color("75ffb5"))
	SummonFx.skill_warning(get_parent(), global_position + Vector2(0, -30), owner_player.global_position + Vector2(0, -30), "support", accent)
	_commit_support()


func force_warning_for_qa() -> void:
	var style := str(profile.get("combat_style", "striker"))
	var accent: Color = profile.get("accent", Color("53e6ff"))
	var warning_target := owner_player.global_position + Vector2(190.0, -24.0)
	if is_instance_valid(target):
		warning_target = target.global_position + Vector2(0, -28)
	if style == "support":
		warning_target = owner_player.global_position + Vector2(0, -30)
	SummonFx.skill_warning(get_parent(), global_position + Vector2(0, -28), warning_target, style, accent)
	_attack_glow = 0.65


func _quantum_reposition() -> void:
	var offset := formation_offset
	global_position = owner_player.global_position + offset
	velocity = Vector2.ZERO
	_unstuck_timer = 0.0
	target = null
	Fx.popup(get_parent(), global_position + Vector2(0, -76), "量子归位", Color(0.45, 0.9, 1.0))


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
	SummonFx.recall(get_parent(), global_position + Vector2(0, -20), profile.get("accent", Color("53e6ff")))
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.12, 0.12), 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.16)
	tween.chain().tween_callback(queue_free)


func _disable() -> void:
	_disabled = true
	collision_layer = 0
	Fx.death_burst(get_parent(), global_position + Vector2(0, -24), Color(0.25, 0.9, 1.0))
	SummonFx.disabled_burst(get_parent(), global_position + Vector2(0, -24), profile.get("accent", Color("53e6ff")))
	disabled.emit(self)
	queue_free()


func _is_air() -> bool:
	return str(profile.get("mobility", "ground")) == "air"


func _draw() -> void:
	var style := str(profile.get("draw_style", "hound"))
	if style == "mole":
		_draw_mole()
	elif style == "drone":
		_draw_drone()
	elif style == "wisp":
		_draw_wisp()
	else:
		_draw_hound()
	_draw_health_bar()


func _draw_hound() -> void:
	var accent: Color = profile.get("accent", Color("53e6ff"))
	var pulse := 0.75 + sin(_phase * 5.0) * 0.18
	draw_colored_polygon(PackedVector2Array([Vector2(-45,-4),Vector2(45,-4),Vector2(34,5),Vector2(-34,5)]), Color(0,0,0,0.42))
	for x in [-27.0, 27.0]:
		draw_circle(Vector2(x,-8),14.0,Color("132431")); draw_circle(Vector2(x,-8),9.0,Color("426274")); draw_circle(Vector2(x,-8),4.0,accent*0.8)
	draw_colored_polygon(PackedVector2Array([Vector2(-40,-18),Vector2(-30,-50),Vector2(10,-58),Vector2(39,-40),Vector2(42,-16),Vector2(20,-8),Vector2(-28,-8)]),Color("1b2a36"))
	draw_polyline(PackedVector2Array([Vector2(-40,-18),Vector2(-30,-50),Vector2(10,-58),Vector2(39,-40),Vector2(42,-16)]),Color("718b9c"),3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(18,-48),Vector2(47,-40),Vector2(54,-25),Vector2(35,-20),Vector2(20,-28)]),Color("263f4d"))
	draw_line(Vector2(-18,-52),Vector2(-25,-72),Color("8eb4c8"),3.0); draw_circle(Vector2(-26,-74),4.0+pulse,accent)
	draw_circle(Vector2(5,-34),13.0+_attack_glow*5.0,Color(accent.r,accent.g,accent.b,0.22+_attack_glow*0.28)); draw_circle(Vector2(5,-34),7.0+pulse,accent if _flash<=0.0 else Color.WHITE)
	draw_line(Vector2(-18,-23),Vector2(23,-23),Color(accent.r,accent.g,accent.b,0.75),4.0)


func _draw_mole() -> void:
	var accent: Color = profile["accent"]
	draw_ellipse_shadow(Vector2(0,-2),Vector2(56,10))
	for x in [-31.0,31.0]:
		draw_circle(Vector2(x,-9),15,Color("171e24")); draw_circle(Vector2(x,-9),8,Color("725a32"))
	draw_colored_polygon(PackedVector2Array([Vector2(-46,-16),Vector2(-38,-57),Vector2(18,-66),Vector2(46,-43),Vector2(46,-13)]),Color("2d2c2a"))
	draw_polyline(PackedVector2Array([Vector2(-46,-16),Vector2(-38,-57),Vector2(18,-66),Vector2(46,-43),Vector2(46,-13)]),Color("b18a4a"),4)
	draw_rect(Rect2(Vector2(22,-65),Vector2(25,49)),Color("493b28"),true); draw_arc(Vector2(35,-40),26,-PI/2,PI/2,16,accent,5)
	draw_circle(Vector2(-7,-39),13+_attack_glow*5,Color(accent.r,accent.g,accent.b,0.25)); draw_circle(Vector2(-7,-39),7,accent if _flash<=0 else Color.WHITE)


func _draw_drone() -> void:
	var accent: Color = profile["accent"]
	var wing := 10.0+sin(_phase*8.0)*4.0
	draw_circle(Vector2.ZERO,42,Color(0,0,0,0.16))
	draw_colored_polygon(PackedVector2Array([Vector2(-52,-23-wing),Vector2(-17,-13),Vector2(-7,-32),Vector2(-36,-47)]),Color("293744"))
	draw_colored_polygon(PackedVector2Array([Vector2(52,-23-wing),Vector2(17,-13),Vector2(7,-32),Vector2(36,-47)]),Color("293744"))
	draw_polyline(PackedVector2Array([Vector2(-48,-40),Vector2(-14,-25),Vector2(0,-48),Vector2(14,-25),Vector2(48,-40)]),accent,3)
	draw_colored_polygon(PackedVector2Array([Vector2(-25,-20),Vector2(-15,-51),Vector2(17,-51),Vector2(30,-20),Vector2(17,0),Vector2(-17,0)]),Color("17242d"))
	draw_circle(Vector2(0,-29),12+_attack_glow*6,Color(accent.r,accent.g,accent.b,0.25)); draw_circle(Vector2(0,-29),7,accent if _flash<=0 else Color.WHITE)
	draw_line(Vector2(0,0),Vector2(0,18),Color("718896"),5); draw_circle(Vector2(0,21),6,accent)


func _draw_wisp() -> void:
	var accent: Color = profile["accent"]
	var pulse := 1.0+sin(_phase*4.0)*0.12
	draw_circle(Vector2(0,-30),40*pulse,Color(accent.r,accent.g,accent.b,0.08))
	draw_arc(Vector2(0,-30),31,0,TAU,28,Color(accent.r,accent.g,accent.b,0.55),3)
	draw_arc(Vector2(0,-30),22,_phase,_phase+PI*1.45,20,accent,4)
	draw_colored_polygon(PackedVector2Array([Vector2(-15,-43),Vector2(0,-57),Vector2(15,-43),Vector2(18,-18),Vector2(0,-6),Vector2(-18,-18)]),Color("203b3a"))
	draw_circle(Vector2(0,-31),10+_attack_glow*6,Color(accent.r,accent.g,accent.b,0.3)); draw_circle(Vector2(0,-31),6,accent if _flash<=0 else Color.WHITE)
	for i in range(3):
		var a := _phase*1.7+float(i)*TAU/3.0
		draw_circle(Vector2(cos(a),sin(a))*32+Vector2(0,-30),3.5,accent)


func _draw_health_bar() -> void:
	var accent: Color = profile.get("accent",Color("53e6ff"))
	var y := -91.0 if not _is_air() else -78.0
	draw_rect(Rect2(Vector2(-38,y),Vector2(76,6)),Color(0.02,0.05,0.08,0.90),true)
	draw_rect(Rect2(Vector2(-37,y+1),Vector2(74.0*float(hp)/float(maxi(1,max_hp)),4)),accent,true)


func draw_ellipse_shadow(center: Vector2, size: Vector2) -> void:
	var points := PackedVector2Array()
	for i in range(16):
		var angle := float(i)*TAU/16.0
		points.append(center+Vector2(cos(angle)*size.x,sin(angle)*size.y))
	draw_colored_polygon(points,Color(0,0,0,0.42))
