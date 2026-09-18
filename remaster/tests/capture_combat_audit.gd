extends SceneTree
## Diagnostic evidence for 0.6.0. This records current behavior, not acceptance of missing features.
var game:Node3D
var state:Node
var target:Node3D
var captures_failed:=0
func _initialize() -> void:call_deferred("run")
func frames(n:int) -> void:
	for i in range(n):await physics_frame
func capture(id:String) -> void:
	await RenderingServer.frame_post_draw
	var result:=root.get_texture().get_image().save_png("res://remaster/qa/combat_audit_"+id+".png")
	if result!=OK:captures_failed+=1
	print("COMBAT AUDIT CAPTURE ",id," ",result)
func arrange(weapon:int,kind:="sentry") -> void:
	state.weapon=weapon;state.hp=120
	game.load_room("temple_sanctum");game.ui.close();game.player.position=Vector3(8,0,0);game.player.facing=1
	target=game.spawn_enemy(kind,Vector3(9.5,0,0));target.hp=5000;target.max_hp=5000;target.timer=100;target.stun=10;target.facing=-1;target.visual.rotation.y=-PI/2
	await frames(16)
	game.ui.banner_time=0;game.ui.toast_time=0;game.player.invulnerable=0;game.player.visual.visible=true
	game.set_process(false);game.camera.position=Vector3(8.8,3.5,14.8)
func attack_input() -> void:
	Input.action_press("r_attack");await frames(2);Input.action_release("r_attack")
func run() -> void:
	state=root.get_node("Reforged");state.persistence_enabled=false;state.new_game();state.bosses.temple_sanctum=true;state.settings.tutorial=false
	game=load("res://remaster/main.tscn").instantiate();root.add_child(game);current_scene=game;await frames(5)
	for weapon in [0,1,3,4,5]:
		await arrange(weapon)
		var sequence:Array=[]
		for i in range(4 if weapon in [3,4] else 3):
			game.player.position.x=8;target.position=Vector3(9.5,0,0)
			await attack_input();sequence.append(game.player.attack_clip())
			if weapon==0 and i==0:
				await frames(3);await capture("blade_windup");await frames(8);await capture("blade_impact")
			if weapon==0 and i==1:await frames(7);await capture("blade_followup")
			while game.player.attack_time>0:await physics_frame
			await frames(2)
		print("GROUND ",state.WEAPONS[weapon]," clips=",sequence," damage=",5000-target.hp)
	await arrange(4)
	game.camera.position=Vector3(8.8,6.2,19)
	game.player.position=Vector3(8,4,0);game.player.velocity=Vector3(0,8,0);await frames(2)
	var air_clips:Array=[]
	for i in range(2):
		await attack_input();air_clips.append(game.player.attack_clip());await frames(4)
		await capture("air_dual_"+str(i+1))
		while game.player.attack_time>0:await physics_frame
	print("AIR dual clips=",air_clips," air position=",game.player.position)
	await arrange(0)
	game.player.take_damage(20,-1);await frames(2)
	print("PLAYER HURT hp=",state.hp," clip=",game.player.anim.current_animation," velocity=",game.player.velocity," immunity=",game.player.invulnerable)
	await capture("player_hurt")
	await arrange(0,"warden")
	target.stun=0;target.timer=100;await frames(1)
	var front:float=target.take_hit(20,1)
	print("WARDEN frontal damage=",front," flash=",target.hit_flash," hit stop=",target.hit_stop," stun=",target.stun," clip=",target.anim.current_animation)
	await frames(1);await capture("shield_impact")
	target.state="recover";var recovery:float=target.take_hit(20,1)
	print("WARDEN recovery damage=",recovery)
	print("PLAYER ACTIVE GUARD action=",InputMap.has_action("r_guard")," block=",InputMap.has_action("r_block")," parry=",InputMap.has_action("r_parry"))
	game.queue_free();await frames(4);print("COMBAT AUDIT capture failures=",captures_failed);quit(captures_failed)
