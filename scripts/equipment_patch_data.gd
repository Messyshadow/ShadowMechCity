class_name EquipmentPatchData
extends RefCounted
## 11.2a 装备量子补丁纯数据层：迁移、报价和属性预览，不执行扣款或升级。

const BRANDS := {
	"forge_soul": {"name":"铸魂工坊", "focus":"近战 / 破防", "accent":Color("ff9d4d")},
	"void_steam": {"name":"虚空蒸汽局", "focus":"远程 / 控场", "accent":Color("53d9ff")},
	"abyss_incubator": {"name":"深渊孵化所", "focus":"持续伤害", "accent":Color("c778ff")},
	"relic_rune": {"name":"遗迹符文院", "focus":"护盾 / 反弹", "accent":Color("e8ca71")},
	"quantum_void": {"name":"量子虚空研究所", "focus":"暴击 / 吸血", "accent":Color("7affc8")},
}

const QUALITIES := ["standard", "refined", "epic", "legendary"]
const QUALITY_NAMES := {"standard":"标准", "refined":"精制", "epic":"史诗", "legendary":"传奇"}
const QUALITY_MULTIPLIERS := [1.0, 1.55, 2.35, 3.45]
const PATCH_LIBRARY := {
	"core_sync": {"name":"核心同步补丁", "rarity":1, "stat_scale":0.12},
	"overclock": {"name":"超频固件", "rarity":2, "stat_scale":0.15},
	"void_kernel": {"name":"虚空内核", "rarity":3, "stat_scale":0.18},
}
const STAT_KEYS := ["atk", "def", "hp", "crit", "ls", "spd"]


static func is_equipment(item: Dictionary) -> bool:
	return item.has("slot") or str(item.get("kind", "")) == "weapon"


static func quality_tier(item: Dictionary) -> int:
	var quality := str(item.get("quality", ""))
	var index := QUALITIES.find(quality)
	return index if index >= 0 else clampi(int(item.get("rarity", 0)), 0, 3)


static func _default_brand(item: Dictionary) -> String:
	match str(item.get("slot", "")):
		"gloves", "boots": return "forge_soul"
		"helmet", "armor": return "relic_rune"
		"amulet": return "quantum_void"
		"ring": return "abyss_incubator"
		_: return "void_steam"


static func _stable_id(item: Dictionary, location_key: String) -> String:
	var identity := "%s|%s|%s|%s|%d" % [
		location_key, item.get("item_id", item.get("weapon_id", "")),
		item.get("name", "equipment"), item.get("slot", item.get("kind", "")),
		int(item.get("rarity", 0)),
	]
	return "gear_" + identity.sha256_text().left(16)


static func ensure_item(source: Dictionary, location_key: String, used_ids: Dictionary = {}) -> Dictionary:
	var item := source.duplicate(true)
	if not is_equipment(item):
		return item
	var instance_id := str(item.get("item_instance_id", ""))
	if instance_id == "" or used_ids.has(instance_id):
		instance_id = _stable_id(item, location_key)
		var suffix := 2
		while used_ids.has(instance_id):
			instance_id = _stable_id(item, "%s:%d" % [location_key, suffix])
			suffix += 1
	item["item_instance_id"] = instance_id
	used_ids[instance_id] = true
	var tier := quality_tier(item)
	item["quality"] = QUALITIES[tier]
	item["brand_id"] = str(item.get("brand_id", _default_brand(item)))
	if not BRANDS.has(item["brand_id"]):
		item["brand_id"] = _default_brand(item)
	item["patch_level"] = maxi(0, int(item.get("patch_level", item.get("lv", 0))))
	item["lv"] = maxi(0, int(item.get("lv", item["patch_level"])))
	item["patches"] = item.get("patches", []) if item.get("patches", []) is Array else []
	item["cosmetic_id"] = str(item.get("cosmetic_id", "%s_factory" % item["brand_id"]))
	return item


static func migrate_equipment(inventory_value, equipped_value) -> Dictionary:
	var used_ids := {}
	var inventory: Array = []
	if inventory_value is Array:
		for index in range(inventory_value.size()):
			var entry = inventory_value[index]
			inventory.append(ensure_item(entry, "inventory:%d" % index, used_ids) if entry is Dictionary else entry)
	var equipped := {}
	if equipped_value is Dictionary:
		var slots: Array = equipped_value.keys()
		slots.sort()
		for slot in slots:
			var entry = equipped_value[slot]
			equipped[slot] = ensure_item(entry, "equipped:%s" % str(slot), used_ids) if entry is Dictionary else entry
	return {"inventory":inventory, "equipped":equipped}


static func upgrade_quote(item: Dictionary, patch_id: String = "core_sync") -> Dictionary:
	var tier := quality_tier(item)
	var level := maxi(0, int(item.get("patch_level", item.get("lv", 0))))
	var patch: Dictionary = PATCH_LIBRARY.get(patch_id, PATCH_LIBRARY["core_sync"])
	var rarity_factor := 1.0 + 0.35 * maxi(0, int(patch.get("rarity", 1)) - 1)
	var cost := int(round(35.0 * QUALITY_MULTIPLIERS[tier] * pow(level + 1, 2) * rarity_factor))
	return {"cost":cost, "from_level":level, "to_level":level + 1, "patch_id":patch_id, "quality":QUALITIES[tier]}


static func attribute_preview(item: Dictionary, patch_id: String = "core_sync") -> Dictionary:
	var level := maxi(0, int(item.get("patch_level", item.get("lv", 0))))
	var patch: Dictionary = PATCH_LIBRARY.get(patch_id, PATCH_LIBRARY["core_sync"])
	var scale := float(patch.get("stat_scale", 0.12))
	var before := {}
	var after := {}
	for stat in STAT_KEYS:
		var base := float(item.get(stat, 0.0))
		before[stat] = base * (1.0 + scale * level)
		after[stat] = base * (1.0 + scale * (level + 1))
	return {"before":before, "after":after, "quote":upgrade_quote(item, patch_id)}
