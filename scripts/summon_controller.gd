class_name SummonController
extends CanvasLayer
## SUMMON HUD / 11.1c 三槽量子伙伴控制器：唯一型号、错峰协同、独立重构与超载保护。

const ROBOT_SCRIPT := preload("res://scripts/summon_robot.gd")
const RULES := preload("res://scripts/summon_rules.gd")
const ROSTER_PANEL_SCRIPT := preload("res://scripts/summon_roster_panel.gd")
const SUMMON_FX := preload("res://scripts/summon_fx.gd")

var world: Node2D
var player: Node2D
var active_robots: Array[SummonRobot] = []
var active_robot: SummonRobot
var desired_deployed := false
var rebuild_by_id: Dictionary = {}
var rebuild_remaining := 0.0
var overload_value := 0.0
var overload_lock_remaining := 0.0
var _hud_refresh_cooldown := 0.0
var peak_fx_count := 0
var panel: PanelContainer
var roster_panel: CanvasLayer
var title_label: Label
var status_label: Label
var overload_bar: ProgressBar
var unit_rows := VBoxContainer.new()


func _ready() -> void:
	layer = 13
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.ensure_role_roster(false)
	_build_hud()
	roster_panel = ROSTER_PANEL_SCRIPT.new()
	roster_panel.controller = self
	add_child(roster_panel)
	Game.summon_changed.connect(_on_summon_changed)
	_refresh_hud()


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	peak_fx_count = maxi(peak_fx_count, SUMMON_FX.active_fx_count(get_tree()))
	var changed := false
	for instance_id in rebuild_by_id.keys():
		var previous := float(rebuild_by_id[instance_id])
		if previous > 0.0:
			rebuild_by_id[instance_id] = maxf(0.0, previous - delta)
			changed = true
	rebuild_remaining = _max_rebuild()
	var profile := RULES.overload_profile(active_robots.size())
	if overload_lock_remaining > 0.0:
		overload_lock_remaining = maxf(0.0, overload_lock_remaining - delta)
		changed = true
	else:
		var old_overload := overload_value
		overload_value = maxf(0.0, overload_value - float(profile["decay"]) * delta)
		changed = changed or not is_equal_approx(old_overload, overload_value)
	_hud_refresh_cooldown = maxf(0.0, _hud_refresh_cooldown - delta)
	if changed and _hud_refresh_cooldown <= 0.0:
		_hud_refresh_cooldown = 0.12
		_refresh_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("summon") and Game.menu_open == 0 and not get_tree().paused:
		toggle_summon()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("summon_cycle") and Game.menu_open == 0 and not get_tree().paused:
		cycle_standby_model()
		get_viewport().set_input_as_handled()


func _on_summon_changed(_snapshot: Dictionary) -> void:
	_refresh_hud()
	if is_instance_valid(roster_panel) and bool(roster_panel.get("open")):
		roster_panel.call("refresh")


func on_room_entered(new_world: Node2D, owner: Node2D) -> void:
	world = new_world
	player = owner
	active_robots.clear()
	active_robot = null
	if desired_deployed:
		_deploy_loadout.call_deferred()
	else:
		_refresh_hud()


func toggle_summon() -> void:
	_prune_active()
	if not active_robots.is_empty():
		desired_deployed = false
		for robot in active_robots:
			if is_instance_valid(robot):
				robot.recall()
		active_robots.clear()
		active_robot = null
		overload_value = 0.0
		_refresh_hud()
		return
	desired_deployed = true
	_deploy_loadout()


func _deploy_loadout() -> void:
	if not is_instance_valid(world) or not is_instance_valid(player):
		return
	_prune_active()
	if not active_robots.is_empty():
		return
	Game.ensure_role_roster(false)
	var ids := RULES.unique_loadout(Game.summon_loadout, Game.summon_slot_level, Game.robot_roster)
	var ready_records: Array[Dictionary] = []
	for instance_id in ids:
		if float(rebuild_by_id.get(instance_id, 0.0)) <= 0.0:
			var record := _record_for(instance_id)
			if not record.is_empty():
				ready_records.append(record)
	var team_profile := RULES.overload_profile(ready_records.size())
	for index in range(ready_records.size()):
		var record: Dictionary = ready_records[index]
		var robot: SummonRobot = ROBOT_SCRIPT.new()
		robot.setup(record, player)
		robot.configure_formation(index, ready_records.size(), float(team_profile["power_scale"]), float(index) * 0.24)
		robot.global_position = player.global_position + robot.formation_offset
		world.add_child(robot)
		SummonFx.projection(world, robot.global_position + Vector2(0, -18), robot.profile.get("accent", Color("53e6ff")), index)
		robot.health_changed.connect(_on_robot_health_changed.bind(robot))
		robot.disabled.connect(_on_robot_disabled)
		robot.attack_committed.connect(_on_robot_attack_committed)
		active_robots.append(robot)
	active_robot = active_robots[0] if not active_robots.is_empty() else null
	_refresh_hud()


func _on_robot_attack_committed(_robot: SummonRobot) -> void:
	var profile := RULES.overload_profile(active_robots.size())
	overload_value = minf(100.0, overload_value + float(profile["gain"]))
	if overload_value >= 100.0 and active_robots.size() >= 2:
		overload_lock_remaining = float(profile["lock_seconds"])
		for robot in active_robots:
			if is_instance_valid(robot):
				robot.apply_overload_lock(overload_lock_remaining)
		if is_instance_valid(world):
			Fx.popup(world, player.global_position + Vector2(0, -120), "量子超载 · 协同冷却", Color("ff6f91"))
		overload_value = 72.0
	_refresh_hud()


func _on_robot_health_changed(_current: int, _maximum: int, _robot: SummonRobot) -> void:
	_refresh_hud()


func _on_robot_disabled(robot: SummonRobot) -> void:
	var instance_id := str(robot.record.get("robot_instance_id", ""))
	rebuild_by_id[instance_id] = float(robot.profile.get("rebuild_seconds", 12.0))
	active_robots.erase(robot)
	active_robot = active_robots[0] if not active_robots.is_empty() else null
	if active_robots.is_empty():
		desired_deployed = false
	_refresh_hud()


func deploy_for_qa(mode: String = "deployed") -> void:
	Game.ensure_role_roster(false)
	rebuild_by_id.clear()
	rebuild_remaining = 0.0
	if mode == "standby":
		desired_deployed = false
		_refresh_hud()
		return
	desired_deployed = true
	_deploy_loadout()
	if mode == "damaged" and is_instance_valid(active_robot):
		active_robot.take_damage(5, active_robot.global_position + Vector2(90, 0))
	elif mode == "cooldown" and is_instance_valid(active_robot):
		active_robot.take_damage(999, active_robot.global_position + Vector2(90, 0))
	elif mode == "support":
		for robot in active_robots:
			if str(robot.profile.get("combat_style", "")) == "support":
				robot.force_support_pulse_for_qa()


func configure_team_for_qa(slot_level: int, model_ids: Array) -> void:
	Game.ensure_role_roster(false)
	Game.summon_slot_level = clampi(slot_level, 1, 3)
	var ids: Array[String] = []
	for model_id in model_ids:
		for record in Game.robot_roster:
			if str(record.get("model_id", "")) == str(model_id):
				ids.append(str(record["robot_instance_id"]))
	Game.summon_loadout = RULES.unique_loadout(ids, Game.summon_slot_level, Game.robot_roster)
	Game.summon_changed.emit(Game.summon_snapshot())


func force_overload_for_qa() -> void:
	overload_value = 96.0
	if not active_robots.is_empty():
		_on_robot_attack_committed(active_robots[0])


func show_fx_for_qa(kind: String) -> void:
	_prune_active()
	match kind:
		"deploy":
			for index in range(active_robots.size()):
				var robot := active_robots[index]
				SummonFx.projection(world, robot.global_position + Vector2(0, -18), robot.profile.get("accent", Color("53e6ff")), index)
		"warning":
			for robot in active_robots:
				robot.force_warning_for_qa()
		"recall":
			toggle_summon()
		"disabled":
			if is_instance_valid(active_robot):
				active_robot.take_damage(active_robot.hp, active_robot.global_position + Vector2(100, 0))
		_:
			push_error("SHOT_SUMMON_FX unknown state: " + kind)
	peak_fx_count = maxi(peak_fx_count, SUMMON_FX.active_fx_count(get_tree()))


func performance_snapshot() -> Dictionary:
	_prune_active()
	return {
		"active_robots": active_robots.size(),
		"active_fx": SUMMON_FX.active_fx_count(get_tree()),
		"peak_fx": peak_fx_count,
		"fx_budget": SUMMON_FX.MAX_ACTIVE_FX,
		"overload": overload_value,
		"fps": Engine.get_frames_per_second(),
	}


func cycle_standby_model() -> void:
	_prune_active()
	if not active_robots.is_empty() or _max_rebuild() > 0.0:
		return
	Game.ensure_role_roster(false)
	var current_id := str(Game.summon_loadout[0]) if not Game.summon_loadout.is_empty() else ""
	var current_index := -1
	for i in range(Game.robot_roster.size()):
		if str(Game.robot_roster[i].get("robot_instance_id", "")) == current_id:
			current_index = i
			break
	var next_record: Dictionary = Game.robot_roster[(current_index + 1) % Game.robot_roster.size()]
	Game.assign_summon_slot(0, str(next_record["robot_instance_id"]))


func select_model_for_qa(model_id: String) -> void:
	Game.ensure_role_roster(false)
	for record in Game.robot_roster:
		if str(record.get("model_id", "")) == model_id:
			Game.summon_loadout = [str(record["robot_instance_id"])]
			Game.summon_changed.emit(Game.summon_snapshot())
			return
	push_error("SHOT_SUMMON_MODEL unknown model: " + model_id)


func debug_snapshot() -> Dictionary:
	_prune_active()
	return {"deployed": not active_robots.is_empty(), "active_count": active_robots.size(), "slot_level": Game.summon_slot_level, "overload": overload_value, "overload_lock": overload_lock_remaining, "rebuild": _max_rebuild()}


func _record_for(instance_id: String) -> Dictionary:
	for record in Game.robot_roster:
		if record is Dictionary and str(record.get("robot_instance_id", "")) == instance_id:
			return record
	return {}


func _prune_active() -> void:
	var valid: Array[SummonRobot] = []
	for robot in active_robots:
		if is_instance_valid(robot) and not robot.is_queued_for_deletion():
			valid.append(robot)
	active_robots = valid
	active_robot = active_robots[0] if not active_robots.is_empty() else null


func _max_rebuild() -> float:
	var result := 0.0
	for value in rebuild_by_id.values():
		result = maxf(result, float(value))
	return result


func _build_hud() -> void:
	panel = PanelContainer.new()
	panel.position = Vector2(24, 282)
	panel.custom_minimum_size = Vector2(300, 118)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.012, 0.027, 0.047, 0.94)
	style.border_color = Color(0.24, 0.83, 0.96, 0.78)
	style.set_border_width_all(2); style.set_corner_radius_all(9)
	style.content_margin_left = 13; style.content_margin_right = 13
	style.content_margin_top = 8; style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var root := VBoxContainer.new(); root.add_theme_constant_override("separation", 3); panel.add_child(root)
	title_label = Label.new(); title_label.add_theme_font_size_override("font_size", 17); title_label.add_theme_color_override("font_color", Color("8defff")); root.add_child(title_label)
	unit_rows.add_theme_constant_override("separation", 1); root.add_child(unit_rows)
	status_label = Label.new(); status_label.add_theme_font_size_override("font_size", 12); status_label.add_theme_color_override("font_color", Color("a8bfd0")); root.add_child(status_label)
	overload_bar = ProgressBar.new(); overload_bar.max_value = 100; overload_bar.show_percentage = false; overload_bar.custom_minimum_size = Vector2(272, 7)
	var fill := StyleBoxFlat.new(); fill.bg_color = Color("ff668c"); fill.set_corner_radius_all(3)
	var back := StyleBoxFlat.new(); back.bg_color = Color("102431"); back.set_corner_radius_all(3)
	overload_bar.add_theme_stylebox_override("fill", fill); overload_bar.add_theme_stylebox_override("background", back); root.add_child(overload_bar)


func _refresh_hud(_current: int = -1, _maximum: int = -1) -> void:
	if not is_instance_valid(panel):
		return
	_prune_active()
	for child in unit_rows.get_children():
		child.queue_free()
	title_label.text = "◆ 量子伙伴  %d/%d    [G] 阵容" % [active_robots.size(), Game.summon_slot_level]
	if active_robots.is_empty():
		var loadout_names: Array[String] = []
		for instance_id in Game.summon_loadout:
			var record := _record_for(instance_id)
			loadout_names.append(str(RobotData.profile(str(record.get("model_id", ""))).get("name", "未知")))
		var standby := Label.new(); standby.text = "待命 · " + " / ".join(loadout_names); standby.add_theme_font_size_override("font_size", 12); unit_rows.add_child(standby)
	else:
		for robot in active_robots:
			var row := Label.new(); row.text = "%s   HP %d/%d" % [str(robot.profile.get("name", "伙伴")), robot.hp, robot.max_hp]
			row.add_theme_font_size_override("font_size", 12); row.add_theme_color_override("font_color", robot.profile.get("accent", Color.WHITE)); unit_rows.add_child(row)
	status_label.text = ("超载锁定 %.1fs" % overload_lock_remaining) if overload_lock_remaining > 0 else ("[C] 回收 · 协同错峰" if not active_robots.is_empty() else "[C] 部署  [Z] 首槽换型")
	overload_bar.value = overload_value
	overload_bar.visible = Game.summon_slot_level >= 2
