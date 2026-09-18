extends SceneTree
const Controls=preload("res://remaster/controls.gd")
var game:Node3D
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func frames(n:=3) -> void:
	for i in range(n):await physics_frame
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("DEVICE SWITCH FAIL: "+message)
func send_key(code:int,pressed:bool) -> void:
	var event:=InputEventKey.new();event.physical_keycode=code;event.keycode=code;event.pressed=pressed;Input.parse_input_event(event);await frames()
func run() -> void:
	var state:Node=root.get_node("Reforged");state.persistence_enabled=false;state.new_game();state.story.intro_seen=true
	game=load("res://remaster/main.tscn").instantiate();root.add_child(game);current_scene=game;await frames()
	print("PHYSICAL JOYPADS: ",Input.get_connected_joypads())
	var input:Node=game.controls
	input.refresh_devices({});await frames()
	check(not input.gamepad and input.active_device==-1,"no devices defaults to PC")
	check("空格" in game.ui.keyboard_hint.text,"default HUD retains PC keys")
	for descriptor in [{"name":"Xbox Wireless Controller","info":{}},{"name":"XBOX 360 Controller","info":{}},{"name":"XInput Gamepad","info":{}},{"name":"Controller","info":{"vendor_id":"1118"}},{"name":"Controller","info":{"vendor_id":1118}},{"name":"Controller","info":{"xinput_index":"0"}},{"name":"Controller","info":{"raw_name":"Xbox Series X Controller"}}]:
		check(Controls.is_xbox_device(descriptor.name,descriptor.info),"recognize "+str(descriptor))
	for descriptor in [{"name":"DualSense Wireless Controller","info":{"vendor_id":"1356"}},{"name":"Nintendo Switch Pro Controller","info":{}},{"name":"USB Joystick","info":{}},{"name":"Controller","info":{"xinput_index":-1}},{"name":"","info":{}}]:
		check(not Controls.is_xbox_device(descriptor.name,descriptor.info),"do not relabel other device "+str(descriptor))
	input.refresh_devices({7:{"name":"Xbox Wireless Controller","info":{}}});await frames()
	check(input.gamepad and input.active_device==7,"startup detects already-connected Xbox")
	check(input.prompt("E 交互")=="RB 交互","startup switches without a button press")
	input.refresh_devices({});input.register_device(0,"Xbox Wireless Controller",{},true);await frames()
	check(input.gamepad and input.active_device==0 and "已连接" in game.ui.toast_label.text,"hot connection switches immediately and announces")
	check("A 跳跃" in game.ui.keyboard_hint.text,"visible HUD updates from connection state")
	var mouse:=InputEventMouseMotion.new();mouse.relative=Vector2(30,12);Input.parse_input_event(mouse);await frames()
	await send_key(KEY_F9,true);await send_key(KEY_F9,false)
	check(input.gamepad,"mouse and keyboard do not replace connected Xbox prompts")
	game.ui.open_settings();await frames()
	var slider:Slider=game.ui.panel.find_child("Setting_master",true,false);slider.value=.5;slider.grab_focus()
	await send_key(KEY_RIGHT,true);await send_key(KEY_RIGHT,false)
	check(is_equal_approx(slider.value,.51),"keyboard right adjusts once while Xbox connected")
	game.ui.close();await frames();var before:float=game.player.position.x
	await send_key(KEY_D,true);await frames(12);await send_key(KEY_D,false)
	check(game.player.position.x>before+.1 and input.gamepad,"keyboard gameplay remains available with Xbox prompts")
	input.register_device(2,"DualSense Wireless Controller",{"vendor_id":"1356"})
	check(input.gamepad and input.active_device==0,"other device does not steal Xbox mode")
	input.register_device(1,"Xbox Elite Controller",{});input.connection_changed(1,false)
	check(input.gamepad and input.active_device==0 and not game.ui.panel_open,"unused pad disconnect leaves active pad alone")
	input.register_device(1,"Xbox Elite Controller",{});input.connection_changed(0,false);await frames()
	check(input.gamepad and input.active_device==1,"active disconnect selects remaining Xbox")
	check(game.ui.panel_kind=="pause","active disconnect pauses instead of resuming on another pad")
	input.connection_changed(1,false);await frames()
	check(not input.gamepad and input.active_device==-1,"last Xbox disconnect restores PC")
	check("空格" in game.ui.keyboard_hint.text,"HUD restores keyboard prompt")
	var signs:Array=game.world.find_children("*","Label3D",true,false)
	check(signs.any(func(node):return "E  同步" in node.text),"world signs restore keyboard prompt")
	var pause_kind:String=game.ui.panel_kind;input.register_device(3,"Xbox Wireless Controller",{},true);await frames()
	check(input.gamepad and game.ui.panel_kind==pause_kind and "已连接" in game.ui.toast_label.text and game.ui.toast_label.position.y==4,"reconnect updates status above pause buttons without unpausing")
	input.connection_changed(3,false);input.register_device(8,"USB Joystick",{});await frames()
	check(not input.gamepad,"non-Xbox alone keeps default PC hints")
	game.queue_free();await frames();print("DEVICE SWITCH TESTS: ",checks," checks; ",failures," failures");quit(1 if failures else 0)
