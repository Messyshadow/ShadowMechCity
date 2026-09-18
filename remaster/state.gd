extends Node
const World = preload("res://remaster/world_data.gd")
const SaveIO = preload("res://remaster/save_io.gd")
const SquadData = preload("res://remaster/squad_data.gd")
const ExplorationData = preload("res://remaster/exploration_data.gd")
const EvolutionData = preload("res://remaster/evolution_data.gd")
## The remaster has its own save schema; the classic save is never overwritten.
signal changed
const SAVE := "user://remaster_v1.json"
var save_path := SAVE
const WEAPONS := ["blade", "hammer", "cannon", "gauntlet", "dual", "spear", "crossbow"]
const WEAPON_NAMES := ["辉光长刃", "铸炉重锤", "脉冲蒸汽炮", "裂岩动力拳套", "影铸双刃", "天穹齿轮枪", "裂隙连发弩"]
const SLOTS := ["helmet", "armor", "gloves", "boots", "amulet", "ring"]
const SKILLS := {
	"blade_1": ["刃舞", "长刃伤害 +20%", "blade", "", 1],
	"blade_2": ["空中追猎", "空中攻击伤害 +40%", "blade", "blade_1", 1],
	"blade_3": ["月弧斩", "K：向前发射贯穿剑气", "blade", "blade_2", 2],
	"hammer_1": ["锻造意志", "重锤伤害 +20%", "hammer", "", 1],
	"hammer_2": ["碎甲", "重锤使敌人硬直更久", "hammer", "hammer_1", 1],
	"hammer_3": ["熔炉震击", "K：大范围震地，破除护甲", "hammer", "hammer_2", 2],
	"cannon_1": ["精密膛线", "蒸汽炮伤害 +20%", "cannon", "", 1],
	"cannon_2": ["弹药回收", "击败敌人额外回收 2 发子弹", "cannon", "cannon_1", 1],
	"cannon_3": ["三联穿甲", "K：消耗 3 发弹药发射三连弹", "cannon", "cannon_2", 2],
	"gauntlet_1": ["铁拳", "拳套四连击伤害 +20%", "gauntlet", "", 1],
	"gauntlet_2": ["升龙驱动", "空中拳击与上勾拳伤害 +40%", "gauntlet", "gauntlet_1", 1],
	"gauntlet_3": ["过载百裂", "K：冲刺并连续重击，附带击退", "gauntlet", "gauntlet_2", 2],
	"dual_1": ["双刃协奏", "双刀伤害 +20%，四段快速连击", "dual", "", 1],
	"dual_2": ["空中回旋", "双刀空中攻击伤害 +40%", "dual", "dual_1", 1],
	"dual_3": ["影刃风暴", "K：向前连续追击，并对两侧敌人斩击", "dual", "dual_2", 2],
	"spear_1": ["长锋贯刺", "长枪伤害 +20%，普通攻击距离 3.6 米", "spear", "", 1],
	"spear_2": ["破盾枪尖", "长枪命中无视盾面减伤，并延长普通敌人硬直", "spear", "spear_1", 1],
	"spear_3": ["天穹穿刺", "K：向前 6 米贯刺；不会穿过实体墙壁", "spear", "spear_2", 2],
	"crossbow_1": ["精密弩机", "弓弩伤害 +20%，使用有限弹药", "crossbow", "", 1],
	"crossbow_2": ["贯穿箭矢", "普通弩箭可以贯穿多个敌人", "crossbow", "crossbow_1", 1],
	"crossbow_3": ["裂隙散射", "K：消耗 3 发弹药，发射三枚贯穿弩箭", "crossbow", "crossbow_2", 2],
	"stride": ["轻盈步伐", "地面移动速度 +12%", "movement", "", 1],
	"dash_flow": ["疾影回转", "冲刺冷却从 0.65 秒缩短至 0.45 秒", "movement", "stride", 1],
	"triple_jump": ["空中接力", "增加一次空中跳跃，最多三段跳", "movement", "dash_flow", 2],
	"wall_drive": ["壁面驱动", "蹬墙跳起跳速度与水平推力提高 20%", "movement", "stride", 1],
	"glide": ["滑翔翼", "下降时按住空格，降低坠落速度至 2.5 米/秒", "movement", "wall_drive", 2],
	"water_drive": ["水下推进", "涉水移动速度提高 35%", "movement", "wall_drive", 1],
	"shadow_guard": ["影幕庇护", "受到攻击后的无敌时间增加 0.25 秒", "shadow", "", 1],
	"shadow_step": ["残影闪避", "冲刺无敌时间增加 0.12 秒", "shadow", "shadow_guard", 1],
	"shadow_edge": ["暗影破势", "命中处于收招状态的敌人时，伤害提高 20%", "shadow", "shadow_step", 2],
	"core_shell": ["核心护层", "最大生命 +20", "mechanical", "", 1],
	"fast_loader": ["快速装填", "蒸汽炮装填时间从 0.9 秒缩短至 0.6 秒", "mechanical", "core_shell", 1],
	"overclock": ["机械超频", "武器终阶技能冷却从 4 秒缩短至 3 秒", "mechanical", "fast_loader", 2],
	"shadow_form": ["夜幕化身", "Z：暗影变身 10 秒，武器伤害 +25%、移动速度 +18%。冷却 30 秒。", "shadow", "shadow_guard", 2],
	"shadow_summon": ["影侍投影", "V：召唤影侍 12 秒，自动近身斩击。冷却 22 秒。投影不可被攻击。", "shadow", "shadow_form", 2],
	"shadow_mastery": ["长夜共鸣", "暗影变身延长至 14 秒，影侍持续 16 秒。", "shadow", "shadow_summon", 2],
	"mechanical_form": ["炉心战甲", "Z：机械变身 10 秒，武器伤害 +20%、受到伤害 -30%、移速 -10%。冷却 30 秒。", "mechanical", "core_shell", 2],
	"mechanical_summon": ["浮游炮台", "V：召唤能量炮台 12 秒，自动发射脉冲弹，不耗枪械弹药。冷却 22 秒。", "mechanical", "mechanical_form", 2],
	"mechanical_mastery": ["永续驱动", "机械变身延长至 14 秒，炮台持续 16 秒。", "mechanical", "mechanical_summon", 2],
}
const DEFAULT_SETTINGS := {"master":.85,"music":.60,"effects":.85,"ambience":.65,"brightness":1.12,"fullscreen":false,"shake":.65,"tutorial":true}
var settings: Dictionary = DEFAULT_SETTINGS.duplicate()
var settings_path := "user://remaster_settings.cfg"
var story: Dictionary = {}
var tutorial: Dictionary = {}
var squad: Dictionary = SquadData.fresh()
var evolution: Dictionary = EvolutionData.fresh()
var persistence_enabled := true
var save_blocked := false
var save_notice := ""
var last_recovery_folder := ""
var coins := 90
var xp := 0
var level := 1
var points := 3
var weapon := 0
var hp := 120.0
var ammo := 40
var magazine := 8
var potions := 3
var skills: Dictionary = {}
var inventory: Array = []
var equipped: Dictionary = {}
var buyback: Array = []
var visited: Dictionary = {}
var bosses: Dictionary = {}
var collected: Dictionary = {}
var merchant_gift := false
var checkpoint_room := "hub"
var checkpoint := Vector3(4, .05, 0)
var serial := 0
var deaths := 0
var mute := false

func _ready() -> void:
	if "--remaster-test" in OS.get_cmdline_user_args():
		persistence_enabled=false;new_game();return
	load_settings();apply_settings()
	if not load_game():
		new_game()

func new_game() -> void:
	coins = 90; xp = 0; level = 1; points = 3; weapon = 0
	ammo = 40; magazine = 8; potions = 3; hp = 120; serial = 0; deaths = 0
	skills.clear(); inventory.clear(); equipped.clear(); buyback.clear()
	visited.clear(); bosses.clear(); collected.clear(); merchant_gift = false
	story.clear();tutorial.clear()
	squad=SquadData.fresh()
	evolution=EvolutionData.fresh()
	checkpoint_room = "hub"; checkpoint = Vector3(4, .05, 0)
	inventory.append(make_item("armor", 0))
	inventory.append(make_item("boots", 0))
	inventory.append(make_item("helmet", 0))
	changed.emit()

func make_item(slot: String, rarity: int, lifesteal := false) -> Dictionary:
	serial += 1
	var names := {"helmet":"守夜面甲", "armor":"铆接胸甲", "gloves":"驱动护手", "boots":"行者铁靴", "amulet":"炉心护符", "ring":"铜制指环"}
	var prefix := ["旧制", "精工", "遗迹", "君王"]
	var it := {"uid":serial, "slot":slot, "rarity":rarity, "name":prefix[rarity] + "·" + names[slot], "attack":0.0, "armor":0.0, "health":0.0, "lifesteal":0.0, "price":18 + rarity * 34}
	if slot in ["gloves", "ring"]: it.attack = 2.0 + rarity * 2
	elif slot in ["helmet", "armor", "boots"]:
		it.armor = 1.0 + rarity * 1.5; it.health = 4.0 + rarity * 5
	else: it.health = 8.0 + rarity * 6
	if lifesteal:
		it.lifesteal = .03 if rarity < 2 else .04
		it.name = "余烬·吸血护符" if rarity == 1 else "血焰·炉心护符"
	return it

func max_health() -> float:
	return 120.0 + float(level - 1) * 5 + stat("health") + (20.0 if skills.has("core_shell") else 0.0) + ExplorationData.count(self,"heart").x*10.0

func stat(key: String) -> float:
	var value := 0.0
	for it in equipped.values(): value += float(it.get(key, 0))
	return value

func attack_damage() -> float:
	var damage: float = [18.0, 30.0, 24.0, 12.0, 11.0, 22.0, 20.0][weapon] + stat("attack") + (level - 1) * 1.5
	if skills.has(WEAPONS[weapon] + "_1"): damage *= 1.2
	return damage

func learn(id: String) -> bool:
	if not SKILLS.has(id) or skills.has(id): return false
	var d: Array = SKILLS[id]
	if points < int(d[4]) or (d[3] != "" and not skills.has(d[3])): return false
	points -= int(d[4]); skills[id] = true
	tutorial["skill"]=true
	commit()
	return true

func first_trade() -> bool:
	if merchant_gift:
		if not tutorial.get("trade",false):tutorial["trade"]=true;commit()
		return false
	merchant_gift = true
	tutorial["trade"]=true
	var gift := make_item("amulet", 1, true)
	inventory.append(gift)
	if not equipped.has("amulet"): equipped.amulet = gift.duplicate(true)
	commit()
	return true

func equip_item(uid: int) -> bool:
	for it in inventory:
		if int(it.uid) == uid:
			equipped[it.slot] = it.duplicate(true)
			hp = minf(hp, max_health()); commit(); return true
	return false

func upgrade_cost(it: Dictionary) -> int:
	return 35+int(it.get("upgrade",0))*30+int(it.rarity)*15

func upgrade_item(uid: int) -> bool:
	for it in inventory:
		if int(it.uid)!=uid:continue
		if int(it.get("upgrade",0))>=5:return false
		var cost:=upgrade_cost(it)
		if coins<cost:return false
		coins-=cost;it["upgrade"]=int(it.get("upgrade",0))+1
		if str(it.slot) in ["gloves","ring"]:it.attack=float(it.attack)+1.5
		else:it.health=float(it.health)+3;it.armor=float(it.armor)+.5
		# Enhancement never raises lifesteal. The same UID survives sale/buyback.
		it.price=int(it.price)+int(cost*.4)
		if int(equipped.get(it.slot,{}).get("uid",-1))==uid:equipped[it.slot]=it.duplicate(true)
		commit();return true
	return false

func sell(uid: int) -> bool:
	for i in range(inventory.size()):
		var it: Dictionary = inventory[i]
		if int(it.uid) != uid: continue
		if int(equipped.get(it.slot, {}).get("uid", -1)) == uid: return false
		var record := it.duplicate(true)
		record["buyback_price"] = int(it.price)
		coins += int(it.price); buyback.append(record); inventory.remove_at(i)
		commit(); return true
	return false

func sell_white() -> int:
	var ids: Array = []
	for it in inventory:
		if int(it.rarity) == 0 and int(equipped.get(it.slot, {}).get("uid", -1)) != int(it.uid): ids.append(int(it.uid))
	for uid in ids: sell(uid)
	return ids.size()

func repurchase(uid: int) -> bool:
	for i in range(buyback.size()):
		var it: Dictionary = buyback[i]
		if int(it.uid) != uid: continue
		if coins < int(it.buyback_price): return false
		coins -= int(it.buyback_price)
		var restored := it.duplicate(true); restored.erase("buyback_price")
		inventory.append(restored); buyback.remove_at(i); commit(); return true
	return false

func buy(kind: String) -> bool:
	var price := {"ammo":25, "potion":30, "armor":115, "gloves":110}
	if not price.has(kind) or coins < int(price[kind]): return false
	if kind == "ammo" and ammo >= 120: return false
	if kind == "potion" and potions >= 9: return false
	coins -= int(price[kind])
	match kind:
		"ammo": ammo = mini(120, ammo + 24)
		"potion": potions += 1
		_: inventory.append(make_item(kind, 1))
	commit(); return true

func reward(is_boss := false) -> void:
	coins += 150 if is_boss else 14
	xp += 120 if is_boss else 25
	ammo = mini(120, ammo + (6 if is_boss else (3 if skills.has("cannon_2") else 1)))
	while xp >= level * 90:
		xp -= level * 90; level += 1; points += 2
		if hp>0:hp = minf(max_health(), hp + 20)
	if is_boss or randf() < .28:
		var rarity := 2 if is_boss else (1 if randf() < .22 else 0)
		var slot: String = SLOTS[randi() % SLOTS.size()]
		# Only 2% of amulet rolls have lifesteal; no guaranteed affix in later drops.
		inventory.append(make_item(slot, rarity, slot == "amulet" and randf() < .02))
	commit()

func rest(room: String, pos: Vector3) -> void:
	tutorial["save"]=true
	checkpoint_room = room; checkpoint = pos
	hp = max_health(); magazine = 8; ammo = maxi(ammo, 24); potions = maxi(potions, 3)
	commit()

func respawn() -> void:
	deaths += 1; hp = max_health(); magazine = 8; ammo = maxi(ammo, 16)
	commit()

func commit() -> void:
	changed.emit(); save_game()

func save_game() -> bool:
	if not persistence_enabled: return true
	if save_blocked:return false
	var data := {"version":1,"coins":coins,"xp":xp,"level":level,"points":points,"weapon":weapon,"hp":hp,"ammo":ammo,"magazine":magazine,"potions":potions,"skills":skills,"inventory":inventory,"equipped":equipped,"buyback":buyback,"visited":visited,"bosses":bosses,"collected":collected,"merchant_gift":merchant_gift,"checkpoint_room":checkpoint_room,"checkpoint":[checkpoint.x,checkpoint.y,checkpoint.z],"serial":serial,"deaths":deaths,"mute":mute}
	data["story"]=story;data["tutorial"]=tutorial;data["squad"]=squad
	data["evolution"]=evolution
	return SaveIO.write(save_path,data)

func load_game() -> bool:
	if not persistence_enabled: return false
	var result:=SaveIO.read_best(save_path)
	save_blocked=bool(result.broken);save_notice=""
	var data:Variant=result.data
	if data==null:
		if save_blocked:save_notice="存档暂时无法读取，已暂停自动保存并保留原文件。"
		return false
	if result.source!=save_path:save_notice="已从可用备份恢复进度。建议到同步终端再次保存。"
	for key in ["coins","xp","level","points","weapon","ammo","magazine","potions","serial","deaths"]:
		set(key, maxi(0, int(data.get(key, get(key)))))
	level = maxi(level,1); weapon = clampi(weapon,0,WEAPONS.size()-1); magazine = mini(magazine,8); ammo = mini(ammo,120)
	squad=data.get("squad",SquadData.fresh())
	evolution=EvolutionData.sanitize(data.get("evolution",{}))
	for key in ["skills","equipped","visited","bosses","collected","story","tutorial"]:
		set(key, data.get(key,{}))
	for key in ["inventory","buyback"]:
		if data.get(key) is Array: set(key, data[key])
	# JSON represents every number as a float. Restore the item's integer fields
	# so UID comparisons, prices and labels (e.g. +5) retain their original type.
	for items in [inventory,buyback,equipped.values()]:
		for it in items:
			if it is Dictionary:
				for key in ["uid","rarity","price","buyback_price","upgrade"]:
					if it.has(key):it[key]=int(it[key])
	merchant_gift = bool(data.get("merchant_gift",false)); mute = bool(data.get("mute",false))
	checkpoint_room = str(data.get("checkpoint_room","hub"))
	var p: Array = data.get("checkpoint",[4,.05,0])
	if p.size() == 3: checkpoint = Vector3(float(p[0]),float(p[1]),0)
	if not World.ROOMS.has(checkpoint_room):checkpoint_room="hub";checkpoint=Vector3(4,.05,0)
	hp = clampf(float(data.get("hp",120)),0,max_health())
	if hp<=0:
		deaths+=1;hp=max_health();magazine=8;ammo=maxi(ammo,16)
		save_notice="上次旅程中核心已熄灭，现从最后存档点重生。"
	return true

func begin_new_journey() -> bool:
	if save_blocked:
		last_recovery_folder=SaveIO.archive(save_path)
		if last_recovery_folder.is_empty():return false
		save_blocked=false;save_notice="已保留损坏存档副本，新的旅程将使用新存档。"
	new_game();return true

func recover_life(damage_dealt: float) -> void:
	# Damage from projectiles already in flight must not revive a dying hunter.
	if hp<=0 or damage_dealt<=0:return
	hp=minf(max_health(),hp+damage_dealt*clampf(stat("lifesteal"),0,.08))

func expand_squad() -> bool:
	var cost:int=SquadData.slot_cost(int(squad.slots))
	if cost==0 or points<cost:return false
	points-=cost;squad.slots+=1;commit();return true

func assign_companion(id:String) -> bool:
	if not SquadData.PROFILES.has(id):return false
	if squad.loadout.has(id):
		if squad.loadout.size()==1:return false
		squad.loadout.erase(id)
	elif squad.loadout.size()<int(squad.slots):squad.loadout.append(id)
	elif int(squad.slots)==1:squad.loadout=[id]
	else:return false
	commit();return true

func set_setting(key: String, value: Variant) -> void:
	if not DEFAULT_SETTINGS.has(key):return
	if key in ["fullscreen","tutorial"]:settings[key]=bool(value)
	else:settings[key]=clampf(float(value),.85 if key=="brightness" else 0.0,1.5 if key=="brightness" else 1.0)
	apply_settings();save_settings();changed.emit()

func apply_settings() -> void:
	for id in ["Music","Effects","Ambience"]:
		if AudioServer.get_bus_index(id)<0:
			AudioServer.add_bus();AudioServer.set_bus_name(AudioServer.bus_count-1,id)
	for pair in [["Master","master"],["Music","music"],["Effects","effects"],["Ambience","ambience"]]:
		var bus:=AudioServer.get_bus_index(pair[0]);var volume:=float(settings[pair[1]])
		AudioServer.set_bus_volume_db(bus,linear_to_db(maxf(.001,volume)))
		AudioServer.set_bus_mute(bus,volume<=0.0 or (pair[0]=="Master" and mute))
	if DisplayServer.get_name()!="headless":
		var mode:=DisplayServer.WINDOW_MODE_FULLSCREEN if bool(settings.fullscreen) else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode()!=mode:DisplayServer.window_set_mode(mode)

func save_settings() -> Error:
	if not persistence_enabled:return OK
	var config:=ConfigFile.new()
	for key in settings:config.set_value("preferences",key,settings[key])
	return config.save(settings_path)

func load_settings() -> void:
	var config:=ConfigFile.new()
	settings=DEFAULT_SETTINGS.duplicate()
	if config.load(settings_path)!=OK:return
	for key in settings:
		var value:Variant=config.get_value("preferences",key,settings[key])
		settings[key]=bool(value) if key in ["fullscreen","tutorial"] else clampf(float(value),.85 if key=="brightness" else 0.0,1.5 if key=="brightness" else 1.0)

func claim_beacon_reward() -> bool:
	if not story.get("beacon_accepted",false) or not story.get("beacon_online",false) or story.get("beacon_claimed",false):return false
	story["beacon_claimed"]=true;coins+=80;points+=2;commit();return true

func tutorial_step() -> Array:
	for step in [["move","A / D 移动，沿明亮的平台边缘前进"],["jump","空格跳跃；在空中再次按下可二段跳"],["dash","Shift 冲刺，可穿过敌人的攻击"],["attack","J 连击；按 Q 可切换武器"],["save","靠近青色终端按 E，设置死亡返回的存档点"],["trade","与赫克交谈领取护符；出售的装备可以回购"],["skill","按 T 打开技能树，选择节点查看效果并学习"]]:
		if not tutorial.get(step[0],false):return step
	return []
