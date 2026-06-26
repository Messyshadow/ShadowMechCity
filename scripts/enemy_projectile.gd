extends Area2D
## 敌方弹幕: 直线飞行, 命中玩家造成伤害. 由 Boss 等发射.

var vel := Vector2.ZERO
var damage := 1
var life := 3.0
var color := Color(1.0, 0.6, 0.3)

func setup(velocity: Vector2, dmg: int, tint: Color = Color(1.0, 0.6, 0.3)) -> void:
	vel = velocity
	damage = dmg
	color = tint

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0b00010   # player
	z_index = 16
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 15.0
	cs.shape = sh
	add_child(cs)
	# 发光弹丸
	var orb := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in range(14):
		var a := TAU * i / 14.0
		pts.append(Vector2(cos(a), sin(a)) * 15.0)
	orb.polygon = pts
	orb.color = color
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	orb.material = mat
	add_child(orb)
	var glow := Polygon2D.new()
	glow.polygon = pts
	glow.scale = Vector2(1.8, 1.8)
	glow.color = Color(color.r, color.g, color.b, 0.35)
	glow.material = mat
	add_child(glow)
	var tw := create_tween().set_loops()
	tw.tween_property(orb, "scale", Vector2(1.2, 1.2), 0.2)
	tw.tween_property(orb, "scale", Vector2(0.9, 0.9), 0.2)
	body_entered.connect(_on_hit)

func _physics_process(delta: float) -> void:
	position += vel * delta
	life -= delta
	if life <= 0.0:
		queue_free()

func _on_hit(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage, global_position)
		Fx.hit_spark(get_parent(), global_position)
		queue_free()
