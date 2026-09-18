extends Node
const Data=preload("res://remaster/squad_data.gd")
const Unit=preload("res://remaster/companion.gd")
var game:Node3D
var units:Dictionary={}

func refresh() -> void:
	for unit in units.values():
		if is_instance_valid(unit):unit.queue_free()
	units.clear()
	if not Reforged.squad.deployed or not is_instance_valid(game.world):return
	for i in range(Reforged.squad.loadout.size()):
		var id:String=Reforged.squad.loadout[i]
		if not Reforged.squad.status.has(id):Reforged.squad.status[id]={"hp":Data.PROFILES[id].hp,"rebuild":0.0}
		var unit:=CharacterBody3D.new();unit.set_script(Unit);unit.game=game;unit.controller=self;unit.identity=id;unit.formation=i
		unit.position=game.player.position+Vector3(-1.5-i*1.1,2.0 if Data.PROFILES[id].air else .1,0)
		game.world.add_child(unit);units[id]=unit

func toggle() -> void:
	if Reforged.hp<=0:return
	Reforged.squad.deployed=not Reforged.squad.deployed;refresh();Reforged.commit()
	game.toast("量子伙伴已部署 · G 调整阵容" if Reforged.squad.deployed else "量子伙伴已回收 · C 再次部署")

func _physics_process(dt:float) -> void:
	if not is_instance_valid(game.player) or game.ui.panel_open or game.transitioning:return
	Reforged.squad.lock=maxf(0,float(Reforged.squad.lock)-dt)
	Reforged.squad.heat=maxf(0,float(Reforged.squad.heat)-dt*(6.0 if units.size()>=3 else 10.0))
	for id in Reforged.squad.status:
		var status:Dictionary=Reforged.squad.status[id]
		if status.rebuild>0:
			status.rebuild=maxf(0,float(status.rebuild)-dt)
			if status.rebuild<=0:
				status.hp=Data.PROFILES[id].hp
				if units.has(id) and is_instance_valid(units[id]):units[id].reassemble()
	if Input.is_action_just_pressed("r_companion"):toggle()

func power_scale() -> float:return .72 if units.size()>=3 else .86 if units.size()==2 else 1.0

func action_committed() -> void:
	Reforged.squad.heat=minf(100,float(Reforged.squad.heat)+(14 if units.size()>=3 else 8 if units.size()==2 else 0))
	if Reforged.squad.heat>=100:Reforged.squad.lock=2.4;Reforged.squad.heat=55.0;game.toast("量子链路过载 · 伙伴暂时停止攻击与修复",2.4)

func area_damage(center:Vector3,half_width:float,height:float,amount:float) -> void:
	for unit in units.values():
		if is_instance_valid(unit) and absf(unit.position.x-center.x)<half_width and absf(unit.position.y-center.y)<height and game.clear_sight(center+Vector3.UP,unit.position+Vector3.UP):unit.take_damage(amount)

func intercept(a:Vector3,b:Vector3,damage:float) -> bool:
	var segment:=b-a;var closest:Node3D=null;var time:=2.0
	for unit in units.values():
		if not is_instance_valid(unit) or unit.status().hp<=0:continue
		var center:Vector3=unit.position+Vector3.UP*.6
		var t:=clampf((center-a).dot(segment)/maxf(.0001,segment.length_squared()),0,1)
		if center.distance_to(a+segment*t)<.65 and t<time:closest=unit;time=t
	if closest:closest.take_damage(damage);return true
	return false

func hud_text() -> String:
	if not Reforged.squad.deployed:return "C  部署量子伙伴    G  阵容"
	var value:="C 回收 / G 阵容   热量 %d%%"%int(Reforged.squad.heat)
	if Reforged.squad.lock>0:value+="  冷却 %.1fs"%float(Reforged.squad.lock)
	for id in Reforged.squad.loadout:
		var status:Dictionary=Reforged.squad.status.get(id,{"hp":Data.PROFILES[id].hp,"rebuild":0.0})
		value+="\n"+str(Data.PROFILES[id].name)+("  重构 %.1fs"%float(status.rebuild) if status.rebuild>0 else "  %d/%d"%[ceili(status.hp),int(Data.PROFILES[id].hp)])
	return value
