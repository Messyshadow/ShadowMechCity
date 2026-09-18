extends CharacterBody3D
var game: Node3D
var kind := "sentry"
var boss_name := ""
var is_boss := false
var max_hp := 65.0
var hp := 65.0
var dead := false
var radius := .42
var visual: Node3D
var anim: AnimationPlayer
var phase := 1
var timer := 1.0
var state := "approach"
var attack_id := "melee"
var attack_index := 0
var facing := -1.0
var direction := -1.0
var stun := 0.0
var warning: Node3D
var attack_count := 0
var origin := Vector3.ZERO
var health_bar: MeshInstance3D

func _ready() -> void:
	collision_layer=4; collision_mask=1; axis_lock_linear_z=true; floor_snap_length=.4
	origin=position
	var scale_factor := 2.0 if is_boss else 1.0
	radius=.7 if is_boss else .38
	var c := CollisionShape3D.new(); var shape := CapsuleShape3D.new()
	shape.radius=radius; shape.height=1.8*scale_factor
	c.shape=shape; c.position.y=shape.height*.5; add_child(c)
	visual=game.model(kind); add_child(visual); visual.scale=Vector3.ONE*scale_factor
	anim=visual.find_child("AnimationPlayer",true,false)
	if anim:
		for id in ["idle","run"]:
			if anim.has_animation(id): anim.get_animation(id).loop_mode=Animation.LOOP_LINEAR
	hp=max_hp
	if not is_boss:
		health_bar=game.cube(self,Vector3(0,2.45,.1),Vector3(1.1,.055,.045),Color(.95,.31,.12),true)

func clip(id: String, speed := 1.0) -> void:
	if anim and anim.has_animation(id) and anim.current_animation != id: anim.play(id,.1,speed)

func _physics_process(dt: float) -> void:
	if dead or game.ui.panel_open or game.transitioning: return
	var target: Vector3=game.player.position
	var dx: float=target.x-position.x
	var dy: float=target.y-position.y
	if is_boss and hp < max_hp*.5 and phase==1:
		phase=2; game.toast(boss_name+" · 核心过载，第二阶段")
		game.burst(position+Vector3.UP*2,Color(1,.15,.05),32); game.audio.play("warning")
	velocity.y-=25*dt
	if kind=="drone" or (kind=="dragon" and state!="charge"):
		velocity.y=(origin.y+2.3+sin(Time.get_ticks_msec()*.0014)*.6-position.y)*3
	if stun>0:
		stun-=dt; velocity.x=move_toward(velocity.x,0,dt*12); clip("hurt")
	else:
		timer-=dt
		match state:
			"approach":
				facing=signf(dx) if absf(dx)>.05 else facing
				var range_x := 14.0 if kind in ["gunner","drone"] else (5.0 if is_boss else 2.1)
				if absf(dx)<range_x and absf(dy)<5 and timer<=0:
					choose_attack()
				elif absf(dx)<18:
					velocity.x=facing*(2.2 if is_boss else 2.1)*(1.15 if phase==2 else 1.0)
					if not safe_step(facing): velocity.x=0
					clip("run" if absf(velocity.x)>.2 else "idle")
				else: velocity.x=0; clip("idle")
			"windup":
				velocity.x=0; clip("shoot" if attack_id in ["volley","beam"] else "attack3",.35)
				if timer<=0: execute_attack()
			"charge":
				velocity.x=direction*(12 if is_boss else 8)
				clip("dash")
				if absf(dx)<radius+.7 and absf(dy)<2: game.player.take_damage(27 if is_boss else 16,direction)
				if timer<=0 or is_on_wall() or not safe_step(direction): recover()
			"recover":
				velocity.x=move_toward(velocity.x,0,dt*30); clip("idle")
				if timer<=0: state="approach"; timer=.25
	visual.rotation.y=lerp_angle(visual.rotation.y,facing*PI/2,dt*9)
	move_and_slide(); position.z=0
	if health_bar: health_bar.scale.x=maxf(.001,hp/max_hp)
	if position.y < -5: take_hit(max_hp*3,0)

func safe_step(dir: float) -> bool:
	if kind in ["drone","dragon"]: return true
	var start := position+Vector3(dir*(radius+.45),.6,0)
	var q := PhysicsRayQueryParameters3D.create(start,start+Vector3.DOWN*2,1)
	return not get_world_3d().direct_space_state.intersect_ray(q).is_empty()

func choose_attack() -> void:
	if not game.clear_sight(position+Vector3.UP,game.player.position+Vector3.UP): timer=.6; return
	if is_boss:
		var patterns := {
			"titan":["slam","charge","volley"],
			"guardian":["slam","beam","summon"],
			"behemoth":["charge","slam","volley"],
			"crocodile":["charge","volley","slam"],
			"dragon":["volley","beam","charge"],
			"knight":["charge","melee","summon"],
			"king":["beam","slam","summon","charge","volley"],
		}
		var moves: Array=patterns.get(kind,["slam","volley"])
		attack_id=moves[attack_index%moves.size()]; attack_index+=1
	else: attack_id="volley" if kind in ["gunner","drone"] else "melee"
	state="windup"; direction=facing; timer=(.92 if is_boss else .65)*( .78 if phase==2 else 1.0)
	var range_x := 5.0 if attack_id in ["slam","melee"] else 11.0
	game.telegraph(position+Vector3(direction*range_x*.5,.045,.0),range_x,timer,attack_id)
	if is_boss: game.audio.play("warning",-8)

func execute_attack() -> void:
	attack_count+=1
	var dx: float=game.player.position.x-position.x
	var dy: float=game.player.position.y-position.y
	match attack_id:
		"charge": state="charge"; timer=.65; return
		"melee":
			game.slash(position+Vector3(direction,1.5,0),direction,Color(1,.2,.08),1.7 if is_boss else 1)
			if absf(dx)<(3.4 if is_boss else 2.2) and dx*direction>-.4 and absf(dy)<2 and game.clear_sight(position+Vector3.UP,game.player.position+Vector3.UP):
				game.player.take_damage(25 if is_boss else 14,direction)
		"slam":
			game.burst(position+Vector3(direction*2,.1,0),Color(1,.3,.06),30)
			game.slash(position+Vector3(0,.15,0),direction,Color(1,.3,.06),4.5)
			game.audio.play("explosion",-2); game.shake=.2
			if absf(dx)<5.2 and absf(dy)<.9: game.player.take_damage(30,direction)
			if phase==2:
				for s in [-1,1]: game.projectile(position+Vector3(s,.45,0),Vector3(s*9,0,0),17,false,Color(1,.3,.1))
		"volley":
			var start := position+Vector3(direction*.8,1.4 if not is_boss else 2.1,0)
			var aim: Vector3=(game.player.position+Vector3.UP-start).normalized()
			for i in range(3 if is_boss else 1):
				game.projectile(start,aim.rotated(Vector3.FORWARD,(i-1)*.16 if is_boss else 0)*(9.0+phase),18 if is_boss else 12,false,Color(1,.3,.08))
			game.audio.play("shot",-8)
		"beam":
			for i in range(4+phase): game.projectile(position+Vector3(direction*(1+i*.65),.6,0),Vector3(direction*15,0,0),22,false,Color(.8,.15,1))
			game.audio.play("shot",-3)
		"summon":
			var active := 0
			for e in game.enemies:
				if is_instance_valid(e) and not e.dead: active+=1
			if active < 5:
				for s in [-1,1]: game.spawn_enemy("sentry",Vector3(clampf(position.x+s*3,2,game.room_width-2),.1,0))
			game.burst(position+Vector3.UP,Color(.7,.15,1),24)
	clip("attack2",1.8); recover()

func recover() -> void:
	state="recover"; timer=(1.2 if is_boss else .9)*( .72 if phase==2 else 1.0)

func take_hit(amount: float, knock: float, break_armor := false) -> void:
	if dead: return
	hp-=amount
	game.damage_number(position+Vector3.UP*(3.5 if is_boss else 2),int(amount))
	game.burst(position+Vector3.UP,Color(1,.62,.18),8); game.audio.play("hit",-5)
	if not is_boss:
		stun=.65 if break_armor else .23; velocity.x=knock*4
	elif break_armor and state=="recover": timer+=.4
	if hp<=0:
		dead=true; collision_layer=0; collision_mask=0
		game.audio.play("explosion",-3); game.burst(position+Vector3.UP,Color(1,.4,.08),24)
		clip("death")
		if is_boss: game.boss_defeated(self)
		else: Reforged.reward(false)
		var tw := create_tween(); tw.tween_property(visual,"scale",Vector3.ONE*.001,.8)
		tw.tween_callback(queue_free)
