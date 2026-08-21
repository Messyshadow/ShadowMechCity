class_name SummonController
extends CanvasLayer
## SUMMON HUD + 11.1b 单槽四定位召唤生命周期。不注册进敌人战斗导演。

const ROBOT_SCRIPT := preload("res://scripts/summon_robot.gd")

var world: Node2D
var player: Node2D
var active_robot: SummonRobot
var desired_deployed := false
var rebuild_remaining := 0.0
var panel: PanelContainer
var name_label: Label
var state_label: Label
var hp_bar: ProgressBar
var hint_label: Label


func _ready() -> void:
	layer = 13
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.ensure_role_roster(false)
	_build_hud()
	Game.summon_changed.connect(func(_snapshot: Dictionary) -> void: _refresh_hud())
	_refresh_hud()


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	if rebuild_remaining > 0.0:
		rebuild_remaining = maxf(0.0, rebuild_remaining - delta)
		_refresh_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("summon") and Game.menu_open == 0 and not get_tree().paused:
		toggle_summon()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("summon_cycle") and Game.menu_open == 0 and not get_tree().paused:
		cycle_standby_model()
		get_viewport().set_input_as_handled()


func on_room_entered(new_world: Node2D, owner: Node2D) -> void:
	world = new_world
	player = owner
	active_robot = null
	if desired_deployed and rebuild_remaining <= 0.0:
		_deploy.call_deferred()
	else:
		_refresh_hud()


func toggle_summon() -> void:
	if is_instance_valid(active_robot):
		desired_deployed = false
		active_robot.recall()
		active_robot = null
		_refresh_hud(0, 0)
		return
	if rebuild_remaining > 0.0:
		return
	desired_deployed = true
	_deploy()


func deploy_for_qa(mode: String = "deployed") -> void:
	Game.ensure_role_roster(false)
	rebuild_remaining = 0.0
	if mode == "standby":
		desired_deployed = false
		_refresh_hud()
		return
	desired_deployed = true
	_deploy()
	if mode == "damaged" and is_instance_valid(active_robot):
		active_robot.take_damage(5, active_robot.global_position + Vector2(90, 0))
	elif mode == "cooldown" and is_instance_valid(active_robot):
		active_robot.take_damage(999, active_robot.global_position + Vector2(90, 0))
	elif mode == "support" and is_instance_valid(active_robot) and is_instance_valid(player):
		if player.has_method("max_hp"):
			player.set("health", maxi(1, int(player.call("max_hp")) - 2))
			player.emit_signal("health_changed", int(player.get("health")), int(player.call("max_hp")))
		active_robot.force_support_pulse_for_qa()


func cycle_standby_model() -> void:
	if is_instance_valid(active_robot) or rebuild_remaining > 0.0:
		return
	Game.ensure_role_roster(false)
	if Game.robot_roster.is_empty():
		return
	var current_id := str(Game.summon_loadout[0]) if not Game.summon_loadout.is_empty() else ""
	var current_index := -1
	for i in range(Game.robot_roster.size()):
		if str(Game.robot_roster[i].get("robot_instance_id", "")) == current_id:
			current_index = i
			break
	var next_record: Dictionary = Game.robot_roster[(current_index + 1) % Game.robot_roster.size()]
	Game.summon_loadout = [str(next_record["robot_instance_id"])]
	Game.summon_changed.emit(Game.summon_snapshot())
	_refresh_hud()


func select_model_for_qa(model_id: String) -> void:
	Game.ensure_role_roster(false)
	for record in Game.robot_roster:
		if str(record.get("model_id", "")) == model_id:
			Game.summon_loadout = [str(record["robot_instance_id"])]
			Game.summon_changed.emit(Game.summon_snapshot())
			_refresh_hud()
			return
	push_error("SHOT_SUMMON_MODEL unknown model: " + model_id)


func debug_snapshot() -> Dictionary:
	var record := _active_record()
	var profile := RobotData.profile(str(record.get("model_id", "scrap_hound_mk1")))
	return {
		"instance_id": record.get("robot_instance_id", ""),
		"name": profile.get("name", "未配置"),
		"role": profile.get("role", ""),
		"deployed": is_instance_valid(active_robot),
		"hp": active_robot.hp if is_instance_valid(active_robot) else 0,
		"max_hp": active_robot.max_hp if is_instance_valid(active_robot) else int(profile.get("max_hp", 1)),
		"rebuild": rebuild_remaining,
	}


func _deploy() -> void:
	if not is_instance_valid(world) or not is_instance_valid(player) or is_instance_valid(active_robot):
		return
	var record := _active_record()
	if record.is_empty():
		return
	active_robot = ROBOT_SCRIPT.new()
	active_robot.setup(record, player)
	var mobility := str(active_robot.profile.get("mobility", "ground"))
	var side := 1.0 if player.global_position.x < 210.0 else -1.0
	active_robot.global_position = player.global_position + (Vector2(side * 105, -118) if mobility == "air" else Vector2(side * 92, -28))
	world.add_child(active_robot)
	active_robot.health_changed.connect(_refresh_hud)
	active_robot.disabled.connect(_on_robot_disabled)
	_refresh_hud(active_robot.hp, active_robot.max_hp)


func _on_robot_disabled(robot: SummonRobot) -> void:
	if robot != active_robot:
		return
	var profile := RobotData.profile(str(_active_record().get("model_id", "scrap_hound_mk1")))
	rebuild_remaining = float(profile.get("rebuild_seconds", 12.0))
	active_robot = null
	desired_deployed = false
	_refresh_hud(0, int(profile.get("max_hp", 1)))


func _active_record() -> Dictionary:
	Game.ensure_role_roster(false)
	var unlocked_slots := clampi(Game.summon_slot_level, 1, 3)
	if unlocked_slots <= 0 or Game.summon_loadout.is_empty():
		return {}
	var active_id := str(Game.summon_loadout[0])
	for record in Game.robot_roster:
		if record is Dictionary and str(record.get("robot_instance_id", "")) == active_id:
			return record
	return {}


func _build_hud() -> void:
	panel = PanelContainer.new()
	panel.name = "SummonStatus"
	panel.position = Vector2(24, 282)
	panel.custom_minimum_size = Vector2(260, 92)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.035, 0.055, 0.91)
	style.border_color = Color(0.24, 0.83, 0.96, 0.78)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14; style.content_margin_right = 14
	style.content_margin_top = 9; style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 3)
	panel.add_child(rows)
	var title_row := HBoxContainer.new()
	rows.add_child(title_row)
	name_label = Label.new()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 17)
	name_label.add_theme_color_override("font_color", Color("8defff"))
	title_row.add_child(name_label)
	var key := Label.new()
	key.text = " C "
	key.add_theme_font_size_override("font_size", 16)
	key.add_theme_color_override("font_color", Color("ffd66b"))
	title_row.add_child(key)
	state_label = Label.new()
	state_label.add_theme_font_size_override("font_size", 13)
	state_label.add_theme_color_override("font_color", Color(0.70,0.82,0.90))
	rows.add_child(state_label)
	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(232, 8)
	hp_bar.show_percentage = false
	var fill := StyleBoxFlat.new(); fill.bg_color = Color("38dceb"); fill.set_corner_radius_all(3)
	var background := StyleBoxFlat.new(); background.bg_color = Color("102431"); background.set_corner_radius_all(3)
	hp_bar.add_theme_stylebox_override("fill", fill); hp_bar.add_theme_stylebox_override("background", background)
	rows.add_child(hp_bar)
	hint_label = Label.new()
	hint_label.text = "[C] 召唤  [Z] 切换型号"
	hint_label.add_theme_font_size_override("font_size", 12)
	hint_label.add_theme_color_override("font_color", Color(0.54,0.72,0.80))
	rows.add_child(hint_label)


func _refresh_hud(current: int = -1, maximum: int = -1) -> void:
	if not is_instance_valid(panel):
		return
	var snapshot := debug_snapshot()
	name_label.text = "◆ %s" % snapshot["name"]
	if rebuild_remaining > 0.0:
		state_label.text = "量子重构中  %.1fs" % rebuild_remaining
	elif bool(snapshot["deployed"]):
		state_label.text = "%s  ·  已部署" % snapshot["role"]
	else:
		state_label.text = "%s  ·  待命" % snapshot["role"]
	var hp_now := int(snapshot["hp"]) if current < 0 else current
	var hp_max := int(snapshot["max_hp"]) if maximum < 0 else maximum
	hp_bar.max_value = maxi(1, hp_max)
	hp_bar.value = hp_now if bool(snapshot["deployed"]) else (0 if rebuild_remaining > 0.0 else hp_max)
	hint_label.text = "[C] 回收伙伴" if bool(snapshot["deployed"]) else ("[C] 重构冷却" if rebuild_remaining > 0.0 else "[C] 召唤  [Z] 切换型号")
