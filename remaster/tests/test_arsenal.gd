extends SceneTree
const Data=preload("res://remaster/squad_data.gd")
const SaveIO=preload("res://remaster/save_io.gd")
var state:Node
var game:Node3D
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func frames(n:int) -> void:
	for i in range(n):await physics_frame
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures.append(message);push_error("ARSENAL FAIL: "+message)
func arrange(weapon:int) -> Node3D:
	state.weapon=weapon;game.load_room("hub");game.ui.close();game.player.position=Vector3(8,.05,0);game.player.facing=1;game.player.invulnerable=100
	var enemy:Node3D=game.spawn_enemy("warden",Vector3(9.3,.05,0));enemy.set_physics_process(false);enemy.facing=-1;enemy.hp=5000;enemy.max_hp=5000
	return enemy
func strike(special:=false) -> void:
	Input.action_press("r_skill" if special else "r_attack");await frames(2);Input.action_release("r_skill" if special else "r_attack");await frames(35)
func run() -> void:
	state=root.get_node("Reforged");state.persistence_enabled=false;state.new_game()
	game=load("res://remaster/main.tscn").instantiate();root.add_child(game);current_scene=game;game.ui.close();await frames(10)
	check(state.WEAPONS.size()==7 and state.SKILLS.size()==33,"seven families and 33 actual skill nodes")
	for id in ["dual_1","dual_2","dual_3","dual_4","air_dual","spear_1","spear_2","spear_3","air_spear","crossbow_shoot"]:
		check(game.player.anim.has_animation(id),"Blender clip imported: "+id)
	state.points=20
	for family in ["dual","spear","crossbow"]:
		check(not state.learn(family+"_3"),"new branch enforces prerequisite "+family)
		for tier in range(1,4):check(state.learn(family+"_"+str(tier)),"new skill learnable "+family+str(tier))
	var enemy:Node3D=arrange(4);await frames(10)
	check(is_instance_valid(game.player.offhand_mesh),"dual blades attach to both hands")
	for i in range(4):await strike()
	check(game.player.combo==3 and enemy.hp<4980,"four dual inputs damage target and reach fourth combo")
	enemy=arrange(4);enemy.facing=1;await frames(10);await strike(true)
	check(5000-enemy.hp>state.attack_damage()*3,"dual special applies multiple timed strikes")
	enemy=arrange(5);enemy.position.x=11.4;await frames(10);await strike()
	check(is_equal_approx(5000-enemy.hp,state.attack_damage()),"spear reaches distant shield and bypasses frontal armor")
	check(enemy.stun>0,"spear break skill applies extended stagger")
	enemy=arrange(5);enemy.position.x=13.3;await frames(10);await strike(true)
	check(enemy.hp<5000,"spear special reaches six metres")
	enemy=arrange(5);enemy.position.x=11.4
	game.solid(Vector3(9.8,1.5,0),Vector3(.3,3,2.5));await frames(10);await strike(true)
	check(enemy.hp==5000,"spear cannot stab through solid geometry")
	enemy=arrange(6);enemy.facing=1;enemy.position.x=10.5
	var second:Node3D=game.spawn_enemy("sentry",Vector3(12,.05,0));second.set_physics_process(false);second.hp=5000;state.magazine=8;await frames(10);await strike();await frames(15)
	check(enemy.hp<5000 and second.hp<5000 and state.magazine==7,"piercing crossbow damages aligned targets for one round")
	state.magazine=0;state.ammo=0;await strike();check(game.player.attack_time<=0 and state.magazine==0,"empty crossbow cannot fire")
	state.magazine=8;game.player.skill_cooldown=0;await strike(true);check(state.magazine==5,"crossbow special spends three rounds")
	state.weapon=6;Input.action_press("r_swap");await frames(2);Input.action_release("r_swap");check(state.weapon==0,"seven-family cycling wraps to first weapon")
	for family in range(4,7):
		game.ui.skill_page="战斗";game.ui.skill_family=family;game.ui.open_skills();await frames(3)
		check(game.ui.preview_family==state.WEAPONS[family] and game.ui.skill_preview.is_playing(),"new branch has model and animated preview "+str(family))
	game.ui.close();state.new_game();game.load_room("hub");game.ui.close();await frames(10)
	state.points=1;check(not state.expand_squad() and state.squad.slots==1,"insufficient points cannot unlock a slot")
	state.points=5;check(state.expand_squad() and state.points==3 and state.squad.slots==2,"second slot costs two points")
	check(state.expand_squad() and state.points==0 and state.squad.slots==3,"third slot costs three points")
	check(not state.expand_squad(),"capacity stops at three")
	check(state.assign_companion("mole") and state.assign_companion("bee"),"distinct ground and air roles can form a squad")
	check(not state.assign_companion("wisp") and state.squad.loadout.size()==3,"full squad rejects a fourth member")
	var invalid:Dictionary=Data.fresh();invalid.loadout=["hound","hound"];invalid.slots=2;check(not Data.valid(invalid),"duplicate model identity is rejected by save validation")
	Input.action_press("r_companion");await frames(2);Input.action_release("r_companion");await frames(10)
	check(state.squad.deployed and game.companions.units.size()==3,"C deploys actual three-unit formation")
	var hound:Node3D=game.companions.units.hound;var mole:Node3D=game.companions.units.mole;var bee:Node3D=game.companions.units.bee
	check(bee.position.y>1 and hound.position.y<.5,"air and ground roles occupy different heights")
	check(is_equal_approx(game.companions.power_scale(),.72),"three companions share the lower damage budget")
	hound.take_damage(20);mole.take_damage(20)
	check(hound.status().hp==40 and mole.status().hp==84,"companions own HP and shield companion mitigates damage")
	game.ui.open_companions();await frames(2);var before:float=hound.cooldown;await frames(40)
	check(hound.cooldown==before and game.ui.panel_kind=="companions","roster menu freezes combat timing")
	game.ui.close();hound.invulnerable=0;hound.take_damage(999)
	check(hound.status().hp==0 and hound.status().rebuild==12,"destroyed companion enters twelve-second reconstruction")
	game.companions.toggle();game.companions.toggle();hound=game.companions.units.hound;await frames(3)
	check(hound.status().hp==0 and hound.status().rebuild>11,"recall/redeploy cannot reset destroyed companion")
	var remaining:float=hound.status().rebuild;game.load_room("temple");game.ui.close();await frames(3)
	for e in game.enemies:e.set_physics_process(false)
	hound=game.companions.units.hound
	check(hound.status().hp==0 and hound.status().rebuild<remaining and hound.status().rebuild>remaining-.2,"room changes preserve reconstruction state")
	game.load_room("hub");game.ui.close();await frames(730)
	hound=game.companions.units.hound;check(hound.status().hp==60 and hound.status().rebuild==0,"reconstruction restores companion after elapsed gameplay time")
	game.player.position=Vector3(8,.05,0);hound.position=Vector3(6,.1,0);hound.set_physics_process(false);hound.invulnerable=0
	for id in ["mole","bee"]:game.companions.units[id].position=Vector3(20,3,0);game.companions.units[id].set_physics_process(false)
	game.projectile(Vector3(4,.6,0),Vector3(12,0,0),10,false,Color.RED);await frames(15)
	check(hound.status().hp==50,"hostile projectile actually damages and is intercepted by companion")
	for id in ["mole","bee"]:game.companions.units[id].set_physics_process(true)
	hound.set_physics_process(true);game.player.position=Vector3(8,.05,0)
	enemy=game.spawn_enemy("sentry",Vector3(10,.05,0));enemy.set_physics_process(false);enemy.hp=5000;enemy.max_hp=5000
	await frames(220)
	check(enemy.hp<5000 and hound.action_count>0,"companion AI acquires nearby threat and lands delayed attack")
	for unit in game.companions.units.values():unit.set_physics_process(false)
	hound.position=Vector3(10,.05,0);hound.invulnerable=0;var hp:float=hound.status().hp
	enemy.position=Vector3(9,.05,0);enemy.direction=1;enemy.attack_id="melee";enemy.execute_attack()
	check(hound.status().hp<hp,"enemy melee attacks damage nearby ground companion")
	for i in range(10):game.companions.action_committed()
	check(state.squad.lock>0,"repeated coordinated attacks trigger overload lock")
	state.squad.heat=0;state.squad.lock=0;game.companions.toggle();state.squad.loadout=["wisp"];game.companions.toggle();await frames(3)
	var wisp:Node3D=game.companions.units.wisp;wisp.cooldown=0;state.hp=60;await frames(40)
	check(state.hp==64 and wisp.action_count==1,"repair companion heals only after its visible windup")
	state.hp=0;wisp.cooldown=0;await frames(40);check(state.hp==0,"support cannot heal a defeated hunter")
	state.hp=60;game.player.position=Vector3(8,.05,0);wisp.position=Vector3(80,2,0);await frames(2)
	check(wisp.position.distance_to(game.player.position)<4,"offscreen companion safely returns to player")
	# Exercise combined enemy/companion AI with every boss, including phase two.
	for room in game.BOSS_MODELS:
		state.squad=Data.fresh();state.squad.slots=3;state.squad.loadout=["hound","mole","bee"];state.squad.deployed=true
		game.load_room(room);game.ui.close();game.player.position=game.boss.position-Vector3(3.5,0,0);game.player.invulnerable=100
		game.boss.max_hp=1000;game.boss.hp=450;await frames(600)
		check(game.boss.hp<450,"three companions land attacks against boss "+room)
		check(game.companions.units.size()<=3 and Data.valid(state.squad),"boss stress preserves valid bounded squad "+room)
	state.squad=Data.fresh();state.squad.loadout=["wisp"];state.squad.deployed=true;game.load_room("hub");game.ui.close();state.weapon=6
	state.save_path="user://arsenal_save_test.json";state.persistence_enabled=true;state.weapon=6
	check(state.save_game(),"expanded arsenal and squad snapshot saves")
	state.new_game();check(state.load_game() and state.weapon==6 and state.squad.loadout==["wisp"] and state.squad.deployed,"weapon, formation and deployment survive load")
	var old:Dictionary=SaveIO.read_file(state.save_path);old.erase("squad")
	var file:=FileAccess.open(state.save_path,FileAccess.WRITE);file.store_string(JSON.stringify(old));file.close()
	check(state.load_game() and state.squad.loadout==["hound"] and not state.squad.deployed,"pre-companion remaster save migrates without changing other progress")
	for suffix in ["",".bak",".tmp",".old"]:
		var path:String=state.save_path+str(suffix)
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	state.persistence_enabled=false;state.save_path=state.SAVE;game.queue_free();await frames(4)
	print("ARSENAL TESTS: ",checks," checks; ",failures.size()," failures");quit(0 if failures.is_empty() else 1)
