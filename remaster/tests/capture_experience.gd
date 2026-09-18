extends SceneTree
var game: Node3D
var state: Node
var failures:=0
func _initialize() -> void:call_deferred("run")
func frames(n: int) -> void:
	for i in range(n):await process_frame
func capture(id: String) -> void:
	game.player.visual.visible=true
	await RenderingServer.frame_post_draw
	var result:=root.get_texture().get_image().save_png("res://remaster/qa/experience_"+id+".png")
	if result!=OK:failures+=1
	print("CAPTURE ",id," ",result)
func freeze() -> void:
	game.player.invulnerable=100
	for enemy in game.enemies:
		if is_instance_valid(enemy):enemy.set_physics_process(false)
func run() -> void:
	state=root.get_node("Reforged");state.persistence_enabled=false;state.new_game();state.settings=state.DEFAULT_SETTINGS.duplicate();state.settings.tutorial=false;state.apply_settings()
	game=load("res://remaster/main.tscn").instantiate();root.add_child(game);current_scene=game;game.ui.close()
	for id in ["hub","temple","mine","water_grotto","factory_works","void_deck","castle_gallery","dawn_garden","dawn_conduit","dawn_beacon"]:
		game.load_room(id);game.ui.close();freeze();game.player.position=Vector3(game.room_width*.44,.1,0)
		await frames(60);game.ui.banner_time=0;await capture(id)
	game.load_room("hub");freeze();game.ui.close();state.settings.tutorial=true;await frames(20);game.ui.banner_time=0;await capture("tutorial")
	for method in ["open_title","open_story","open_guide","open_settings","open_shop","open_npc","open_journal"]:
		if method=="open_shop":state.first_trade()
		game.ui.call(method);await frames(22);await capture(method);game.ui.close()
	state.points=8
	for page in ["战斗","身法","暗影 / 机械"]:
		game.ui.skill_page=page;game.ui.skill_family=3;game.ui.open_skills();await frames(22);await capture("skills_"+str(["战斗","身法","暗影 / 机械"].find(page)));game.ui.close()
	game.ui.open_map();game.ui.map_view.fit_all();await frames(8);await capture("map");game.ui.close()
	game.load_room("dawn_beacon");game.ui.close();freeze();game.player.position=Vector3(10,.1,0);await frames(30);game.ui.banner_time=0
	var stalker:Node3D=game.spawn_enemy("stalker",Vector3(13,.1,0));stalker.facing=-1;stalker.visual.rotation.y=-PI/2;stalker.set_physics_process(false);stalker.choose_attack();stalker.clip("slam",.55)
	await frames(10);await capture("stalker_windup");stalker.execute_attack();stalker.clip("dash");await frames(7);await capture("stalker_lunge")
	var guard:Node3D=game.spawn_enemy("warden",Vector3(12,.1,0));guard.visual.rotation.y=-PI/2;guard.set_physics_process(false);guard.take_hit(8,1)
	for mesh in guard.armor_meshes:mesh.material_overlay=guard.flash_material
	await frames(3);await capture("warden_hit")
	for enemy in game.enemies:
		if is_instance_valid(enemy):enemy.take_hit(enemy.hp+1,1,true)
	state.story.beacon_accepted=true;state.settings.tutorial=false
	game.player.position=Vector3(game.room_width-6,.1,0);await create_timer(1.3).timeout
	game.activate_beacon();await frames(12);await capture("beacon_online")
	game.ui.open_settings();state.set_setting("fullscreen",true);await frames(15)
	if DisplayServer.window_get_mode()!=DisplayServer.WINDOW_MODE_FULLSCREEN:failures+=1;push_error("Fullscreen preference did not reach the OS")
	state.set_setting("fullscreen",false);await frames(15)
	if DisplayServer.window_get_mode()!=DisplayServer.WINDOW_MODE_WINDOWED:failures+=1;push_error("Windowed preference did not reach the OS")
	print("DISPLAY CHECKS: fullscreen/windowed; failures=",failures)
	game.queue_free();await frames(4);quit(failures)
