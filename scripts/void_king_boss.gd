extends CharacterBody2D
## 虚空机械君王：机械武装→虚空形态→光核失控三阶段。

signal hp_changed(cur:int,maxv:int,phase:int)
signal defeated
const PROJ:=preload("res://scripts/enemy_projectile.gd")
const GRAVITY:=1500.0
var boss_name:="虚空机械君王"; var sprite_name:="golem"; var frame_count:=6; var anim_fps:=9.0; var sprite_scale:=2.1
var max_hp:=600; var body_size:=Vector2(140,170); var tint:=Color(0.55,0.25,0.85); var can_summon:=false; var summon_type:="soul_cannon"
var hp:=0; var phase:=1; var state:="intro"; var cd:=0.8; var timer:=1.0; var dir:=-1
var player:Node2D; var anim:AnimatedSprite2D; var touch:Area2D; var body_col:CollisionShape2D; var touch_col:CollisionShape2D

func _ready()->void:
	add_to_group("enemy");add_to_group("boss");collision_layer=0b00100;collision_mask=0b00001;hp=max_hp;_build();hp_changed.emit(hp,max_hp,phase)

func _build()->void:
	body_col=CollisionShape2D.new();var s:=RectangleShape2D.new();s.size=body_size;body_col.shape=s;body_col.position=Vector2(0,-body_size.y*0.5);add_child(body_col)
	anim=AnimatedSprite2D.new();anim.sprite_frames=AnimLoader.build_enemy(sprite_name,frame_count,anim_fps);anim.centered=false;anim.scale=Vector2(sprite_scale,sprite_scale);anim.modulate=tint
	var tex:=anim.sprite_frames.get_frame_texture("move",0);if tex:anim.position=Vector2(-tex.get_width()*sprite_scale*0.5,-tex.get_height()*sprite_scale)
	anim.play("move");add_child(anim);touch=Area2D.new();touch.collision_layer=0;touch.collision_mask=0b00010;touch_col=CollisionShape2D.new();var ts:=RectangleShape2D.new();ts.size=body_size;touch_col.shape=ts;touch_col.position=body_col.position;touch.add_child(touch_col);add_child(touch)

func _physics_process(delta:float)->void:
	player=get_tree().get_first_node_in_group("player") as Node2D
	if state=="dead":return
	if not is_on_floor():velocity.y=minf(velocity.y+GRAVITY*delta,900)
	else:velocity.y=0
	cd-=delta;timer-=delta;if player:dir=1 if player.global_position.x>global_position.x else -1;anim.flip_h=dir>0
	match state:
		"intro":velocity.x=0;if timer<=0:state="idle"
		"tele":velocity.x=0;if timer<=0:_execute()
		"charge":velocity.x=dir*(470+phase*90);if timer<=0:state="idle";cd=0.6
		_:
			velocity.x=move_toward(velocity.x,0.0,900*delta)
			if cd<=0 and player:_telegraph()
	move_and_slide();for b in touch.get_overlapping_bodies():if b.is_in_group("player") and b.has_method("take_damage"):b.take_damage(3,global_position)

func _telegraph()->void:
	state="tele";timer=0.55 if phase==1 else 0.4;velocity.x=0;Fx.popup(get_parent(),global_position+Vector2(0,-190),["机械剑阵","虚空折跃","光核过载"][phase-1],tint)

func _execute()->void:
	var pick:=randi()%(phase+1)
	if pick==0:state="charge";timer=0.65
	elif pick==1:_barrage(5+phase*2);state="idle";cd=0.9
	elif pick==2:_warn_teleport();state="idle";cd=0.9
	else:_warn_core_pulse();state="idle";cd=1.0

func _barrage(n:int)->void:
	if not player:return
	var o:=global_position+Vector2(0,-100);var aim:=(player.global_position+Vector2(0,-40)-o).normalized()
	for i in range(n):var p:=Area2D.new();p.set_script(PROJ);p.position=o;get_parent().add_child(p);p.setup(aim.rotated(deg_to_rad(lerp(-45.0,45.0,float(i)/float(n-1))))*(360+phase*45),2,Color(0.65,0.3,1))

func _warn_teleport()->void:
	if not player:return
	var target:=player.global_position+Vector2((-1 if randf()<0.5 else 1)*260,-40);Fx.shockwave(get_parent(),target,Color(0.4,0.65,1));_teleport_after_warning.call_deferred(target)

func _teleport_after_warning(target:Vector2)->void:
	await get_tree().create_timer(0.45).timeout
	Fx.death_burst(get_parent(),global_position,Color(0.5,0.2,1));global_position=target;Fx.death_burst(get_parent(),global_position,Color(0.7,0.3,1));_barrage(7)

func _warn_core_pulse()->void:
	Fx.shockwave(get_parent(),global_position,Color(1,0.35,0.8));Fx.popup(get_parent(),global_position+Vector2(0,-190),"光核脉冲 · 远离!",Color(1,0.4,0.7));_core_pulse_after_warning.call_deferred()

func _core_pulse_after_warning()->void:
	await get_tree().create_timer(0.55).timeout;Game.shake(12);Fx.shockwave(get_parent(),global_position,Color(1,0.25,0.55))
	if player and global_position.distance_to(player.global_position)<300 and player.has_method("take_damage"):player.take_damage(3,global_position)

func take_damage(amount:int,_kb:Vector2)->void:
	if state=="dead":return
	hp-=amount;var np:=1 if hp>max_hp*2/3 else(2 if hp>max_hp/3 else 3)
	if np!=phase:phase=np;tint=[Color(0.55,0.25,0.85),Color(0.35,0.65,1),Color(1,0.25,0.55)][phase-1];anim.modulate=tint;anim.scale=Vector2(sprite_scale,sprite_scale)*(1.0+0.1*(phase-1));body_size=Vector2(140+phase*8,170+phase*10);body_col.shape.size=body_size;body_col.position=Vector2(0,-body_size.y*0.5);touch_col.shape.size=body_size;touch_col.position=body_col.position;state="intro";timer=0.9;Fx.screen_flash(get_tree(),Color(tint.r,tint.g,tint.b,0.4));Game.shake(14)
	hp_changed.emit(maxi(hp,0),max_hp,phase);if hp<=0:_die()

func _die()->void:
	state="dead";set_deferred("collision_layer",0);touch.set_deferred("monitoring",false);defeated.emit();Fx.screen_flash(get_tree(),Color(1,1,1,0.6));Fx.death_burst(get_parent(),global_position,Color(1,0.4,0.8));Game.shake(20)
	var tw:=create_tween();tw.tween_property(anim,"modulate:a",0.0,1.0);tw.tween_callback(queue_free)
