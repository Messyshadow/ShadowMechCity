extends SceneTree
var game: Node3D
var state: Node
var failures:Array[String]=[]
var checks:=0

func _initialize() -> void:call_deferred("run")
func frames(n: int) -> void:
	for i in range(n):await physics_frame
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:failures.append(message);push_error("REVISION FAIL: "+message)
func clean_room(id := "hub") -> void:
	game.load_room(id);game.ui.close();game.transition_cooldown=0;game.player.invulnerable=100
	for enemy in game.enemies:
		if is_instance_valid(enemy):enemy.set_physics_process(false)

func run() -> void:
	state=root.get_node("Reforged");state.persistence_enabled=false;state.new_game()
	game=load("res://remaster/main.tscn").instantiate();root.add_child(game);current_scene=game;game.ui.close();await frames(15)
	# Weapon animation data must differ, rather than renaming one shared animation.
	for clip in ["blade_1","blade_2","blade_3","hammer_1","hammer_2","slam","gauntlet_1","gauntlet_2","gauntlet_3","gauntlet_4","air_blade","air_hammer","air_gauntlet","uppercut","reload","stairs","swim","wall_slide"]:
		check(game.player.anim.has_animation(clip),"imported action "+clip)
	var skeleton:Skeleton3D=game.player.visual.find_children("*","Skeleton3D",true,false)[0]
	var joint:=skeleton.find_bone("armR")
	game.player.set_physics_process(false)
	game.player.anim.play("gauntlet_1");game.player.anim.seek(.30,true)
	var punch:Quaternion=skeleton.get_bone_pose_rotation(joint)
	game.player.anim.play("hammer_1");game.player.anim.seek(.30,true)
	check(not punch.is_equal_approx(skeleton.get_bone_pose_rotation(joint)),"punch and hammer have different bone poses")
	clean_room();await frames(30)
	state.weapon=3;game.player.refresh_weapon();await frames(2)
	check(is_instance_valid(game.player.offhand_mesh),"gauntlets attach to both hands")
	state.weapon=0;game.player.refresh_weapon();await frames(2)
	check(not is_instance_valid(game.player.offhand_mesh),"switching away removes second gauntlet")
	# Upgrade cost, equipped stat propagation, cap, and exact sell/buyback round trip.
	state.coins=5000;var item:Dictionary=state.inventory[0];var uid:=int(item.uid)
	state.equip_item(uid);var armor_before:float=state.stat("armor");var money:int=state.coins
	var cost:int=state.upgrade_cost(item)
	check(state.upgrade_item(uid) and state.coins==money-cost,"upgrade debits its displayed price exactly")
	check(state.stat("armor")>armor_before and int(state.equipped.armor.upgrade)==1,"equipped upgrade updates actual combat stats")
	for i in range(4):state.upgrade_item(uid)
	money=state.coins
	check(not state.upgrade_item(uid) and state.coins==money,"enhancement cap does not charge coins")
	state.equipped.clear();var enhanced:Dictionary=item.duplicate(true)
	check(state.sell(uid) and state.repurchase(uid),"enhanced item may be sold and repurchased")
	check(state.inventory.back()==enhanced,"buyback preserves enhanced stats and identity")
	state.coins=0;var before:Dictionary=state.inventory[0].duplicate(true)
	check(not state.upgrade_item(int(before.uid)) and state.inventory[0]==before,"insufficient funds leave item untouched")
	# Collision-driven locomotion: cross the real floor and pits in each normal room.
	var traversal_failures:Array[String]=[]
	for id in Rooms.ROOMS:
		if Rooms.ROOMS[id].has("boss"):continue
		clean_room(id);game.player.position=Vector3(2,.1,0);state.hp=state.max_health()
		await frames(10)
		var target:float=game.room_width-2.0
		var start_id:String=game.room_id
		Input.action_press("r_right")
		for frame in range(600):
			if frame%38==0:Input.action_press("r_jump")
			if frame%38==20:Input.action_release("r_jump")
			await frames(1)
			if game.room_id!=start_id or game.player.death_time>0:break
			if game.player.position.x>=target:break
		Input.action_release("r_right");Input.action_release("r_jump")
		var reached:bool=game.room_id==start_id and game.player.position.x>=target-.3
		if not reached:traversal_failures.append(id+" "+str(game.player.position))
		check(reached,"physical left-to-right route "+id)
	print("ROUTE FAILURES ",traversal_failures)
	# Stairs must actually move horizontally and support backing out midway.
	clean_room("temple");await frames(5)
	var stairs:Dictionary={}
	for l in game.ladders:
		if l.kind=="stairs":stairs=l;break
	check(not stairs.is_empty(),"temple has a physical stair entrance")
	game.player.position=Vector3(stairs.x,.1,0)
	Input.action_press("r_down");await frames(22);Input.action_release("r_down")
	check(game.player.climbing and absf(game.player.position.x-float(stairs.x))>.5,"stairs move horizontally while descending")
	Input.action_press("r_up");await frames(28);Input.action_release("r_up")
	check(game.room_id=="temple" and not game.player.climbing and game.player.position.y>=0,"stair descent may be cancelled by walking back up")
	# Delayed attack timing, pause consistency, aerial evasion, and cleanup.
	clean_room();game.player.position=Vector3(6,.1,0);await frames(20);game.player.invulnerable=0;state.hp=state.max_health()
	game.schedule_strike(Vector3(6,0,0),3,.35,21,Color.ORANGE,"test")
	game.ui.open_inventory();await frames(45)
	check(state.hp==state.max_health() and game.strikes.size()==1,"menu pauses scheduled attack and damage")
	check(is_instance_valid(game.strikes[0].node),"warning marker remains visible while paused")
	game.ui.close();await frames(30)
	check(state.hp<state.max_health() and game.strikes.is_empty(),"attack resumes and resolves after closing menu")
	game.player.invulnerable=0;state.hp=state.max_health();game.player.position.y=2.5;game.player.velocity=Vector3.ZERO;game.player.lock_input=true
	game.schedule_strike(Vector3(6,0,0),3,.10,21,Color.ORANGE,"test");await frames(12)
	check(state.hp==state.max_health(),"jumping above a ground shockwave avoids damage")
	game.player.lock_input=false
	# Exercise every new signature attack through actual runtime effects.
	var attacks:={"boss":["furnace"],"temple_sanctum":["rune"],"mine_boss":["rocks"],"water_boss":["bite","tail","tide"],"void_throne":["dive"],"castle_knights":["lunge","combo"],"castle_throne":["rift"]}
	for id in attacks:
		for attack in attacks[id]:
			clean_room(id);await frames(4)
			var enemy:Node3D=game.boss;enemy.attack_id=attack;enemy.target_x=game.player.position.x;enemy.direction=-1
			var count:int=enemy.attack_count;enemy.execute_attack()
			check(enemy.attack_count==count+1,"signature executes "+attack)
			if attack in ["furnace","rune","rocks","tail","combo","rift"]:
				check(not game.strikes.is_empty(),"signature creates timed warnings "+attack)
				enemy.dead=true;game.boss_defeated(enemy)
				check(game.strikes.is_empty(),"boss death removes pending damage "+attack)
				state.bosses.clear();game.ui.close()
			elif attack=="dive":check(enemy.state=="leap" and enemy.velocity.y>0,"dragon dive includes airborne movement")
	# Enhanced item schema remains compatible with the established save file format.
	state.save_path="user://remaster_revision_test.json";state.persistence_enabled=true;state.save_game()
	var inventory_copy:Array=state.inventory.duplicate(true);state.inventory.clear()
	var loaded:bool=state.load_game()
	var serialized_before:=JSON.stringify(inventory_copy)
	var serialized_after:=JSON.stringify(state.inventory)
	check(loaded and serialized_before==serialized_after,"enhancement survives save and reload")
	state.persistence_enabled=false
	for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(state.save_path+suffix)
	state.save_path=state.SAVE
	print("REVISION TESTS: ",checks," checks; ",failures.size()," failures")
	game.queue_free();await frames(3);quit(0 if failures.is_empty() else 1)
