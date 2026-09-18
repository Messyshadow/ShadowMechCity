extends SceneTree
var game:Node3D
var state:Node
var failures:=0
func _initialize() -> void:call_deferred("run")
func frames(n:=8) -> void:
	for i in range(n):await physics_frame
func capture(id:String) -> void:
	await frames();await RenderingServer.frame_post_draw
	var result:=root.get_texture().get_image().save_png("res://remaster/qa/exploration_"+id+".png")
	if result!=OK:failures+=1
	print("EXPLORATION CAPTURE ",id," ",result)
func scene(id:String,x:float) -> void:
	game.load_room(id);game.ui.close();state.settings.tutorial=false
	game.player.position=Vector3(x,0,0);game.player.invulnerable=0;game.player.set_physics_process(false);game.set_physics_process(false)
	for enemy in game.enemies:enemy.set_physics_process(false)
	game.ui.banner_time=0;game.ui.toast_time=0
	await frames(80)
func run() -> void:
	state=root.get_node("Reforged");state.persistence_enabled=false;state.new_game();state.story.intro_seen=true
	game=load("res://remaster/main.tscn").instantiate();root.add_child(game);current_scene=game
	game.controls.refresh_devices({});await frames()
	if "--capture-supply" in OS.get_cmdline_user_args():
		await scene("dawn_conduit",10.5);await capture("supply_world")
		game.queue_free();await frames();quit(failures);return
	await scene("cavern",9);await capture("modules_world")
	await scene("temple",game.room_width*.36);await capture("sealed_heart")
	if not game.exploration.seals.is_empty():
		var pos:Vector3=game.exploration.seals[0].pos
		game.exploration.detonate(pos);await capture("unsealed_heart")
	await scene("secret_hub_archive",10);await capture("archive_world")
	await scene("dawn_conduit",10.5);await capture("supply_world")
	state.ExplorationData.collect(state,"memory_hub_archive");state.ExplorationData.collect(state,"module_bomb");state.ExplorationData.collect(state,"heart_hub")
	game.ui.open_collection("记忆档案");await capture("archive_page")
	game.ui.open_collection("探索模块");await capture("modules_page")
	game.ui.open_collection("补给与进度");await capture("supply_page")
	game.controls.register_device(0,"Xbox Controller",{});game.ui.open_collection("探索模块");await capture("controller_modules")
	for card in game.ui.panel.find_children("*","Button",true,false):
		if card.tooltip_text=="暗影滑翔翼":card.grab_focus()
	await capture("controller_scroll")
	game.ui.open_map();game.ui.map_view.fit_all();await capture("map")
	game.queue_free();await frames();print("EXPLORATION CAPTURES failures=",failures);quit(failures)
