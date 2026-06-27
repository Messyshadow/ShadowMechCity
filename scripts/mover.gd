extends AnimatableBody2D
## 移动平台 / 链条升降机: 往返移动并载着站立其上的玩家(AnimatableBody2D + sync_to_physics)。
## 用 _physics_process 按时间设位置(不改 monitoring/shape, 无 flush 风险)。

var plat_w := 160.0
var axis := "h"        # h=水平 v=垂直
var dist := 200.0      # 单向行程(从中点 ±dist 摆动)
var period := 3.0      # 往返周期(s)
var phase := 0.0       # 相位偏移(让多台错开)
var tint := Color(1, 1, 1)
var _origin: Vector2
var _t := 0.0

func setup(w: float, ax: String, d: float, per: float, ph: float, tn: Color) -> void:
	plat_w = w; axis = ax; dist = d; period = maxf(0.5, per); phase = ph; tint = tn

func _ready() -> void:
	sync_to_physics = true
	collision_layer = 0b00001   # world: 玩家可站立
	collision_mask = 0
	z_index = 4
	_origin = position
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(plat_w, 22)
	cs.shape = sh
	add_child(cs)
	var spr := Sprite2D.new()
	spr.texture = load("res://assets/tiles/platform.png")
	spr.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	spr.region_enabled = true
	spr.region_rect = Rect2(0, 0, plat_w, 22)
	spr.modulate = tint
	add_child(spr)
	# 链条/轨道指示(发光端点)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var glow := Line2D.new()
	glow.width = 3.0
	glow.default_color = Color(1.0, 0.7, 0.35, 0.7)
	if axis == "v":
		glow.points = PackedVector2Array([Vector2(0, -dist), Vector2(0, dist)])
	else:
		glow.points = PackedVector2Array([Vector2(-dist, 0), Vector2(dist, 0)])
	glow.z_index = -1
	glow.material = add
	add_child(glow)

func _physics_process(delta: float) -> void:
	_t += delta
	var off := sin((_t / period) * TAU + phase) * dist
	if axis == "v":
		position = _origin + Vector2(0, off)
	else:
		position = _origin + Vector2(off, 0)
