extends Area2D
## 传送带: 把站在其上的玩家沿 push 方向横向推送(装配车间招牌)。
## _physics_process 轮询 + 直接位移微推(不改物理状态)。

var belt_w := 240.0
var belt_h := 24.0
var push := 90.0       # 正=向右, 负=向左 (px/s)
var tint := Color(1, 1, 1)
var _t := 0.0
var _arrows: Node2D

func setup(w: float, h: float, p: float, tn: Color) -> void:
	belt_w = w; belt_h = h; push = p; tint = tn

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0b00010   # player
	z_index = 5
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(belt_w, belt_h + 24.0)   # 略高, 站在带面上即判定
	cs.shape = sh
	cs.position = Vector2(0, -12)
	add_child(cs)
	# 带面
	var base := Polygon2D.new()
	base.polygon = PackedVector2Array([Vector2(-belt_w * 0.5, -belt_h * 0.5), Vector2(belt_w * 0.5, -belt_h * 0.5), Vector2(belt_w * 0.5, belt_h * 0.5), Vector2(-belt_w * 0.5, belt_h * 0.5)])
	base.color = Color(0.32, 0.34, 0.4)
	add_child(base)
	_arrows = Node2D.new()
	add_child(_arrows)
	var dir := signf(push)
	var n := int(belt_w / 50.0)
	for i in range(n):
		var a := Polygon2D.new()
		a.polygon = PackedVector2Array([Vector2(-8, -6), Vector2(8, 0), Vector2(-8, 6)])
		a.color = Color(1.0, 0.7, 0.3)
		a.position = Vector2(-belt_w * 0.5 + 25 + i * 50, 0)
		a.scale.x = dir
		_arrows.add_child(a)

func _physics_process(delta: float) -> void:
	_t += delta
	# 箭头流动
	for a in _arrows.get_children():
		a.position.x += push * 0.4 * delta
		if push > 0 and a.position.x > belt_w * 0.5:
			a.position.x -= belt_w
		elif push < 0 and a.position.x < -belt_w * 0.5:
			a.position.x += belt_w
	for b in get_overlapping_bodies():
		if b.is_in_group("player"):
			b.global_position.x += push * delta
