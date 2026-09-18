extends SceneTree
## GPU capture, using the real game scene and isolated progression.
var game: Node3D
var state: Node

func _initialize() -> void:call_deferred("run")

func frames(n: int) -> void:
	for i in range(n):await process_frame

func capture(id: String) -> void:
	game.player.visual.visible=true
	await RenderingServer.frame_post_draw
	var result:=root.get_texture().get_image().save_png("res://remaster/qa/revision_"+id+".png")
	print("CAPTURE ",id," ",result)

func run() -> void:
	state=root.get_node("Reforged");state.persistence_enabled=false;state.new_game()
	game=load("res://remaster/main.tscn").instantiate();root.add_child(game);current_scene=game;game.ui.close()
	for id in ["hub","temple","mine","water_grotto","factory_works","void_deck","castle_gallery","temple_sanctum","mine_boss","water_boss","void_throne","boss","castle_knights","castle_throne"]:
		game.load_room(id);game.ui.close();game.player.invulnerable=100
		if is_instance_valid(game.boss):
			game.player.position.x=game.boss.position.x-5.5
			if id=="void_throne":game.boss.position.y=2.3
			game.boss.set_physics_process(false);game.boss.visual.rotation.y=-PI/2
		for enemy in game.enemies:
			if is_instance_valid(enemy):enemy.set_physics_process(false)
		await frames(75);game.ui.banner_time=0;await capture(id)
	game.load_room("hub");game.player.position=Vector3(12,.1,0);await frames(30)
	for method in ["open_inventory","open_skills","open_map"]:
		game.ui.call(method);await frames(25);await capture(method);game.ui.close()
	state.weapon=3;game.player.refresh_weapon();game.ui.banner_time=0
	game.player.begin_attack(false);await frames(4);await capture("punch_windup")
	await frames(7);await capture("punch_impact")
	for index in [0,1,2]:
		state.weapon=index;game.player.refresh_weapon();game.player.attack_time=0;game.player.begin_attack(false)
		await frames(8);game.player.set_physics_process(false);await capture("weapon_"+str(index));game.player.set_physics_process(true);await frames(45)
	game.load_room("temple");game.transition_cooldown=0;game.player.invulnerable=100
	for l in game.ladders:
		if l.kind=="stairs":game.player.position=Vector3(l.x,.1,0);break
	Input.action_press("r_down");await frames(18);Input.action_release("r_down");game.player.set_physics_process(false);await frames(35);game.ui.banner_time=0;await capture("stairs")
	game.queue_free();await frames(3);quit()
