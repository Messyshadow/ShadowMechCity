class_name CharacterEquipmentPreview
extends Control
## 真实角色/武器预览。护甲暂无独立立绘时仅使用轻微色调和槽位图标。

signal slot_selected(slot: String)

const VIEW_SIZE := Vector2i(310, 250)

var actor: AnimatedSprite2D
var weapon_sprite: Sprite2D
var slot_buttons: Dictionary = {}
var weapon_label: Label

func _ready() -> void:
	custom_minimum_size = Vector2(VIEW_SIZE)
	_build()
	refresh()

func _build() -> void:
	var viewport_container := SubViewportContainer.new()
	viewport_container.position = Vector2.ZERO
	viewport_container.size = Vector2(VIEW_SIZE)
	viewport_container.stretch = true
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(viewport_container)
	var viewport := SubViewport.new()
	viewport.size = VIEW_SIZE
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport_container.add_child(viewport)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.015, 0.028, 0.05, 1.0)
	backdrop.size = Vector2(VIEW_SIZE)
	viewport.add_child(backdrop)
	for radius in [70.0, 96.0]:
		var ring := Line2D.new()
		ring.width = 1.5
		ring.default_color = Color(0.2, 0.65, 0.82, 0.26)
		var points := PackedVector2Array()
		for index in range(33):
			var angle := TAU * float(index) / 32.0
			points.append(Vector2(155, 130) + Vector2(cos(angle), sin(angle)) * radius)
		ring.points = points
		viewport.add_child(ring)
	actor = AnimatedSprite2D.new()
	actor.sprite_frames = AnimLoader.build_player()
	actor.position = Vector2(155, 178)
	actor.scale = Vector2(1.55, 1.55)
	actor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	viewport.add_child(actor)
	actor.play("idle")
	weapon_sprite = Sprite2D.new()
	weapon_sprite.position = Vector2(174, 136)
	weapon_sprite.scale = Vector2(0.72, 0.72)
	weapon_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	viewport.add_child(weapon_sprite)
	var positions := {
		"helmet": Vector2(8, 18), "armor": Vector2(8, 92), "gloves": Vector2(8, 166),
		"boots": Vector2(238, 18), "amulet": Vector2(238, 92), "ring": Vector2(238, 166),
	}
	for slot in ItemsData.SLOT_ORDER:
		var button := Button.new()
		button.position = positions[slot]
		button.size = Vector2(64, 60)
		button.tooltip_text = ItemsData.SLOTS[slot]["name"]
		button.pressed.connect(func(): slot_selected.emit(slot))
		UI.style_button(button)
		add_child(button)
		slot_buttons[slot] = button
	weapon_label = Label.new()
	weapon_label.position = Vector2(76, 218)
	weapon_label.size = Vector2(158, 26)
	weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weapon_label.add_theme_font_size_override("font_size", 15)
	weapon_label.add_theme_color_override("font_color", Color(0.75, 0.94, 1.0))
	add_child(weapon_label)

func refresh() -> void:
	var weapon := Weapons.get_weapon(Game.weapon_index)
	weapon_sprite.texture = load(str(weapon.get("sprite", "")))
	weapon_sprite.rotation = float(weapon.get("rest_rot", -0.5))
	weapon_label.text = "主武器 · " + str(weapon.get("name", "未知"))
	var armor_count := 0
	for slot in ItemsData.SLOT_ORDER:
		var button: Button = slot_buttons[slot]
		if Game.equipped.has(slot):
			var item: Dictionary = Game.equipped[slot]
			button.text = "%s\n+%d" % [str(ItemsData.SLOTS[slot]["name"]).left(1), int(item.get("lv", 0))]
			button.add_theme_color_override("font_color", ItemsData.rarity_color(int(item.get("rarity", 0))))
			armor_count += 1
		else:
			button.text = "%s\n—" % str(ItemsData.SLOTS[slot]["name"]).left(1)
			button.add_theme_color_override("font_color", Color(0.48, 0.58, 0.68))
	actor.modulate = Color(0.86 + armor_count * 0.018, 0.92, 1.0, 1.0)
