extends SceneTree
const Data=preload("res://remaster/exploration_data.gd")
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
	if not ok:failures+=1;push_error("EXPLORATION FAIL: "+message)
func run() -> void:
	state=root.get_node("Reforged");state.persistence_enabled=false;state.new_game()
	game=load("res://remaster/main.tscn").instantiate();root.add_child(game);current_scene=game;await frames()
	check(Data.count(state,"heart")==Vector2i(0,6),"six original life fragments")
	check(Data.count(state,"memory")==Vector2i(0,7),"seven named original archives")
	check(Data.count(state,"module")==Vector2i(0,5),"five original exploration modules")
	check(Data.count(state,"supply")==Vector2i(0,8),"eight regional supply caches")
	check(Data.has_module(state,"dash") and Data.has_module(state,"double_jump"),"baseline movement available")
	check(not Data.collect(state,"not_real") and state.collected.is_empty(),"unknown reward refused")
	state.hp=0;check(Data.collect(state,"heart_hub").is_empty(),"dead player cannot collect and revive");state.hp=50
	check(not Data.collect(state,"heart_hub").is_empty() and state.max_health()==130 and state.hp==60,"fragment permanently grows max HP and grants only 10 health")
	check(Data.collect(state,"heart_hub").is_empty() and state.max_health()==130,"fragment cannot be duplicated")
	state.ammo=120;state.potions=9
	check(Data.collect(state,"supply_hub").is_empty() and not state.collected.has("supply_hub"),"full inventory leaves supply cache intact")
	state.ammo=117
	check(not Data.collect(state,"supply_hub").is_empty() and state.ammo==120 and state.potions==9,"partial capacity caps ammo without potion overflow")
	state.ammo=0;check(Data.collect(state,"supply_hub").is_empty() and state.ammo==0,"supply cache cannot be farmed")
	state.potions=0;Data.collect(state,"supply_mine");check(state.ammo==24 and state.potions==1,"supply grants configured quantities")
	var initial_coins:int=state.coins;var initial_items:int=state.inventory.size()
	var chest_id:=""
	for id in Data.catalog():
		if Data.catalog()[id].kind=="chest":chest_id=id;break
	Data.collect(state,chest_id);Data.collect(state,chest_id)
	check(state.coins==initial_coins+55 and state.inventory.size()==initial_items+1,"legacy chest one-time equipment reward")
	Data.collect(state,"memory_hub_archive")
	check(Data.count(state,"memory").x==1 and Data.Archives.COLLECTIBLES.memory_hub_archive.title=="零号班次","original archive lore recorded")
	check(not game.gate_reason("secret_mine_cache").is_empty(),"fresh secret gate requires modules")
	for module in ["bomb","wall_climb","glide","aqua","shadow_glider"]:
		check(not Data.has_module(state,module),"module initially absent: "+module)
		Data.collect(state,"module_"+module)
		check(Data.has_module(state,module),"module collection enables: "+module)
	for id in Data.World.ROOMS:
		if Data.World.ROOMS[id].get("hidden_room",false):check(game.gate_reason(id).is_empty(),"all modules open secret: "+id)
	state.new_game();state.visited.secret_castle_ossuary=true
	check(game.gate_reason("secret_castle_ossuary").is_empty(),"previously visited secret remains accessible after update")
	state.skills.water_drive=true;check(Data.has_module(state,"aqua"),"existing water skill satisfies aquatic gates")
	state.skills.glide=true;check(Data.has_module(state,"glide"),"existing glide skill retained")
	state.skills.wall_drive=true;check(Data.has_module(state,"wall_climb"),"existing wall skill satisfies optional gates")
	state.skills.clear()
	for id in Data.World.ROOMS:
		game.load_room(id);await frames(1)
		for pickup in game.pickups:
			check(is_instance_valid(pickup.node) and is_instance_valid(pickup.label),"visible pickup: "+pickup.id)
			check(pickup.pos.x>=2 and pickup.pos.x<=game.room_width-2 and pickup.pos.y<7,"reward inside reachable height bounds: "+pickup.id)
		game.ui.close()
	state.new_game();game.load_room("temple");game.ui.close();game.player.set_physics_process(false);game.set_physics_process(false);await frames()
	check(game.exploration.seals.size()==1,"original temple heart protected by seal")
	if game.exploration.seals.size()==1:
		var seal:Dictionary=game.exploration.seals[0];var id:String=seal.id
		game.player.position=seal.pos;game.exploration.tick(.01)
		check(not state.collected.has(id),"locked fragment cannot be touched through seal")
		check(not game.exploration.throw_bomb(),"bomb requires module")
		Data.collect(state,"module_bomb")
		game.player.position=Vector3(6,0,0)
		check(game.exploration.throw_bomb() and game.exploration.bombs.size()==1,"bomb spawned")
		check(not game.exploration.throw_bomb(),"bomb cooldown prevents spam")
		game.ui.open_pause();var remaining:float=game.exploration.bombs[0].time;await frames(20)
		check(is_equal_approx(game.exploration.bombs[0].time,remaining),"paused bomb fuse frozen")
		game.ui.close();game.exploration.detonate(seal.pos);await frames()
		check(game.exploration.seals.is_empty() and state.collected.get("seal_"+id,false),"blast removes seal persistently")
		game.player.position=seal.pos;game.exploration.tick(.01)
		check(state.collected.get(id,false) and state.max_health()==130,"unsealed fragment collectable")
		game.load_room("temple");await frames()
		check(game.exploration.seals.is_empty() and not game.pickups.any(func(p):return p.id==id),"seal and fragment remain gone on revisit")
	# Real fixed-frame projectile flight, enemy damage, range and world collision.
	game.load_room("hub");game.ui.close();game.player.set_physics_process(false);game.set_physics_process(false);game.player.position=Vector3(6,0,0);game.player.facing=1;await frames()
	var target:Node3D=game.spawn_enemy("sentry",Vector3(11,0,0));target.set_physics_process(false);target.max_hp=200;target.hp=200
	var distant:Node3D=game.spawn_enemy("sentry",Vector3(23,0,0));distant.set_physics_process(false);var distant_hp:float=distant.hp
	check(game.exploration.throw_bomb(),"new room resets discarded bomb cooldown")
	for i in range(75):game.exploration.tick(1.0/60);await physics_frame
	check(game.exploration.bombs.is_empty(),"bomb detonates after fuse")
	game.exploration.detonate(target.position+Vector3.UP*.8)
	check(target.hp<200 and distant.hp==distant_hp,"blast damages nearby enemy only")
	# Save/load uses existing schema and doesn't inflate fragment health on repeated loads.
	var original_path:String=state.save_path;state.save_path="user://exploration_test_save.json";state.persistence_enabled=true
	Data.collect(state,"memory_hub_archive");state.save_game();var saved_hp:float=state.max_health()
	state.new_game();check(state.load_game() and state.max_health()==saved_hp and Data.count(state,"memory").x==1,"collections survive disk round trip")
	check(state.load_game() and state.max_health()==saved_hp,"loading twice does not add health twice")
	for suffix in ["",".tmp",".bak",".old"]:
		if FileAccess.file_exists(state.save_path+suffix):DirAccess.remove_absolute(state.save_path+suffix)
	state.persistence_enabled=false;state.save_path=original_path
	game.ui.open_collection("记忆档案");await frames();check(game.ui.panel_kind=="collection","archive panel opens")
	game.ui.open_collection("探索模块");await frames();check(game.ui.controller_focusables().size()>=4,"module page keyboard/controller navigation")
	game.controls.register_device(0,"Xbox Controller",{});check(game.controls.prompt("F 投掷 / F11 全屏")=="↓ + Y 投掷 / F11 全屏","bomb prompt changes without corrupting F11")
	game.ui.controller_button(JOY_BUTTON_B);check(game.ui.panel_kind=="journal","controller back returns to journal")
	game.ui.open_collection("探索模块");await frames()
	var cards:Array=game.ui.panel.find_children("*","Button",true,false)
	for card in cards:
		if card.tooltip_text=="暗影滑翔翼":card.grab_focus()
	await frames(8)
	var scroll:ScrollContainer=game.ui.panel.find_children("*","ScrollContainer",true,false)[0]
	check(scroll.scroll_vertical>0,"last module can be reached by focus scrolling")
	# Exercise the new action through actual mapped keyboard and Xbox events.
	game.load_room("hub");game.ui.close();game.player.position=Vector3(4,0,0);game.player.invulnerable=100;game.set_physics_process(true);game.player.set_physics_process(true);await frames(5)
	var key:=InputEventKey.new();key.physical_keycode=KEY_F;key.keycode=KEY_F;key.pressed=true;Input.parse_input_event(key);await frames(2)
	check(game.exploration.bombs.size()==1,"F input actually throws bomb")
	key.pressed=false;Input.parse_input_event(key);await frames(220)
	for code in [JOY_BUTTON_DPAD_DOWN,JOY_BUTTON_Y]:
		var event:=InputEventJoypadButton.new();event.device=0;event.button_index=code;event.pressed=true;Input.parse_input_event(event)
	await frames(2)
	check(game.exploration.bombs.size()==1 and game.player.attack_time<=0 and game.player.skill_cooldown<=0,"Xbox down plus Y throws without firing weapon skill")
	for code in [JOY_BUTTON_DPAD_DOWN,JOY_BUTTON_Y]:
		var event:=InputEventJoypadButton.new();event.device=0;event.button_index=code;event.pressed=false;Input.parse_input_event(event)
	await frames()
	# No teleport to reward height: jump twice from the floor, then steer onto the shelf.
	state.new_game();game.load_room("hub");game.ui.close();game.player.invulnerable=100
	var heart:Dictionary={}
	for pickup in game.pickups:
		if pickup.id=="heart_hub":heart=pickup
	game.player.position=Vector3(heart.pos.x-3,0,0);await frames(5)
	Input.action_press("r_jump");await frames(20);Input.action_release("r_jump");await frames(2)
	Input.action_press("r_jump");await frames(14);Input.action_press("r_right");await frames(25)
	Input.action_release("r_jump");Input.action_release("r_right");await frames(10)
	check(state.collected.get("heart_hub",false),"baseline double jump reaches the new hub reward from the floor")
	state.new_game();state.ammo=0;state.magazine=0;state.potions=0;state.hp=1
	var money:int=state.coins;state.rest("hub",Vector3(4,0,0))
	check(state.hp==state.max_health() and state.magazine==8 and state.ammo==24 and state.potions==3 and state.coins==money,"checkpoint offers free full health, magazine and minimum supply")
	state.rest("hub",Vector3(4,0,0));check(state.ammo==24 and state.potions==3,"repeated rest doesn't accumulate reserves")
	state.ammo=90;state.potions=8;state.rest("hub",Vector3(4,0,0));check(state.ammo==90 and state.potions==8,"checkpoint does not discard supplies above floor")
	state.ammo=0;money=state.coins;check(state.buy("ammo") and state.ammo==24 and state.coins==money-25,"merchant charges 25 game coins for 24 rounds")
	state.ammo=120;money=state.coins;check(not state.buy("ammo") and state.coins==money,"full reserve does not charge at merchant")
	state.ammo=0;state.reward();check(state.ammo==1,"ordinary enemy drops one round")
	state.skills.cannon_2=true;state.reward();check(state.ammo==4,"recycling increases ordinary drop to three")
	state.reward(true);check(state.ammo==10,"boss drops six rounds even with recycling")
	state.ammo=119;state.reward(true);check(state.ammo==120,"combat rewards respect reserve cap")
	game.queue_free();await frames();print("EXPLORATION TESTS: ",checks," checks; ",failures," failures");quit(1 if failures else 0)
