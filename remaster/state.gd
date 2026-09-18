extends Node
## The remaster has its own save schema; the classic save is never overwritten.
signal changed
const SAVE := "user://remaster_v1.json"
var save_path := SAVE
const WEAPONS := ["blade", "hammer", "cannon", "gauntlet"]
const WEAPON_NAMES := ["辉光长刃", "铸炉重锤", "脉冲蒸汽炮", "裂岩动力拳套"]
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
}
var persistence_enabled := true
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
	if not load_game():
		new_game()

func new_game() -> void:
	coins = 90; xp = 0; level = 1; points = 3; weapon = 0
	ammo = 40; magazine = 8; potions = 3; hp = 120; serial = 0; deaths = 0
	skills.clear(); inventory.clear(); equipped.clear(); buyback.clear()
	visited.clear(); bosses.clear(); collected.clear(); merchant_gift = false
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
	return 120.0 + float(level - 1) * 5 + stat("health")

func stat(key: String) -> float:
	var value := 0.0
	for it in equipped.values(): value += float(it.get(key, 0))
	return value

func attack_damage() -> float:
	var damage: float = [18.0, 30.0, 24.0, 12.0][weapon] + stat("attack") + (level - 1) * 1.5
	if skills.has(WEAPONS[weapon] + "_1"): damage *= 1.2
	return damage

func learn(id: String) -> bool:
	if not SKILLS.has(id) or skills.has(id): return false
	var d: Array = SKILLS[id]
	if points < int(d[4]) or (d[3] != "" and not skills.has(d[3])): return false
	points -= int(d[4]); skills[id] = true
	commit()
	return true

func first_trade() -> bool:
	if merchant_gift: return false
	merchant_gift = true
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
		hp = minf(max_health(), hp + 20)
	if is_boss or randf() < .28:
		var rarity := 2 if is_boss else (1 if randf() < .22 else 0)
		var slot: String = SLOTS[randi() % SLOTS.size()]
		# Only 2% of amulet rolls have lifesteal; no guaranteed affix in later drops.
		inventory.append(make_item(slot, rarity, slot == "amulet" and randf() < .02))
	commit()

func rest(room: String, pos: Vector3) -> void:
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
	var data := {"version":1,"coins":coins,"xp":xp,"level":level,"points":points,"weapon":weapon,"hp":hp,"ammo":ammo,"magazine":magazine,"potions":potions,"skills":skills,"inventory":inventory,"equipped":equipped,"buyback":buyback,"visited":visited,"bosses":bosses,"collected":collected,"merchant_gift":merchant_gift,"checkpoint_room":checkpoint_room,"checkpoint":[checkpoint.x,checkpoint.y,checkpoint.z],"serial":serial,"deaths":deaths,"mute":mute}
	var f := FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if f == null: return false
	f.store_string(JSON.stringify(data)); f.close()
	if FileAccess.file_exists(save_path):
		DirAccess.copy_absolute(save_path, save_path + ".bak")
		DirAccess.remove_absolute(save_path)
	return DirAccess.rename_absolute(save_path + ".tmp", save_path) == OK

func load_game() -> bool:
	if not persistence_enabled: return false
	var data: Variant = null
	for path in [save_path, save_path + ".bak"]:
		if FileAccess.file_exists(path):
			data = JSON.parse_string(FileAccess.get_file_as_string(path))
			if data is Dictionary and int(data.get("version", 0)) == 1: break
	if not data is Dictionary or int(data.get("version", 0)) != 1: return false
	for key in ["coins","xp","level","points","weapon","ammo","magazine","potions","serial","deaths"]:
		set(key, maxi(0, int(data.get(key, get(key)))))
	level = maxi(level,1); weapon = clampi(weapon,0,3); magazine = mini(magazine,8); ammo = mini(ammo,120)
	for key in ["skills","equipped","visited","bosses","collected"]:
		if data.get(key) is Dictionary: set(key, data[key])
	for key in ["inventory","buyback"]:
		if data.get(key) is Array: set(key, data[key])
	merchant_gift = bool(data.get("merchant_gift",false)); mute = bool(data.get("mute",false))
	checkpoint_room = str(data.get("checkpoint_room","hub"))
	if not Rooms.ROOMS.has(checkpoint_room): checkpoint_room = "hub"
	var p: Array = data.get("checkpoint",[4,.05,0])
	if p.size() == 3: checkpoint = Vector3(float(p[0]),float(p[1]),0)
	hp = clampf(float(data.get("hp",120)),1,max_health())
	return true
