extends CharacterBody2D
## 主角控制器: 跑/可变跳/土狼时间/跳跃缓冲/二段跳/墙滑+蹬墙跳/冲刺/三段连击
## 节点子物体在 _ready() 中以代码构建, 无需 .tscn

signal health_changed(cur: int, maxv: int)
signal weapon_changed(name: String, color: Color)
signal attacked
signal died
signal resource_changed(mp: float, max_mp: float, rage: float, max_rage: float)

# ---- 移动手感参数 ----
const RUN_SPEED := 270.0
const GROUND_ACCEL := 2400.0
const AIR_ACCEL := 1700.0
const GROUND_FRICTION := 2800.0
const AIR_FRICTION := 700.0
const TURN_BOOST := 1.7            # 反向时加速倍率(更跟手)

const GRAVITY := 1500.0
const FALL_GRAVITY_MULT := 1.45    # 下落更快, 手感更利落
const MAX_FALL := 780.0
const JUMP_VELOCITY := -600.0
const JUMP_CUT := 0.42             # 松开跳跃键时上升速度衰减(可变跳跃高度)

const COYOTE_TIME := 0.12          # 土狼时间
const JUMP_BUFFER := 0.13          # 跳跃缓冲
const MAX_AIR_JUMPS := 1           # 二段跳次数
const AIR_JUMP_MULT := 1.08        # 二段跳比一段更高(更容易够到空中敌)

const WALL_SLIDE_SPEED := 80.0     # 墙滑更慢, 留出反应时间
const CLIMB_SPEED := 150.0         # 攀墙速度(需能力)
const GLIDE_FALL_SPEED := 95.0     # 滑翔下落速度(需能力)
# 水域(10.2): 基础游泳人人可用; 水下推进器(aqua)= 快速全向游动, 可顶住水流闸门
const BASE_SWIM := 120.0           # 无推进器: 划水慢
const AQUA_SWIM := 300.0           # 有推进器: 快速全向
const WATER_ACCEL := 1000.0
const BUOY_SINK := 70.0            # 无推进器中性时缓沉
var _water_t := 0.0                # >0 表示在水中(水域每帧刷新)
var water_flow := Vector2.ZERO     # 当前所在水流速度(水流闸门用)
const WALL_JUMP_PUSH := 340.0
const WALL_JUMP_UP := -620.0       # 蹬墙跳更高, 便于爬出深坑
const WALL_JUMP_LOCK := 0.10       # 蹬墙跳后水平控制锁定(更短, 便于回身上平台)

const DASH_SPEED := 680.0
const DASH_TIME := 0.16
const DASH_COOLDOWN := 0.45

const MAX_HEALTH := 5
const HURT_KNOCKBACK := Vector2(260, -260)
const IFRAME_TIME := 0.9

const HERO_SCALE := 2.8
const ANIM_OFFSET_Y := -46.0
const KILL_Y := 1150.0            # 掉落死亡线
const SKILL_COOLDOWN := 0.6       # 斩击波冷却
const DIVE_SPEED := 1000.0        # 空中下砸速度

const PROJECTILE_SCRIPT := preload("res://scripts/projectile.gd")
const BOMB_SCRIPT := preload("res://scripts/bomb.gd")

# ---- 运行时状态 ----
enum S { NORMAL, DASH, ATTACK, HURT, DEAD, DIVE }
var state: int = S.NORMAL
var facing := 1
var health := MAX_HEALTH
var skill_cd := 0.0
var bomb_cd := 0.0

# ---- 主动技能资源(v2): 技力(MP) + 怒气 ----
const MAX_MP := 100.0
const MAX_RAGE := 100.0
const MP_REGEN := 7.0          # 每秒自然回复
const MP_ON_HIT := 8.0         # 命中敌人回蓝
const RAGE_ON_HIT := 7.0
const RAGE_ON_HURT := 12.0
var mp := MAX_MP
var rage := 0.0
var _skill_cds := {}           # archetype_id -> 剩余冷却
var _tap_dir := 0              # 搓招: 上次方向键
var _tap_t := 0.0             # 搓招: 上次按下时刻(s)
var _dash_ready := 0.0         # >0 表示最近双击了某方向(突进技窗口)
var _dash_dir := 0             # 双击的方向(-1/1); 突进须仍按住同向才触发
var _down_ready := 0.0         # >0 表示最近双击了↓(环身爆发窗口)
var _downtap_t := 0.0

var coyote := 0.0
var jump_buffer := 0.0
var air_jumps := 0
var jumping := false
var wall_lock := 0.0

var can_dash := true
var dash_timer := 0.0
var dash_cd := 0.0

var attack_index := 0
var attack_timer := 0.0
var combo_window := 0.0
var hit_targets: Array = []

var iframes := 0.0
var spawn_point := Vector2.ZERO

var slash_frames: SpriteFrames

# 武器
var weapon_index := 0
var weapon: Dictionary = Weapons.get_weapon(0)
var attack_up := false
var fx_frames := {}      # 各武器特效帧

# 子节点
var anim: AnimatedSprite2D
var sprite_scale_base := Vector2.ONE
var hitbox: Area2D
var hitbox_shape: CollisionShape2D
var hitbox_rect: RectangleShape2D
var weapon_pivot: Node2D
var weapon_sprite: Sprite2D

func _ready() -> void:
	add_to_group("player")
	collision_layer = 0b00010    # player
	collision_mask = 0b100001    # world + 冲刺门(bit6); 冲刺时去掉bit6相位穿越
	_build_nodes()
	spawn_point = global_position
	weapon_index = Game.weapon_index
	weapon = Weapons.get_weapon(weapon_index)
	_apply_weapon()
	if slash_frames == null:
		slash_frames = AnimLoader.build_slash()
	fx_frames["slash"] = slash_frames
	fx_frames["bolt"] = AnimLoader.build_effect("bolt", 7, 16.0)
	fx_frames["spin"] = AnimLoader.build_effect("spin", 10, 14.0)
	fx_frames["bolt2"] = AnimLoader.build_effect("bolt2", 4, 16.0)
	health = max_hp()
	Game.skills_changed.connect(_on_skills_changed)
	Game.gear_changed.connect(_on_gear_changed)
	health_changed.emit(health, max_hp())

# ---- 技能加成 ----
func max_hp() -> int:
	return MAX_HEALTH + Game.skill_lv("hp") + int(round(Game.equip_bonus("hp"))) + Game.heart_pieces
func max_mp() -> float:
	return MAX_MP + 20.0 * Game.skill_lv("mp_max")   # 机械超频:技力强化
func _max_air_jumps() -> int:
	return MAX_AIR_JUMPS + Game.skill_lv("triple")
func _run_speed() -> float:
	return RUN_SPEED * (1.0 + 0.08 * Game.skill_lv("speed") + Game.equip_bonus("spd"))
func _on_skills_changed() -> void:
	# 加点后回满血作为奖励
	health = max_hp()
	health_changed.emit(health, max_hp())
func _on_gear_changed() -> void:
	# 装备变化: 钳制血量到新上限并刷新显示
	health = clampi(health, 1, max_hp())
	health_changed.emit(health, max_hp())

func heal(n: int) -> void:
	health = mini(health + n, max_hp())
	health_changed.emit(health, max_hp())

func _build_nodes() -> void:
	# 碰撞体 (脚在原点, 身体在上方)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(28, 60)
	col.shape = shape
	col.position = Vector2(0, -30)
	add_child(col)

	# 动画精灵 (Pixel Adventure 32px, 放大)
	anim = AnimatedSprite2D.new()
	anim.sprite_frames = AnimLoader.build_player()
	anim.centered = true
	anim.scale = Vector2(HERO_SCALE, HERO_SCALE)
	anim.position = Vector2(0, ANIM_OFFSET_Y)
	anim.play("idle")
	add_child(anim)
	sprite_scale_base = Vector2(HERO_SCALE, HERO_SCALE)

	# 攻击判定框 (在身前, 随朝向翻转)
	hitbox = Area2D.new()
	hitbox.collision_layer = 0
	hitbox.collision_mask = 0b00100   # enemy
	hitbox.monitoring = false
	hitbox_shape = CollisionShape2D.new()
	hitbox_rect = RectangleShape2D.new()
	hitbox_rect.size = Vector2(78, 84)
	hitbox_shape.shape = hitbox_rect
	hitbox_shape.position = Vector2(52, -34)
	hitbox.add_child(hitbox_shape)
	add_child(hitbox)

	# 手持武器 (可见挥砍): pivot 在手部, sprite 沿 pivot 伸出
	weapon_pivot = Node2D.new()
	weapon_pivot.position = Vector2(6, -34)
	add_child(weapon_pivot)
	weapon_sprite = Sprite2D.new()
	weapon_sprite.position = Vector2(0, -22)   # 沿 pivot 向外/上伸出
	weapon_sprite.scale = Vector2(1.4, 1.4)
	weapon_pivot.add_child(weapon_sprite)

func _physics_process(delta: float) -> void:
	# 掉出世界 -> 死亡重生
	if state != S.DEAD and global_position.y > KILL_Y:
		_die()
		return

	match state:
		S.DASH:    _do_dash(delta)
		S.ATTACK:  _do_attack_state(delta)
		S.HURT:    _do_hurt(delta)
		S.DIVE:    _do_dive(delta)
		S.DEAD:    pass
		_:         _do_normal(delta)

	_update_timers(delta)
	move_and_slide()
	_update_anim()
	_update_squash(delta)
	_update_weapon(delta)

func _update_timers(delta: float) -> void:
	if iframes > 0.0:
		iframes -= delta
		anim.visible = int(iframes * 20.0) % 2 == 0
	else:
		anim.visible = true
	if dash_cd > 0.0:
		dash_cd -= delta
	if skill_cd > 0.0:
		skill_cd -= delta
	if bomb_cd > 0.0:
		bomb_cd -= delta
	if combo_window > 0.0:
		combo_window -= delta
		if combo_window <= 0.0:
			attack_index = 0
	if wall_lock > 0.0:
		wall_lock -= delta
	# 主动技能资源: 技力回复 / 各招冷却 / 搓招窗口
	var mmax := max_mp()
	if mp < mmax:
		mp = minf(mp + (MP_REGEN + 3.0 * Game.skill_lv("mp_regen")) * delta, mmax)
	for k in _skill_cds:
		if _skill_cds[k] > 0.0:
			_skill_cds[k] -= delta
	if _dash_ready > 0.0:
		_dash_ready -= delta
	if _down_ready > 0.0:
		_down_ready -= delta
	if _water_t > 0.0:
		_water_t -= delta
	resource_changed.emit(mp, mmax, rage, MAX_RAGE)

func is_in_water() -> bool:
	return _water_t > 0.0

# 由 water.gd 每帧调用: 标记在水中并传入该处水流
func enter_water(flow: Vector2) -> void:
	_water_t = 0.12
	water_flow = flow

# ------------------------------------------------------------- 普通状态
func _do_normal(delta: float) -> void:
	var input_dir := Input.get_axis("move_left", "move_right")
	var on_floor := is_on_floor()

	# 朝向
	if input_dir != 0.0 and wall_lock <= 0.0:
		facing = signi(int(sign(input_dir)))

	# 水平加减速
	var accel := GROUND_ACCEL if on_floor else AIR_ACCEL
	if input_dir != 0.0:
		if signf(input_dir) != signf(velocity.x) and velocity.x != 0.0:
			accel *= TURN_BOOST
		if wall_lock <= 0.0:
			velocity.x = move_toward(velocity.x, input_dir * _run_speed(), accel * delta)
	else:
		var fric := GROUND_FRICTION if on_floor else AIR_FRICTION
		velocity.x = move_toward(velocity.x, 0.0, fric * delta)

	# 计时器: 土狼 / 缓冲
	if on_floor:
		coyote = COYOTE_TIME
		air_jumps = _max_air_jumps()
		can_dash = true
		jumping = false
	else:
		coyote = max(0.0, coyote - delta)

	if Input.is_action_just_pressed("jump"):
		jump_buffer = JUMP_BUFFER
	else:
		jump_buffer = max(0.0, jump_buffer - delta)

	# 墙滑 / 攀墙(需能力)
	var on_wall := is_on_wall_only() and not on_floor
	var wall_n := get_wall_normal()
	var toward_wall := on_wall and input_dir != 0.0 and signf(input_dir) == -signf(wall_n.x)
	var climbing := toward_wall and Game.has_ability("wall_climb")
	if climbing:
		velocity.y = Input.get_axis("move_up", "move_down") * CLIMB_SPEED
		velocity.x = -wall_n.x * 50.0
		air_jumps = _max_air_jumps()
		if absf(velocity.y) > 12.0 and randf() < 0.2:
			Fx.dust(get_parent(), global_position + Vector2(wall_n.x * -16, 16), wall_n.x)
	elif toward_wall and velocity.y > 0.0:
		velocity.y = min(velocity.y, WALL_SLIDE_SPEED)
		air_jumps = _max_air_jumps()
		if randf() < 0.25:
			Fx.dust(get_parent(), global_position + Vector2(wall_n.x * -16, 30), wall_n.x)

	var in_water := is_in_water()
	if in_water:
		# 水域: 游泳(替代重力/跳跃)。基础人人可用; 水下推进器=快速全向, 可顶住水流
		var aqua := Game.has_ability("aqua")
		var swim := AQUA_SWIM if aqua else BASE_SWIM
		var vy_in := Input.get_axis("move_up", "move_down")
		var target := Vector2(input_dir * swim, 0.0)
		if aqua:
			target.y = vy_in * swim
		else:
			if Input.is_action_pressed("jump"):
				target.y = -BASE_SWIM
			elif vy_in != 0.0:
				target.y = vy_in * BASE_SWIM
			else:
				target.y = BUOY_SINK
		target += water_flow          # 水流闸门: 基础划水顶不住, 推进器能过
		velocity = velocity.move_toward(target, WATER_ACCEL * delta)
		air_jumps = _max_air_jumps()  # 出水即可跳
		can_dash = true
		if randf() < 0.12:
			Fx.dust(get_parent(), global_position + Vector2(randf_range(-10, 10), 8), 0.0)
	elif not on_floor and not climbing:
		# 重力(攀墙时不施加)
		var g := GRAVITY
		if velocity.y > 0.0:
			g *= FALL_GRAVITY_MULT
		velocity.y = min(velocity.y + g * delta, MAX_FALL)
		# 滑翔(需能力): 下落时按住跳键减速下落
		if velocity.y > 0.0 and Game.has_ability("glide") and Input.is_action_pressed("jump"):
			velocity.y = minf(velocity.y, GLIDE_FALL_SPEED)
			if randf() < 0.25:
				Fx.dust(get_parent(), global_position + Vector2(0, 14), 0.0)

	# 跳跃判定(水中用跳键划水, 不触发跳)
	if jump_buffer > 0.0 and not in_water:
		if coyote > 0.0:
			_jump()
		elif on_wall:
			_wall_jump(wall_n)
		elif air_jumps > 0:
			air_jumps -= 1
			_jump(AIR_JUMP_MULT)
			Fx.dust(get_parent(), global_position + Vector2(0, 30), 0)
			Fx.shockwave(get_parent(), global_position + Vector2(0, 10), Color(0.6, 0.9, 1.0, 0.7))

	# 可变跳跃高度
	if jumping and Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT
		jumping = false

	# 落地尘土
	if on_floor and _was_in_air:
		Fx.dust(get_parent(), global_position + Vector2(0, 30), 0)
		_squash(Vector2(1.25, 0.75))
		_play_sfx("land", -6.0)
	_was_in_air = not on_floor

	# 切换武器
	if Input.is_action_just_pressed("switch"):
		_switch_weapon()

	# 搓招: 双击前进方向 -> 突进技窗口
	var now := float(Time.get_ticks_msec()) * 0.001
	for d in [-1, 1]:
		var act := "move_left" if d == -1 else "move_right"
		if Input.is_action_just_pressed(act):
			if _tap_dir == d and (now - _tap_t) < 0.28:
				_dash_ready = 0.32
				_dash_dir = d
			_tap_dir = d
			_tap_t = now
	# 搓招: 双击↓ -> 环身爆发窗口
	if Input.is_action_just_pressed("move_down"):
		if (now - _downtap_t) < 0.28:
			_down_ready = 0.32
		_downtap_t = now

	# 冲刺(初始技能)
	if Input.is_action_just_pressed("dash") and can_dash and dash_cd <= 0.0:
		_start_dash()
		return

	# 主动技能 (K + 方向搓招): ↑K=上挑 / 双击前进+K=突进斩 / 否则=地面波
	if Input.is_action_just_pressed("skill"):
		_try_skill()
		return

	# 大招 (V, 满怒气)
	if Input.is_action_just_pressed("ult"):
		_cast_ult()
		return

	# 投掷炸弹 (需解锁能力)
	if Input.is_action_just_pressed("bomb"):
		if not Game.has_ability("bomb"):
			Fx.popup(get_parent(), global_position + Vector2(0, -92), "需要炸弹能力 (熔岩腔穴)", Color(1, 0.7, 0.4))
		elif bomb_cd <= 0.0:
			_throw_bomb()
		return

	# 攻击 / 空中下砸 / 上劈
	if Input.is_action_just_pressed("attack"):
		if not on_floor and Input.is_action_pressed("move_down"):
			_start_dive()
		else:
			attack_up = Input.is_action_pressed("move_up")
			_start_attack()
		return

var _was_in_air := false

func _jump(mult: float = 1.0) -> void:
	velocity.y = JUMP_VELOCITY * mult
	jumping = true
	jump_buffer = 0.0
	coyote = 0.0
	_squash(Vector2(0.75, 1.3))
	_play_sfx("jump", -4.0)

func _wall_jump(wall_n: Vector2) -> void:
	velocity.x = wall_n.x * WALL_JUMP_PUSH
	velocity.y = WALL_JUMP_UP
	facing = signi(int(sign(wall_n.x)))
	jumping = true
	jump_buffer = 0.0
	wall_lock = WALL_JUMP_LOCK
	air_jumps = _max_air_jumps()
	_squash(Vector2(0.8, 1.25))
	_play_sfx("jump", -2.0)
	Fx.dust(get_parent(), global_position + Vector2(-wall_n.x * 16, 20), -wall_n.x)

# ------------------------------------------------------------- 冲刺
func _start_dash() -> void:
	state = S.DASH
	dash_timer = DASH_TIME
	can_dash = false
	dash_cd = maxf(0.12, DASH_COOLDOWN - 0.1 * Game.skill_lv("dashcd"))
	velocity = Vector2(facing * DASH_SPEED, 0.0)
	iframes = max(iframes, DASH_TIME)   # 冲刺无敌帧
	collision_mask = 0b00001            # 冲刺中相位穿越冲刺门
	Fx.dash_dust(get_parent(), global_position + Vector2(0, 20), facing)
	_play_sfx("dash", -3.0)
	_squash(Vector2(1.35, 0.7))

func _do_dash(delta: float) -> void:
	dash_timer -= delta
	velocity.y = 0.0
	if int(dash_timer * 40.0) % 2 == 0:
		_spawn_ghost()
	if dash_timer <= 0.0:
		state = S.NORMAL
		velocity.x *= 0.5
		collision_mask = 0b100001        # 恢复与冲刺门碰撞

func _spawn_ghost() -> void:
	var g := Sprite2D.new()
	g.texture = anim.sprite_frames.get_frame_texture(anim.animation, anim.frame)
	g.flip_h = anim.flip_h
	g.global_position = global_position
	g.modulate = Color(0.5, 0.8, 1.0, 0.5)
	g.z_index = -1
	get_parent().add_child(g)
	var tw := g.create_tween()
	tw.tween_property(g, "modulate:a", 0.0, 0.25)
	tw.tween_callback(g.queue_free)

# ------------------------------------------------------------- 斩击波(远程技能)
# K = 重攻击, 每把武器各不相同
func _throw_bomb() -> void:
	_aim_facing()
	bomb_cd = 0.9
	var b := CharacterBody2D.new()
	b.set_script(BOMB_SCRIPT)
	b.position = global_position + Vector2(facing * 22, -42)
	get_parent().add_child(b)
	if b.has_method("setup"):
		b.setup(Vector2(facing * 250.0, -360.0), 4 + Game.skill_lv("atk"))
	_play_sfx("dash", -5.0)
	_squash(Vector2(1.15, 0.85))

func _fire_skill() -> void:
	_aim_facing()
	skill_cd = SKILL_COOLDOWN
	match weapon["id"]:
		"hammer": _heavy_hammer()
		"cannon": _heavy_cannon()
		_:        _heavy_sword()

# ---- 主动技能分派(v2): K + 方向搓招 ----
func gain_mp(n: float) -> void:
	mp = minf(mp + n, max_mp())

func gain_rage(n: float) -> void:
	rage = minf(rage + n, MAX_RAGE)

func _skill_dmg(mult: float) -> int:
	var base: int = int(weapon["damage"]) + Game.skill_lv("atk") + Game.skill_lv("power") + int(round(Game.equip_bonus("atk")))
	var oc := 1.0 + 0.15 * Game.skill_lv("skill_dmg")   # 机械超频:过载输出
	return int(round(float(base) * mult * oc))

func _try_skill() -> void:
	# 优先级: ↑上挑 > 双击↓环身爆发 > (双击同向且仍按住)突进 > 地面波
	# 仅"单按住方向跑"时按K → 一律地面波, 不会误触方向技
	var hx := Input.get_axis("move_left", "move_right")
	var arch := "ground"
	if Input.is_action_pressed("move_up") and not Input.is_action_pressed("move_down"):
		arch = "upper"
	elif _down_ready > 0.0 and Input.is_action_pressed("move_down"):
		arch = "burst"
		_down_ready = 0.0
	elif _dash_ready > 0.0 and hx != 0.0 and signf(hx) == float(_dash_dir):
		arch = "dash_atk"
		_dash_ready = 0.0   # 消费掉, 防一次双击连放
	_cast(arch)

func _cast(arch: String) -> void:
	var d: Dictionary = SkillsActive.ARCHETYPES[arch]
	if float(_skill_cds.get(arch, 0.0)) > 0.0:
		return
	if mp < float(d["mp"]):
		Fx.popup(get_parent(), global_position + Vector2(0, -92), "技力不足", Color(0.6, 0.8, 1.0))
		return
	_aim_facing()
	mp -= float(d["mp"])
	_skill_cds[arch] = float(d["cd"]) * (1.0 - 0.15 * Game.skill_lv("skill_cd"))   # 机械超频:招式精通
	gain_rage(4.0)
	Fx.cast_ring(get_parent(), global_position + Vector2(0, -30), weapon["color"])
	match arch:
		"ground":   _fire_skill()
		"upper":    _skill_upper()
		"dash_atk": _skill_dash_atk()
		"burst":    _skill_burst()
	resource_changed.emit(mp, max_mp(), rage, MAX_RAGE)

# ---- 技能辅助 ----
# 范围伤害(圆形, 向外击退)
func _aoe_hit(center: Vector2, radius: float, dmg: int, kb_scale: float, kb_up: float) -> void:
	for e in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(e) or not e.has_method("take_damage"):
			continue
		var ep: Vector2 = (e as Node2D).global_position
		if ep.distance_to(center) < radius:
			var kd := signf(ep.x - center.x)
			if kd == 0.0:
				kd = float(facing)
			e.take_damage(dmg, Vector2(kd * kb_scale, kb_up))
			Fx.hit_spark(get_parent(), ep)
			Fx.hit_ring(get_parent(), ep, weapon["color"])

# 任意角度飞弹(全向弹幕/防空齐射用)
func _spawn_proj_vel(scale: float, tint: Color, dmg: int, v: Vector2, life: float, pierce: int = 2) -> void:
	var proj := Area2D.new()
	proj.set_script(PROJECTILE_SCRIPT)
	proj.position = global_position + Vector2(0, -34)
	get_parent().add_child(proj)
	if proj.has_method("setup"):
		proj.setup(fx_frames["bolt2"], 1.0, dmg, scale, tint)
		proj.vel = v
		proj.life = life
		proj.pierce = pierce

# ============================================================ 上挑(↑+K) · 各武器变形
func _skill_upper() -> void:
	var col: Color = weapon["color"]
	var center := global_position + Vector2(facing * 34, -46)
	match weapon["id"]:
		"cannon":   # 防空齐射: 不跳, 向上扇形 3 弹
			for a in [-1.75, -1.57, -1.39]:   # 朝上 ±扇形(弧度)
				_spawn_proj_vel(1.3, col, _skill_dmg(1.0), Vector2(cos(a), sin(a)) * 760.0, 1.0)
			Fx.shockwave(get_parent(), center + Vector2(0, -10), col)
			_play_sfx("atk_cannon", -2.0)
		"hammer":   # 上勾锤: 大跳 + 强力击飞 + 橙冲击
			if is_on_floor():
				velocity.y = -260.0
			Fx.play_slash(get_parent(), center, facing, fx_frames.get("bolt", slash_frames), 1.5, col)
			Fx.shockwave(get_parent(), center, col)
			Fx.shockwave(get_parent(), center + Vector2(0, -20), Color(1, 0.8, 0.4))
			_aoe_hit(center, 130.0, _skill_dmg(2.0), 150.0, -640.0)
			Game.shake(11.0)
			_play_sfx("atk_hammer", -2.0)
		_:          # 铁剑 上挑斩: 小跳 + 青色挑飞(接空连)
			if is_on_floor():
				velocity.y = -300.0
			Fx.play_slash(get_parent(), center, facing, slash_frames, 1.25, col)
			Fx.shockwave(get_parent(), center, col)
			_aoe_hit(center, 115.0, _skill_dmg(1.5), 130.0, -560.0)
			Game.shake(7.0)
			_play_sfx("attack", -2.0)
	Fx.screen_flash(get_tree(), Color(col.r, col.g, col.b, 0.14))
	Game.hitstop(0.06, 0.05)
	_squash(Vector2(0.85, 1.25))

# ============================================================ 突进(双击前进+K) · 各武器变形
func _skill_dash_atk() -> void:
	var col: Color = weapon["color"]
	match weapon["id"]:
		"cannon":   # 后跃齐射: 向后跃 + 向前扇形 3 弹(拉开距离)
			velocity = Vector2(-facing * 520.0, -200.0)
			for i in range(3):
				_spawn_proj_vel(1.4, col, _skill_dmg(1.0), Vector2(facing, -0.15 + i * 0.15) * 900.0, 1.6, 3)
			Fx.shockwave(get_parent(), global_position + Vector2(facing * 30, -30), col)
			_play_sfx("atk_cannon", -2.0)
			_squash(Vector2(0.8, 1.3))
		"hammer":   # 蛮牛冲撞: 霸体推进 + 强击退
			velocity = Vector2(facing * 520.0, 0.0)
			iframes = maxf(iframes, 0.3)   # 霸体
			for i in range(3):
				_spawn_ghost()
			Fx.speed_lines(get_parent(), global_position + Vector2(0, -30), facing, col)
			Fx.shockwave(get_parent(), global_position + Vector2(facing * 40, 6), col)
			_aoe_hit(global_position + Vector2(facing * 60, -30), 150.0, _skill_dmg(1.8), 420.0, -200.0)
			Game.shake(10.0)
			_play_sfx("atk_hammer", -2.0)
			_squash(Vector2(1.5, 0.6))
		_:          # 铁剑 瞬步连斩: 快速突进 + 沿途多段
			velocity = Vector2(facing * 640.0, 0.0)
			iframes = maxf(iframes, 0.2)
			for i in range(3):
				_spawn_ghost()
			Fx.speed_lines(get_parent(), global_position + Vector2(0, -30), facing, col)
			Fx.play_slash(get_parent(), global_position + Vector2(facing * 50, -30), facing, slash_frames, 1.3, col)
			Fx.play_slash(get_parent(), global_position + Vector2(facing * 80, -40), facing, slash_frames, 1.0, col)
			_aoe_hit(global_position + Vector2(facing * 115, -30), 145.0, _skill_dmg(1.3), 260.0, -160.0)
			Game.shake(8.0)
			_play_sfx("dash", -2.0)
			_squash(Vector2(1.4, 0.7))
	Game.hitstop(0.06, 0.05)

# ============================================================ 环身爆发(双击↓+K) · 各武器变形
func _skill_burst() -> void:
	var col: Color = weapon["color"]
	var center := global_position + Vector2(0, -30)
	match weapon["id"]:
		"cannon":   # 全向弹幕: 360° 8 弹
			for i in range(8):
				var a := TAU * i / 8.0
				_spawn_proj_vel(1.2, col, _skill_dmg(1.0), Vector2(cos(a), sin(a)) * 620.0, 1.2, 2)
			Fx.shockwave(get_parent(), center, col)
			_play_sfx("atk_cannon", -1.0)
		"hammer":   # 震地圈: 环形冲击波 + 强向外击退
			velocity.y = -180.0
			Fx.shockwave(get_parent(), global_position + Vector2(0, 6), col)
			Fx.shockwave(get_parent(), center, Color(1, 0.8, 0.4))
			Fx.explosion(get_parent(), center, 150.0)
			_aoe_hit(center, 170.0, _skill_dmg(1.6), 360.0, -180.0)
			Game.shake(13.0)
			_play_sfx("atk_hammer", -1.0)
		_:          # 铁剑 旋风斩: 环身多段斩
			velocity.y = -160.0
			for i in range(5):
				var a := TAU * i / 5.0
				Fx.play_slash(get_parent(), center + Vector2(cos(a), sin(a)) * 70.0, facing, slash_frames, 1.0, col)
			Fx.shockwave(get_parent(), center, col)
			_aoe_hit(center, 135.0, _skill_dmg(1.4), 240.0, -120.0)
			Game.shake(9.0)
			_play_sfx("attack", -1.0)
	Fx.screen_flash(get_tree(), Color(col.r, col.g, col.b, 0.16))
	Game.hitstop(0.07, 0.05)
	_squash(Vector2(1.2, 0.85))

# ============================================================ 大招(V, 满怒气) · 各武器终结技
func _cast_ult() -> void:
	if rage < MAX_RAGE:
		Fx.popup(get_parent(), global_position + Vector2(0, -92), "怒气不足", Color(1.0, 0.6, 0.3))
		return
	rage = 0.0
	_aim_facing()
	var col: Color = weapon["color"]
	Game.hitstop(0.16, 0.05)
	Game.shake(18.0)
	Fx.screen_flash(get_tree(), Color(col.r, col.g, col.b, 0.32))
	Fx.cast_ring(get_parent(), global_position + Vector2(0, -30), col)
	Fx.cast_ring(get_parent(), global_position + Vector2(0, -48), Color(1, 1, 1))
	match weapon["id"]:
		"hammer":   # 陨星重击: 巨型砸地, 超大范围
			velocity.y = -120.0
			var gp := global_position + Vector2(0, 4)
			Fx.explosion(get_parent(), gp, 260.0)
			Fx.shockwave(get_parent(), gp, col)
			Fx.shockwave(get_parent(), gp + Vector2(0, -30), Color(1, 0.85, 0.4))
			_aoe_hit(global_position, 300.0, _skill_dmg(3.0), 360.0, -360.0)
		"cannon":   # 过载炮击: 蓄力贯穿巨炮(双发)
			for yo in [-26.0, -48.0]:
				_spawn_projectile(fx_frames["bolt2"], 3.0, col, _skill_dmg(2.0), 1200.0, 2.0, 99, yo)
			Fx.shockwave(get_parent(), global_position + Vector2(facing * 60, -34), col)
			Fx.explosion(get_parent(), global_position + Vector2(facing * 90, -34), 150.0)
			_aoe_hit(global_position + Vector2(facing * 160, -34), 200.0, _skill_dmg(2.0), 300.0, -120.0)
		_:          # 铁剑 千刃斩: 三道剑气 + 范围爆发
			for i in range(3):
				_spawn_projectile(slash_frames, 1.8 + i * 0.3, col, _skill_dmg(1.2), 720.0, 1.4, 99, -34.0 - i * 14.0)
				Fx.play_slash(get_parent(), global_position + Vector2(facing * 44, -34 - i * 12), facing, slash_frames, 1.4, col)
			_aoe_hit(global_position, 240.0, _skill_dmg(2.5), 420.0, -300.0)
	Fx.popup(get_parent(), global_position + Vector2(0, -96), "▶ " + weapon["name"] + " 终结技!", col)
	_play_sfx("slam", -1.0)
	resource_changed.emit(mp, max_mp(), rage, MAX_RAGE)

func _spawn_projectile(frames: SpriteFrames, scale: float, tint: Color, dmg: int,
		spd: float, life: float, pierce: int, yoff: float = -34.0) -> void:
	var proj := Area2D.new()
	proj.set_script(PROJECTILE_SCRIPT)
	proj.position = global_position + Vector2(facing * 48, yoff)
	get_parent().add_child(proj)
	if proj.has_method("setup"):
		proj.setup(frames, float(facing), dmg, scale, tint)
		proj.speed = spd
		proj.life = life
		proj.pierce = pierce

# 铁剑重攻击: 青色剑气波
func _oc(n: int) -> int:   # 机械超频:过载输出, 统一作用于地面波(与其它主动技一致)
	return int(round(float(n) * (1.0 + 0.15 * Game.skill_lv("skill_dmg"))))

func _heavy_sword() -> void:
	_spawn_projectile(slash_frames, 1.5, Color(0.7, 0.97, 1.0),
		_oc(3 + Game.skill_lv("power")), 660.0, 1.5, 2 + Game.skill_lv("wave"))
	Fx.play_slash(get_parent(), global_position + Vector2(facing * 42, -34), facing, slash_frames, 1.1, Color(0.7, 0.97, 1.0))
	Fx.screen_flash(get_tree(), Color(0.5, 0.85, 1.0, 0.14))
	Game.shake(4.0)
	_play_sfx("attack", -2.0)
	_squash(Vector2(1.2, 0.85))
	if is_on_floor():
		velocity.x = -facing * 60.0

# 蒸汽炮重攻击: 蓄力远程重炮(飞很远)
func _heavy_cannon() -> void:
	_spawn_projectile(fx_frames["bolt2"], 1.6, Color(0.9, 0.97, 1.0),
		_oc(5 + Game.skill_lv("power")), 1000.0, 2.8, 3 + Game.skill_lv("wave"))
	Fx.shockwave(get_parent(), global_position + Vector2(facing * 56, -34), Color(0.8, 0.9, 1.0))
	Fx.hit_spark(get_parent(), global_position + Vector2(facing * 60, -34))
	Fx.screen_flash(get_tree(), Color(0.8, 0.9, 1.0, 0.2))
	Game.shake(8.0)
	_play_sfx("atk_cannon", -1.0)
	_squash(Vector2(1.3, 0.8))
	if is_on_floor():
		velocity.x = -facing * 150.0

# 重锤重攻击: 沿地面推进的震地冲击波
func _heavy_hammer() -> void:
	_spawn_projectile(fx_frames["bolt"], 1.7, Color(1.0, 0.6, 0.25),
		_oc(5 + Game.skill_lv("power")), 460.0, 1.3, 99, -16.0)
	Fx.shockwave(get_parent(), global_position + Vector2(0, 8), Color(1.0, 0.55, 0.2))
	Fx.shockwave(get_parent(), global_position + Vector2(facing * 90, 8), Color(1.0, 0.55, 0.2))
	Fx.screen_flash(get_tree(), Color(1.0, 0.6, 0.2, 0.18))
	Game.shake(9.0)
	_play_sfx("atk_hammer", -1.0)
	_squash(Vector2(1.4, 0.7))   # 后坐力

# ------------------------------------------------------------- 空中下砸
func _start_dive() -> void:
	state = S.DIVE
	velocity = Vector2(0, DIVE_SPEED)
	iframes = maxf(iframes, 0.12)
	_squash(Vector2(0.65, 1.45))
	_play_sfx("dash", -4.0)

func _do_dive(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 1200.0 * delta)
	velocity.y = DIVE_SPEED
	_spawn_ghost()
	if is_on_floor():
		_dive_land()

func _dive_land() -> void:
	state = S.NORMAL
	_squash(Vector2(1.8, 0.5))
	var col: Color = weapon["color"]
	Fx.dust(get_parent(), global_position + Vector2(-30, 0), -1)
	Fx.dust(get_parent(), global_position + Vector2(30, 0), 1)
	Fx.hit_spark(get_parent(), global_position)
	_play_sfx("slam", -3.0)
	# 各武器下砸变形
	var radius := 160.0
	var dmg := _skill_dmg(1.5)
	match weapon["id"]:
		"hammer":   # 天崩: 大范围砸地震荡
			radius = 220.0
			dmg = _skill_dmg(2.2)
			Fx.explosion(get_parent(), global_position, 200.0)
			Fx.shockwave(get_parent(), global_position, col)
			Game.shake(17.0)
			Game.hitstop(0.11, 0.04)
		"cannon":   # 俯冲轰炸: 落点爆炸 + 左右扫射弹
			Fx.explosion(get_parent(), global_position, 150.0)
			for sx in [-1.0, 1.0]:
				_spawn_proj_vel(1.2, col, _skill_dmg(1.0), Vector2(sx, -0.2) * 700.0, 0.9, 2)
			Game.shake(13.0)
			Game.hitstop(0.09, 0.04)
		_:          # 铁剑 流星斩: 橙红双层冲击波
			Fx.shockwave(get_parent(), global_position, Color(1.0, 0.6, 0.2))
			Fx.shockwave(get_parent(), global_position, Color(1.0, 0.85, 0.4))
			Game.shake(13.0)
			Game.hitstop(0.09, 0.04)
	Fx.screen_flash(get_tree(), Color(col.r, col.g, col.b, 0.2))
	_aoe_hit(global_position, radius, dmg, 320.0, -280.0)

# ------------------------------------------------------------- 武器 / 攻击
func _switch_weapon() -> void:
	weapon_index = (weapon_index + 1) % Weapons.LIST.size()
	weapon = Weapons.get_weapon(weapon_index)
	Game.weapon_index = weapon_index
	_apply_weapon()
	weapon_changed.emit(weapon["name"], weapon["color"])
	Fx.popup(get_parent(), global_position + Vector2(0, -86), "▶ " + weapon["name"], weapon["color"])
	_play_sfx("ui", -4.0)

func _apply_weapon() -> void:
	if weapon_sprite:
		weapon_sprite.texture = load(weapon["sprite"])
	if weapon_pivot:
		weapon_pivot.position = weapon["hand"]

func _update_weapon(_delta: float) -> void:
	if weapon_pivot == null:
		return
	weapon_pivot.scale.x = float(facing)
	# 非攻击状态: 武器回到休息姿态
	if state != S.ATTACK:
		weapon_pivot.rotation = lerp_angle(weapon_pivot.rotation, weapon["rest_rot"], 0.4)
		weapon_sprite.visible = weapon["type"] == "melee" or state == S.NORMAL

func _aim_facing() -> void:
	# 出招瞬间按当前方向键修正朝向, 保证攻击/技能方向跟手
	var ia := Input.get_axis("move_left", "move_right")
	if ia != 0.0:
		facing = signi(int(sign(ia)))

func _start_attack() -> void:
	_aim_facing()
	attacked.emit()
	state = S.ATTACK
	var combo_max: int = weapon["combo"]
	attack_index = (attack_index % combo_max) + 1
	attack_timer = weapon["atk_time"]
	combo_window = 0.0
	hit_targets.clear()

	if weapon["type"] == "ranged":
		_aim_facing()
		_fire_weapon()
		return

	# 近战: 判定框 + 可见挥砍
	var reach: float = weapon["reach"]
	var spin_finisher: bool = attack_index >= combo_max and Game.skill_lv("spin") > 0
	if spin_finisher:
		# 旋风斩: 围绕自身的范围判定 + 旋涡特效
		hitbox_rect.size = Vector2(210, 150)
		hitbox_shape.position = Vector2(0, -40)
		Fx.play_slash(get_parent(), global_position + Vector2(0, -40), facing, fx_frames["spin"], 1.5, Color(0.8, 0.95, 1.0))
		Fx.screen_flash(get_tree(), Color(0.7, 0.9, 1.0, 0.14))
		Game.shake(8.0)
	elif attack_up:
		hitbox_rect.size = weapon["hit_size"]
		hitbox_shape.position = Vector2(facing * reach * 0.4, -86)   # 上方判定(打飞行敌)
	else:
		hitbox_rect.size = weapon["hit_size"]
		hitbox_shape.position = Vector2(facing * reach, -34)
	hitbox.monitoring = true
	_swing_weapon()

	# 武器专属特效 (颜色/形态/大小各不同)
	var fxf: SpriteFrames = fx_frames.get(weapon["fx"], slash_frames)
	var sc: float = (0.85 + 0.28 * attack_index) * float(weapon["fx_scale"])
	var fpos: Vector2 = global_position + (Vector2(facing * 52, -34) if not attack_up else Vector2(facing * 16, -92))
	Fx.play_slash(get_parent(), fpos, facing, fxf, sc, weapon["fx_tint"])
	if weapon["id"] == "hammer":   # 重锤: 额外冲击波 + 闪光
		Fx.shockwave(get_parent(), fpos + Vector2(0, 28), weapon["color"])
		Fx.screen_flash(get_tree(), Color(1.0, 0.55, 0.2, 0.12))
	_play_sfx(weapon["sfx"], -3.0)
	if is_on_floor() and not attack_up:
		velocity.x = facing * (110.0 if attack_index < combo_max else 230.0)

func _swing_weapon() -> void:
	if weapon_pivot == null:
		return
	weapon_sprite.visible = true
	var from_a: float
	var to_a: float
	if attack_up:
		from_a = -2.7; to_a = -0.3
	elif attack_index % 2 == 1:
		from_a = -2.0; to_a = 0.7       # 上劈下砍
	else:
		from_a = 0.7; to_a = -2.0       # 反向回砍
	weapon_pivot.rotation = from_a
	var tw := weapon_pivot.create_tween()
	tw.tween_property(weapon_pivot, "rotation", to_a, weapon["atk_time"] * 0.8) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _fire_weapon() -> void:
	# 蒸汽炮: 发射弹丸 + 炮口火花 + 后坐力
	var proj := Area2D.new()
	proj.set_script(PROJECTILE_SCRIPT)
	proj.position = global_position + Vector2(facing * 46, -34)
	get_parent().add_child(proj)
	var dmg: int = weapon["damage"] + Game.skill_lv("power")
	if proj.has_method("setup"):
		# 普通射击: 清晰的能量弹, 飞得远
		proj.setup(fx_frames["bolt2"], float(facing), dmg, 0.9, Color(0.85, 0.95, 1.0))
		proj.speed = 780.0
		proj.life = 2.2
		proj.pierce = 1 + Game.skill_lv("wave")
	# 炮口小火花(不再盖住弹丸)
	Fx.hit_spark(get_parent(), global_position + Vector2(facing * 58, -34))
	Game.shake(weapon["shake"])
	_play_sfx(weapon["sfx"], -2.0)
	weapon_pivot.rotation = 0.0
	if is_on_floor():
		velocity.x = -facing * 100.0

func _do_attack_state(delta: float) -> void:
	if not is_on_floor():
		velocity.y = min(velocity.y + GRAVITY * delta, MAX_FALL)
	velocity.x = move_toward(velocity.x, 0.0, 1600.0 * delta)

	# 命中检测 (active window 几乎整个挥砍, 刀光碰到即伤害)
	var t: float = weapon["atk_time"]
	if hitbox.monitoring and attack_timer < t * 0.92 and attack_timer > t * 0.12:
		for body in hitbox.get_overlapping_bodies():
			if body.is_in_group("enemy") and not hit_targets.has(body):
				hit_targets.append(body)
				_land_hit(body)

	# 连段输入
	var combo_max: int = weapon["combo"]
	if attack_timer < t * 0.55 and Input.is_action_just_pressed("attack") and attack_index < combo_max and weapon["type"] == "melee":
		hitbox.monitoring = false
		attack_up = Input.is_action_pressed("move_up")
		_start_attack()
		return

	attack_timer -= delta
	if attack_timer <= 0.0:
		hitbox.monitoring = false
		combo_window = 0.4
		attack_up = false
		state = S.NORMAL

func _land_hit(enemy: Node2D) -> void:
	var combo_max: int = weapon["combo"]
	var is_finisher: bool = attack_index >= combo_max
	# 基础伤害 + 近战强化 + 终结技加成
	var dmg: int = weapon["damage"] + Game.skill_lv("atk") + int(round(Game.equip_bonus("atk"))) + (1 if is_finisher else 0)
	if Game.skill_lv("ultimate") > 0:
		dmg += 1
	# 暴击 (技能 + 装备)
	var is_crit := randf() < (0.12 * Game.skill_lv("crit") + Game.equip_bonus("crit"))
	if is_crit:
		dmg *= 2
	var kb := Vector2(facing * (240.0 if not is_finisher else 440.0), -120.0)
	if enemy.has_method("take_damage"):
		enemy.take_damage(dmg, kb)
	var hit_pos: Vector2 = (global_position + enemy.global_position) * 0.5
	Fx.hit_spark(get_parent(), hit_pos)
	if is_crit:
		Fx.popup(get_parent(), hit_pos + Vector2(0, -20), "暴击!", Color(1.0, 0.85, 0.3))
		Fx.hit_spark(get_parent(), hit_pos)
	# 吸血
	var ls := Game.skill_lv("lifesteal") + int(round(Game.equip_bonus("ls")))
	if ls > 0 and health < max_hp() and randf() < 0.15 * ls:
		health = mini(health + 1, max_hp())
		health_changed.emit(health, max_hp())
		Fx.popup(get_parent(), global_position + Vector2(0, -80), "+1", Color(0.5, 1.0, 0.6))
	var shake: float = weapon["shake"]
	if is_finisher or is_crit:
		Game.hitstop(0.10, 0.03)
		Game.shake(shake * 1.6)
		Fx.screen_flash(get_tree(), Color(1.0, 0.9, 0.6, 0.16))
	else:
		Game.hitstop(0.05, 0.05)
		Game.shake(shake)
	_play_sfx("hit", -8.0)
	# 命中回技力 + 攒怒气
	gain_mp(MP_ON_HIT)
	gain_rage(RAGE_ON_HIT)

# ------------------------------------------------------------- 受伤/死亡
func take_damage(amount: int, from_pos: Vector2) -> void:
	if iframes > 0.0 or state == S.DEAD:
		return
	# 装备防御减伤(每3点防御减1伤, 至少受1)
	var defense := Game.equip_bonus("def")
	amount = maxi(1, amount - int(floor(defense / 3.0)))
	health -= amount
	health_changed.emit(health, max_hp())
	gain_rage(RAGE_ON_HURT)
	Fx.popup(get_parent(), global_position + Vector2(0, -70), "-%d" % amount, Color(1, 0.4, 0.4))
	Game.shake(7.0)
	Game.hitstop(0.08, 0.05)
	if health <= 0:
		_die()
		return
	state = S.HURT
	iframes = IFRAME_TIME
	var dir := signf(global_position.x - from_pos.x)
	if dir == 0.0:
		dir = -facing
	velocity = Vector2(dir * HURT_KNOCKBACK.x, HURT_KNOCKBACK.y)

func _do_hurt(delta: float) -> void:
	velocity.y = min(velocity.y + GRAVITY * delta, MAX_FALL)
	velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	if is_on_floor() or velocity.y > 0.0:
		state = S.NORMAL

func _die() -> void:
	state = S.DEAD
	died.emit()
	Fx.death_burst(get_parent(), global_position, Color(0.5, 0.8, 1.0))
	anim.visible = false
	Game.shake(12.0)
	await get_tree().create_timer(0.8).timeout
	_respawn()

func _respawn() -> void:
	global_position = spawn_point
	velocity = Vector2.ZERO
	health = max_hp()
	iframes = 0.5
	state = S.NORMAL
	anim.visible = true
	health_changed.emit(health, max_hp())

# ------------------------------------------------------------- 表现
func _update_anim() -> void:
	anim.flip_h = facing < 0
	match state:
		S.DASH:
			_set_anim("dash")
		S.DIVE:
			_set_anim("fall")
		S.HURT:
			_set_anim("hurt")
		S.ATTACK:
			_set_anim("attack%d" % attack_index)
		S.DEAD:
			pass
		_:
			if is_on_floor():
				if abs(velocity.x) > 12.0:
					_set_anim("run")
				else:
					_set_anim("idle")
			else:
				if is_on_wall_only() and velocity.y > 0.0:
					_set_anim("wall_slide")
				elif velocity.y < 0.0:
					_set_anim("jump")
				else:
					_set_anim("fall")

func _set_anim(name: String) -> void:
	if anim.animation != name:
		anim.play(name)

# 挤压拉伸
func _squash(mult: Vector2) -> void:
	anim.scale = sprite_scale_base * mult
func _update_squash(delta: float) -> void:
	anim.scale = anim.scale.lerp(sprite_scale_base, 1.0 - exp(-18.0 * delta))

func _play_sfx(key: String, db: float = 0.0) -> void:
	if has_node("/root/Main"):
		var m := get_node("/root/Main")
		if m.has_method("play_sfx"):
			m.play_sfx(key, db)
