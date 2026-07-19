class_name SkillPreview
extends SubViewportContainer
## 独立技能教学预览：只播放表现，不生成 Area2D 或消耗 Game 资源。

const PREVIEW_SIZE := Vector2i(410, 150)

var viewport: SubViewport
var actor: AnimatedSprite2D
var weapon_sprite: Sprite2D
var current_tween: Tween

func _ready() -> void:
	custom_minimum_size = Vector2(PREVIEW_SIZE)
	stretch = true
	_build_preview()

func _build_preview() -> void:
	viewport = SubViewport.new()
	viewport.name = "SkillPreviewViewport"
	viewport.size = PREVIEW_SIZE
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.018, 0.035, 0.06, 1.0)
	backdrop.position = Vector2.ZERO
	backdrop.size = Vector2(PREVIEW_SIZE)
	viewport.add_child(backdrop)
	for index in range(6):
		var line := Line2D.new()
		line.width = 1.0
		line.default_color = Color(0.16, 0.48, 0.62, 0.24)
		line.points = PackedVector2Array([Vector2(18 + index * 74, 18), Vector2(58 + index * 74, 128)])
		viewport.add_child(line)
	var floor_line := Line2D.new()
	floor_line.width = 3.0
	floor_line.default_color = Color(0.22, 0.82, 0.98, 0.55)
	floor_line.points = PackedVector2Array([Vector2(20, 122), Vector2(390, 122)])
	viewport.add_child(floor_line)
	actor = AnimatedSprite2D.new()
	actor.sprite_frames = AnimLoader.build_player()
	actor.position = Vector2(205, 108)
	actor.scale = Vector2(1.2, 1.2)
	actor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	viewport.add_child(actor)
	weapon_sprite = Sprite2D.new()
	weapon_sprite.position = Vector2(219, 82)
	weapon_sprite.scale = Vector2(0.58, 0.58)
	weapon_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	viewport.add_child(weapon_sprite)
	actor.play("idle")

func play_node(node: Dictionary, weapon: Dictionary = {}) -> void:
	if actor == null:
		return
	if current_tween and current_tween.is_valid():
		current_tween.kill()
	actor.position = Vector2(205, 108)
	actor.rotation = 0.0
	actor.modulate = Color.WHITE
	weapon_sprite.rotation = float(weapon.get("rest_rot", -0.5))
	weapon_sprite.texture = load(str(weapon.get("sprite", ""))) if str(weapon.get("sprite", "")) != "" else null
	var preview := str(node.get("preview", "idle_guard"))
	var animation := "idle"
	if preview in ["run"]:
		animation = "run"
	elif preview in ["jump", "glide", "climb", "swim"]:
		animation = "jump"
	elif preview in ["dash"]:
		animation = "dash"
	elif preview in ["attack_1", "hammer_attack", "cannon_attack"]:
		animation = "attack1"
	elif preview in ["attack_2", "spin", "skill_wave"]:
		animation = "attack2"
	elif preview in ["ultimate", "skill_cast", "bomb"]:
		animation = "attack3"
	actor.play(animation)
	current_tween = create_tween().set_loops()
	if preview == "run" or preview == "dash":
		current_tween.tween_property(actor, "position:x", 295.0, 0.7)
		current_tween.tween_property(actor, "position:x", 125.0, 0.0)
	else:
		current_tween.tween_property(actor, "modulate", Color(0.55, 0.92, 1.0), 0.28)
		current_tween.tween_property(actor, "modulate", Color.WHITE, 0.28)

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and viewport:
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if is_visible_in_tree() else SubViewport.UPDATE_DISABLED
