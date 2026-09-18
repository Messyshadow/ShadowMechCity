extends RefCounted
## Learned nodes stay in the existing skills dictionary. Only cooldowns and loadout persist.
const BRANCHES := ["shadow", "mechanical"]
const NAMES := {"shadow":"暗影", "mechanical":"机械"}
const COLORS := {"shadow":Color(.65,.3,1), "mechanical":Color(1,.57,.14)}
const NODES := {
	"shadow":["shadow_guard","shadow_step","shadow_edge","shadow_form","shadow_summon","shadow_mastery"],
	"mechanical":["core_shell","fast_loader","overclock","mechanical_form","mechanical_summon","mechanical_mastery"]
}
const FORM_NAMES := {"shadow":"夜幕化身", "mechanical":"炉心战甲"}
const SUMMON_NAMES := {"shadow":"影侍投影", "mechanical":"浮游炮台"}
static func fresh() -> Dictionary:return {"branch":"shadow","form_cd":0.0,"summon_cd":0.0}
static func sanitize(value:Variant) -> Dictionary:
	var result:=fresh()
	if not value is Dictionary:return result
	if value.get("branch","") in BRANCHES:result.branch=str(value.branch)
	for key in ["form_cd","summon_cd"]:
		var number:Variant=value.get(key,0)
		if (number is float or number is int) and is_finite(float(number)):
			result[key]=clampf(float(number),0,30 if key=="form_cd" else 22)
	return result
static func spent(state:Node,branch:String) -> int:
	var total:=0
	for id in NODES.get(branch,[]):
		if state.skills.has(id):total+=int(state.SKILLS[id][4])
	return total
static func duration(state:Node,branch:String,summon:=false) -> float:
	return (12.0 if summon else 10.0)+(4.0 if state.skills.has(branch+"_mastery") else 0.0)
