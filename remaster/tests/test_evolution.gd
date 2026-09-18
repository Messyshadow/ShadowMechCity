extends SceneTree
const Data=preload("res://remaster/evolution_data.gd")
const SaveIO=preload("res://remaster/save_io.gd")
var game:Node3D
var state:Node
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func frames(n:=3) -> void:
	for i in range(n):await physics_frame
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("EVOLUTION FAIL: "+message)
func run() -> void:
	state=root.get_node("Reforged");state.persistence_enabled=false;state.new_game()
	game=load("res://remaster/main.tscn").instantiate();root.add_child(game);current_scene=game;await frames()
	game.ui.close();game.load_room("hub");await frames()
	check(not game.evolution.activate_form() and not game.evolution.activate_summon(),"unlearned active abilities refused")
	state.points=25
	check(not state.learn("shadow_summon") and state.points==25,"summon prerequisite enforced without spending")
	for branch in Data.BRANCHES:
		for id in Data.NODES[branch]:check(state.learn(id),"learn "+id)
		check(Data.spent(state,branch)==10,"branch invested points: "+branch)
	check(state.points==5 and not state.learn("shadow_form"),"learning debits exactly once")
	check(state.skills.has("shadow_guard") and state.max_health()==140,"legacy passives preserved")
	check(not game.evolution.select_branch("invalid"),"unknown loadout refused")
	game.player.position=Vector3(8,0,0);game.player.set_physics_process(false)
	check(game.evolution.activate_form() and game.evolution.form_left==14,"learned mastery gives 14 second form")
	check(is_instance_valid(game.evolution.form_visual),"Blender transformation visible")
	check(not game.evolution.activate_form() and not game.evolution.select_branch("mechanical"),"cannot stack form or change active branch")
	check(game.evolution.damage_scale()==1.25 and game.evolution.speed_scale()==1.18,"shadow modifiers active")
	var target:Node3D=game.spawn_enemy("sentry",Vector3(9.5,0,0));target.set_physics_process(false);target.hp=500;target.max_hp=500
	game.player.facing=1;game.player.combo=0;game.player.skill_attack=false;game.player.airborne_attack=false;game.player.resolve_attack()
	check(is_equal_approx(target.hp,477.5),"form scales actual melee damage")
	check(game.evolution.activate_summon() and game.evolution.summon_left==16,"summon and form coexist with mastery")
	check(not game.evolution.activate_summon() and not state.squad.deployed,"temporary summon is single slot and independent of robot squad")
	var life:float=game.evolution.form_left;var cooldown:float=state.evolution.form_cd
	game.ui.open_pause();await frames(50)
	check(game.evolution.form_left==life and state.evolution.form_cd==cooldown and game.evolution.summon_left==16,"menus freeze all evolution timers")
	game.ui.close();await frames(140)
	check(game.evolution.action_count>0 and target.hp<477.5,"shadow summon moves and deals damage")
	game.evolution.tick(20)
	check(game.evolution.form_left==0 and game.evolution.summon_left==0 and game.evolution.form_visual==null and game.evolution.summon_unit==null,"expiry removes models and all temporary bonuses")
	check(game.evolution.damage_scale()==1 and game.evolution.speed_scale()==1 and game.evolution.incoming_scale()==1,"base stats restored")
	check(game.evolution.select_branch("mechanical") and not game.evolution.activate_form(),"shared cooldown prevents route-switch bypass")
	state.evolution.form_cd=0;state.evolution.summon_cd=0
	check(game.evolution.activate_form() and game.evolution.activate_summon(),"mechanical pair activatable")
	game.player.invulnerable=0;state.hp=140;game.player.take_damage(20,-1)
	check(is_equal_approx(state.hp,126),"mechanical form reduces actual incoming damage 30 percent")
	check(game.evolution.damage_scale()==1.2 and game.evolution.speed_scale()==.9,"mechanical tradeoff applies")
	var ammo:int=state.ammo;var magazine:int=state.magazine;var before:float=target.hp;var actions:int=game.evolution.action_count
	await frames(150)
	check(game.evolution.action_count>actions and target.hp<before,"mechanical summon projectiles damage enemy")
	check(state.ammo==ammo and state.magazine==magazine,"energy summon spends no firearm ammo")
	# An opaque wall between the summon and a dummy must block its actual attack.
	game.evolution.set_physics_process(false)
	for child in game.world.get_children():
		if child.get_script()==game.ProjectileScript:child.queue_free()
	await frames(2)
	var wall:=StaticBody3D.new();wall.collision_layer=1;game.world.add_child(wall)
	var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(.4,8,5);shape.shape=box;wall.add_child(shape);wall.position=Vector3(8,2,0)
	game.evolution.summon_unit.position=Vector3(6,1,0);target.position=Vector3(10,0,0);game.evolution.target=target
	await frames(2);before=target.hp;actions=game.evolution.action_count
	check(not game.clear_sight(game.evolution.summon_unit.position,target.position+Vector3.UP),"wall fixture blocks line of sight")
	game.evolution.resolve_summon();await frames(12)
	check(target.hp==before and game.evolution.action_count==actions,"no summon fire through a solid wall")
	wall.queue_free();game.evolution.set_physics_process(true)
	var saved_cd:float=state.evolution.form_cd
	game.load_room("hub");await frames()
	check(game.evolution.form_left==0 and game.evolution.summon_left==0 and state.evolution.form_cd>saved_cd-1,"room change ends effects and preserves cooldown")
	state.evolution.form_cd=0;state.evolution.summon_cd=0;game.player.set_physics_process(false)
	game.evolution.activate_form();game.evolution.activate_summon();game.player.invulnerable=0;game.player.take_damage(999,1)
	check(state.hp==0 and game.evolution.form_left==0 and game.evolution.summon_unit==null,"death immediately clears transformation and summon")
	check(not game.evolution.activate_form() and not game.evolution.activate_summon(),"dead player cannot activate")
	state.respawn();game.load_room("hub");game.ui.close();await frames()
	check(state.evolution.form_cd>0 and not game.evolution.activate_form(),"respawn retains cooldown")
	# Persistence includes only cooldown/loadout, never active temporary objects.
	state.save_path="user://evolution_contract.json";state.persistence_enabled=true;state.save_game()
	var saved:Dictionary=SaveIO.read_best(state.save_path).data
	check(saved.evolution.branch=="mechanical" and not saved.evolution.has("form_left"),"save excludes temporary state")
	state.new_game();state.load_game();game.load_room("hub")
	check(state.skills.has("mechanical_summon") and state.evolution.branch=="mechanical" and state.evolution.form_cd>0,"skills loadout and cooldown survive reload")
	check(game.evolution.form_left==0 and game.evolution.summon_left==0,"load does not resurrect temporary effects")
	saved.erase("evolution");SaveIO.write(state.save_path,saved);state.load_game()
	check(state.evolution==Data.fresh() and state.skills.has("shadow_guard") and state.skills.has("core_shell"),"old saves keep learned passives and default new field safely")
	check(Data.sanitize({"branch":"bad","form_cd":"bad","summon_cd":-5})==Data.fresh(),"malformed cooldown data normalized")
	check(Data.sanitize({"form_cd":INF,"summon_cd":200}).summon_cd==22,"nonfinite and excessive cooldowns bounded")
	state.persistence_enabled=false
	# Keyboard actions and gamepad chords are exclusive with base skill/deploy actions.
	game.ui.close();game.player.position=Vector3(6,0,0);state.evolution=Data.fresh();await frames()
	Input.action_press("r_evolve");await frames(2);Input.action_release("r_evolve")
	check(game.evolution.form_left>0,"Z action triggers transformation in actor")
	Input.action_press("r_summon");await frames(2);Input.action_release("r_summon")
	check(game.evolution.summon_left>0,"V action triggers summon in actor")
	game.evolution.clear_runtime();state.evolution=Data.fresh();game.controls.gamepad=true;game.player.skill_cooldown=0
	Input.action_press("r_up");Input.action_press("r_skill");await frames(2);Input.action_release("r_skill");Input.action_release("r_up")
	check(game.evolution.form_left>0 and game.player.skill_cooldown==0,"Xbox up plus Y evolves without weapon skill")
	Input.action_press("r_up");Input.action_press("r_companion");await frames(2);Input.action_release("r_companion");Input.action_release("r_up")
	check(game.evolution.summon_left>0 and not state.squad.deployed,"Xbox up plus L3 summons without deploying robots")
	game.evolution.clear_runtime();state.evolution=Data.fresh();game.ui.open_pause()
	Input.action_press("r_evolve");Input.action_press("r_summon");await frames(2);game.ui.close();await frames(2)
	check(game.evolution.form_left==0 and game.evolution.summon_left==0,"held menu keys do not leak on close")
	Input.action_release("r_evolve");Input.action_release("r_summon");await frames(2)
	for branch in Data.BRANCHES:
		game.ui.skill_page="进化";game.ui.evolution_branch=branch;game.ui.skill_selection=branch+"_form";game.ui.open_skills();await frames()
		for id in Data.NODES[branch]:check(game.ui.panel.find_child("EvolutionNode_"+id,true,false)!=null,"selectable tree node "+id)
		check(is_instance_valid(game.ui.skill_preview),"animated evolution preview: "+branch)
	check("↑ + Y" in game.controls.prompt("Z 变身") and "↑ + L3" in game.controls.prompt("V 召唤"),"Xbox evolution prompts")
	game.controls.gamepad=false;check(game.controls.prompt("Z 变身 V 召唤")=="Z 变身 V 召唤","PC evolution prompts")
	state.new_game();check(state.evolution==Data.fresh(),"new game clears cooldowns and loadout")
	game.queue_free();await frames(4)
	print("EVOLUTION TESTS: ",checks," checks, ",failures," failures");quit(failures)
