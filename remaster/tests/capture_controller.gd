extends SceneTree
var game:Node3D
var failures:=0
func _initialize() -> void:call_deferred("run")
func frames(n:int) -> void:
	for i in range(n):await physics_frame
func capture(id:String) -> void:
	await frames(6);await RenderingServer.frame_post_draw
	var result:=root.get_texture().get_image().save_png("res://remaster/qa/controller_"+id+".png")
	if result!=OK:failures+=1
	print("CONTROLLER CAPTURE ",id," ",result)
func run() -> void:
	var state:Node=root.get_node("Reforged");state.persistence_enabled=false;state.new_game();state.story.intro_seen=true
	game=load("res://remaster/main.tscn").instantiate();root.add_child(game);current_scene=game;await frames(8)
	game.controls.register_device(0,"Xbox Wireless Controller",{})
	var event:=InputEventJoypadButton.new();event.device=0;event.button_index=JOY_BUTTON_DPAD_DOWN;event.pressed=true;Input.parse_input_event(event)
	await frames(2);event.pressed=false;Input.parse_input_event(event)
	await capture("title")
	game.ui.close();game.player.invulnerable=0;game.ui.banner_time=0;game.player.position=game.merchant_position-Vector3(.3,0,0)
	await capture("hud")
	game.ui.open_skills();game.ui.skill_family=6;game.ui.open_skills();await capture("skills")
	game.ui.open_settings();await frames(4);game.ui.panel.find_child("Setting_master",true,false).grab_focus();await capture("settings")
	game.ui.open_map();game.ui.map_view.fit_all();await capture("map")
	game.ui.open_guide();await capture("guide")
	state.coins=9999
	for i in range(12):state.inventory.append(state.make_item("armor",0))
	game.ui.open_inventory();await frames(6)
	var scroll:ScrollContainer=game.ui.panel.find_children("*","ScrollContainer",true,false)[0]
	var buttons:Array=scroll.find_children("*","Button",true,false);buttons[buttons.size()-2].grab_focus();await capture("inventory")
	game.queue_free();await frames(4);print("CONTROLLER CAPTURES failures=",failures);quit(failures)
