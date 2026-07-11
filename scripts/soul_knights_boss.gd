extends CharacterBody2D
## 铸魂骑士团：盾骑→枪骑→炮骑，末段加入联合弹幕。

signal hp_changed(cur: int, maxv: int, phase: int)
signal defeated

const PROJ := preload("res://scripts/enemy_projectile.gd")
const GRAVITY := 1500.0
var boss_name := "王城铸魂骑士团"
var sprite_name := "golem"
var frame_count := 6
var anim_fps := 8.0
var sprite_scale := 1.8
var max_hp := 420
var body_size := Vector2(120,145)
var tint := Color(0.65,0.5,0.9)
var can_summon := false
var summon_type := "soul_spear"
var hp := 0
var phase := 1
var members := ["铸魂盾骑", "铸魂枪骑", "铸魂炮骑"]
var active_member := 0
var state := "intro"
var cd := 1.0
var timer := 0.8
var dir := -1
var player: Node2D
var anim: AnimatedSprite2D
var touch: Area2D

func _ready() -> void:
	add_to_group("enemy"); add_to_group("boss"); collision_layer = 0b00100; collision_mask = 0b00001
	hp = max_hp; _build(); _apply_role_visual(); hp_changed.emit(hp,max_hp,phase)

func _build() -> void:
	var c:=CollisionShape2D.new(); var s:=RectangleShape2D.new(); s.size=body_size; c.shape=s; c.position=Vector2(0,-body_size.y*0.5); add_child(c)
	anim=AnimatedSprite2D.new(); anim.sprite_frames=AnimLoader.build_enemy(sprite_name,frame_count,anim_fps); anim.centered=false; anim.scale=Vector2(sprite_scale,sprite_scale); anim.modulate=tint
	var tex:=anim.sprite_frames.get_frame_texture("move",0); if tex: anim.position=Vector2(-tex.get_width()*sprite_scale*0.5,-tex.get_height()*sprite_scale)
	anim.play("move"); add_child(anim)
	touch=Area2D.new(); touch.collision_layer=0; touch.collision_mask=0b00010; var tc:=CollisionShape2D.new(); var ts:=RectangleShape2D.new(); ts.size=body_size; tc.shape=ts; tc.position=c.position; touch.add_child(tc); add_child(touch)

func _physics_process(delta: float) -> void:
	player=get_tree().get_first_node_in_group("player") as Node2D
	if state=="dead": velocity.y=minf(velocity.y+GRAVITY*delta,800); move_and_slide(); return
	if not is_on_floor(): velocity.y=minf(velocity.y+GRAVITY*delta,900)
	else: velocity.y=0
	cd-=delta; timer-=delta
	if player: dir=1 if player.global_position.x>global_position.x else -1; anim.flip_h=dir>0
	match state:
		"intro":
			velocity.x=0
			if timer<=0: state="idle"
		"guard":
			velocity.x=0
			if timer<=0: state="bash"; timer=0.35
		"bash","thrust":
			velocity.x=dir*(380.0 if phase==1 else 620.0)
			if timer<=0: state="idle"; cd=0.7
		"leap":
			if is_on_floor() and timer<0.5: state="idle"; cd=0.75; Fx.shockwave(get_parent(),global_position,Color(0.9,0.35,0.65)); Game.shake(9)
		_:
			velocity.x=move_toward(velocity.x,0.0,900*delta)
			if cd<=0 and player: _choose()
	move_and_slide(); _contact()

func _choose() -> void:
	Fx.popup(get_parent(),global_position+Vector2(0,-170),["盾反预备","贯魂突刺","炮骑齐射"][phase-1],tint)
	if phase==1: state="guard"; timer=0.45
	elif phase==2:
		if randi()%2==0: state="thrust"; timer=0.48
		else: state="leap"; timer=0.8; velocity=Vector2(dir*260,-720)
	else:
		_fire_fan(7)
		if hp<max_hp/6: _joint_attack()
		cd=1.0

func _joint_attack() -> void:
	# 末段三骑士联合：炮骑扇射，盾骑冲击波，枪骑高速穿刺。
	_fire_fan(11); Fx.shockwave(get_parent(),global_position,Color(0.55,0.75,1)); state="thrust"; timer=0.55; Game.shake(10)

func _fire_fan(count:int) -> void:
	if not player:return
	var o:=global_position+Vector2(0,-90); var aim:=(player.global_position+Vector2(0,-35)-o).normalized()
	for i in range(count):
		var p:=Area2D.new(); p.set_script(PROJ); p.position=o; get_parent().add_child(p); p.setup(aim.rotated(deg_to_rad(lerp(-36.0,36.0,float(i)/float(count-1))))*380,2,Color(0.8,0.35,1.0))

func _contact() -> void:
	for b in touch.get_overlapping_bodies():
		if b.is_in_group("player") and b.has_method("take_damage"): b.take_damage(3,global_position)

func take_damage(amount:int,_kb:Vector2) -> void:
	if state=="dead":return
	# 盾骑防御窗口减伤但不完全免疫。
	if phase==1 and state=="guard": amount=maxi(1,amount/4)
	hp-=amount
	var next_phase:=1 if hp>max_hp*2/3 else (2 if hp>max_hp/3 else 3)
	if next_phase!=phase: phase=next_phase; _advance_member()
	hp_changed.emit(maxi(hp,0),max_hp,phase)
	if hp<=0:_die()

func _advance_member() -> void:
	Fx.death_burst(get_parent(),global_position,tint)
	active_member=phase-1
	tint=[Color(0.55,0.72,1),Color(0.95,0.35,0.65),Color(0.65,0.3,1)][phase-1]; anim.modulate=tint; state="intro"; timer=0.7; cd=0.4
	_apply_role_visual()
	Fx.screen_flash(get_tree(),Color(tint.r,tint.g,tint.b,0.3)); Fx.popup(get_parent(),global_position+Vector2(0,-180),members[active_member]+" 参战",tint)

func _apply_role_visual() -> void:
	for child in get_children():
		if child.has_meta("role_visual"): child.queue_free()
	if phase==1:
		var shield:=Polygon2D.new();shield.polygon=PackedVector2Array([Vector2(-70,-125),Vector2(-20,-145),Vector2(-16,-45),Vector2(-62,-28)]);shield.color=Color(0.35,0.65,1,0.75);shield.set_meta("role_visual",true);add_child(shield)
	elif phase==2:
		var spear:=Line2D.new();spear.width=8;spear.default_color=Color(1,0.35,0.7);spear.points=PackedVector2Array([Vector2(-80,-125),Vector2(105,-70)]);spear.set_meta("role_visual",true);add_child(spear)
	else:
		for side in [-1,1]:
			var mate:=Polygon2D.new();mate.polygon=PackedVector2Array([Vector2(side*55,-150),Vector2(side*105,-110),Vector2(side*70,-45)]);mate.color=Color(0.55 if side<0 else 0.9,0.35,1,0.65);mate.set_meta("role_visual",true);add_child(mate)

func _die() -> void:
	state="dead"; set_deferred("collision_layer",0); touch.set_deferred("monitoring",false); defeated.emit(); Game.shake(16); Fx.death_burst(get_parent(),global_position,tint)
	var tw:=create_tween();tw.tween_property(anim,"modulate:a",0.0,0.7);tw.tween_callback(queue_free)
