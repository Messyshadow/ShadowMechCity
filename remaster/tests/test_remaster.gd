extends SceneTree
var failures: Array[String]=[]
var checks:=0
var game: Node3D
var state: Node

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks+=1
	if not condition:failures.append(message);push_error("FAIL: "+message)

func frames(count: int) -> void:
	for i in range(count):await physics_frame

func run() -> void:
	state=root.get_node("Reforged");state.persistence_enabled=false;state.new_game()
	check(state.max_health()==120,"new hunter has extra starting health")
	check(state.first_trade(),"merchant gift awarded on first conversation")
	check(not state.first_trade(),"merchant gift cannot be duplicated")
	check(state.stat("lifesteal")==.03,"gift is equipped and grants 3 percent lifesteal")
	var gift_uid:int=state.equipped.amulet.uid
	check(not state.sell(gift_uid),"equipped item cannot accidentally be sold")
	var first:Dictionary=state.inventory[0].duplicate(true)
	var coins:int=state.coins
	check(state.sell(int(first.uid)),"can sell unused armor")
	check(state.coins==coins+int(first.price),"sale credits exact price")
	check(state.buyback.size()==1,"sale creates dedicated buyback record")
	check(state.repurchase(int(first.uid)),"can repurchase sold item")
	check(state.coins==coins and state.inventory.back()==first,"repurchase restores exact UID and stats")
	check(not state.repurchase(int(first.uid)),"repurchase cannot duplicate item")
	check(not state.learn("gauntlet_3"),"skill prerequisite enforced")
	check(state.learn("gauntlet_1") and state.learn("gauntlet_2"),"gauntlet branch learns in order")
	state.points=3;check(state.learn("gauntlet_3"),"gauntlet overdrive unlocks")
	state.coins=0;var stock:int=state.ammo
	check(not state.buy("ammo") and state.ammo==stock,"insufficient funds do not create ammunition")
	# Real save/reload round trip in an isolated test file.
	state.save_path="user://remaster_qa_test.json";state.persistence_enabled=true
	state.sell(int(first.uid))
	state.rest("mine",Vector3(3.75,.08,0));state.coins=243;state.save_game()
	state.coins=0;state.checkpoint_room="hub"
	check(state.load_game() and state.coins==243 and state.checkpoint_room=="mine","persistent save roundtrip keeps economy and checkpoint")
	check(state.buyback.size()==1 and int(state.buyback[0].uid)==int(first.uid),"buyback item survives save and reload")
	check(state.repurchase(int(first.uid)),"saved buyback item can be purchased after restart")
	state.persistence_enabled=false
	for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(state.save_path+suffix)
	state.save_path=state.SAVE;state.new_game()
	game=load("res://remaster/main.tscn").instantiate();root.add_child(game);current_scene=game
	game.ui.close();await frames(3)
	var required:=["idle","run","jump","fall","attack1","attack2","attack3","shoot","climb","dash","hurt","death","skill"]
	for id in required:check(game.player.anim.has_animation(id),"Blender animation imported: "+id)
	var queue:Array=["hub"];var seen:Dictionary={"hub":true}
	while not queue.is_empty():
		var id:String=queue.pop_front()
		for d in Rooms.ROOMS[id].get("doors",[]):
			check(Rooms.ROOMS.has(str(d.to)),"valid destination: "+id+" > "+str(d.to))
			if not seen.has(str(d.to)):seen[str(d.to)]=true;queue.append(str(d.to))
	check(seen.size()==Rooms.ROOMS.size(),"all original rooms are connected to central station")
	for id in Rooms.ROOMS:
		game.load_room(id)
		game.player.invulnerable=100
		state.hp=state.max_health()
		await frames(2)
		check(is_instance_valid(game.player) and game.world.get_child_count()>20,"3D room builds: "+id)
		for d in game.doors:
			if d.side in ["up","down"]:
				var found:=false
				for l in game.ladders:
					if str(l.door.to)==str(d.to):found=true
				check(found,"physical shaft for "+id+" > "+str(d.to))
		if Rooms.ROOMS[id].has("boss"):
			print("TEST BOSS ",id," spawn=",game.player.position)
			check(is_instance_valid(game.boss),"3D boss spawns: "+id)
			game.boss.timer=0;game.boss.position=game.player.position+Vector3(4,0,0)
			await frames(150)
			if not is_instance_valid(game.boss):
				check(false,"boss disappeared in "+id+" now "+game.room_id);continue
			check(game.boss.attack_count>0,"boss AI executes telegraphed attack: "+id)
			game.boss.hp=game.boss.max_hp*.4;await frames(2)
			check(game.boss.phase==2,"boss enters phase two: "+id)
	# Actual key-driven forward and reverse travel, including reported void deck.
	game.load_room("hub");game.ui.close();await frames(75)
	var up:Dictionary={}
	for d in game.doors:
		if str(d.to)=="void_deck":up=d
	game.player.position=Vector3(float(up.x),.1,0)
	Input.action_press("r_up");await frames(165);Input.action_release("r_up")
	check(game.room_id=="void_deck","holding W rides central lift into void deck")
	await frames(70)
	var down:Dictionary={}
	for d in game.doors:
		if str(d.to)=="hub":down=d
	if not down.is_empty():
		game.player.position=Vector3(float(down.x),.1,0)
		Input.action_press("r_down");await frames(115);Input.action_release("r_down")
	check(game.room_id=="hub","holding S returns from void deck to central station")
	# Every shaft, including ladders and endpoint entry after an accidental drop.
	for id in ["temple_sanctum","mine_boss","water_boss","boss","void_throne","castle_knights","castle_throne"]:state.bosses[id]=true
	for id in Rooms.ROOMS:
		for d in Rooms.ROOMS[id].get("doors",[]):
			game.load_room(id);game.ui.close();game.player.invulnerable=100;game.transition_cooldown=0
			game.player.position=Vector3(game.door_x(d),.1,0)
			if str(d.side) in ["left","right"]:
				Input.action_press("r_interact");await frames(35);Input.action_release("r_interact")
				check(game.room_id==str(d.to),"key-driven horizontal doorway: "+id+" > "+str(d.to))
				continue
			var action:="r_up" if d.side=="up" else "r_down"
			Input.action_press(action);await frames(165 if d.side=="up" else 115);Input.action_release(action)
			check(game.room_id==str(d.to),"key-driven shaft traversal: "+id+" > "+str(d.to))
	state.bosses.clear()
	game.load_room("void_deck");game.transition_cooldown=0;game.player.invulnerable=100
	for d in game.doors:
		if d.side=="down":game.player.position=Vector3(d.x,-3.14,0)
	Input.action_press("r_down");await frames(45);Input.action_release("r_down")
	check(game.room_id=="hub","down input at bottom of shaft still exits after falling in")
	# Jump buffering, airborne attack, limited ammunition and death checkpoint.
	game.player.position=Vector3(9,.1,0);await frames(25)
	Input.action_press("r_jump");await frames(4);Input.action_release("r_jump");await frames(10)
	check(game.player.position.y>.3,"jump input produces upward movement")
	Input.action_press("r_attack");await frames(2);Input.action_release("r_attack")
	check(game.player.attack_time>0,"airborne melee attack starts")
	await frames(30);state.weapon=2;state.magazine=1;state.ammo=0
	game.player.begin_attack(false);check(state.magazine==0,"ranged attack consumes one cartridge")
	await frames(30);game.player.begin_attack(false);check(game.player.attack_time<=0,"empty weapon cannot fire")
	state.rest("hub",Vector3(4.5,.1,0));game.load_room("mine")
	game.player.invulnerable=0;game.player.take_damage(999,0);await frames(95)
	check(game.room_id=="hub" and game.player.position.x<6,"death returns to activated save room, not current room")
	check(state.hp==state.max_health(),"checkpoint respawn restores health")
	# UI integration in real scene tree.
	for method in ["open_inventory","open_skills","open_map","open_shop","open_pause","open_title"]:
		game.ui.call(method);await frames(2);check(game.ui.panel_open,"panel opens: "+method);game.ui.close()
	game.ui.open_map();await frames(2)
	game.ui.map_view.set_zoom(99);check(game.ui.map_view.zoom<=1.7,"map zoom clamps upper bound")
	game.ui.map_view.set_zoom(.01);check(game.ui.map_view.zoom>=.32,"map zoom clamps lower bound")
	game.ui.close()
	print("REMASTER TESTS: ",checks," checks; ",failures.size()," failures; ",Rooms.ROOMS.size()," rooms")
	game.queue_free();await frames(3)
	quit(0 if failures.is_empty() else 1)
