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
	 "usage":"在熔炉区秘室取得影铸双刃后开放。", "input":"J / K / 方向+K", "preview":"dual_attack"},
	{"id":"dual_edge", "name":"双刃同步", "page":"战斗", "family":"双刀", "pos":Vector2(300,105),
	 "type":"被动", "max":3, "cost":1, "req":[], "weapon_required":"dual_blades", "desc":"双刀轻攻击伤害 +1/级",
	 "usage":"装备影铸双刃后，J 连击命中自动生效。", "input":"J 连击", "preview":"dual_attack"},
	{"id":"dual_cross", "name":"交叉切割", "page":"战斗", "family":"双刀", "pos":Vector2(300,335),
	 "type":"主动强化", "max":3, "cost":1, "req":["dual_edge"], "weapon_required":"dual_blades", "desc":"K 交叉处决伤害倍率 +0.12/级",
	 "usage":"贴近敌人按 K，以两道交叉刃光处决硬直目标。", "input":"K", "preview":"dual_heavy"},
	{"id":"dual_execution", "name":"影步处决", "page":"战斗", "family":"双刀", "pos":Vector2(520,220),
	 "type":"组合", "max":1, "cost":2, "req":["dual_edge","dual_cross"], "weapon_required":"dual_blades", "desc":"影步追击强化并使四连终结额外伤害 +2",
	 "usage":"先以 J×4 留下刃痕，再双击方向并按 K 穿身追击。", "input":"J → J → J → J，随后 → → + K", "preview":"dual_combo"},
	{"id":"family_spear_root", "name":"长枪战技", "page":"战斗", "family":"长枪", "pos":Vector2(120,220),
	 "type":"家族根", "max":0, "cost":0, "req":[], "weapon_required":"spear", "desc":"长枪装备与技能树入口",
	 "usage":"在遗迹圣殿秘室取得天穹齿轮枪后开放。", "input":"J / K / 方向+K", "preview":"spear_attack"},
	{"id":"spear_mastery", "name":"枪锋校准", "page":"战斗", "family":"长枪", "pos":Vector2(300,105),
	 "type":"被动", "max":3, "cost":1, "req":[], "weapon_required":"spear", "desc":"长枪轻攻击伤害 +1/级",
	 "usage":"保持中距离，以枪尖 J 连击命中自动生效。", "input":"J 连击", "preview":"spear_attack"},
	{"id":"spear_charge", "name":"蓄势贯穿", "page":"战斗", "family":"长枪", "pos":Vector2(300,335),
	 "type":"主动强化", "max":3, "cost":1, "req":["spear_mastery"], "weapon_required":"spear", "desc":"K 贯穿刺伤害倍率 +0.14/级",
	 "usage":"与敌人保持一段枪身距离按 K，贯穿直线目标。", "input":"K", "preview":"spear_heavy"},
	{"id":"spear_dragon", "name":"天穹龙贯", "page":"战斗", "family":"长枪", "pos":Vector2(520,220),
	 "type":"组合", "max":1, "cost":2, "req":["spear_mastery","spear_charge"], "weapon_required":"spear", "desc":"冲锋贯穿获得更高伤害与击退",
	 "usage":"用 ↑+K 挑空敌人，落地后双击方向并按 K 贯穿整条战线。", "input":"↑ + K，随后 → → + K", "preview":"spear_combo"},
	{"id":"family_crossbow_root", "name":"弓弩战技", "page":"战斗", "family":"弓弩", "pos":Vector2(120,220),
	 "type":"家族根", "max":0, "cost":0, "req":[], "weapon_required":"crossbow", "desc":"弓弩装备与技能树入口",
	 "usage":"在虚空要塞秘室取得裂隙连发弩后开放。", "input":"J / K / 方向+K", "preview":"crossbow_attack"},
	{"id":"crossbow_focus", "name":"弱点校准", "page":"战斗", "family":"弓弩", "pos":Vector2(300,105),
	 "type":"被动", "max":3, "cost":1, "req":[], "weapon_required":"crossbow", "desc":"弓弩普通箭伤害 +1/级",
	 "usage":"装备裂隙连发弩后，J 射击自动应用弱点校准。", "input":"J 射击", "preview":"crossbow_attack"},
	{"id":"crossbow_burst", "name":"爆裂弩机", "page":"战斗", "family":"弓弩", "pos":Vector2(300,335),
	 "type":"主动强化", "max":3, "cost":1, "req":["crossbow_focus"], "weapon_required":"crossbow", "desc":"K 重弩伤害倍率 +0.14/级",
	 "usage":"瞄准直线精英按 K，发射高穿透爆裂重弩。", "input":"K", "preview":"crossbow_heavy"},
	{"id":"crossbow_barrage", "name":"裂隙钉阵", "page":"战斗", "family":"弓弩", "pos":Vector2(520,220),
	 "type":"组合", "max":1, "cost":2, "req":["crossbow_focus","crossbow_burst"], "weapon_required":"crossbow", "desc":"环射钉阵每枚箭矢伤害倍率 +0.15",
	 "usage":"先以 J×2 固定射击节奏，再双击下并按 K 释放十方向钉阵。", "input":"J → J，随后 ↓ ↓ + K", "preview":"crossbow_combo"},
	{"id": "sword_resonance", "name":"共鸣剑波", "page":"战斗", "family":"刀剑", "pos":Vector2(500,360),
	 "type":"功能主动", "max":1, "cost":1, "req":["wave"], "weapon_required":"sword", "desc":"剑气隔空启动青色共鸣机关",
	 "usage":"面向共鸣机括按 K；剑波只启动明确标记的机关，不破坏墙体。", "input":"K", "preview":"skill_wave",
	 "interaction_tags":["sword_wave"], "resource_rule":"消耗地面技力；不可提供无限位移", "preview_stages":["startup","travel","impact","interaction","recovery"], "environment_use":"激活青色剑波继电器并展开短桥"},
	{"id": "hammer_demolition", "name":"熔炉震碎", "page":"战斗", "family":"铁锤", "pos":Vector2(350,220),
	 "type":"功能主动", "max":1, "cost":1, "req":[], "weapon_required":"hammer", "desc":"完整重击粉碎橙色脆岩与松动机械墙",
	 "usage":"贴近橙色裂纹墙按 K；炸弹仍可处理允许双解的脆墙。", "input":"K", "preview":"hammer_attack",
	 "interaction_tags":["hammer_charge"], "resource_rule":"受 K 技冷却限制；仅作用于脆墙", "preview_stages":["startup","travel","impact","interaction","recovery"], "environment_use":"粉碎橙色裂纹墙，兼容炸弹双解"},
	{"id": "cannon_steam_jet", "name":"蒸汽跃迁", "page":"战斗", "family":"蒸汽枪炮", "pos":Vector2(350,220),
	 "type":"功能主动", "max":1, "cost":1, "req":[], "weapon_required":"cannon", "desc":"借高压喷口完成一次短时悬浮跃迁",
	 "usage":"靠近白蓝蒸汽锚按 ↑+K；只在锚点响应时获得推进。", "input":"↑ + K", "preview":"jump",
	 "interaction_tags":["cannon_steam"], "resource_rule":"消耗上挑技力；锚点有 1 秒冷却", "preview_stages":["startup","travel","impact","interaction","recovery"], "environment_use":"在高压蒸汽锚获得一次向上横移"},
	{"id": "dual_grapple", "name":"影索回弹", "page":"战斗", "family":"双刀", "pos":Vector2(520,360),
	 "type":"功能身法", "max":1, "cost":2, "req":["dual_edge"], "weapon_required":"dual_blades", "desc":"抓取紫色机械环并立即弹射",
	 "usage":"面向紫色锚点双击方向后按 K；不能抓取普通墙面。", "input":"→ → + K", "preview":"dash",
	 "interaction_tags":["dual_grapple"], "resource_rule":"消耗突进技力；锚点冷却且不悬挂", "preview_stages":["startup","travel","impact","interaction","recovery"], "environment_use":"从紫色锚点获得一次定向上弹"},
	{"id": "spear_drill", "name":"齿轮钻突", "page":"战斗", "family":"长枪", "pos":Vector2(520,360),
	 "type":"功能主动", "max":1, "cost":2, "req":["spear_charge"], "weapon_required":"spear", "desc":"钻穿带螺旋齿纹的薄型机械壁",
	 "usage":"面向金色螺旋薄壁双击方向后按 K；不能替代炸弹墙。", "input":"→ → + K", "preview":"spear_combo",
	 "interaction_tags":["spear_drill"], "resource_rule":"消耗突进技力；只穿一面标记薄壁", "preview_stages":["startup","travel","impact","interaction","recovery"], "environment_use":"钻穿金色螺旋纹机械薄壁"},
	{"id": "crossbow_remote", "name":"远程机括", "page":"战斗", "family":"弓弩", "pos":Vector2(520,360),
	 "type":"功能主动", "max":1, "cost":1, "req":["crossbow_focus"], "weapon_required":"crossbow", "desc":"重弩矢远距离启动青绿靶盘",
	 "usage":"面向青绿靶盘按 K；用于短桥和可选机关，不破坏重型墙。", "input":"K", "preview":"crossbow_heavy",
	 "interaction_tags":["crossbow_remote"], "resource_rule":"消耗地面技力；每个机关仅首次启动", "preview_stages":["startup","travel","impact","interaction","recovery"], "environment_use":"远程启动青绿靶盘并展开短桥"},
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
