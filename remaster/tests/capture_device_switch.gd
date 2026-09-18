extends SceneTree
var game:Node3D
var failures:=0
func _initialize() -> void:call_deferred("run")
func frames(n:=8) -> void:
	for i in range(n):await physics_frame
func capture(id:String) -> void:
	await frames();await RenderingServer.frame_post_draw
	var result:=root.get_texture().get_image().save_png("res://remaster/qa/device_"+id+".png")
	if result!=OK:failures+=1
	print("DEVICE CAPTURE ",id," ",result)
func run() -> void:
	var state:Node=root.get_node("Reforged");state.persistence_enabled=false;state.new_game();state.story.intro_seen=true
	game=load("res://remaster/main.tscn").instantiate();root.add_child(game);current_scene=game
	game.controls.refresh_devices({});await capture("default_pc")
	game.controls.register_device(0,"Xbox Wireless Controller",{},true);await capture("connected_title")
	game.ui.close();game.player.invulnerable=0;game.ui.banner_time=0
	game.player.position=game.merchant_position-Vector3(.3,0,0)
	var mouse:=InputEventMouseMotion.new();mouse.relative=Vector2(30,12);Input.parse_input_event(mouse)
	if not game.controls.gamepad:failures+=1
	await capture("connected_hud")
	game.controls.connection_changed(0,false);await capture("disconnected_pc")
	game.controls.register_device(0,"Xbox Wireless Controller",{},true);await capture("reconnected_pause")
	game.queue_free();await frames(3);print("DEVICE CAPTURES failures=",failures);quit(failures)
