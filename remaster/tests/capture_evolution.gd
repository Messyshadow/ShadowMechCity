extends SceneTree
const Data=preload("res://remaster/evolution_data.gd")
var game:Node3D
var state:Node
var failures:=0
func _initialize() -> void:call_deferred("run")
func frames(n:int) -> void:
	for i in range(n):await physics_frame
func capture(id:String) -> void:
	await RenderingServer.frame_post_draw
	var error:=root.get_texture().get_image().save_png("res://remaster/qa/evolution_"+id+".png")
	if error!=OK:failures+=1
	print("EVOLUTION CAPTURE ",id," ",error)
func run() -> void:
	state=root.get_node("Reforged");state.persistence_enabled=false;state.new_game();state.points=24
	state.settings.tutorial=false;state.bosses.temple_sanctum=true
	for branch in Data.BRANCHES:
		for id in Data.NODES[branch]:state.learn(id)
	game=load("res://remaster/main.tscn").instantiate();root.add_child(game);current_scene=game;await frames(10)
	for branch in Data.BRANCHES:
		game.ui.close();game.evolution.clear_runtime();state.evolution=Data.fresh();game.evolution.select_branch(branch)
		game.load_room("temple_sanctum");game.player.position=Vector3(8,0,0);game.player.facing=1;await frames(20)
		game.set_process(false);game.camera.position=Vector3(9,3.6,15.8);game.ui.banner_time=0
		game.ui.skill_page="进化";game.ui.evolution_branch=branch;game.ui.skill_selection=branch+"_form";game.ui.open_skills();await frames(20);await capture(branch+"_tree")
		game.ui.skill_selection=branch+"_summon";game.ui.open_skills();await frames(18);await capture(branch+"_summon_preview")
		game.ui.close();game.player.invulnerable=0;await frames(4);Input.action_press("r_evolve");await frames(2);Input.action_release("r_evolve");await frames(22);game.ui.toast_time=0
		await capture(branch+"_form")
		var enemy:Node3D=game.spawn_enemy("sentry",Vector3(12,0,0));enemy.hp=9999;enemy.max_hp=9999;enemy.timer=100;enemy.set_physics_process(false)
		Input.action_press("r_summon");await frames(2);Input.action_release("r_summon");await frames(40);game.ui.toast_time=0
		await capture(branch+"_summon_windup");await frames(24);await capture(branch+"_summon_strike")
		print(branch," form active=",game.evolution.form_left," summon active=",game.evolution.summon_left," actions=",game.evolution.action_count," enemy hp=",enemy.hp)
	game.evolution.clear_runtime();game.controls.gamepad=true
	game.ui.skill_page="进化";game.ui.evolution_branch="mechanical";game.ui.skill_selection="mechanical_form";game.ui.open_skills();await frames(20);await capture("xbox_tree")
	game.ui.open_guide();await frames(5);await capture("xbox_guide")
	game.controls.gamepad=false;game.ui.open_guide();await frames(5);await capture("pc_guide")
	game.queue_free();await frames(4);print("EVOLUTION VISUAL failures=",failures);quit(failures)
