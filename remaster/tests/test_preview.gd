extends SceneTree
const SaveIO=preload("res://remaster/save_io.gd")
const TEST_SAVE="user://preview_save_test.json"
var state:Node
var game:Node3D
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func frames(count:int) -> void:
	for i in range(count):await physics_frame
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures.append(message);push_error("PREVIEW FAIL: "+message)
func put(path:String,value:String) -> void:
	var file:=FileAccess.open(path,FileAccess.WRITE);file.store_string(value);file.close()
func clean() -> void:
	for suffix in ["",".bak",".tmp",".old",".bak.tmp",".bak.old"]:
		var path:String=TEST_SAVE+str(suffix)
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
func strike() -> void:
	game.player.attack_time=0;game.player.combo_window=0;game.player.hit_pause=0
	Input.action_press("r_attack");await frames(2);Input.action_release("r_attack");await frames(30)
func run() -> void:
	state=root.get_node("Reforged");state.persistence_enabled=false;state.new_game();clean()
	state.save_path=TEST_SAVE;state.persistence_enabled=true;state.coins=246;state.story.intro_seen=true
	check(state.save_game(),"new snapshot is written and validated")
	var baseline:Dictionary=SaveIO.read_file(TEST_SAVE)
	state.coins=357;check(state.save_game(),"second generation is committed")
	check(int(SaveIO.read_file(TEST_SAVE+".bak").coins)==246,"backup retains prior valid generation")
	put(TEST_SAVE,"{incomplete")
	state.coins=0;check(state.load_game() and state.coins==246,"truncated primary restores whole backup")
	check(not state.save_blocked and not state.save_notice.is_empty(),"backup recovery is reported")
	check(state.save_game() and int(SaveIO.read_file(TEST_SAVE+".bak").coins)==246,"recovery save does not replace good backup with broken primary")
	for key in ["checkpoint","inventory","equipped","hp","story"]:
		var invalid:Dictionary=baseline.duplicate(true);invalid[key]="wrong type";put(TEST_SAVE,JSON.stringify(invalid))
		state.coins=999;check(state.load_game() and state.coins==246,"schema mismatch restores backup: "+key)
	var invalid:Dictionary=baseline.duplicate(true);invalid.inventory[0].rarity=8
	check(not SaveIO.valid(invalid),"invalid equipment rarity is rejected before UI indexing")
	invalid=baseline.duplicate(true);invalid.buyback.append(invalid.inventory[0].duplicate(true))
	check(not SaveIO.valid(invalid),"duplicate item identity is rejected")
	invalid=baseline.duplicate(true);invalid.version=2;check(not SaveIO.valid(invalid),"unknown schema cannot be silently rewritten")
	invalid=baseline.duplicate(true);invalid.checkpoint[0]=INF;check(not SaveIO.valid(invalid),"non-finite position is rejected")
	clean();put(TEST_SAVE,"broken");put(TEST_SAVE+".tmp",JSON.stringify(baseline))
	check(state.load_game() and state.coins==246,"complete interrupted temporary write can recover")
	clean();put(TEST_SAVE+".old",JSON.stringify(baseline))
	check(state.load_game() and state.coins==246,"interrupted replacement can recover previous primary")
	clean();put(TEST_SAVE,JSON.stringify(baseline));var original:=FileAccess.get_sha256(TEST_SAVE)
	check(SaveIO.replace_file(TEST_SAVE+".missing",TEST_SAVE)!=OK and FileAccess.get_sha256(TEST_SAVE)==original,"failed replacement rolls back exact previous bytes")
	invalid=baseline.duplicate(true);invalid.erase("story");invalid.erase("tutorial");put(TEST_SAVE,JSON.stringify(invalid))
	state.story.beacon_claimed=true;state.tutorial.move=true
	check(state.load_game() and state.story.is_empty() and state.tutorial.is_empty(),"legacy save does not inherit another journey's optional progress")
	invalid=baseline.duplicate(true);invalid.hp=0;invalid.deaths=2;invalid.checkpoint_room="mine";invalid.checkpoint=[8,.05,0];invalid.ammo=0;invalid.magazine=0
	put(TEST_SAVE,JSON.stringify(invalid))
	check(state.load_game() and state.hp==state.max_health() and state.deaths==3,"loading a defeated character performs one checkpoint respawn")
	check(state.checkpoint_room=="mine" and state.checkpoint.x==8 and state.ammo==16 and state.magazine==8,"death recovery keeps checkpoint and restores minimum ammunition")
	check(state.save_game() and state.load_game() and state.deaths==3,"saved death recovery is not counted again on relaunch")
	invalid=baseline.duplicate(true);invalid.checkpoint_room="removed_room";invalid.checkpoint=[999,999,0];put(TEST_SAVE,JSON.stringify(invalid))
	check(state.load_game() and state.checkpoint_room=="hub" and state.checkpoint==Vector3(4,.05,0),"unknown legacy room falls back with safe hub coordinates")
	clean();put(TEST_SAVE,"broken primary");put(TEST_SAVE+".bak","broken backup")
	state.coins=735;check(not state.load_game() and state.save_blocked and state.coins==735,"all-broken load preserves in-memory progress and locks writes")
	state.new_game();check(not state.save_game() and FileAccess.get_file_as_string(TEST_SAVE)=="broken primary","new-game initialization cannot overwrite broken files")
	game=load("res://remaster/main.tscn").instantiate();root.add_child(game);current_scene=game;state.persistence_enabled=true;await frames(5)
	check(game.ui.panel_kind=="save_recovery","startup opens the recovery panel")
	game.ui.close();check(game.ui.panel_kind=="save_recovery" and game.ui.panel_open,"closing recovery cannot enter an unsaved journey")
	game.ui.open_title();game.ui.continue_journey();check(game.ui.panel_kind=="save_recovery","continue is guarded until recovery is resolved")
	game.ui.open_title();game.ui.start_new_journey()
	check(state.save_blocked and FileAccess.get_file_as_string(TEST_SAVE)=="broken primary","first new-journey click leaves original files intact")
	game.ui.start_new_journey();var archive:String=state.last_recovery_folder
	check(not state.save_blocked and game.ui.panel_kind=="story" and SaveIO.read_file(TEST_SAVE)!=null,"confirmed new journey establishes a usable new save")
	check(FileAccess.get_file_as_string(archive.path_join("save.json"))=="broken primary" and FileAccess.get_file_as_string(archive.path_join("save.bak.json"))=="broken backup","recovery archive preserves exact broken primary and backup")
	for name in DirAccess.get_files_at(archive):DirAccess.remove_absolute(archive.path_join(name))
	DirAccess.remove_absolute(archive)
	state.persistence_enabled=false;state.save_path=state.SAVE;clean();state.new_game();game.load_room("hub");game.ui.close()
	game.player.position=Vector3(8,.02,0);game.player.facing=1;game.player.invulnerable=100;await frames(12)
	state.first_trade();state.hp=60
	var target:Node3D=game.spawn_enemy("warden",Vector3(9.35,.02,0));target.set_physics_process(false);target.facing=-1;target.hp=5000;target.max_hp=5000
	await strike();var damage:float=5000-target.hp
	check(is_equal_approx(damage,7.2),"real frontal melee receives shield mitigation")
	check(is_equal_approx(state.hp,60+damage*.03),"melee lifesteal uses mitigated damage")
	state.hp=60;state.xp=0;target.hp=1;await strike()
	check(target.dead and is_equal_approx(state.hp,60.03),"overkill lifesteal is capped by target's remaining life")
	var coins:int=state.coins;check(target.take_hit(999,1)==0 and state.coins==coins,"dead targets cannot yield repeated damage or rewards")
	await frames(60)
	target=game.spawn_enemy("sentry",Vector3(10,.02,0));target.set_physics_process(false);target.hp=2;state.hp=60;state.xp=0
	game.projectile(Vector3(8,1,0),Vector3(23,0,0),120,true,Color.CYAN);await frames(9)
	check(target.dead and is_equal_approx(state.hp,60.06),"actual projectile overkill heals only life removed")
	await frames(60)
	target=game.spawn_enemy("sentry",Vector3(10,.02,0));target.set_physics_process(false);target.hp=2;state.hp=0;state.xp=state.level*90-1
	var level:int=state.level
	game.projectile(Vector3(8,1,0),Vector3(23,0,0),120,true,Color.CYAN);await frames(9)
	check(target.dead and state.level==level+1 and state.hp==0,"in-flight kill and level-up cannot revive a defeated hunter")
	state.hp=state.max_health()-.1;state.recover_life(1000);check(state.hp==state.max_health(),"lifesteal cannot exceed maximum life")
	game.queue_free();await frames(4)
	print("PREVIEW TESTS: ",checks," checks; ",failures.size()," failures");quit(0 if failures.is_empty() else 1)
