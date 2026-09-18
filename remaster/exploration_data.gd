extends RefCounted
## Stable collection IDs preserve pre-0.6 chest saves and the original archive names.
const World=preload("res://remaster/world_data.gd")
const Archives=preload("res://scripts/quest_data.gd")
const MODULES := {
	"wall_climb":["磁力攀墙器","贴墙时按住 W 缓慢攀升；也可开启磁力检修口。"],
	"bomb":["脉冲炸弹","F 投掷，1.2 秒后爆炸；可炸开橙色封板，冷却 3.5 秒。"],
	"glide":["滑翔翼","下落时按住空格滑翔；解锁风道检修口。"],
	"aqua":["水下推进器","涉水速度提高 35%；解锁水下密封检修口。"],
	"shadow_glider":["暗影滑翔翼","下落时按住空格，坠落速度降低至 1.6 米/秒。"]
}
const SUPPLY_ROOMS := ["hub","mine","temple_atrium","water_channel","factory_entry","void_core","castle_chapel","dawn_conduit"]
const SEALED_HEARTS := ["heart_temple","heart_water","heart_factory"]
static var cache:Dictionary={}

static func catalog() -> Dictionary:
	if not cache.is_empty():return cache
	for room_id in World.ROOMS:
		var room:Dictionary=World.ROOMS[room_id]
		var items:Array=room.get("items",[]).duplicate()
		if room.get("hidden_room",false):items.append([float(room.bounds[2])*.5,0,"chest",""])
		for i in range(items.size()):
			var kind:="chest" if str(items[i][2])=="chest" else "coin"
			cache[str(room_id)+":"+str(i)]={"room":room_id,"kind":kind,"name":"精工装备箱" if kind=="chest" else "散落金币","x":float(items[i][0])/64.0,"index":i}
		for item in room.get("secrets",[]):
			var id:=str(item[3]);var kind:=str(item[2])
			cache[id]={"room":room_id,"kind":kind,"name":str(Archives.COLLECTIBLES[id].title) if kind=="memory" else "生命碎片","x":float(item[0])/64.0,"sealed":id in SEALED_HEARTS}
		for item in room.get("abilities",[]):
			var id:=str(item[2])
			if MODULES.has(id):cache["module_"+id]={"room":room_id,"kind":"module","name":MODULES[id][0],"module":id,"x":float(item[0])/64.0}
		if room_id in SUPPLY_ROOMS:cache["supply_"+str(room_id)]={"room":room_id,"kind":"supply","name":"巡线补给箱","x":float(room.bounds[2])/64.0*.67}
	return cache

static func count(state:Node,kind:String,room_id:="") -> Vector2i:
	var value:=Vector2i.ZERO
	for id in catalog():
		var data:Dictionary=cache[id]
		if (kind!="" and data.kind!=kind) or (room_id!="" and data.room!=room_id):continue
		value.y+=1
		if state.collected.get(id,false)==true:value.x+=1
	return value

static func has_module(state:Node,id:String) -> bool:
	if id in ["dash","double_jump"]:return true
	if state.collected.get("module_"+id,false)==true:return true
	return state.skills.has({"aqua":"water_drive","wall_climb":"wall_drive"}.get(id,id))

static func missing(state:Node,target:String) -> Array:
	# Old remaster saves retain access to secret rooms already reached.
	if state.visited.get(target,false)==true:return []
	for room in World.ROOMS.values():
		for door in room.get("doors",[]):
			if str(door.to)!=target or not bool(door.get("hidden",false)):continue
			var result:Array=[]
			for ability in door.get("requires",[]):
				if not has_module(state,str(ability)):result.append(str(ability))
			return result
	return []

static func collect(state:Node,id:String) -> String:
	if not catalog().has(id) or state.collected.get(id,false)==true or state.hp<=0:return ""
	var data:Dictionary=cache[id];var message:=""
	match str(data.kind):
		"coin":state.coins+=10;message="+10 金币"
		"chest":
			state.coins+=55;state.inventory.append(state.make_item(state.SLOTS[randi()%6],1));message="精工装备 + 55 金币"
		"supply":
			var rounds:=mini(24,120-int(state.ammo));var bottles:=mini(1,9-int(state.potions))
			if rounds<=0 and bottles<=0:return ""
			state.ammo+=maxi(0,rounds);state.potions+=maxi(0,bottles)
			message="巡线补给 · +%d 备弹 / +%d 药剂"%[maxi(0,rounds),maxi(0,bottles)]
		"heart":message="生命碎片 · 最大生命永久 +10"
		"memory":message="档案已同步 · "+str(data.name)+" · N 查看收藏"
		"module":message="获得 "+str(data.name)+" · N 查看探索模块与用法"
	state.collected[id]=true
	if data.kind=="heart":state.hp=minf(state.max_health(),state.hp+10)
	state.commit();return message
