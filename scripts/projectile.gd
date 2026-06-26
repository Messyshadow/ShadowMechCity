extends Area2D
## 斩击波: 向前飞行, 命中敌人造成伤害 (穿透有限次)

var dir := 1.0
var speed := 620.0
var damage := 2
var pierce := 2
var life := 1.4
var _hit: Array = []

func setup(frames: SpriteFrames, facing: float, p_damage: int, scale: float = 1.2, tint: Color = Color.WHITE) -> void:
	dir = facing
	damage = p_damage
	var a := AnimatedSprite2D.new()
	a.sprite_frames = frames
	a.flip_h = facing < 0
	a.scale = Vector2(scale, scale)
	a.modulate = tint
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	a.material = mat
	add_child(a)
	var names := frames.get_animation_names()
	a.play(names[0] if names.size() > 0 else "default")

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0b00100   # enemy
	z_index = 20
	var cs := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 22.0
	shape.height = 70.0
	cs.shape = shape
	cs.rotation = PI / 2.0
	add_child(cs)
	body_entered.connect(_on_body)
	# 拖尾粒子
	Fx.dash_dust(get_parent(), global_position, dir)

func _physics_process(delta: float) -> void:
	position.x += dir * speed * delta
	life -= delta
	if life <= 0.0:
		_fade()

func _on_body(body: Node) -> void:
	if body.is_in_group("enemy") and not _hit.has(body) and body.has_method("take_damage"):
		_hit.append(body)
		body.take_damage(damage, Vector2(dir * 280.0, -90.0))
		Fx.hit_spark(get_parent(), global_position)
		Game.shake(3.0)
		pierce -= 1
		if pierce <= 0:
			_fade()

func _fade() -> void:
	set_physics_process(false)
	monitoring = false
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.12)
	tw.tween_callback(queue_free)
