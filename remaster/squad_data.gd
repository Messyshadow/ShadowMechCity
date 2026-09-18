extends RefCounted
## The four keys are stable instance identities in this remaster save.
const PROFILES={
	"hound":{"name":"先锋犬 MK-I","role":"地面 · 近战护卫","hp":60.0,"damage":10.0,"range":1.8,"cooldown":1.25,"air":false,"color":Color(.2,.85,1)},
	"mole":{"name":"壁垒鼹 MK-I","role":"地面 · 重装盾卫","hp":95.0,"damage":5.0,"range":1.6,"cooldown":1.5,"air":false,"color":Color(1,.65,.2)},
	"bee":{"name":"天轨蜂 MK-I","role":"空中 · 远程炮击","hp":45.0,"damage":12.0,"range":7.5,"cooldown":1.8,"air":true,"color":Color(.8,.4,1)},
	"wisp":{"name":"流明萤 MK-I","role":"空中 · 修复支援","hp":50.0,"damage":0.0,"range":5.0,"cooldown":5.0,"air":true,"color":Color(.3,1,.65)}
}
static func fresh() -> Dictionary:return {"slots":1,"loadout":["hound"],"deployed":false,"status":{},"heat":0.0,"lock":0.0}
static func slot_cost(slots:int) -> int:return 2 if slots==1 else 3 if slots==2 else 0
static func finite_number(value:Variant) -> bool:return (value is int or value is float) and is_finite(float(value))
static func valid(value:Variant) -> bool:
	if not value is Dictionary:return false
	if not finite_number(value.get("slots")) or int(value.slots)<1 or int(value.slots)>3:return false
	if not value.get("deployed") is bool or not value.get("loadout") is Array or not value.get("status") is Dictionary:return false
	if value.loadout.is_empty() or value.loadout.size()>int(value.slots):return false
	var seen:Dictionary={}
	for id in value.loadout:
		if not id is String or not PROFILES.has(id) or seen.has(id):return false
		seen[id]=true
	for key in ["heat","lock"]:
		if not finite_number(value.get(key)) or float(value[key])<0:return false
	for id in value.status:
		if not PROFILES.has(id) or not value.status[id] is Dictionary:return false
		for key in ["hp","rebuild"]:
			if not finite_number(value.status[id].get(key)) or float(value.status[id][key])<0:return false
	return true
