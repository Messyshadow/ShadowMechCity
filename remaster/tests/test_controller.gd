extends SceneTree
const Controls=preload("res://remaster/controls.gd")
var game:Node3D
var state:Node
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func frames(n:int) -> void:
	for i in range(n):await physics_frame
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures.append(message);push_error("CONTROLLER FAIL: "+message)
func button(code:int,pressed:bool) -> void:
	var event:=InputEventJoypadButton.new();event.device=0;event.button_index=code;event.pressed=pressed;Input.parse_input_event(event);await frames(3)
func tap(code:int) -> void:
	await button(code,true);await button(code,false)
func axis(code:int,value:float,n:=3) -> void:
	var event:=InputEventJoypadMotion.new();event.device=0;event.axis=code;event.axis_value=value;Input.parse_input_event(event);await frames(n)
func named_button(value:String) -> Button:
	for node in game.ui.controller_focusables():
		if node is Button and str(node.get_meta("prompt_source",""))==value:return node
	return null
func run() -> void:
	state=root.get_node("Reforged");state.persistence_enabled=false;state.new_game();state.story.intro_seen=true
	game=load("res://remaster/main.tscn").instantiate();root.add_child(game);current_scene=game;await frames(8)
	print("CONNECTED JOYPADS: ",Input.get_connected_joypads())
	var event_count:=InputMap.action_get_events("r_jump").size();game.register_input()
	check(InputMap.action_get_events("r_jump").size()==event_count,"registration is idempotent")
	for action in Controls.BUTTONS:
		var event:=InputEventJoypadButton.new();event.button_index=Controls.BUTTONS[action];event.device=0
		check(InputMap.event_is_action(event,action),action+" accepts standardized Xbox button")
	check(InputMap.action_get_events("r_jump")[0] is InputEventKey,"keyboard bindings retained")
	await button(JOY_BUTTON_A,true)
	check(not game.ui.panel_open and game.controls.gamepad,"A confirms title and selects Xbox prompts")
	check(game.player.position.y<.2 and game.player.jump_buffer==0,"menu confirmation does not leak into jump")
	await button(JOY_BUTTON_A,false);await frames(10);await button(JOY_BUTTON_A,true)
	check(game.player.velocity.y>0,"fresh A press jumps")
	await button(JOY_BUTTON_A,false);await frames(70)
	var before_x:float=game.player.position.x
	await axis(JOY_AXIS_LEFT_X,.12,10);check(absf(game.player.position.x-before_x)<.03,"stick drift below deadzone is ignored")
	await axis(JOY_AXIS_LEFT_X,.65,14);check(game.player.position.x>before_x+.1 and game.player.velocity.x<7.2,"left stick supplies proportional movement")
	await axis(JOY_AXIS_LEFT_X,0);await frames(15)
	await button(JOY_BUTTON_X,true);check(game.player.attack_time>0,"X starts melee attack");await button(JOY_BUTTON_X,false);await frames(30)
	state.skills.blade_3=true;await tap(JOY_BUTTON_Y);check(game.player.skill_cooldown>0,"Y starts learned weapon skill");await frames(45)
	await tap(JOY_BUTTON_LEFT_SHOULDER);check(state.weapon==1,"LB switches weapon")
	await tap(JOY_BUTTON_B);check(game.player.dash_cooldown>0,"B dashes in world");await frames(45)
	await tap(JOY_BUTTON_START);check(game.ui.panel_kind=="pause","Menu opens pause")
	await button(JOY_BUTTON_B,true);check(not game.ui.panel_open and game.player.dash_time<=0,"B returns without leaking dash");await button(JOY_BUTTON_B,false)
	await tap(JOY_BUTTON_BACK);check(game.ui.panel_kind=="inventory","View opens equipment")
	for kind in ["skills","map","journal","companions","inventory"]:
		await tap(JOY_BUTTON_RIGHT_SHOULDER);check(game.ui.panel_kind==kind,"RB reaches "+kind)
	await tap(JOY_BUTTON_LEFT_SHOULDER);check(game.ui.panel_kind=="companions","LB cycles pages backwards")
	await tap(JOY_BUTTON_B);await tap(JOY_BUTTON_LEFT_STICK);check(state.squad.deployed,"L3 deploys companions")
	await tap(JOY_BUTTON_RIGHT_STICK);check(game.ui.panel_kind=="companions","R3 opens roster");await tap(JOY_BUTTON_B)
	game.ui.open_skills();await frames(4);named_button("身法").grab_focus();await tap(JOY_BUTTON_A)
	check(game.ui.skill_page=="身法","A selects skill category")
	check(root.gui_get_focus_owner()==named_button("身法"),"focus survives page rebuild")
	game.ui.open_settings();await frames(4)
	var slider:Slider=game.ui.panel.find_child("Setting_master",true,false);slider.value=.5;slider.grab_focus()
	await tap(JOY_BUTTON_DPAD_RIGHT);check(slider.value>.5 and slider.value<.7,"D-pad adjusts settings once per initial press")
	await button(JOY_BUTTON_DPAD_RIGHT,true);await frames(30);await button(JOY_BUTTON_DPAD_RIGHT,false)
	check(slider.value>.6,"held direction repeats in menus")
	await tap(JOY_BUTTON_B);check(game.ui.panel_kind=="pause","B returns from settings to pause")
	game.ui.open_map();await frames(4);var map:Control=game.ui.map_view;var old_zoom:float=map.zoom
	await axis(JOY_AXIS_TRIGGER_RIGHT,1,15);check(map.zoom>old_zoom,"RT zooms map")
	state.magazine=0;await button(JOY_BUTTON_B,true);check(game.player.reload_time==0,"map RT does not reload when closing while held")
	await button(JOY_BUTTON_B,false);await axis(JOY_AXIS_TRIGGER_RIGHT,0);await axis(JOY_AXIS_TRIGGER_RIGHT,1)
	check(game.player.reload_time>0,"new RT press reloads in world");await axis(JOY_AXIS_TRIGGER_RIGHT,0);await frames(65)
	state.hp=45;var potions:int=state.potions;await axis(JOY_AXIS_TRIGGER_LEFT,1);await axis(JOY_AXIS_TRIGGER_LEFT,0)
	check(state.hp>45 and state.potions==potions-1,"LT consumes one healing potion")
	game.ui.open_map();await frames(4);map=game.ui.map_view;map.set_zoom(1);map.pan=Vector2(-100,-100);var old_pan:Vector2=map.pan
	await axis(JOY_AXIS_RIGHT_X,1,12);check(map.pan.x<old_pan.x,"right stick pans map");await axis(JOY_AXIS_RIGHT_X,0)
	await tap(JOY_BUTTON_Y);check(map.zoom<.5,"Y fits complete map");await tap(JOY_BUTTON_X)
	check(map.pan.x<=20 and map.pan.y<=55,"X recenters map within limits")
	game.ui.close();await frames(5);game.player.position=game.merchant_position;game.player.velocity=Vector3.ZERO
	await tap(JOY_BUTTON_RIGHT_SHOULDER);check(game.ui.panel_kind=="shop" and state.merchant_gift,"RB interacts with merchant")
	check(root.gui_get_focus_owner() in game.ui.controller_focusables(),"shop has controller focus")
	state.coins=9999
	for i in range(18):state.inventory.append(state.make_item("armor",0))
	game.ui.open_inventory();await frames(6)
	var scroll:ScrollContainer=game.ui.panel.find_children("*","ScrollContainer",true,false)[0]
	var items:Array=scroll.find_children("*","Button",true,false)
	items[0].grab_focus()
	for i in range(12):game.ui.controller_move(Vector2.DOWN);await frames(2)
	check(scroll.scroll_vertical>0,"inventory follows controller focus into offscreen rows")
	game.ui.close();await frames(4);game.controls.connection_changed(0,false)
	check(game.ui.panel_kind=="pause" and not game.controls.gamepad,"active controller disconnect pauses gameplay")
	var key:=InputEventKey.new();key.physical_keycode=KEY_ESCAPE;key.pressed=true;Input.parse_input_event(key);await frames(3)
	key.pressed=false;Input.parse_input_event(key);await frames(3);check(not game.ui.panel_open,"keyboard can resume after disconnect")
	game.controls.gamepad=true
	check(game.controls.prompt("E 交互 / J 普攻 / K 技能 / HEK'S SALVAGE")=="RB 交互 / X 普攻 / Y 技能 / HEK'S SALVAGE","prompt substitution preserves English words")
	await frames(3)
	var signs:Array=game.world.find_children("*","Label3D",true,false)
	check(signs.any(func(node):return "RB" in node.text),"world interaction signs switch to controller prompts")
	check(game.controls.prompt("↑ W · 检修梯")=="左摇杆↑ · 检修梯","vertical passage signs show stick direction")
	state.story.intro_seen=false;game.ui.open_title();await frames(3);await tap(JOY_BUTTON_B)
	check(game.ui.panel_kind=="story","title B follows the same guarded continue flow")
	await tap(JOY_BUTTON_B);check(game.ui.panel_kind=="title","story B returns to title")
	game.controls.gamepad=false;check(game.controls.prompt("E 交互")=="E 交互","keyboard prompts restore")
	game.queue_free();await frames(4);print("CONTROLLER TESTS: ",checks," checks; ",failures.size()," failures");quit(1 if failures.size()>0 else 0)
