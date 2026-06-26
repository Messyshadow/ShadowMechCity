class_name Pickup
extends Area2D
## 掉落物/道具: 金币 / 经验珠 / 生命碎片 / 宝箱
## 由 Pickup.spawn(...) 创建. 支持"拾取吸附"技能.

var kind := "coin"      # coin / orb / shard / chest / key / gear
var value := 1
var item_id := ""       # key 的钥匙id
var item_data: Dictionary = {}   # gear 的装备数据
var _t := 0.0
var _spawn_y := 0.0
var sprite: Sprite2D

const TEX := {
	"coin": "res://assets/items/coin.png",
	"orb": "res://assets/items/orb.png",
	"shard": "res://assets/items/shard.png",
	"chest": "res://assets/items/chest.png",
	"key": "res://assets/items/key.png",
	"gear": "res://assets/items/shard.png",
	"ability": "res://assets/items/orb.png",
}

static func spawn_ability(parent: Node, pos: Vector2, ability_id: String) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var p := Area2D.new()
	p.set_script(load("res://scripts/pickup.gd"))
	p.kind = "ability"
	p.item_id = ability_id
	p.position = pos
	parent.add_child(p)

static func spawn_gear(parent: Node, pos: Vector2, item: Dictionary) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var p := Area2D.new()
	p.set_script(load("res://scripts/pickup.gd"))
	p.kind = "gear"
	p.item_data = item
	p.position = pos + Vector2(randf_range(-18, 18), -randf_range(10, 30))
	parent.add_child(p)

static func spawn(parent: Node, pos: Vector2, kind: String, value: int = 1, scatter: bool = false, item_id: String = "") -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var p := Area2D.new()
	p.set_script(load("res://scripts/pickup.gd"))
	p.kind = kind
	p.value = value
	p.item_id = item_id
	p.position = pos + (Vector2(randf_range(-18, 18), -randf_range(10, 30)) if scatter else Vector2.ZERO)
	parent.add_child(p)

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0b00010   # player
	z_index = 8
	_spawn_y = global_position.y
	sprite = Sprite2D.new()
	sprite.texture = load(TEX.get(kind, TEX["coin"]))
	if kind == "gear" and not item_data.is_empty():
		sprite.modulate = ItemsData.rarity_color(int(item_data.get("rarity", 0)))
	elif kind == "ability":
		sprite.modulate = Color(0.5, 0.95, 1.0)
		sprite.scale = Vector2(1.8, 1.8)
	add_child(sprite)
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 26.0
	cs.shape = sh
	add_child(cs)
	body_entered.connect(_on_body)
	# 宝箱有发光底圈
	if kind == "chest":
		sprite.z_index = 9

func _physics_process(delta: float) -> void:
	_t += delta
	if kind == "chest":
		return
	# 漂浮上下浮动
	global_position.y = _spawn_y + sin(_t * 4.0) * 4.0
	sprite.rotation = sin(_t * 3.0) * 0.2
	# 拾取吸附
	if Game.skill_lv("magnet") > 0:
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		if pl and is_instance_valid(pl):
			var d := pl.global_position - global_position
			if d.length() < 200.0:
				global_position += d.normalized() * 360.0 * delta
				_spawn_y = global_position.y

func _on_body(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	match kind:
		"coin":
			Game.add_coins(value)
		"orb":
			Game.add_xp(value)
		"shard":
			if body.has_method("heal"):
				body.heal(value)
			Fx.popup(get_parent(), global_position + Vector2(0, -16), "+%d♥" % value, Color(1, 0.5, 0.6))
		"key":
			Game.give_item(item_id)
			Fx.popup(get_parent(), global_position + Vector2(0, -20), "获得钥匙!", Color(1, 0.85, 0.3))
			Fx.hit_spark(get_parent(), global_position)
			Game.shake(3.0)
			queue_free()
			return
		"gear":
			Game.add_item(item_data)
			var rc: Color = ItemsData.rarity_color(int(item_data.get("rarity", 0)))
			Fx.popup(get_parent(), global_position + Vector2(0, -18), "获得 " + str(item_data.get("name", "装备")), rc)
			Fx.hit_spark(get_parent(), global_position)
			queue_free()
			return
		"ability":
			Game.grant_ability(item_id)
			var an: String = Game.ABILITY_NAME.get(item_id, item_id)
			Fx.popup(get_parent(), global_position + Vector2(0, -28), "获得能力: " + an + "!", Color(0.5, 0.95, 1.0))
			Fx.screen_flash(get_tree(), Color(0.5, 0.9, 1.0, 0.35))
			Fx.hit_spark(get_parent(), global_position)
			Game.shake(6.0)
			queue_free()
			return
		"chest":
			_open_chest()
			return
	_collect_fx()
	queue_free()

func _open_chest() -> void:
	# 宝箱: 喷出金币 + 经验 + 提示
	var n := 6 + randi() % 6
	for i in range(n):
		Pickup.spawn(get_parent(), global_position, "coin", 2 + randi() % 4, true)
	for i in range(3):
		Pickup.spawn(get_parent(), global_position, "orb", 2, true)
	# 宝箱必出一件装备
	Pickup.spawn_gear(get_parent(), global_position, ItemsData.generate())
	Fx.popup(get_parent(), global_position + Vector2(0, -28), "宝箱!", Color(1, 0.85, 0.4))
	Fx.hit_spark(get_parent(), global_position)
	Game.shake(4.0)
	queue_free()

func _collect_fx() -> void:
	var c := Color(1, 0.85, 0.4) if kind == "coin" else (Color(0.5, 1, 0.6) if kind == "orb" else Color(1, 0.5, 0.6))
	Fx.popup(get_parent(), global_position, "+%d" % value, c)
