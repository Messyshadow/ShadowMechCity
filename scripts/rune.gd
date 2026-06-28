extends Area2D
## 符文板: 玩家踩上去点亮; 同房间所有符文板点亮 → 符文封门解除(招牌机关)。
## body_entered 信号里只改自身视觉 + 通知 main(main 用 queue_free 移除封门, deferred 安全)。

var rw := 90.0
var lit := false
var _core: Polygon2D
var _ring: Line2D
var _t := 0.0

func setup(w: float) -> void:
	rw = w

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0b00010   # player
	z_index = 5
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(rw, 30)
	cs.shape = sh
	cs.position = Vector2(0, -8)
	add_child(cs)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	# 符文板底座
	var base := Polygon2D.new()
	base.polygon = PackedVector2Array([Vector2(-rw * 0.5, -6), Vector2(rw * 0.5, -6), Vector2(rw * 0.5, 8), Vector2(-rw * 0.5, 8)])
	base.color = Color(0.35, 0.3, 0.5)
	add_child(base)
	# 符文环(暗 → 亮)
	_ring = Line2D.new()
	_ring.width = 3.0
	_ring.closed = true
	_ring.default_color = Color(0.7, 0.6, 1.0, 0.5)
	var pts := PackedVector2Array()
	for i in range(12):
		var a := TAU * i / 12.0
		pts.append(Vector2(cos(a) * rw * 0.34, sin(a) * rw * 0.18 - 2))
	_ring.points = pts
	_ring.material = add
	add_child(_ring)
	_core = Polygon2D.new()
	_core.polygon = pts
	_core.color = Color(0.6, 0.5, 1.0, 0.0)
	_core.material = add
	add_child(_core)
	body_entered.connect(_on_body)

func _physics_process(delta: float) -> void:
	_t += delta
	if lit:
		_core.modulate.a = 0.7 + 0.3 * sin(_t * 4.0)

func _on_body(body: Node) -> void:
	if lit or not body.is_in_group("player"):
		return
	lit = true
	_ring.default_color = Color(1.0, 0.9, 0.5)
	_core.color = Color(1.0, 0.85, 0.4, 0.9)
	Fx.hit_ring(get_parent(), global_position + Vector2(0, -4), Color(1.0, 0.9, 0.5))
	Fx.popup(get_parent(), global_position + Vector2(0, -40), "符文亮起", Color(1.0, 0.9, 0.5))
	var m := get_node_or_null("/root/Main")
	if m and m.has_method("rune_lit_inc"):
		m.rune_lit_inc()
