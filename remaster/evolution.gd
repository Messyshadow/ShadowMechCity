extends Node
const Data=preload("res://remaster/evolution_data.gd")
var game:Node3D
var form_branch:=""
var form_left:=0.0
var form_visual:Node3D
var summon_branch:=""
var summon_left:=0.0
var summon_unit:Node3D
var summon_model:Node3D
var summon_cooldown:=0.0
var summon_windup:=0.0
var target:Node3D
var action_count:=0
var clock:=0.0

func clear_runtime() -> void:
	end_form();end_summon()
func end_form() -> void:
	if is_instance_valid(form_visual):form_visual.queue_free()
	form_visual=null;form_left=0;form_branch=""
func end_summon() -> void:
	if is_instance_valid(summon_unit):summon_unit.queue_free()
	summon_unit=null;summon_model=null;summon_left=0;summon_branch="";target=null;summon_windup=0
func select_branch(branch:String) -> bool:
	if branch not in Data.BRANCHES:return false
	if form_left>0 or summon_left>0:
		game.toast("变身或召唤结束后，可以切换进化路线。");return false
	Reforged.evolution.branch=branch;Reforged.commit();return true
func available(kind:String) -> bool:
	if not is_instance_valid(game.player) or Reforged.hp<=0 or game.transitioning or game.ui.panel_open:return false
	if game.player.climbing or game.player.lock_input:return false
	var branch:String=Reforged.evolution.branch
	if not Reforged.skills.has(branch+"_"+kind):
		game.toast("按 T → 进化，学习当前路线的"+("变身" if kind=="form" else "召唤")+"技能。");return false
	if Reforged.evolution[kind+"_cd"]>0:
		game.toast("进化"+("变身" if kind=="form" else "召唤")+"冷却 %.1f 秒"%float(Reforged.evolution[kind+"_cd"]));return false
	return true
func activate_form() -> bool:
	if form_left>0 or not available("form"):return false
	form_branch=Reforged.evolution.branch;form_left=Data.duration(Reforged,form_branch)
	form_visual=game.model("evolution_"+form_branch);game.player.visual.add_child(form_visual)
	Reforged.evolution.form_cd=30.0;Reforged.commit()
	game.burst(game.player.position+Vector3.UP,Data.COLORS[form_branch],22);game.audio.play("save",-7)
	game.toast(Data.FORM_NAMES[form_branch]+" · 持续 %d 秒"%int(form_left));return true
func activate_summon() -> bool:
	if summon_left>0 or not available("summon"):return false
	summon_branch=Reforged.evolution.branch;summon_left=Data.duration(Reforged,summon_branch,true)
	summon_unit=Node3D.new();game.world.add_child(summon_unit)
	summon_unit.position=game.player.position+Vector3(-game.player.facing*1.4,1.6,0)
	summon_model=game.model("summon_"+summon_branch);summon_unit.add_child(summon_model)
	summon_cooldown=.45;summon_windup=0;target=null
	Reforged.evolution.summon_cd=22.0;Reforged.commit()
	game.burst(summon_unit.position,Data.COLORS[summon_branch],15);game.audio.play("dash",-5)
	game.toast(Data.SUMMON_NAMES[summon_branch]+" · 持续 %d 秒"%int(summon_left));return true
func damage_scale() -> float:return 1.25 if form_branch=="shadow" else 1.2 if form_branch=="mechanical" else 1.0
func speed_scale() -> float:return 1.18 if form_branch=="shadow" else .9 if form_branch=="mechanical" else 1.0
func incoming_scale() -> float:return .7 if form_branch=="mechanical" else 1.0
func _physics_process(dt:float) -> void:
	if not is_instance_valid(game.player) or game.ui.panel_open or game.transitioning:return
	tick(dt)
func tick(dt:float) -> void:
	if Reforged.hp<=0:clear_runtime();return
	clock+=dt
	for key in ["form_cd","summon_cd"]:Reforged.evolution[key]=maxf(0,float(Reforged.evolution[key])-dt)
	if form_left>0:
		form_left=maxf(0,form_left-dt)
		if form_left<=0:
			game.burst(game.player.position+Vector3.UP,Data.COLORS[form_branch],8);end_form()
		elif is_instance_valid(form_visual):form_visual.scale=Vector3.ONE*(1.0+.015*sin(clock*5))
	if summon_left>0:
		summon_left=maxf(0,summon_left-dt)
		if summon_left<=0:
			if is_instance_valid(summon_unit):game.burst(summon_unit.position,Data.COLORS[summon_branch],8)
			end_summon()
		else:update_summon(dt)
func update_summon(dt:float) -> void:
	if not is_instance_valid(summon_unit):end_summon();return
	if is_instance_valid(target) and (target.dead or target.position.distance_to(game.player.position)>8 or not game.clear_sight(summon_unit.position,target.position+Vector3.UP)):target=null;summon_windup=0
	if not is_instance_valid(target):
		var nearest:=7.0
		for enemy in game.enemies:
			if not is_instance_valid(enemy) or enemy.dead:continue
			var distance:float=enemy.position.distance_to(game.player.position)
			if distance<nearest and game.clear_sight(game.player.position+Vector3.UP,enemy.position+Vector3.UP) and game.clear_sight(summon_unit.position,enemy.position+Vector3.UP):target=enemy;nearest=distance
	var destination:Vector3=game.player.position+Vector3(-game.player.facing*1.4,1.7,0)
	var direction:float=game.player.facing
	if is_instance_valid(target):
		direction=1 if target.position.x>=summon_unit.position.x else -1
		destination=target.position+Vector3(-direction*(1.1 if summon_branch=="shadow" else 3.4),1.0 if summon_branch=="shadow" else 2.0,0)
	summon_unit.position=summon_unit.position.move_toward(destination,dt*7)
	if summon_unit.position.distance_to(game.player.position)>12:summon_unit.position=game.player.position+Vector3(0,1.7,0)
	summon_model.rotation.y=direction*(PI/4 if summon_branch=="shadow" else PI/2);summon_model.position.y=sin(clock*5)*.10
	summon_cooldown=maxf(0,summon_cooldown-dt)
	if summon_windup>0:
		summon_windup-=dt;summon_model.rotation.z=sin(summon_windup*15)*.18
		if summon_windup<=0:resolve_summon();summon_cooldown=1.15 if summon_branch=="shadow" else 1.4
	elif is_instance_valid(target) and summon_cooldown<=0 and summon_unit.position.distance_to(target.position+Vector3.UP)<(2 if summon_branch=="shadow" else 6):
		summon_windup=.22;game.burst(summon_unit.position,Data.COLORS[summon_branch],4)
func resolve_summon() -> void:
	if Reforged.hp<=0 or not is_instance_valid(target) or target.dead:return
	var origin:Vector3=summon_unit.position;var point:Vector3=target.position+Vector3.UP
	if origin.distance_to(point)>(2.2 if summon_branch=="shadow" else 6.0) or not game.clear_sight(origin,point):return
	var damage:=16.0+float(Reforged.level-1)*1.2
	if summon_branch=="shadow":
		var direction:=1.0 if point.x>=origin.x else -1.0
		target.take_hit(damage,direction,false,origin);game.slash(origin,direction,Data.COLORS.shadow,.9);game.audio.play("slash",-12)
	else:game.projectile(origin,(point-origin).normalized()*17,damage,true,Data.COLORS.mechanical,false,false);game.audio.play("shot",-13)
	action_count+=1
func hud_text() -> String:
	var branch:String=Reforged.evolution.branch
	var form:String=Data.FORM_NAMES[branch]+(" %.1fs"%form_left if form_left>0 else " · %.1fs"%float(Reforged.evolution.form_cd) if Reforged.evolution.form_cd>0 else " · 就绪" if Reforged.skills.has(branch+"_form") else " · 未学习")
	var summon:String=Data.SUMMON_NAMES[branch]+(" %.1fs"%summon_left if summon_left>0 else " · %.1fs"%float(Reforged.evolution.summon_cd) if Reforged.evolution.summon_cd>0 else " · 就绪" if Reforged.skills.has(branch+"_summon") else " · 未学习")
	return "进化 · "+Data.NAMES[branch]+"\nZ "+form+"\nV "+summon
