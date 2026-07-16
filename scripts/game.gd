extends Node
## 全局单例(autoload): 注册输入、命中顿帧(hitstop)、屏幕震动路由、计分

signal enemy_killed(total: int)
signal progression_changed     # xp/level/coins 变化
signal skills_changed          # 技能加点变化
signal gear_changed            # 装备变化(刷新人物属性/背包UI)
signal dialogue_started(npc_id: String)
signal dialogue_ended(npc_id: String)
signal quest_changed(states: Dictionary)

const QuestRuntime = preload("res://scripts/quest_runtime.gd")

var kills: int = 0
var weapon_index: int = 0      # 跨关卡保留当前武器
var unlocked_weapons: Array[String] = ["sword", "hammer", "cannon"]
var _hitstop_token: int = 0

# ---- 成长系统 ----
var xp: int = 0
var level: int = 1
var skill_points: int = 0
var coins: int = 0
var skills: Dictionary = {}    # skill_id -> 已点等级

# ---- 银河城世界状态 ----
signal map_changed
var current_room: String = ""
var menu_open: int = 0              # 已打开的 UI 面板数(技能/地图/设置/暂停), >0 时禁止 Esc 暂停冲突
var visited: Dictionary = {}        # room_id -> true
var items: Dictionary = {}          # 钥匙/能力 id -> true
var unlocked_doors: Dictionary = {} # "roomA>roomB" -> true (已解锁的门)
var dialogue_flags: Dictionary = {} # 首次见面/已读节点等对话状态
var story_flags: Dictionary = {}    # 阶段12任务与阶段11伏笔共用的叙事标记
var quest_flags: Dictionary = {}    # complete:<quest_id> -> true，兼容事实回算
var tracked_quest_id: String = "echo_coordinates"

# ---- 收集系统(隐藏宝藏/生命碎片, 回溯解锁) ----
var collected: Dictionary = {}      # secret_id -> true (已收集, 不再刷出)
var cleared_rooms: Dictionary = {}  # 本次生命内已清空的战斗房，过门不立即刷怪
var opened_chests: Dictionary = {}  # 本次生命内已开的普通宝箱，防反复进门刷奖励
var permanent_chests: Dictionary = {} # 永久宝箱完成度；读档后不重复生成
var heart_pieces: int = 0           # 生命碎片数 → 永久 +最大生命
const HEART_TOTAL := 6              # 全图生命碎片总数(收集度统计)

func is_collected(id: String) -> bool:
	return collected.has(id)

func collect_secret(id: String, kind: String) -> void:
	if id == "" or collected.has(id):
		return
	collected[id] = true
	if kind == "heart":
		heart_pieces += 1
	gear_changed.emit()      # 刷新玩家最大生命
	map_changed.emit()       # 刷新地图收集度

func visit_room(id: String) -> void:
	current_room = id
	if not visited.has(id):
		visited[id] = true
	map_changed.emit()
	refresh_quests()

func mark_room_cleared(id: String) -> void:
	if id != "":
		cleared_rooms[id] = true

func is_room_cleared(id: String) -> bool:
	return cleared_rooms.has(id)

func open_session_chest(id: String) -> void:
	if id != "":
		opened_chests[id] = true
		permanent_chests[id] = true
		map_changed.emit()

func is_session_chest_open(id: String) -> bool:
	return opened_chests.has(id)

func is_chest_collected(id: String) -> bool:
	return permanent_chests.has(id)

func reset_session_encounters() -> void:
	cleared_rooms.clear()
	opened_chests.clear()

func give_item(id: String) -> void:
	items[id] = true
	map_changed.emit()
	refresh_quests()

func has_item(id: String) -> bool:
	return items.has(id)

func unlock_door(tag: String) -> void:
	unlocked_doors[tag] = true

func is_door_unlocked(tag: String) -> bool:
	return unlocked_doors.has(tag)

# ---- 存档 / 读档 ----
const SAVE_PATH := "user://save.json"
var player_hp: int = 5      # 存档时由 main 写入

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> void:
	var data := {
		"xp": xp, "level": level, "skill_points": skill_points, "coins": coins,
		"kills": kills, "weapon_index": weapon_index, "player_hp": player_hp,
		"skills": skills, "items": items, "unlocked_doors": unlocked_doors,
		"visited": visited, "current_room": current_room,
		"inventory": inventory, "equipped": equipped, "abilities": abilities,
		"unlocked_weapons": unlocked_weapons,
		"collected": collected, "heart_pieces": heart_pieces,
		"permanent_chests": permanent_chests,
		"dialogue_flags": dialogue_flags, "story_flags": story_flags,
		"quest_flags": quest_flags, "tracked_quest_id": tracked_quest_id,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()

func load_save() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		return false
	xp = int(data.get("xp", 0)); level = int(data.get("level", 1))
	skill_points = int(data.get("skill_points", 0)); coins = int(data.get("coins", 0))
	kills = int(data.get("kills", 0)); weapon_index = int(data.get("weapon_index", 0))
	player_hp = int(data.get("player_hp", 5))
	skills = data.get("skills", {}); items = data.get("items", {})
	unlocked_doors = data.get("unlocked_doors", {}); visited = data.get("visited", {})
	current_room = data.get("current_room", "")
	inventory = data.get("inventory", []); equipped = data.get("equipped", {})
	abilities = data.get("abilities", {})
	unlocked_weapons = _migrate_weapon_unlocks(data.get("unlocked_weapons", []))
	if weapon_index < 0 or weapon_index >= Weapons.LIST.size() or not is_weapon_unlocked(Weapons.LIST[weapon_index]["id"]):
		weapon_index = 0
	collected = data.get("collected", {}); heart_pieces = int(data.get("heart_pieces", 0))
	permanent_chests = data.get("permanent_chests", {})
	var loaded_dialogue = data.get("dialogue_flags", {})
	var loaded_story = data.get("story_flags", {})
	dialogue_flags = loaded_dialogue if loaded_dialogue is Dictionary else {}
	story_flags = loaded_story if loaded_story is Dictionary else {}
	var loaded_quests = data.get("quest_flags", {})
	quest_flags = loaded_quests if loaded_quests is Dictionary else {}
	tracked_quest_id = str(data.get("tracked_quest_id", ""))
	refresh_quests(false)
	return true

func reset() -> void:
	xp = 0; level = 1; skill_points = 0; coins = 0; kills = 0
	weapon_index = 0; player_hp = 5
	skills = {}; items = {}; unlocked_doors = {}; visited = {}; current_room = ""
	inventory = []; equipped = {}; abilities = {}; unlocked_weapons = ["sword", "hammer", "cannon"]
	collected = {}; heart_pieces = 0
	permanent_chests = {}
	dialogue_flags = {}; story_flags = {}; quest_flags = {}; tracked_quest_id = "echo_coordinates"
	reset_session_encounters()
	refresh_quests(false)

func xp_needed() -> int:
	return 4 + level * 3

func add_xp(n: int) -> void:
	xp += n
	while xp >= xp_needed():
		xp -= xp_needed()
		level += 1
		skill_points += 1
	progression_changed.emit()

func add_coins(n: int) -> void:
	coins += n
	progression_changed.emit()

func skill_lv(id: String) -> int:
	return skills.get(id, 0)

func can_upgrade(node: Dictionary) -> bool:
	if skill_lv(node["id"]) >= node["max"]:
		return false
	if skill_points < node["cost"]:
		return false
	for req in node["req"]:
		if skill_lv(req) <= 0:
			return false
	return true

func upgrade_skill(node: Dictionary) -> bool:
	if not can_upgrade(node):
		return false
	skills[node["id"]] = skill_lv(node["id"]) + 1
	skill_points -= node["cost"]
	skills_changed.emit()
	progression_changed.emit()
	return true

# ---- 背包 / 装备 ----
var inventory: Array = []        # 未装备物品(item 字典)
var equipped: Dictionary = {}    # slot -> item

func add_item(item: Dictionary) -> void:
	inventory.append(item)
	gear_changed.emit()

func equip_item(idx: int) -> void:
	if idx < 0 or idx >= inventory.size():
		return
	var item: Dictionary = inventory[idx]
	inventory.remove_at(idx)
	var slot: String = item["slot"]
	if equipped.has(slot):
		inventory.append(equipped[slot])
	equipped[slot] = item
	gear_changed.emit()

func unequip(slot: String) -> void:
	if equipped.has(slot):
		inventory.append(equipped[slot])
		equipped.erase(slot)
		gear_changed.emit()

func enhance(item: Dictionary) -> bool:
	var cost: int = ItemsData.enhance_cost(item)
	if coins < cost:
		return false
	coins -= cost
	item["lv"] = int(item.get("lv", 0)) + 1
	progression_changed.emit()
	gear_changed.emit()
	return true

func equip_bonus(stat: String) -> float:
	var total := 0.0
	for slot in equipped:
		total += ItemsData.value(equipped[slot], stat)
	return total

# ---- 能力(银河城: 找到才解锁, 用于能力门) ----
var abilities: Dictionary = {}     # ability_id -> true
const ABILITY_NAME := {"dash": "冲刺", "bomb": "炸弹", "wall_climb": "攀墙", "glide": "滑翔翼", "shadow_glider": "暗影滑翔翼", "aqua": "水下推进器", "double_jump": "二段跳"}

func has_ability(id: String) -> bool:
	return abilities.has(id)

func grant_ability(id: String) -> void:
	abilities[id] = true
	# 兼容升级：暗影滑翔翼包含旧 glide，旧存档和熔岩腔穴能力均不失效。
	if id == "shadow_glider":
		abilities["glide"] = true
	progression_changed.emit()

func completion_snapshot() -> Dictionary:
	return Completion.snapshot(Rooms.ROOMS, visited, items, permanent_chests, unlocked_weapons, collected)

func narrative_snapshot() -> Dictionary:
	var completion := completion_snapshot()
	return {
		"visited_count": visited.size(),
		"hidden_count": int(completion.get("hidden", {}).get("done", 0)),
		"boss_count": _boss_defeat_count(),
		"memory_count": _memory_count(),
		"weapon_count": unlocked_weapons.size(),
	}

func quest_snapshot() -> Dictionary:
	var narrative := narrative_snapshot()
	return {
		"visited": visited.duplicate(true),
		"items": items.duplicate(true),
		"dialogue_flags": dialogue_flags.duplicate(true),
		"story_flags": story_flags.duplicate(true),
		"unlocked_weapons": unlocked_weapons.duplicate(),
		"collected": collected.duplicate(true),
		"kills": kills,
		"hidden_count": narrative.get("hidden_count", 0),
		"boss_count": narrative.get("boss_count", 0),
		"memory_count": narrative.get("memory_count", 0),
		"weapon_count": narrative.get("weapon_count", 0),
	}

func refresh_quests(notify: bool = true) -> Dictionary:
	var runtime = QuestRuntime.new()
	var states: Dictionary = runtime.evaluate_all(quest_snapshot(), quest_flags)
	var side_states: Dictionary = runtime.evaluate_side(quest_snapshot(), quest_flags)
	states.merge(side_states)
	var changed := false
	for quest_id in states:
		if str(states[quest_id].get("status", "")) == "complete":
			var flag := "complete:" + str(quest_id)
			if not quest_flags.has(flag):
				quest_flags[flag] = true
				changed = true
	tracked_quest_id = runtime.pick_tracked(states, tracked_quest_id)
	if notify:
		quest_changed.emit(states)
	return {"states": states, "changed": changed, "tracked": tracked_quest_id}

func set_tracked_quest(id: String) -> bool:
	var states: Dictionary = QuestRuntime.new().evaluate_all(quest_snapshot(), quest_flags)
	states.merge(QuestRuntime.new().evaluate_side(quest_snapshot(), quest_flags))
	if not states.has(id) or str(states[id].get("status", "")) == "locked":
		return false
	if tracked_quest_id == id:
		return true
	tracked_quest_id = id
	quest_changed.emit(states)
	return true

func set_dialogue_flag(id: String) -> bool:
	if id == "" or dialogue_flags.has(id):
		return false
	dialogue_flags[id] = true
	refresh_quests()
	return true

func set_story_flag(id: String) -> bool:
	if id == "" or story_flags.has(id):
		return false
	story_flags[id] = true
	refresh_quests()
	return true

func _boss_defeat_count() -> int:
	var total := 0
	for key in items:
		if str(key).begins_with("boss_"):
			total += 1
	return total

func _memory_count() -> int:
	var total := 0
	for key in collected:
		if str(key).begins_with("memory_"):
			total += 1
	return total

func unlock_weapon(id: String) -> bool:
	if is_weapon_unlocked(id):
		return false
	for weapon in Weapons.LIST:
		if weapon["id"] == id:
			unlocked_weapons.append(id)
			progression_changed.emit()
			return true
	return false

func is_weapon_unlocked(id: String) -> bool:
	return unlocked_weapons.has(id)

func _migrate_weapon_unlocks(saved: Variant) -> Array[String]:
	var result: Array[String] = ["sword", "hammer", "cannon"]
	if saved is Array:
		for id in saved:
			var sid := str(id)
			if not result.has(sid):
				for weapon in Weapons.LIST:
					if weapon["id"] == sid:
						result.append(sid)
	return result

const ACTIONS := {
	"move_left":  [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"move_up":    [KEY_W, KEY_UP],
	"move_down":  [KEY_S, KEY_DOWN],
	"jump":       [KEY_SPACE],
	"attack":     [KEY_J],
	"dash":       [KEY_L, KEY_SHIFT],
	"skill":      [KEY_K],
	"switch":     [KEY_Q],
	"skill_menu": [KEY_T],
	"map_menu":   [KEY_M],
	"inv_menu":   [KEY_U, KEY_I],
	"quest_menu": [KEY_N],
	"bomb":       [KEY_F],
	"ult":        [KEY_V],
	"restart":    [KEY_R],
	"interact":   [KEY_E, KEY_ENTER],
}

func _enter_tree() -> void:
	_register_inputs()

func _register_inputs() -> void:
	for action in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for keycode in ACTIONS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = keycode
			InputMap.action_add_event(action, ev)
	# 菜单导航: 让 W/S 也能上下切换(↑↓/回车为引擎默认)
	for nav in [["ui_up", KEY_W], ["ui_down", KEY_S]]:
		if InputMap.has_action(nav[0]):
			var ne := InputEventKey.new()
			ne.physical_keycode = nav[1]
			InputMap.action_add_event(nav[0], ne)
	# 鼠标: 左键攻击, 右键冲刺
	if InputMap.has_action("attack"):
		var mb := InputEventMouseButton.new()
		mb.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("attack", mb)
	if InputMap.has_action("dash"):
		var mb2 := InputEventMouseButton.new()
		mb2.button_index = MOUSE_BUTTON_RIGHT
		InputMap.action_add_event("dash", mb2)

## 命中顿帧: 短暂减慢时间, 增强打击感. 用真实时间计时, 不受 time_scale 影响.
func hitstop(duration: float = 0.07, scale: float = 0.04) -> void:
	_hitstop_token += 1
	var my_token := _hitstop_token
	Engine.time_scale = scale
	await get_tree().create_timer(duration, true, false, true).timeout
	# 只有最后一个 hitstop 负责恢复, 避免叠加时提前恢复
	if my_token == _hitstop_token:
		Engine.time_scale = 1.0

## 屏幕震动: 通知 camera 组
func shake(amount: float = 5.0) -> void:
	get_tree().call_group("camera", "add_trauma", amount)

func add_kill() -> void:
	kills += 1
	enemy_killed.emit(kills)
