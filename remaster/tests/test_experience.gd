extends SceneTree
const World=preload("res://remaster/world_data.gd")
var game: Node3D
var state: Node
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func frames(n: int) -> void:
	for i in range(n):await physics_frame
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:failures.append(message);push_error("EXPERIENCE FAIL: "+message)
func run() -> void:
	state=root.get_node("Reforged");state.persistence_enabled=false;state.new_game()
	game=load("res://remaster/main.tscn").instantiate();root.add_child(game);current_scene=game;game.ui.close();await frames(15)
	check(World.ROOMS.size()==40 and Rooms.ROOMS.size()==37,"remaster expands without mutating classic rooms")
	check(game.next_hop("hub","dawn_beacon")=="dawn_garden","NPC route reaches the expansion from hub")
	for id in World.ROOMS:
		for door in World.ROOMS[id].get("doors",[]):check(World.ROOMS.has(str(door.to)),"valid destination "+id)
	for link in [["hub","dawn_garden"],["dawn_garden","hub"],["dawn_garden","dawn_conduit"],["dawn_conduit","dawn_garden"],["dawn_conduit","dawn_beacon"],["dawn_beacon","dawn_conduit"]]:
		game.load_room(link[0]);game.ui.close();game.player.invulnerable=100;game.transition_cooldown=0
		for d in game.doors:
			if str(d.to)!=link[1]:continue
			game.player.position=Vector3(d.x,.1,0)
			var action:String={"up":"r_up","down":"r_down"}.get(str(d.side),"r_interact")
			Input.action_press(action);await frames(170);Input.action_release(action)
			check(game.room_id==link[1],"key-driven expansion link "+str(link));break
	for id in ["dawn_garden","dawn_conduit","dawn_beacon"]:
		game.load_room(id);game.ui.close();game.player.position=Vector3(2,.1,0);game.player.invulnerable=100;await frames(8)
		for enemy in game.enemies:enemy.set_physics_process(false)
		Input.action_press("r_right")
		for frame in range(650):
			if frame%38==0:Input.action_press("r_jump")
			if frame%38==20:Input.action_release("r_jump")
			await frames(1)
			if game.player.position.x>=game.room_width-2:break
		Input.action_release("r_right");Input.action_release("r_jump")
		check(game.player.position.x>=game.room_width-2.3 and game.player.death_time<=0,"collision-driven traversal "+id)
		check(game.enemies.size()==2,"expansion enemy formation "+id)
	game.load_room("dawn_beacon");await frames(3)
	check(not game.activate_beacon(),"living guards block beacon activation")
	for enemy in game.enemies:enemy.dead=true
	check(game.activate_beacon() and state.story.beacon_online,"cleared beacon can be activated")
	check(game.beacon_glow.visible and game.beacon_lamp.visible,"quest activates persistent beacon illumination")
	check(not state.claim_beacon_reward(),"reward requires accepting the NPC quest")
	state.story.beacon_accepted=true;var money:int=state.coins;var points:int=state.points
	check(state.claim_beacon_reward() and state.coins==money+80 and state.points==points+2,"NPC grants promised reward")
	check(not state.claim_beacon_reward() and state.coins==money+80,"NPC reward cannot duplicate")
	state.first_trade();state.tutorial.erase("trade")
	check(not state.first_trade() and state.tutorial.get("trade",false),"existing merchant gift can still complete the tutorial without duplication")
	game.load_room("hub");game.ui.close();await frames(10)
	state.skills.clear();state.points=40
	var base_health:float=state.max_health()
	check(not state.learn("triple_jump"),"movement prerequisite enforced")
	for id in ["stride","dash_flow","triple_jump","wall_drive","glide","water_drive","shadow_guard","shadow_step","shadow_edge","core_shell","fast_loader","overclock"]:
		check(state.learn(id),"learn real skill "+id)
	check(is_equal_approx(state.max_health(),base_health+20),"mechanical core raises actual max health")
	state.weapon=2;state.magazine=0;game.player.reload();check(is_equal_approx(game.player.reload_time,.6),"loader reduces actual reload time")
	game.player.reload_time=0;state.weapon=0;state.skills.blade_3=true;game.player.begin_attack(true)
	check(is_equal_approx(game.player.skill_cooldown,3.0),"overclock reduces actual skill cooldown")
	game.player.invulnerable=0;game.player.take_damage(1,0)
	check(is_equal_approx(game.player.invulnerable,1.1),"shadow guard extends actual immunity")
	game.player.attack_time=0;game.player.hit_pause=0;game.player.invulnerable=100;game.player.position=Vector3(5,6,0);game.player.velocity=Vector3.ZERO
	await frames(10)
	game.player.jumping=2;game.player.coyote=0
	Input.action_press("r_jump");await frames(2);Input.action_release("r_jump")
	check(game.player.jumping==3 and game.player.velocity.y>0,"third jump really propels the player")
	game.player.velocity.y=-8;Input.action_press("r_jump");await frames(2);Input.action_release("r_jump")
	check(game.player.velocity.y>=-2.51,"glide caps actual falling speed")
	game.load_room("hub");game.ui.close();game.player.invulnerable=100;game.player.position=Vector3(5,.1,0)
	Input.action_press("r_right");await frames(25);Input.action_release("r_right")
	check(is_equal_approx(game.player.velocity.x,8.064),"stride increases collision-driven ground speed")
	Input.action_press("r_dash");await frames(2);Input.action_release("r_dash")
	check(game.player.dash_cooldown>.39 and game.player.dash_cooldown<=.45 and game.player.invulnerable>.30 and game.player.invulnerable<=.36,"dash cooldown and shadow immunity affect the actual dash")
	await frames(25);game.player.position=Vector3(.3,4,0);game.player.velocity=Vector3.ZERO
	Input.action_press("r_left");await frames(12);game.player.coyote=0
	Input.action_press("r_jump");await frames(2);Input.action_release("r_jump");Input.action_release("r_left")
	check(game.player.velocity.y>13 and game.player.velocity.x>9,"wall drive boosts the real wall-jump impulse")
	game.load_room("water_grotto");game.ui.close();game.player.invulnerable=100;game.player.position=Vector3(6,.1,0);await frames(3)
	Input.action_press("r_right");await frames(15);Input.action_release("r_right")
	check(game.player.water and is_equal_approx(game.player.velocity.x,5.67),"water drive boosts actual submerged motion")
	game.load_room("hub");game.ui.close();game.player.invulnerable=100
	game.player.position=Vector3(5,.1,0);await frames(35)
	var guard:Node3D=game.spawn_enemy("warden",Vector3(7,.1,0));guard.set_physics_process(false);guard.facing=-1;var before:float=guard.hp
	guard.take_hit(10,1);check(is_equal_approx(guard.hp,before-4),"shield mitigates frontal hits")
	guard.state="recover";before=guard.hp;guard.take_hit(10,1)
	check(is_equal_approx(guard.hp,before-12),"shadow edge rewards striking recovery, bypassing shield")
	check(guard.hit_stop>0 and guard.hit_flash>0,"hit response schedules flash and hit stop")
	game.load_room("dawn_beacon");game.player.position=Vector3(10,.1,0);await frames(3)
	var stalker:Node3D=game.spawn_enemy("stalker",Vector3(12,.1,0));stalker.set_physics_process(false);stalker.choose_attack()
	check(stalker.attack_id=="charge" and stalker.state=="windup","stalker telegraphs a distinct lunge")
	stalker.execute_attack();check(stalker.state=="charge","stalker launches the lunge")
	check(stalker.anim.current_animation=="dash","lunge plays its attack animation immediately")
	for method in ["open_title","open_settings","open_story","open_guide","open_journal","open_npc","open_shop"]:
		game.ui.call(method);await frames(2);check(game.ui.panel_open,"panel builds "+method)
		for label in game.ui.panel.find_children("*","Label",true,false):
			if label.has_meta("paragraph_width"):check(label.size.x<=float(label.get_meta("paragraph_width"))+.1,"paragraph fits panel in "+method)
		game.ui.close()
	for page in ["战斗","身法","暗影 / 机械"]:
		game.ui.skill_page=page;game.ui.open_skills();await frames(2)
		check(game.ui.panel_kind=="skills" and is_instance_valid(game.ui.skill_preview),"tree and preview build "+page)
	game.ui.open_settings("title")
	var music_slider:HSlider=game.ui.panel.find_child("Setting_music",true,false)
	music_slider.value=.23
	var effects_slider:HSlider=game.ui.panel.find_child("Setting_effects",true,false)
	effects_slider.value=0
	var brightness_slider:HSlider=game.ui.panel.find_child("Setting_brightness",true,false)
	brightness_slider.value=1.3
	game.ui.return_from_settings();check(game.ui.panel_kind=="title","settings returns to its originating menu");game.ui.close()
	check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))),.23),"music slider changes its own bus")
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Effects")),"zero effects volume mutes effects bus")
	check(is_equal_approx(game.environment.adjustment_brightness,1.3),"brightness applies to rendered environment")
	state.settings_path="user://experience_settings_test.cfg";state.save_path="user://experience_save_test.json";state.persistence_enabled=true
	check(state.save_settings()==OK and state.save_game(),"preferences and progression save")
	state.settings=state.DEFAULT_SETTINGS.duplicate();state.story.clear();state.skills.clear();state.load_settings();state.load_game()
	check(is_equal_approx(float(state.settings.music),.23) and state.story.get("beacon_claimed",false) and state.skills.has("glide"),"settings, quest and skills survive reload")
	state.new_game();check(is_equal_approx(float(state.settings.music),.23) and state.story.is_empty(),"new journey preserves preferences and resets quest")
	for path in [state.settings_path,state.save_path,state.save_path+".bak",state.save_path+".tmp"]:DirAccess.remove_absolute(path)
	state.persistence_enabled=false;state.settings_path="user://remaster_settings.cfg";state.save_path=state.SAVE
	game.queue_free();await frames(4);print("EXPERIENCE TESTS: ",checks," checks; ",failures.size()," failures");quit(0 if failures.is_empty() else 1)
