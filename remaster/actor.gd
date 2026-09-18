extends CharacterBody3D
## Articulated Blender character with animation clips, 2.5D movement and combat.
var game: Node3D
var visual: Node3D
var anim: AnimationPlayer
var weapon_mesh: Node3D
var facing := 1.0
var invulnerable := 0.0
var dash_time := 0.0
var dash_cooldown := 0.0
var attack_time := 0.0
var attack_total := .4
var attack_done := false
var combo := 0
var combo_window := 0.0
var buffered_attack := false
var jumping := 0
var coyote := .0
var jump_buffer := .0
var climbing := false
var climb_x := 0.0
var climb_low := 0.0
var climb_high := 0.0
var climb_door: Dictionary = {}
var climb_lift := false
var weapon_socket: BoneAttachment3D
var overdrive_remaining := 0
var overdrive_interval := 0.0
var uppercut := false
var reload_time := 0.0
var skill_cooldown := 0.0
var skill_attack := false
var step_clock := 0.0
var death_time := 0.0
var water := false
var was_grounded := false
var lock_input := false
var hit_pause := 0.0
var wall_lock := 0.0
var last_weapon := -1
var health: float:
	get: return Reforged.hp
	set(value): Reforged.hp = value

func _ready() -> void:
	collision_layer = 2; collision_mask = 1
	axis_lock_linear_z = true; floor_snap_length = .3
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new(); capsule.radius = .3; capsule.height = 1.8
	shape.shape = capsule; shape.position.y = .92; add_child(shape)
	visual = game.model("hero"); add_child(visual)
	anim = visual.find_child("AnimationPlayer",true,false)
	if anim:
		for name in anim.get_animation_list():
			if name in ["idle","run","climb","fall"]: anim.get_animation(name).loop_mode = Animation.LOOP_LINEAR
	refresh_weapon()

func refresh_weapon() -> void:
	if weapon_mesh: weapon_mesh.queue_free()
	if not weapon_socket:
		var skeletons:=visual.find_children("*","Skeleton3D",true,false)
		if not skeletons.is_empty():
			weapon_socket=BoneAttachment3D.new();skeletons[0].add_child(weapon_socket);weapon_socket.bone_name="foreR"
	weapon_mesh = game.model(Reforged.WEAPONS[Reforged.weapon])
	if weapon_socket:
		weapon_socket.add_child(weapon_mesh);weapon_mesh.position=Vector3(0,.32,0)
	else:
		visual.add_child(weapon_mesh);weapon_mesh.position=Vector3(-.48,.86,.12)
	weapon_mesh.scale = Vector3.ONE * (.72 if Reforged.weapon == 3 else .85)
	weapon_mesh.rotation_degrees.x = 100
	last_weapon = Reforged.weapon

func play_clip(id: String, speed := 1.0) -> void:
	if anim and anim.has_animation(id) and (anim.current_animation != id or not anim.is_playing()):
		anim.play(id,.09,speed)

func _physics_process(dt: float) -> void:
	if last_weapon != Reforged.weapon: refresh_weapon()
	invulnerable = maxf(0,invulnerable-dt); dash_cooldown = maxf(0,dash_cooldown-dt)
	skill_cooldown = maxf(0,skill_cooldown-dt); wall_lock = maxf(0,wall_lock-dt)
	visual.visible = invulnerable <= 0 or int(invulnerable*18) % 2 == 0
	if death_time > 0:
		death_time -= dt; play_clip("death")
		if death_time <= 0: game.respawn()
		return
	if game.ui.panel_open or lock_input: return
	if weapon_mesh:weapon_mesh.visible=not climbing
	if overdrive_remaining>0:
		overdrive_interval-=dt
		if overdrive_interval<=0:
			overdrive_remaining-=1;overdrive_interval=.09
			game.burst(position+Vector3(facing,1,0),Color(1,.4,.05),6)
			for enemy in game.enemies:
				if is_instance_valid(enemy) and not enemy.dead and enemy.position.distance_to(position)<3 and (enemy.position.x-position.x)*facing>-.3:
					if game.clear_sight(position+Vector3.UP,enemy.position+Vector3.UP):enemy.take_hit(Reforged.attack_damage()*.5,facing)
	if hit_pause > 0:
		hit_pause -= dt; return
	var axis := Input.get_axis("r_left","r_right")
	var vertical := Input.get_axis("r_down","r_up")
	if Input.is_action_just_pressed("r_jump"): jump_buffer = .13
	else: jump_buffer = maxf(0,jump_buffer-dt)
	if is_on_floor(): coyote = .12; jumping = 0
	else: coyote = maxf(0,coyote-dt)
	if climbing:
		velocity = Vector3(0, vertical*3.3, 0)
		position.x = move_toward(position.x,climb_x,dt*10)
		# Climbing is constrained to a visible rail, deliberately ignores rim collision.
		position.y = clampf(position.y + velocity.y*dt,climb_low,climb_high)
		visual.rotation.y=PI if not climb_lift else facing*PI/2
		play_clip("idle" if climb_lift else "climb",1.1 if vertical else 0.0)
		step_clock -= dt
		if absf(vertical) > .1 and step_clock <= 0 and not climb_lift: game.audio.play("climb",-7); step_clock=.3
		if (vertical > 0 and position.y >= climb_high-.06) or (vertical < 0 and position.y <= climb_low+.06):
			if not climb_door.is_empty() and ((climb_door.side == "up" and vertical > 0) or (climb_door.side == "down" and vertical < 0)):
				game.use_door(climb_door); return
			climbing = false; position.x += .95; position.y += .1
		if Input.is_action_just_pressed("r_jump"):
			climbing = false; velocity = Vector3(facing*5,9,0); jumping=1; game.audio.play("jump")
		return
	if absf(vertical) > .1 and attack_time <= 0 and game.try_climb(vertical): return
	if reload_time > 0:
		reload_time -= dt
		if reload_time <= 0:
			var amount := mini(8-Reforged.magazine,Reforged.ammo)
			Reforged.magazine += amount; Reforged.ammo -= amount
	if Input.is_action_just_pressed("r_reload"): reload()
	if Input.is_action_just_pressed("r_swap") and attack_time <= 0:
		Reforged.weapon = (Reforged.weapon + 1)%4; refresh_weapon()
	if Input.is_action_just_pressed("r_heal") and Reforged.potions > 0 and health < Reforged.max_health():
		Reforged.potions -= 1; health = minf(Reforged.max_health(),health+60)
		game.audio.play("save",-5); game.burst(position+Vector3.UP,Color(.1,1,.6),12); Reforged.commit()
	if Input.is_action_just_pressed("r_dash") and dash_cooldown <= 0:
		dash_time=.18; dash_cooldown=.65; invulnerable=.24; game.audio.play("dash")
	if dash_time > 0:
		dash_time -= dt; velocity=Vector3(facing*18,0,0); play_clip("dash")
		game.trail(position+Vector3.UP,Color(.03,.65,.9))
	else:
		if wall_lock <= 0: velocity.x = move_toward(velocity.x,axis*(4.2 if water else 7.2),dt*48)
		velocity.y -= (13 if water else 25)*dt
		if axis != 0 and attack_time <= 0: facing=signf(axis)
		if is_on_wall() and velocity.y < -2 and axis != 0: velocity.y=-2.0
		if jump_buffer > 0 and (coyote > 0 or jumping < 2 or is_on_wall()):
			if is_on_wall() and coyote <= 0:
				velocity.x=get_wall_normal().x*8; facing=signf(velocity.x); wall_lock=.22
				velocity.y=12.0; jumping=1; game.audio.play("wall_jump")
			else:
				velocity.y=11.7 if not water else 8.5
				jumping = 1 if coyote > 0 else jumping+1; game.audio.play("jump")
			jump_buffer=0; coyote=0; play_clip("jump")
		if Input.is_action_just_released("r_jump") and velocity.y>4: velocity.y *= .55
	if Input.is_action_just_pressed("r_attack"):
		if attack_time > 0: buffered_attack=true
		else: begin_attack(false)
	if Input.is_action_just_pressed("r_skill") and attack_time<=0: begin_attack(true)
	combo_window=maxf(0,combo_window-dt)
	if attack_time>0:
		attack_time-=dt
		if not attack_done and attack_time < attack_total*.6:
			attack_done=true; resolve_attack()
		play_clip("skill" if skill_attack else ("shoot" if Reforged.weapon==2 else "attack"+str(mini(combo+1,3))),1.0/attack_total)
		if weapon_mesh: weapon_mesh.rotation.x=lerpf(-1.5,2.8,1.0-attack_time/attack_total)
		if attack_time<=0:
			combo_window=.65
			if buffered_attack: buffered_attack=false; begin_attack(false)
	else:
		if weapon_mesh: weapon_mesh.rotation.x=lerp_angle(weapon_mesh.rotation.x,1.7,dt*12)
		if not is_on_floor(): play_clip("jump" if velocity.y>0 else "fall")
		elif absf(velocity.x)>.3:
			play_clip("run",1.2); step_clock-=dt
			if step_clock<=0: game.audio.play("step",-10); step_clock=.3
		else: play_clip("idle")
	visual.rotation.y=lerp_angle(visual.rotation.y,facing*PI/2,dt*18)
	move_and_slide(); position.z=0
	if is_on_floor() and not was_grounded: game.audio.play("land",-5)
	was_grounded=is_on_floor()
	if position.y < -5: take_damage(999,0)

func reload() -> void:
	if reload_time<=0 and Reforged.magazine<8 and Reforged.ammo>0:
		reload_time=.9; game.audio.play("reload")

func begin_attack(special: bool) -> void:
	if reload_time > 0: return
	if special:
		if not Reforged.skills.has(Reforged.WEAPONS[Reforged.weapon]+"_3"):
			game.toast("按 T 学习本武器的终阶技能"); return
		if skill_cooldown > 0: return
	if Reforged.weapon==2:
		var needed := 3 if special else 1
		if Reforged.magazine<needed:
			game.audio.play("empty"); reload(); return
		Reforged.magazine-=needed
	skill_attack=special
	uppercut=Reforged.weapon==3 and Input.is_action_pressed("r_up") and not special
	if uppercut:velocity.y=9.0
	if special: skill_cooldown=4.0
	if combo_window<=0: combo=0
	else: combo=(combo+1)%(4 if Reforged.weapon==3 else 3)
	attack_total=([.34,.57,.3,.23][Reforged.weapon]) * (1.5 if special else 1.0)
	attack_time=attack_total; attack_done=false
	if anim: anim.stop()

func resolve_attack() -> void:
	var damage := Reforged.attack_damage() * (1.5 if combo==2 else 1.0)
	if not is_on_floor() and Reforged.weapon in [0,3] and Reforged.skills.has(Reforged.WEAPONS[Reforged.weapon]+"_2"): damage*=1.4
	if skill_attack: damage*=2.2
	if Reforged.weapon==2:
		game.audio.play("shot"); game.shake=.09
		for i in range(3 if skill_attack else 1):
			var muzzle:=position+Vector3(facing*.8,1.12+i*.10,0)
			# A muzzle can overlap thin cover while the capsule remains outside it.
			if game.clear_sight(position+Vector3(0,1.12+i*.10,0),muzzle):
				game.projectile(muzzle,Vector3(facing*23,i*.8,0),damage,true,Color(.2,.9,1))
			else: game.burst(position+Vector3(facing*.4,1.12,0),Color(1,.5,.1),4)
		return
	game.audio.play("punch" if Reforged.weapon==3 else "slash")
	var reach: float=[2.15,2.6,0.0,1.6][Reforged.weapon]
	if skill_attack: reach=4.5
	game.slash(position+Vector3(facing*.7,1,0),facing,Color(1,.5,.12) if Reforged.weapon in [1,3] else Color(.15,.85,1),reach*.5)
	if skill_attack and Reforged.weapon==0:
		game.projectile(position+Vector3(0,1,0),Vector3(facing*15,0,0),damage,true,Color(.2,.85,1),true)
	if skill_attack and Reforged.weapon==3: velocity.x=facing*14; wall_lock=.2
	if skill_attack and Reforged.weapon==3:overdrive_remaining=4;overdrive_interval=.09
	for e in game.enemies:
		if not is_instance_valid(e) or e.dead: continue
		var offset: Vector3 = e.position-position
		if absf(offset.x)<reach+e.radius and absf(offset.y)<2.5 and (offset.x*facing>-.35 or (skill_attack and Reforged.weapon==1)):
			if game.clear_sight(position+Vector3.UP,e.position+Vector3.UP):
				e.take_hit(damage,facing,Reforged.weapon==1 and Reforged.skills.has("hammer_2"))
				# Stop the approach on contact so follow-up punches keep their target.
				if skill_attack and Reforged.weapon==3:velocity.x=0
				if uppercut and not e.is_boss:e.velocity.y=8
				health=minf(Reforged.max_health(),health+damage*minf(.08,Reforged.stat("lifesteal")))
				hit_pause=.045; game.shake=.13
	if skill_attack and Reforged.weapon==1:
		game.burst(position,Color(1,.4,.08),28); game.audio.play("explosion",-6)

func take_damage(amount: float, direction: float) -> void:
	if invulnerable>0 or death_time>0 or game.ui.panel_open: return
	health-=maxf(1,amount-Reforged.stat("armor"))
	invulnerable=.85; velocity=Vector3(direction*5,4,0); wall_lock=.2
	game.shake=.2; game.audio.play("hurt"); game.burst(position+Vector3.UP,Color(1,.15,.1),10)
	if health<=0:
		health=0; death_time=1.2; climbing=false; attack_time=0
		game.toast("核心熄灭 · 正在返回最后激活的存档点")
