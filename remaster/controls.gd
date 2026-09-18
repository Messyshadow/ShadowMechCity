extends Node
## Xbox layout. Gameplay and menu input share hardware, not button presses.
const KEYS := {"r_left":[KEY_A,KEY_LEFT],"r_right":[KEY_D,KEY_RIGHT],"r_up":[KEY_W,KEY_UP],"r_down":[KEY_S,KEY_DOWN],"r_jump":[KEY_SPACE],"r_attack":[KEY_J],"r_skill":[KEY_K],"r_dash":[KEY_SHIFT,KEY_L],"r_swap":[KEY_Q],"r_reload":[KEY_R],"r_heal":[KEY_H],"r_interact":[KEY_E],"r_map":[KEY_M],"r_inventory":[KEY_I,KEY_U],"r_skills":[KEY_T],"r_pause":[KEY_ESCAPE],"r_journal":[KEY_N],"r_companion":[KEY_C],"r_roster":[KEY_G]}
const BUTTONS := {"r_jump":JOY_BUTTON_A,"r_attack":JOY_BUTTON_X,"r_skill":JOY_BUTTON_Y,"r_dash":JOY_BUTTON_B,"r_swap":JOY_BUTTON_LEFT_SHOULDER,"r_interact":JOY_BUTTON_RIGHT_SHOULDER,"r_companion":JOY_BUTTON_LEFT_STICK,"r_roster":JOY_BUTTON_RIGHT_STICK,"r_inventory":JOY_BUTTON_BACK,"r_pause":JOY_BUTTON_START,"r_left":JOY_BUTTON_DPAD_LEFT,"r_right":JOY_BUTTON_DPAD_RIGHT,"r_up":JOY_BUTTON_DPAD_UP,"r_down":JOY_BUTTON_DPAD_DOWN}
const AXES := {"r_left":[JOY_AXIS_LEFT_X,-1.0],"r_right":[JOY_AXIS_LEFT_X,1.0],"r_up":[JOY_AXIS_LEFT_Y,-1.0],"r_down":[JOY_AXIS_LEFT_Y,1.0],"r_heal":[JOY_AXIS_TRIGGER_LEFT,1.0],"r_reload":[JOY_AXIS_TRIGGER_RIGHT,1.0],"r_pan_left":[JOY_AXIS_RIGHT_X,-1.0],"r_pan_right":[JOY_AXIS_RIGHT_X,1.0],"r_pan_up":[JOY_AXIS_RIGHT_Y,-1.0],"r_pan_down":[JOY_AXIS_RIGHT_Y,1.0]}
var game:Node3D
var gamepad := false
var active_device := -1
var xbox_devices:Dictionary = {}
var blocked_actions:Dictionary = {}
var menu_direction := Vector2.ZERO
var repeat_time := 0.0

static func register_actions() -> void:
	for action in KEYS:
		if not InputMap.has_action(action):InputMap.add_action(action)
		for code in KEYS[action]:
			var event:=InputEventKey.new();event.physical_keycode=code
			if not InputMap.action_has_event(action,event):InputMap.action_add_event(action,event)
	for action in BUTTONS:
		var event:=InputEventJoypadButton.new();event.button_index=BUTTONS[action];event.device=-1
		if not InputMap.action_has_event(action,event):InputMap.action_add_event(action,event)
	for action in AXES:
		if not InputMap.has_action(action):InputMap.add_action(action)
		InputMap.action_set_deadzone(action,.25 if action in ["r_left","r_right","r_up","r_down"] else .45)
		var event:=InputEventJoypadMotion.new();event.axis=AXES[action][0];event.axis_value=AXES[action][1];event.device=-1
		if not InputMap.action_has_event(action,event):InputMap.action_add_event(action,event)

func _ready() -> void:
	Input.joy_connection_changed.connect(connection_changed)
	var devices:Dictionary={}
	for device in Input.get_connected_joypads():
		devices[device]={"name":Input.get_joy_name(device),"info":Input.get_joy_info(device)}
	refresh_devices(devices)

static func is_xbox_device(device_name:String,info:Dictionary) -> bool:
	var name_lower:=(device_name+" "+str(info.get("raw_name",""))).to_lower()
	# Godot's SDL backend returns IDs/indexes as decimal strings on Windows.
	return "xbox" in name_lower or "xinput" in name_lower or int(info.get("vendor_id",0))==0x045e or (info.has("xinput_index") and int(info.xinput_index)>=0)

func refresh_devices(devices:Dictionary) -> void:
	xbox_devices.clear()
	for device in devices:
		var descriptor:Dictionary=devices[device]
		if is_xbox_device(str(descriptor.get("name","")),descriptor.get("info",{})):xbox_devices[int(device)]=true
	refresh_mode()

func register_device(device:int,device_name:String,info:Dictionary,announce:=false) -> void:
	if is_xbox_device(device_name,info):xbox_devices[device]=true
	else:xbox_devices.erase(device)
	refresh_mode()
	if announce and xbox_devices.has(device):game.ui.toast("Xbox 手柄已连接，已自动切换按键提示。",5)

func refresh_mode() -> void:
	if not xbox_devices.has(active_device):active_device=-1 if xbox_devices.is_empty() else int(xbox_devices.keys()[0])
	gamepad=not xbox_devices.is_empty()
	menu_direction=Vector2.ZERO;repeat_time=0

func _input(event:InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if not xbox_devices.has(event.device):return
		if (event is InputEventJoypadButton and event.pressed) or (event is InputEventJoypadMotion and absf(event.axis_value)>.45):
			active_device=event.device
		if game.ui.panel_open:
			if event is InputEventJoypadButton and event.pressed:game.ui.controller_button(event.button_index)
			get_viewport().set_input_as_handled()

func _process(dt:float) -> void:
	for action in blocked_actions.keys():
		if not Input.is_action_pressed(action):blocked_actions.erase(action)
	if not game.ui.panel_open or not gamepad:menu_direction=Vector2.ZERO;return
	# Read only this pad here. Shared gameplay actions include keyboard arrows,
	# which the GUI already handles; polling those would move menu focus twice.
	var direction:=Vector2(Input.get_joy_axis(active_device,JOY_AXIS_LEFT_X),Input.get_joy_axis(active_device,JOY_AXIS_LEFT_Y))
	direction.x+=int(Input.is_joy_button_pressed(active_device,JOY_BUTTON_DPAD_RIGHT))-int(Input.is_joy_button_pressed(active_device,JOY_BUTTON_DPAD_LEFT))
	direction.y+=int(Input.is_joy_button_pressed(active_device,JOY_BUTTON_DPAD_DOWN))-int(Input.is_joy_button_pressed(active_device,JOY_BUTTON_DPAD_UP))
	if direction.length()<.45:menu_direction=Vector2.ZERO;repeat_time=0
	else:
		direction=Vector2(signf(direction.x),0) if absf(direction.x)>absf(direction.y) else Vector2(0,signf(direction.y))
		repeat_time-=dt
		if direction!=menu_direction or repeat_time<=0:
			game.ui.controller_move(direction)
			repeat_time=.32 if direction!=menu_direction else .12;menu_direction=direction
	if game.ui.panel_kind=="map" and is_instance_valid(game.ui.map_view):
		var map:Control=game.ui.map_view
		var movement:=Vector2(Input.get_joy_axis(active_device,JOY_AXIS_RIGHT_X),Input.get_joy_axis(active_device,JOY_AXIS_RIGHT_Y))
		movement=movement.normalized()*clampf((movement.length()-.45)/.55,0,1)
		if movement.length()>.05:map.pan-=movement*dt*650;map.clamp_pan();map.queue_redraw()
		var zoom_axis:=trigger_strength(JOY_AXIS_TRIGGER_RIGHT)-trigger_strength(JOY_AXIS_TRIGGER_LEFT)
		if absf(zoom_axis)>.05:map.set_zoom(map.zoom*exp(zoom_axis*dt))

func suppress_held_actions() -> void:
	for action in KEYS:
		if Input.is_action_pressed(action):blocked_actions[action]=true
	menu_direction=Vector2.ZERO;repeat_time=.32

func just_pressed(action:String) -> bool:return not blocked_actions.has(action) and Input.is_action_just_pressed(action)
func pressed(action:String) -> bool:return not blocked_actions.has(action) and Input.is_action_pressed(action)
func axis(negative:String,positive:String) -> float:
	return (0.0 if blocked_actions.has(positive) else Input.get_action_strength(positive))-(0.0 if blocked_actions.has(negative) else Input.get_action_strength(negative))

func trigger_strength(code:int) -> float:return clampf((Input.get_joy_axis(active_device,code)-.45)/.55,0,1)

func connection_changed(device:int,connected:bool) -> void:
	if connected:
		register_device(device,Input.get_joy_name(device),Input.get_joy_info(device),true)
	else:
		var was_active:=device==active_device and gamepad
		xbox_devices.erase(device);refresh_mode()
		if was_active:
			suppress_held_actions()
			if not game.ui.panel_open:game.ui.open_pause()
			game.ui.toast("当前手柄已断开，已暂停。另一只 Xbox 手柄仍可用，按 A 继续。" if gamepad else "Xbox 手柄已断开，已暂停并切回 PC 按键。重新连接后将自动切换。",6)

func prompt(value:String) -> String:
	if not gamepad:return value
	# Only replace standalone control tokens, never English words or NPC names.
	var tokens:={"A D":"左摇杆","W S":"左摇杆↑↓","W / S":"左摇杆↑↓","A / D":"左摇杆","空格":"A","Shift":"B","J":"X","K":"Y","Q":"LB","R":"RT","H":"LT","E":"RB","C":"L3","G":"R3","T":"View → 技能","I":"View","N":"View → 任务","M":"View → 地图","Esc":"B"}
	for key in ["A / D","W / S","A D","W S","空格","Shift","Esc"]:value=value.replace(key,tokens[key])
	value=value.replace("Enter","A")
	value=value.replace("↑ W","左摇杆↑").replace("↓ S","左摇杆↓")
	value=value.replace("滚轮缩放 · 左键拖动","LT / RT 缩放 · 右摇杆移动")
	var matcher:=RegEx.new();matcher.compile("(?<![A-Za-z0-9])([JKQRHECGTINM])(?![A-Za-z0-9])")
	var matches:=matcher.search_all(value)
	for i in range(matches.size()-1,-1,-1):
		var match_result:RegExMatch=matches[i];value=value.substr(0,match_result.get_start())+tokens[match_result.get_string()]+value.substr(match_result.get_end())
	return value
