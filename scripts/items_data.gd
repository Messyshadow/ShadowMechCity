class_name ItemsData
extends RefCounted
## 装备数据: 槽位 / 稀有度 / 词条 / 随机生成 / 强化

# 槽位 -> 中文名 + 主词条
const SLOTS := {
	"helmet": {"name": "头盔", "stats": ["hp", "def"]},
	"armor":  {"name": "铠甲", "stats": ["def", "hp"]},
	"gloves": {"name": "护手", "stats": ["atk", "crit"]},
	"boots":  {"name": "战靴", "stats": ["spd", "def"]},
	"amulet": {"name": "护符", "stats": ["crit", "ls"]},
	"ring":   {"name": "戒指", "stats": ["atk", "ls"]},
}
const SLOT_ORDER := ["helmet", "armor", "gloves", "boots", "amulet", "ring"]

# 稀有度: 名称 / 颜色 / 词条数 / 数值倍率
const RARITY := [
	{"name": "普通", "color": Color(0.8, 0.85, 0.9), "affixes": 1, "mult": 1.0},
	{"name": "稀有", "color": Color(0.4, 0.7, 1.0), "affixes": 2, "mult": 1.5},
	{"name": "史诗", "color": Color(0.75, 0.45, 1.0), "affixes": 3, "mult": 2.2},
	{"name": "传奇", "color": Color(1.0, 0.65, 0.2), "affixes": 4, "mult": 3.2},
]

const STAT_NAME := {
	"atk": "攻击", "def": "防御", "hp": "生命", "crit": "暴击率", "ls": "吸血", "spd": "移速",
}

# 词条基础值(普通1件的量级)
const STAT_BASE := {
	"atk": 1.0, "def": 1.0, "hp": 1.0, "crit": 0.05, "ls": 1.0, "spd": 0.04,
}

static func rarity_color(r: int) -> Color:
	return RARITY[clampi(r, 0, 3)]["color"]

static func stat_text(stat: String, val) -> String:
	if stat == "crit" or stat == "spd":
		return "%s +%d%%" % [STAT_NAME[stat], int(round(val * 100.0))]
	return "%s +%d" % [STAT_NAME[stat], int(round(val))]

## 随机生成一件装备. rarity 不传则按权重随机.
static func generate(rarity: int = -1) -> Dictionary:
	if rarity < 0:
		var roll := randf()
		rarity = 0 if roll < 0.55 else (1 if roll < 0.83 else (2 if roll < 0.96 else 3))
	var slot: String = SLOT_ORDER[randi() % SLOT_ORDER.size()]
	var rd: Dictionary = RARITY[rarity]
	var item := {
		"slot": slot, "rarity": rarity, "lv": 0,
		"atk": 0.0, "def": 0.0, "hp": 0.0, "crit": 0.0, "ls": 0.0, "spd": 0.0,
	}
	# 词条: 优先主词条, 再随机补
	var pool: Array = SLOTS[slot]["stats"].duplicate()
	for s in ["atk", "def", "hp", "crit", "ls", "spd"]:
		if not pool.has(s):
			pool.append(s)
	var n: int = rd["affixes"]
	for i in range(n):
		var stat: String = pool[i] if i < pool.size() else pool[randi() % pool.size()]
		var amt: float = STAT_BASE[stat] * rd["mult"] * randf_range(0.8, 1.3)
		# hp 取整且偏小(以心为单位)
		if stat == "hp":
			amt = max(1.0, round(STAT_BASE["hp"] * (1.0 if rarity < 2 else 2.0)))
		item[stat] += amt
	item["name"] = "%s·%s" % [rd["name"], SLOTS[slot]["name"]]
	return item

## 单件装备某属性的有效值(含强化等级 +12%/级)
static func value(item: Dictionary, stat: String) -> float:
	if item == null or not item.has(stat):
		return 0.0
	return float(item[stat]) * (1.0 + 0.12 * int(item.get("lv", 0)))

## 强化花费
static func enhance_cost(item: Dictionary) -> int:
	return (int(item["rarity"]) + 1) * 25 * (int(item.get("lv", 0)) + 1)
