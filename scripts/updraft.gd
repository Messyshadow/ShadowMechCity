extends Area2D
## 热气流: 玩家进入时被向上托举(熔炉大厅招牌, 做垂直动线)。
## _physics_process 轮询, 在区域内把玩家上行速度设为 -force(不改物理状态)。

var dw := 160.0
var dh := 300.0
var force := 280.0
var flow := Vector2(0, -280.0)
var kind := "updraft"
var _t := 0.0

func setup(w: float, h: float, f: float) -> void:
	dw = w; dh = h; force = f
	flow = Vector2(0, -f)

func setup_flow(w: float, h: float, velocity: Vector2, flow_kind: String = "wind") -> void:
	dw = w; dh = h; flow = velocity; force = velocity.length(); kind = flow_kind

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0b00010   # player
	z_index = 3
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(dw, dh)
	cs.shape = sh
	add_child(cs)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var col := Polygon2D.new()
	col.polygon = PackedVector2Array([Vector2(-dw * 0.5, -dh * 0.5), Vector2(dw * 0.5, -dh * 0.5), Vector2(dw * 0.5, dh * 0.5), Vector2(-dw * 0.5, dh * 0.5)])
	col.color = Color(0.55, 0.35, 1.0, 0.2) if kind == "wind" else Color(0.4, 0.8, 1.0, 0.18)
	col.material = add
	add_child(col)

func _physics_process(delta: float) -> void:
	_t += delta
	# 上升气浪粒子
	if randf() < 0.3:
		Fx.dust(get_parent(), global_position + Vector2(randf_range(-dw, dw) * 0.45, randf_range(-dh, dh) * 0.45), 0.0)
	for b in get_overlapping_bodies():
		if b.is_in_group("player"):
			# 托举: 设为上行速度(玩家自身重力下一帧会拉, 持续在气流内则上升/悬浮)
			if "velocity" in b:
				var applied := flow
				var enhanced := Game.has_ability("shadow_glider") and Input.is_action_pressed("jump")
				if enhanced:
					applied.x *= 0.35
					if applied.y < 0.0:
						applied.y *= 1.25
				b.velocity = b.velocity.move_toward(applied, 900.0 * delta)
