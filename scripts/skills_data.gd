class_name SkillsData
extends RefCounted
## 13A 空间技能图谱。旧技能 ID 保持不变，保证历史存档兼容。

const PAGES := ["基础", "身法", "战斗", "探索"]
const FAMILIES := ["刀剑", "铁锤", "蒸汽枪炮", "双刀", "长枪", "弓弩"]

const TREE := [
	{"id":"hp", "name":"生命强化", "page":"基础", "family":"", "pos":Vector2(120,220),
	 "type":"被动", "max":3, "cost":1, "req":[], "desc":"最大生命 +1",
	 "usage":"自动生效；适合需要更多容错的近战构筑。", "input":"自动生效", "preview":"idle_guard"},
	{"id":"power", "name":"能量强化", "page":"基础", "family":"", "pos":Vector2(300,120),
	 "type":"被动", "max":3, "cost":1, "req":[], "desc":"技能基础伤害 +1",
	 "usage":"释放任意主动技能时自动计入伤害。", "input":"自动生效", "preview":"skill_cast"},
	{"id":"mp_max", "name":"技力强化", "page":"基础", "family":"", "pos":Vector2(300,300),
	 "type":"被动", "max":3, "cost":1, "req":[], "desc":"技力上限 +20",
	 "usage":"自动提高蓝色技力槽上限，适合连续释放招式。", "input":"自动生效", "preview":"skill_cast"},
	{"id":"mp_regen", "name":"技力回流", "page":"基础", "family":"", "pos":Vector2(500,320),
	 "type":"被动", "max":3, "cost":1, "req":["mp_max"], "desc":"技力回复 +3/秒",
	 "usage":"战斗与探索中持续生效；技力未满时可见回复。", "input":"自动生效", "preview":"idle_guard"},
	{"id":"skill_dmg", "name":"过载输出", "page":"基础", "family":"", "pos":Vector2(500,100),
	 "type":"被动", "max":3, "cost":1, "req":["power"], "desc":"主动技能伤害 +15%",
	 "usage":"使用 K 方向技或 V 终结技时自动生效。", "input":"K / 方向+K / V", "preview":"skill_cast"},
	{"id":"skill_cd", "name":"招式精通", "page":"基础", "family":"", "pos":Vector2(660,180),
	 "type":"被动", "max":2, "cost":2, "req":["skill_dmg"], "desc":"主动技能冷却 -15%",
	 "usage":"主动技能进入冷却时自动缩短等待时间。", "input":"自动生效", "preview":"skill_cast"},
	{"id":"speed", "name":"疾行", "page":"身法", "family":"", "pos":Vector2(120,220),
	 "type":"被动", "max":3, "cost":1, "req":[], "desc":"移动速度 +8%",
	 "usage":"地面移动时持续生效，不改变空中惯性。", "input":"A / D", "preview":"run"},
	{"id":"dashcd", "name":"迅捷冲刺", "page":"身法", "family":"", "pos":Vector2(340,120),
	 "type":"被动", "max":3, "cost":1, "req":["speed"], "desc":"冲刺冷却 -0.1秒",
	 "usage":"每次冲刺结束后自动缩短再次冲刺的等待。", "input":"Shift / L", "preview":"dash"},
	{"id":"triple", "name":"三段跳", "page":"身法", "family":"", "pos":Vector2(340,320),
	 "type":"主动能力", "max":1, "cost":2, "req":["speed"], "desc":"额外获得一段空中跳",
	 "usage":"离地后再次按跳跃；新增一段空中跳次数。", "input":"空中 Space", "preview":"jump"},
	{"id":"atk", "name":"近战强化", "page":"战斗", "family":"刀剑", "pos":Vector2(100,220),
	 "type":"被动", "max":3, "cost":1, "req":[], "desc":"近战伤害 +1",
	 "usage":"装备刀剑并命中时自动生效。", "input":"自动生效", "preview":"attack_1"},
	{"id":"crit", "name":"暴击强化", "page":"战斗", "family":"刀剑", "pos":Vector2(300,80),
	 "type":"被动", "max":3, "cost":1, "req":["atk"], "desc":"暴击率 +12%",
	 "usage":"刀剑攻击命中时自动掷出暴击判定；暴击显示强化闪光。", "input":"自动生效", "preview":"attack_2"},
	{"id":"lifesteal", "name":"吸血攻击", "page":"战斗", "family":"刀剑", "pos":Vector2(300,220),
	 "type":"被动", "max":2, "cost":2, "req":["atk"], "desc":"命中有几率回复生命",
	 "usage":"近战命中敌人时自动判定；满生命时不会浪费视觉提示。", "input":"J / K 命中", "preview":"attack_2"},
	{"id":"wave", "name":"剑气波强化", "page":"战斗", "family":"刀剑", "pos":Vector2(300,360),
	 "type":"被动", "max":3, "cost":1, "req":["atk"], "desc":"斩击波穿透 +1",
	 "usage":"释放地面波时自动增加可穿透目标数量。", "input":"↓ + K", "preview":"skill_wave"},
	{"id":"spin", "name":"旋风斩", "page":"战斗", "family":"刀剑", "pos":Vector2(460,220),
	 "type":"组合", "max":1, "cost":2, "req":["atk"], "desc":"连段终结化为范围旋风斩",
	 "usage":"第三次轻攻击命中前继续按 J；适合被包围时收尾。", "input":"J → J → J", "preview":"spin"},
	{"id":"ultimate", "name":"终极剑技", "page":"战斗", "family":"刀剑", "pos":Vector2(660,220),
	 "type":"终结", "max":1, "cost":3, "req":["spin","crit"], "desc":"满怒气释放刀剑终结技",
	 "usage":"怒气达到 100 后按 V；适合精英破防或 Boss 输出窗口。", "input":"怒气满 → V", "preview":"ultimate"},
	{"id":"magnet", "name":"拾取吸附", "page":"探索", "family":"", "pos":Vector2(100,220),
	 "type":"被动", "max":1, "cost":1, "req":[], "desc":"金币与经验自动吸附",
	 "usage":"靠近掉落物时自动生效，不影响能力门。", "input":"自动生效", "preview":"pickup"},
	{"id":"ability_bomb_root", "name":"爆破共鸣", "page":"探索", "family":"", "pos":Vector2(300,80),
	 "type":"能力根", "max":0, "cost":0, "req":[], "ability_required":"bomb", "desc":"炸弹能力强化入口",
	 "usage":"在熔岩腔穴取得炸弹后开放；13A 仅展示获取状态。", "input":"F", "preview":"bomb"},
	{"id":"ability_wall_root", "name":"壁行共鸣", "page":"探索", "family":"", "pos":Vector2(300,180),
	 "type":"能力根", "max":0, "cost":0, "req":[], "ability_required":"wall_climb", "desc":"攀墙能力强化入口",
	 "usage":"取得攀墙后开放；13A 仅展示获取状态。", "input":"贴墙 W / S", "preview":"climb"},
	{"id":"ability_aqua_root", "name":"深潜共鸣", "page":"探索", "family":"", "pos":Vector2(300,280),
	 "type":"能力根", "max":0, "cost":0, "req":[], "ability_required":"aqua", "desc":"水下推进强化入口",
	 "usage":"取得水下推进器后开放；13A 仅展示获取状态。", "input":"水中 Shift / L", "preview":"swim"},
	{"id":"ability_glider_root", "name":"暗翼共鸣", "page":"探索", "family":"", "pos":Vector2(300,380),
	 "type":"能力根", "max":0, "cost":0, "req":[], "ability_required":"glide", "desc":"滑翔与暗影滑翔强化入口",
	 "usage":"取得滑翔翼后开放；暗影滑翔翼继续兼容旧 glide。", "input":"下落时按住 Space", "preview":"glide"},
	{"id":"family_hammer_root", "name":"铁锤战技", "page":"战斗", "family":"铁锤", "pos":Vector2(120,220),
	 "type":"家族根", "max":0, "cost":0, "req":[], "weapon_required":"hammer", "desc":"铁锤专属技能树入口",
	 "usage":"现有铁锤招式保持可用；专属可加点节点在 13B 交付。", "input":"J / 方向+K", "preview":"hammer_attack"},
	{"id":"family_cannon_root", "name":"蒸汽枪炮战技", "page":"战斗", "family":"蒸汽枪炮", "pos":Vector2(120,220),
	 "type":"家族根", "max":0, "cost":0, "req":[], "weapon_required":"cannon", "desc":"蒸汽枪炮技能树入口",
	 "usage":"现有蒸汽炮招式保持可用；专属可加点节点在 13B 交付。", "input":"J / 方向+K", "preview":"cannon_attack"},
	{"id":"family_dual_root", "name":"双刀战技", "page":"战斗", "family":"双刀", "pos":Vector2(120,220),
	 "type":"家族根", "max":0, "cost":0, "req":[], "weapon_required":"dual_blades", "desc":"双刀装备与技能树入口",
	 "usage":"取得双刀后开放；装备和技能在 13B 同批交付。", "input":"取得武器后显示", "preview":"locked_weapon"},
	{"id":"family_spear_root", "name":"长枪战技", "page":"战斗", "family":"长枪", "pos":Vector2(120,220),
	 "type":"家族根", "max":0, "cost":0, "req":[], "weapon_required":"spear", "desc":"长枪装备与技能树入口",
	 "usage":"取得长枪后开放；装备和技能在 13B 同批交付。", "input":"取得武器后显示", "preview":"locked_weapon"},
	{"id":"family_crossbow_root", "name":"弓弩战技", "page":"战斗", "family":"弓弩", "pos":Vector2(120,220),
	 "type":"家族根", "max":0, "cost":0, "req":[], "weapon_required":"crossbow", "desc":"弓弩装备与技能树入口",
	 "usage":"取得弓弩后开放；装备和技能在 13B 同批交付。", "input":"取得武器后显示", "preview":"locked_weapon"},
]

static func nodes_for(page: String, family: String = "") -> Array:
	var result: Array = []
	for node in TREE:
		if node["page"] == page and (page != "战斗" or node.get("family", "") == family):
			result.append(node)
	return result

static func by_branch() -> Dictionary:
	var result := {}
	for node in TREE:
		var branch: String = node["page"]
		if branch == "身法":
			branch = "移动"
		elif branch == "基础" and str(node["id"]) in ["mp_max", "mp_regen", "skill_dmg", "skill_cd"]:
			branch = "超频"
		elif node["id"] == "ultimate":
			branch = "终极"
		result.get_or_add(branch, []).append(node)
	return result

static func modifiers(levels: Dictionary) -> Dictionary:
	return {
		"max_health": float(levels.get("hp", 0)),
		"attack_flat": float(levels.get("atk", 0) + levels.get("power", 0)),
		"crit_chance": 0.12 * float(levels.get("crit", 0)),
		"move_speed_percent": 0.08 * float(levels.get("speed", 0)),
		"max_mp": 20.0 * float(levels.get("mp_max", 0)),
		"mp_regen": 3.0 * float(levels.get("mp_regen", 0)),
		"skill_damage_percent": 0.15 * float(levels.get("skill_dmg", 0)),
		"cooldown_reduction": 0.15 * float(levels.get("skill_cd", 0)),
	}
