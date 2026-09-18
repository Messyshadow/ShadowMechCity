extends CharacterBody3D
const Data=preload("res://remaster/squad_data.gd")
var game:Node3D
var controller:Node
var identity:="hound"
var formation:=0
var profile:Dictionary
var visual:Node3D
var animation:AnimationPlayer
var health_bar:MeshInstance3D
var cooldown:=1.2
var invulnerable:=0.0
var windup:=0.0
var target:Node3D
var facing:=1.0
var stuck:=0.0
var action_count:=0
var warning:MeshInstance3D

func status() -> Dictionary:return Reforged.squad.status[identity]
func _ready() -> void:
	profile=Data.PROFILES[identity];collision_layer=8;collision_mask=0 if profile.air else 1;floor_snap_length=.4;axis_lock_linear_z=true
	var shape:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new();capsule.radius=.3;capsule.height=1.0;shape.shape=capsule;shape.position.y=.5;add_child(shape)
	visual=game.model("ally_"+identity);add_child(visual);animation=visual.find_child("AnimationPlayer",true,false)
	for id in ["idle","run"]:animation.get_animation(id).loop_mode=Animation.LOOP_LINEAR
	health_bar=game.cube(self,Vector3(0,1.25,.2),Vector3(.85,.045,.035),profile.color,true)
	warning=game.cube(self,Vector3(0,.08,0),Vector3(1.2,.025,1.2),profile.color,true);warning.visible=false
	cooldown=float(profile.cooldown)+formation*.24
	game.burst(position+Vector3.UP*.5,profile.color,9)

func clip(id:String) -> void:
	if animation.current_animation!=id or not animation.is_playing():animation.play(id,.08)

func reassemble() -> void:
	position=game.player.position+Vector3(-1.5-formation,2.0 if profile.air else .1,0)
	cooldown=float(profile.cooldown)+formation*.24;invulnerable=.6;windup=0;target=null;visual.visible=true
	game.burst(position+Vector3.UP*.5,profile.color,12)

func take_damage(amount:float) -> void:
	if status().hp<=0 or invulnerable>0:return
	status().hp=maxf(0,float(status().hp)-maxf(0,amount)*(.55 if identity=="mole" else 1.0));invulnerable=.65
	windup=0;warning.visible=false;clip("hurt");game.burst(position+Vector3.UP*.6,Color(1,.4,.15),5)
	if status().hp<=0:
		status().rebuild=12.0;clip("death");game.toast(str(profile.name)+" 损毁 · 12 秒后重构");Reforged.commit()

func _physics_process(dt:float) -> void:
	if not Reforged.squad.status.has(identity) or not Reforged.squad.deployed or not Reforged.squad.loadout.has(identity):queue_free();return
	if game.ui.panel_open or game.transitioning:return
	if status().hp<=0:visual.visible=false;health_bar.visible=false;warning.visible=false;return
	health_bar.visible=true;health_bar.scale.x=clampf(float(status().hp)/float(profile.hp),.01,1)
	invulnerable=maxf(0,invulnerable-dt);visual.visible=invulnerable<=0 or int(invulnerable*16)%2==0
	cooldown=maxf(0,cooldown-dt)
	if Reforged.hp<=0:warning.visible=false;windup=0;clip("idle");return
	var destination:Vector3=game.player.position+Vector3([-1.8,1.8,-3.0][formation],2.0+formation*.25 if profile.air else 0.0,0)
	if is_instance_valid(target) and (target.dead or target.position.distance_to(game.player.position)>9):target=null
	if not is_instance_valid(target) and identity!="wisp":
		var best:=8.0
		for enemy in game.enemies:
			if not is_instance_valid(enemy) or enemy.dead:continue
			var distance:float=enemy.position.distance_to(game.player.position)
			var engaged:bool=enemy.hp<enemy.max_hp or enemy.state!="approach" or distance<4.5
			if engaged and distance<best and game.clear_sight(game.player.position+Vector3.UP,enemy.position+Vector3.UP):best=distance;target=enemy
	if is_instance_valid(target):
		facing=signf(target.position.x-position.x)
		destination=target.position+Vector3(-facing*float(profile.range)*.75,1.4 if profile.air else 0,0)
	var dx:=destination.x-position.x
	if absf(dx)>.1:facing=signf(dx)
	if profile.air:
		velocity=(destination-position)*3;velocity=velocity.limit_length(7.5);position+=velocity*dt
	else:
		velocity.y-=25*dt;velocity.x=clampf(dx*4,-6.0,6.0)
		if is_on_wall() and is_on_floor():velocity.y=8
		move_and_slide()
	position.z=0;visual.rotation.y=lerp_angle(visual.rotation.y,facing*PI/2,dt*12)
	if (is_on_wall() or (absf(velocity.x)<.1 and absf(dx)>3)):stuck+=dt
	else:stuck=0
	if position.distance_to(game.player.position)>13 or position.y< -4 or stuck>2:
		position=game.player.position+Vector3(0,2 if profile.air else 1,0);velocity=Vector3.ZERO;stuck=0;windup=0
		game.burst(position,profile.color,7)
	if Reforged.squad.lock>0:windup=0;warning.visible=false;clip("idle");return
	if windup>0:
		windup-=dt;warning.visible=true;clip("attack")
		if windup<=0:warning.visible=false;resolve_action();cooldown=float(profile.cooldown)
	elif cooldown<=0:
		var can_heal:bool=identity=="wisp" and position.distance_to(game.player.position)<5 and Reforged.hp<Reforged.max_health()
		var can_attack:bool=is_instance_valid(target) and position.distance_to(target.position)<float(profile.range)+.8
		if can_heal or can_attack:windup=.28;clip("attack")
	else:clip("run" if velocity.length()>.4 else "idle")

func resolve_action() -> void:
	if Reforged.hp<=0:return
	if identity=="wisp":
		if position.distance_to(game.player.position)>5 or not game.clear_sight(position+Vector3.UP*.5,game.player.position+Vector3.UP):return
		Reforged.hp=minf(Reforged.max_health(),Reforged.hp+4);status().hp=minf(float(profile.hp),float(status().hp)+4)
		game.burst(game.player.position+Vector3.UP,profile.color,10)
	else:
		if not is_instance_valid(target) or target.dead or position.distance_to(target.position)>float(profile.range)+1:return
		if not game.clear_sight(position+Vector3.UP*.6,target.position+Vector3.UP):return
		facing=signf(target.position.x-position.x)
		var damage:float=profile.damage*controller.power_scale()
		if identity=="bee":game.projectile(position+Vector3.UP*.5,(target.position+Vector3.UP-position-Vector3.UP*.5).normalized()*15,damage,true,profile.color,false,false)
		else:
			target.take_hit(damage,facing,identity=="mole",position);game.slash(position+Vector3(facing*.6,.6,0),facing,profile.color,.8)
	action_count+=1;controller.action_committed()
