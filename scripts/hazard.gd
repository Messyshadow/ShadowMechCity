extends Area2D
## 环境陷阱(蒸汽/熔铁/齿轮): 接触造成伤害。
## 自包含: 在 _physics_process 轮询重叠玩家并扣血(带冷却), 不在信号期改物理状态。

var dmg := 1
var hz_w := 100.0
var hz_h := 40.0
var kind := "steam"   # steam / lava / gear
var _cd := 0.0
var _t := 0.0
var _vis: Node2D
var _gear: Node2D
# 蒸汽阀周期喷发(P4): 预警→喷发→收
const STEAM_PERIOD := 2.6
const STEAM_ERUPT := 1.0       # 喷发(有伤害)持续
const STEAM_WARN := 0.5        # 喷发前预警时长
var _erupting := false

func setup(w: float, h: float, d: int, k: String) -> void:
	hz_w = w; hz_h = h; dmg = d; kind = k

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0b00010   # player
	z_index = 6
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	if kind == "steam":
		# 蒸汽=向上的气柱, 危害区在喷口上方
		sh.size = Vector2(hz_w, hz_h * 5.0)
		cs.position = Vector2(0, -hz_h * 2.5)
	else:
		sh.size = Vector2(hz_w, hz_h)
	cs.shape = sh
	add_child(cs)
	_build_visual()

func _rect_poly(w: float, h: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(-w * 0.5, -h * 0.5), Vector2(w * 0.5, -h * 0.5), Vector2(w * 0.5, h * 0.5), Vector2(-w * 0.5, h * 0.5)])

func _build_visual() -> void:
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	match kind:
		"lava", "poison":
			var main_col := Color(1.0, 0.45, 0.12) if kind == "lava" else Color(0.45, 0.85, 0.25)
			var core_col := Color(1.0, 0.85, 0.4) if kind == "lava" else Color(0.7, 1.0, 0.5)
			_vis = Polygon2D.new()
			(_vis as Polygon2D).polygon = _rect_poly(hz_w, hz_h)
			(_vis as Polygon2D).color = main_col
			_vis.material = add
			add_child(_vis)
			var core := Polygon2D.new()
			core.polygon = _rect_poly(hz_w, hz_h * 0.5)
			core.color = core_col
			core.position = Vector2(0, hz_h * 0.2)
			core.material = add
			add_child(core)
		"gear":
			_gear = Node2D.new()
			add_child(_gear)
			var g := Polygon2D.new()
			var pts := PackedVector2Array()
			var r := minf(hz_w, hz_h) * 0.5
			for i in range(16):
				var a := TAU * i / 16.0
				var rr := r if i % 2 == 0 else r * 0.7
				pts.append(Vector2(cos(a), sin(a)) * rr)
			g.polygon = pts
			g.color = Color(0.7, 0.72, 0.78)
			_gear.add_child(g)
			var hub := Polygon2D.new()
			hub.polygon = _rect_poly(r * 0.5, r * 0.5)
			hub.color = Color(0.35, 0.37, 0.42)
			_gear.add_child(hub)
		_:   # steam: 锚定喷口、向上的气柱(scale.y 增长即喷起)
			_vis = Polygon2D.new()
			(_vis as Polygon2D).polygon = PackedVector2Array([
				Vector2(-hz_w * 0.5, -hz_h), Vector2(hz_w * 0.5, -hz_h),
				Vector2(hz_w * 0.5, 0), Vector2(-hz_w * 0.5, 0)])
			(_vis as Polygon2D).color = Color(0.85, 0.95, 1.0, 0.5)
			_vis.material = add
			_vis.scale.y = 0.25
			add_child(_vis)

func _physics_process(delta: float) -> void:
	_t += delta
	_cd = maxf(0.0, _cd - delta)
	if _gear:
		_gear.rotation += delta * 3.0
	# 蒸汽阀: 周期喷发(预警→喷发), 只有喷发期才有伤害+高柱; 其余时间安全可踩
	var active := true
	if kind == "steam":
		var ph := fmod(_t, STEAM_PERIOD)
		_erupting = ph < STEAM_ERUPT
		active = _erupting
		var warn := ph >= (STEAM_PERIOD - STEAM_WARN)
		if _vis:
			if _erupting:
				_vis.scale.y = 1.0 + 5.0 * (1.0 - ph / STEAM_ERUPT)   # 喷起的高柱, 渐收
				_vis.modulate.a = 0.85
			elif warn:
				_vis.scale.y = 0.4
				_vis.modulate.a = 0.3 + 0.4 * sin(_t * 22.0)          # 预警闪烁
			else:
				_vis.scale.y = 0.25
				_vis.modulate.a = 0.18
		if _erupting and randf() < 0.5:
			Fx.dust(get_parent(), global_position + Vector2(randf_range(-hz_w, hz_w) * 0.4, -hz_h * 0.5), 0.0)
	elif _vis:
		_vis.modulate.a = 0.55 + 0.45 * sin(_t * 5.0)
	# 接触伤害(轮询; 玩家 iframes + 本地冷却双重节流; 蒸汽仅喷发期)
	if active and _cd <= 0.0:
		for b in get_overlapping_bodies():
			if b.is_in_group("player") and b.has_method("take_damage"):
				b.take_damage(dmg, global_position)
				_cd = 0.7
				break
