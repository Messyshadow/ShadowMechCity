class_name SkillsData
extends RefCounted
## 技能树定义 (功能性子集, 对应 docs/skill_tree.md 的 5 大分支)
## id/name/branch/max/cost/req(前置)/desc

const TREE := [
	# 基础(蓝)
	{"id": "hp", "name": "生命强化", "branch": "基础", "max": 3, "cost": 1, "req": [], "desc": "最大生命 +1"},
	{"id": "power", "name": "能量强化", "branch": "基础", "max": 3, "cost": 1, "req": [], "desc": "斩击波/技能伤害 +1"},
	# 移动(绿)
	{"id": "speed", "name": "疾行", "branch": "移动", "max": 3, "cost": 1, "req": [], "desc": "移动速度 +8%"},
	{"id": "dashcd", "name": "迅捷冲刺", "branch": "移动", "max": 3, "cost": 1, "req": [], "desc": "冲刺冷却 -0.1s"},
	{"id": "triple", "name": "三段跳", "branch": "移动", "max": 1, "cost": 2, "req": ["speed"], "desc": "额外获得一段空中跳"},
	# 战斗(红)
	{"id": "atk", "name": "近战强化", "branch": "战斗", "max": 3, "cost": 1, "req": [], "desc": "近战伤害 +1"},
	{"id": "crit", "name": "暴击强化", "branch": "战斗", "max": 3, "cost": 1, "req": ["atk"], "desc": "暴击率 +12%"},
	{"id": "lifesteal", "name": "吸血攻击", "branch": "战斗", "max": 2, "cost": 2, "req": ["atk"], "desc": "命中有几率回血"},
	{"id": "wave", "name": "剑气波强化", "branch": "战斗", "max": 3, "cost": 1, "req": [], "desc": "斩击波穿透 +1"},
	{"id": "spin", "name": "旋风斩", "branch": "战斗", "max": 1, "cost": 2, "req": ["atk"], "desc": "连击终结化为范围旋风斩"},
	# 机械超频(青) - 主动技能强化(技力/怒气体系)
	{"id": "mp_max", "name": "技力强化", "branch": "超频", "max": 3, "cost": 1, "req": [], "desc": "技力上限 +20"},
	{"id": "mp_regen", "name": "技力回流", "branch": "超频", "max": 3, "cost": 1, "req": ["mp_max"], "desc": "技力回复 +3/s"},
	{"id": "skill_dmg", "name": "过载输出", "branch": "超频", "max": 3, "cost": 1, "req": [], "desc": "主动技能伤害 +15%"},
	{"id": "skill_cd", "name": "招式精通", "branch": "超频", "max": 2, "cost": 2, "req": ["skill_dmg"], "desc": "招式冷却 -15%"},
	# 探索(黄)
	{"id": "magnet", "name": "拾取吸附", "branch": "探索", "max": 1, "cost": 1, "req": [], "desc": "金币/经验自动吸附"},
	# 终极(紫)
	{"id": "ultimate", "name": "终极剑技", "branch": "终极", "max": 1, "cost": 3, "req": ["spin", "crit"], "desc": "全属性强化, 打击更狠"},
]

static func by_branch() -> Dictionary:
	var d := {}
	for n in TREE:
		d.get_or_add(n["branch"], []).append(n)
	return d
