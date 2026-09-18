extends SceneTree
var state:Node
var game:Node3D
var failures:=0
func _initialize() -> void:call_deferred("run")
func frames(n:int) -> void:
	for i in range(n):await physics_frame
func capture(id:String) -> void:
	game.player.visual.visible=true
	await RenderingServer.frame_post_draw
	var result:=root.get_texture().get_image().save_png("res://remaster/qa/arsenal_"+id+".png")
	if result!=OK:failures+=1
	print("CAPTURE ",id," ",result)
func run() -> void:
	state=root.get_node("Reforged");state.persistence_enabled=false;state.new_game();state.settings.tutorial=false;state.apply_settings()
	game=load("res://remaster/main.tscn").instantiate();root.add_child(game);current_scene=game
	game.ui.open_title();await frames(20);await capture("title")
	state.save_blocked=true;game.ui.open_save_recovery();await frames(12);await capture("recovery");state.save_blocked=false
	state.points=30
	for family in range(4,7):
		game.ui.skill_page="战斗";game.ui.skill_family=family;game.ui.skill_selection=state.WEAPONS[family]+"_3";game.ui.open_skills()
		await frames(22);await capture("skills_"+str(family))
	for id in ["hound","mole","bee","wisp"]:
		game.ui.companion_selection=id;game.ui.open_companions();await frames(22);await capture("roster_"+id)
	game.ui.close();state.expand_squad();state.expand_squad();state.assign_companion("mole");state.assign_companion("bee")
	game.load_room("dawn_garden");game.ui.close();game.player.position=Vector3(10,.1,0);game.player.invulnerable=0
	for enemy in game.enemies:enemy.queue_free()
	game.enemies.clear();game.companions.toggle();await frames(80);game.ui.banner_time=0;await capture("squad")
	for index in range(4,7):
		state.weapon=index;state.skills[state.WEAPONS[index]+"_3"]=true;game.player.refresh_weapon();game.player.attack_time=0;game.player.combo_window=0
		game.player.begin_attack(false);await frames(3);await capture("weapon_"+str(index)+"_windup")
		await frames(7);await capture("weapon_"+str(index)+"_strike");await frames(55)
	state.hp=60;state.squad.loadout=["wisp"];game.companions.refresh();await frames(90)
	game.companions.units.wisp.cooldown=0;await frames(3);await capture("repair_windup");await frames(19);await capture("repair_resolve")
	if state.hp!=64:failures+=1;push_error("Repair capture did not reach the heal impact")
	state.squad.loadout=["hound","mole","bee"];game.companions.refresh();await frames(10)
	game.companions.units.hound.take_damage(999);await frames(4);await capture("reconstruction")
	game.ui.open_guide();await frames(8);await capture("guide")
	game.queue_free();await frames(4);print("ARSENAL CAPTURES failures=",failures);quit(failures)
