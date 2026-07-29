class_name PortalInteraction
extends Area2D
## 主动传送入口：负责入口分类、提示与交互请求；房间切换仍由 main.gd 执行。

signal travel_requested(door_data: Dictionary)
signal travel_blocked(missing: Array[String])
signal focus_changed(focused: bool)

var door_data: Dictionary = {}
var target_name := ""
var was_visited := false
var missing: Array[String] = []
var player_near := false
var _request_sent := false
var _prompt: Label

static func requires_interaction(door: Dictionary) -> bool:
	var override := str(door.get("trigger_mode", ""))
	if override == "interact":
		return true
	if override == "auto":
		return false
	return bool(door.get("hidden", false)) or str(door.get("side", "")) in ["up", "down"]

static func anchor_position(door: Dictionary, bounds: Array) -> Vector2:
	var side := str(door.get("side", ""))
	var p := float(door.get("p", 0.0))
	match side:
		"left":
			return Vector2(float(bounds[0]) + 12.0, (p + float(bounds[3])) * 0.5)
		"right":
			return Vector2(float(bounds[2]) - 12.0, (p + float(bounds[3])) * 0.5)
		"down":
			return Vector2(p, float(bounds[3]) - 34.0)
		"up":
			if bool(door.get("hidden", false)):
				return Vector2(p, float(bounds[1]) + 54.0)
			return Vector2(p, float(bounds[3]) - 30.0)
	return Vector2.ZERO

static func prompt_text(door: Dictionary, target_name: String, visited: bool, missing: Array) -> String:
	if not missing.is_empty():
		return "需要：" + " / ".join(missing)
	if bool(door.get("hidden", false)):
		return "[E / Enter] 前往 " + target_name if visited else "[E / Enter] 进入隐藏回响"
	if str(door.get("side", "")) == "down":
		return "[E / Enter] 向下进入"
	if str(door.get("side", "")) == "up":
		return "[E / Enter] 向上攀登"
	return "[E / Enter] 启动传送阵"

func configure(data: Dictionary, destination: String, visited: bool, missing_names: Array) -> void:
	door_data = data.duplicate(true)
	target_name = destination
	was_visited = visited
	set_missing(missing_names)
	_request_sent = false
	if not is_instance_valid(_prompt):
		_build_prompt()
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
	_refresh_prompt()

func set_missing(missing_names: Array) -> void:
	missing.clear()
	for entry in missing_names:
		missing.append(str(entry))
	_refresh_prompt()

func reset_request() -> void:
	_request_sent = false

func force_prompt_visible(value: bool) -> void:
	player_near = value
	if is_instance_valid(_prompt):
		_prompt.visible = value
		_prompt.modulate.a = 1.0 if value else 0.0
	focus_changed.emit(value)

func attempt_interaction() -> void:
	if not player_near or _request_sent:
		return
	if not missing.is_empty():
		travel_blocked.emit(missing.duplicate())
		_pulse_blocked()
		return
	_request_sent = true
	if is_instance_valid(_prompt):
		_prompt.hide()
	travel_requested.emit(door_data)

func _unhandled_input(event: InputEvent) -> void:
	var game := get_node_or_null("/root/Game")
	var menu_open := int(game.get("menu_open")) if is_instance_valid(game) else 0
	if not player_near or menu_open != 0:
		return
	if event.is_action_pressed("interact"):
		attempt_interaction()
		get_viewport().set_input_as_handled()

func _build_prompt() -> void:
	_prompt = Label.new()
	_prompt.name = "PortalPrompt"
	_prompt.size = Vector2(380, 70)
	_prompt.position = _prompt_position()
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt.z_index = 120
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.add_theme_font_size_override("font_size", 20)
	_prompt.add_theme_color_override("font_outline_color", Color(0.01, 0.015, 0.035, 0.98))
	_prompt.add_theme_constant_override("outline_size", 7)
	_prompt.hide()
	add_child(_prompt)

func _prompt_position() -> Vector2:
	var side := str(door_data.get("side", ""))
	if side == "up":
		return Vector2(-190, 62) if bool(door_data.get("hidden", false)) else Vector2(-190, -142)
	if side == "down":
		return Vector2(-190, -152)
	return Vector2(-190, -132)

func _refresh_prompt() -> void:
	if not is_instance_valid(_prompt):
		return
	_prompt.text = prompt_text(door_data, target_name, was_visited, missing)
	var color := Color(0.58, 0.93, 1.0)
	if bool(door_data.get("hidden", false)):
		color = Color(0.82, 0.62, 1.0)
	if not missing.is_empty():
		color = Color(0.65, 0.58, 0.76)
	_prompt.add_theme_color_override("font_color", color)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		force_prompt_visible(true)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_near = false
		_request_sent = false
		if is_instance_valid(_prompt):
			_prompt.hide()
		focus_changed.emit(false)

func _pulse_blocked() -> void:
	if not is_instance_valid(_prompt):
		return
	_prompt.modulate = Color(1.0, 0.55, 0.72)
	var tween := _prompt.create_tween()
	tween.tween_property(_prompt, "modulate", Color.WHITE, 0.22)
