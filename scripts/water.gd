extends Area2D
## 水域: 玩家进入即可游泳(浮力/划水); 可带水流(flow)做"水流闸门"(基础划水顶不住, 水下推进器能过)。
## _physics_process 轮询通知玩家 enter_water(不改物理状态, 无 flush 风险)。

var ww := 400.0
var wh := 300.0
var flow := Vector2.ZERO
var _t := 0.0
var _surface: Line2D

func setup(w: float, h: float, fx: float, fy: float) -> void:
	ww = w; wh = h; flow = Vector2(fx, fy)

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0b00010   # player
	z_index = 7
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(ww, wh)
	cs.shape = sh
	add_child(cs)
	# 水体(半透明蓝)
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([Vector2(-ww * 0.5, -wh * 0.5), Vector2(ww * 0.5, -wh * 0.5), Vector2(ww * 0.5, wh * 0.5), Vector2(-ww * 0.5, wh * 0.5)])
	body.color = Color(0.25, 0.55, 0.85, 0.32) if flow == Vector2.ZERO else Color(0.3, 0.7, 0.7, 0.34)
	add_child(body)
	# 水面高光
	_surface = Line2D.new()
	_surface.width = 3.0
	_surface.default_color = Color(0.6, 0.9, 1.0, 0.7)
	_surface.points = PackedVector2Array([Vector2(-ww * 0.5, -wh * 0.5), Vector2(ww * 0.5, -wh * 0.5)])
	add_child(_surface)
	# 水流方向箭头(若有 flow)
	if flow != Vector2.ZERO:
		var add := CanvasItemMaterial.new()
		add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		var fdir := flow.normalized()
		for i in range(6):
			var ar := Polygon2D.new()
			ar.polygon = PackedVector2Array([Vector2(-10, -7), Vector2(10, 0), Vector2(-10, 7)])
			ar.color = Color(0.7, 1.0, 1.0, 0.5)
			ar.position = Vector2(randf_range(-ww, ww) * 0.4, randf_range(-wh, wh) * 0.4)
			ar.rotation = fdir.angle()
			ar.material = add
			add_child(ar)

func _physics_process(delta: float) -> void:
	_t += delta
	for b in get_overlapping_bodies():
		if b.is_in_group("player") and b.has_method("enter_water"):
			b.enter_water(flow)
			if randf() < 0.25:
				Fx.dust(get_parent(), (b as Node2D).global_position + Vector2(randf_range(-12, 12), -20), 0.0)
